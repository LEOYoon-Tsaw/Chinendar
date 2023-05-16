//
//  Delegates.swift
//  MacWidgetExtension
//
//  Created by Leo Liu on 5/9/23.
//

import CoreLocation
import CoreData
#if os(macOS)
import SystemConfiguration
#elseif os(iOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#endif

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    @Published private var _location: CGPoint?
    var location: CGPoint? {
        get {
            _location
        } set {
            _location = newValue
            if newValue == nil {
                lastUpdated = Date.distantPast
            } else {
                lastUpdated = Date()
            }
        }
    }
    let manager = CLLocationManager()
    private var completion: ((CGPoint?) -> Void)?
    private var lastUpdated = Date.distantPast
    var enabled = true

    override init() {
        super.init()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestLocation(completion: ((CGPoint?) -> Void)?) {
        if let completion = completion {
            self.completion = completion
        }
        if enabled && (lastUpdated.distance(to: Date()) > 3600) {
            switch manager.authorizationStatus {
#if os(macOS)
            case .authorized, .authorizedAlways:
                manager.startUpdatingLocation()
#else
            case .authorizedWhenInUse, .authorizedAlways:
                manager.startUpdatingLocation()
#endif
            case .notDetermined:        // Authorization not determined yet.
                manager.requestWhenInUseAuthorization()
            default:
                if let completion = completion {
                    completion(nil)
                    self.completion = nil
                }
                break
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            manager.stopUpdatingLocation()
            self.location = CGPoint(x: location.coordinate.latitude, y: location.coordinate.longitude)
            if let completion = completion {
                completion(self.location)
                self.completion = nil
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
#if os(macOS)
        case .authorized, .authorizedAlways:  // Location services are available.
            requestLocation(completion: nil)
#else
        case .authorizedWhenInUse, .authorizedAlways:  // Location services are available.
            requestLocation(completion: nil)
#endif
            
        case .restricted, .denied:
            break
            
        case .notDetermined:        // Authorization not determined yet.
            manager.requestWhenInUseAuthorization()
            
        @unknown default:
            print("Unhandled Location Authorization Case")
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
}

class DataContainer: ObservableObject {
    static let shared = DataContainer()
    
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentCloudKitContainer(name: "ChineseTime")
#if DEBUG
        do {
            // Use the container to initialize the development schema.
            try container.initializeCloudKitSchema(options: [])
        } catch let error as NSError {
            print(error.localizedDescription)
        }
#endif
        #if os(macOS)
        let prefix = Bundle.main.object(forInfoDictionaryKey: "GroupID") as! String
        let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: prefix)!
        let description = NSPersistentStoreDescription(url: url.appendingPathComponent("ChineseTime"))
        #elseif os(iOS)
        let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.ChineseTime")!
        let description = NSPersistentStoreDescription(url: url.appendingPathComponent("ChineseTime.sqlite"))
        #elseif os(watchOS)
        let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.ChineseTime.Watch")!
        let description = NSPersistentStoreDescription(url: url.appendingPathComponent("ChineseTime.sqlite"))
        #endif
        description.configuration = "Cloud"
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.YLiu.ChineseTime")
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error)")
            }
        })
        return container
    }()
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    var deviceName: String {
#if os(macOS)
        return SCDynamicStoreCopyComputerName(nil, nil).map { String($0) } ?? "Mac"
#elseif os(iOS)
        return UIDevice.current.name
#elseif os(watchOS)
        return WKInterfaceDevice.current().name
#endif
    }
    
    func present(error: NSError) {
        print(error.localizedDescription)
    }
    
    func readSave(name: String? = nil, deviceName: String? = nil) -> String? {

        try? persistentContainer.viewContext.setQueryGenerationFrom(.current)
        let managedContext = self.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Layout")
        fetchRequest.predicate = NSPredicate(format: "(name == %@) AND (deviceName == %@)", argumentArray: [name ?? NSLocalizedString("Default", comment: "Default save file name"), deviceName ?? self.deviceName])
        if let fetchedEntities = try? managedContext.fetch(fetchRequest),
            let retrievedLayout = fetchedEntities.last?.value(forKey: "code") as? String {
            return retrievedLayout
        } else {
            return nil
        }
    }
    
    func loadSave(name: String? = nil, deviceName: String? = nil) {
        
        try? persistentContainer.viewContext.setQueryGenerationFrom(.current)
        let managedContext = self.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Layout")
        fetchRequest.predicate = NSPredicate(format: "(name == %@) AND (deviceName == %@)", argumentArray: [name ?? NSLocalizedString("Default", comment: "Default save file name"), deviceName ?? self.deviceName])
        if let fetchedEntities = try? managedContext.fetch(fetchRequest),
            let savedLayout = fetchedEntities.last?.value(forKey: "code") as? String {
            WatchLayout.shared.update(from: savedLayout)
        } else {
            let filePath = Bundle.main.path(forResource: "layout", ofType: "txt")!
            let defaultLayout = try! String(contentsOfFile: filePath)
            WatchLayout.shared.update(from: defaultLayout)
        }
    }
    
    struct SavedTheme {
        var name: String
        let deviceName: String
        var modifiedDate: Date
    }
    
    func listAll() -> [SavedTheme] {
        try? persistentContainer.viewContext.setQueryGenerationFrom(.current)
        let managedContext = self.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Layout")
        var results = [SavedTheme]()
        if let fetchedEntities = try? managedContext.fetch(fetchRequest) {
            for entity in fetchedEntities {
                results.append(SavedTheme(name: (entity.value(forKey: "name") as? String) ?? NSLocalizedString("神祕檔", comment: "Unknown saved file"),
                                          deviceName: (entity.value(forKey: "deviceName") as? String) ?? "",
                                          modifiedDate: (entity.value(forKey: "modifiedDate") as? Date) ?? Date.distantPast
                                        ))
            }
        }
        return results
    }
    
    func renameSave(name: String, deviceName: String, newName: String) {
        let managedContext = self.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Layout")
        fetchRequest.predicate = NSPredicate(format: "(name == %@) AND (deviceName == %@)", argumentArray: [name, deviceName])
        if let fetchedEntities = try? managedContext.fetch(fetchRequest),
           fetchedEntities.count > 0 {
            let savedLayout = fetchedEntities.last!
            savedLayout.setValue(newName, forKey: "name")
            do {
                try managedContext.save()
            } catch let error as NSError {
                present(error: error)
            }
        }
    }
    
    func deleteSave(name: String, deviceName: String) {
        let managedContext = self.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Layout")
        if name == NSLocalizedString("神祕檔", comment: "Unknown saved file") {
            fetchRequest.predicate = NSPredicate(format: "name == NULL OR name == ''")
        } else {
            fetchRequest.predicate = NSPredicate(format: "(name == %@) AND (deviceName == %@)", argumentArray: [name, deviceName])
        }
        if let fetchedEntities = try? managedContext.fetch(fetchRequest) {
            print(fetchedEntities.count)
            for i in 0..<fetchedEntities.count {
                managedContext.delete(fetchedEntities[i])
            }
            do {
                try managedContext.save()
            } catch let error as NSError {
                present(error: error)
            }
        }
    }
    
    func saveLayout(_ layout: String, name: String? = nil) {
        let managedContext = self.persistentContainer.viewContext
        managedContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Layout")
        fetchRequest.predicate = NSPredicate(format: "(name == %@) AND (deviceName == %@)", argumentArray: [name ?? NSLocalizedString("Default", comment: "Default save file name"), deviceName])
        let savedLayout: NSManagedObject
        if let fetchedEntities = try? managedContext.fetch(fetchRequest), fetchedEntities.count > 0 {
            savedLayout = fetchedEntities.last!
            for i in 0..<(fetchedEntities.count-1) {
                managedContext.delete(fetchedEntities[i])
            }
        } else {
            let newLayoutEntity = NSEntityDescription.entity(forEntityName: "Layout", in: managedContext)!
            savedLayout = NSManagedObject(entity: newLayoutEntity, insertInto: managedContext)
        }
        savedLayout.setValue(layout, forKey: "code")
        savedLayout.setValue(Date(), forKey: "modifiedDate")
        savedLayout.setValue(name ?? NSLocalizedString("Default", comment: "Default save file name"), forKey: "name")
        savedLayout.setValue(self.deviceName, forKey: "deviceName")
        do {
            try managedContext.save()
        } catch let error as NSError {
            present(error: error)
        }
    }
}

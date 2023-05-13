//
//  Delegates.swift
//  MacWidgetExtension
//
//  Created by Leo Liu on 5/9/23.
//

import WidgetKit
import SwiftUI
import Intents
import CoreData

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
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "ChineseTime")
        #if os(macOS)
        let prefix = Bundle.main.object(forInfoDictionaryKey: "GroupID") as! String
        let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: prefix)!
        container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: url.appendingPathComponent("ChineseTime"))]
        #elseif os(iOS)
        let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.ChineseTime")!
        container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: url.appendingPathComponent("ChineseTime.sqlite"))]
        #elseif os(watchOS)
        let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.ChineseTime.Watch")!
        container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: url.appendingPathComponent("ChineseTime.sqlite"))]
        #endif
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
    
    func loadSave() {
        let managedContext = self.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Layout")
        if let fetchedEntities = try? managedContext.fetch(fetchRequest),
            let savedLayout = fetchedEntities.last?.value(forKey: "code") as? String {
            WatchLayout.shared.update(from: savedLayout)
            if fetchedEntities.count > 1 {
                for i in 0..<(fetchedEntities.count-1) {
                    managedContext.delete(fetchedEntities[i])
                }
            }
        } else {
            let filePath = Bundle.main.path(forResource: "layout", ofType: "txt")!
            let defaultLayout = try! String(contentsOfFile: filePath)
            WatchLayout.shared.update(from: defaultLayout)
        }
    }
    
    func saveLayout(_ layout: String) {
        let managedContext = self.persistentContainer.viewContext
        managedContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        let layoutEntity = NSEntityDescription.entity(forEntityName: "Layout", in: managedContext)!
        let savedLayout = NSManagedObject(entity: layoutEntity, insertInto: managedContext)
        savedLayout.setValue(layout, forKey: "code")

        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
}

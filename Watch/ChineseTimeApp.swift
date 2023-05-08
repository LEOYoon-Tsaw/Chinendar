//
//  ChineseTimeApp.swift
//  ChineseTime Watch App
//
//  Created by Leo Liu on 5/3/23.
//

import SwiftUI
import CoreData

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

class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    static let shared = LocationManager()
    
    @Published var location: CGPoint?
    let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestLocation() {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            manager.stopUpdatingLocation()
            self.location = CGPoint(x: location.coordinate.latitude, y: location.coordinate.longitude)
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:  // Location services are available.
            requestLocation()
            
        case .restricted, .denied:
            break
            
        case .notDetermined:        // Authorization not determined yet.
            manager.requestWhenInUseAuthorization()
            
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
}

@main
struct ChineseTime_Watch_App: App {
    
    init() {
        DataContainer.shared.loadSave()
        let _ = WatchConnectivityManager.shared
        LocationManager.shared.manager.requestWhenInUseAuthorization()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

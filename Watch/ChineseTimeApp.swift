//
//  ChineseTimeApp.swift
//  ChineseTime Watch App
//
//  Created by Leo Liu on 5/3/23.
//

import SwiftUI
import CoreData

func getStatusBarHeight(frameHeight height: CGFloat) -> CGFloat {
    if height <= 170 {
        return 19
    } else if height <= 195 {
        return 21
    } else if height <= 197 {
        return 28
    } else if height <= 215 {
        return 34
    } else if height <= 224 {
        return 31
    } else if height <= 242 {
        return 35
    } else if height <= 251 {
        return 37
    } else {
        return 40
    }
}

class DataContainer {
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
            WatchFace.layoutTemplate = savedLayout
            if fetchedEntities.count > 1 {
                for i in 0..<(fetchedEntities.count-1) {
                    managedContext.delete(fetchedEntities[i])
                }
            }
        } else {
            let filePath = Bundle.main.path(forResource: "layout", ofType: "txt")!
            let defaultLayout = try! String(contentsOfFile: filePath)
            WatchFace.layoutTemplate = defaultLayout
        }
    }
    
    func saveLayout(_ layout: String? = nil) -> String? {
        let managedContext = self.persistentContainer.viewContext
        managedContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        let layoutEntity = NSEntityDescription.entity(forEntityName: "Layout", in: managedContext)!
        let savedLayout = NSManagedObject(entity: layoutEntity, insertInto: managedContext)
        let encoded: String?
        if let layout = layout {
            encoded = layout
            savedLayout.setValue(layout, forKey: "code")
        } else {
            encoded = WatchFace.currentInstance?.watchLayout.encode()
            savedLayout.setValue(encoded, forKey: "code")
        }
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        return encoded
    }
}

class LocationManager: NSObject, CLLocationManagerDelegate {
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
            if let watchFace = WatchFace.currentInstance {
                watchFace.realLocation = CGPoint(x: location.coordinate.latitude, y: location.coordinate.longitude)
                watchFace.update(forceRefresh: true)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .denied:
            print("Denied")
        case .authorizedAlways:
            manager.startUpdatingLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            manager.startUpdatingLocation()
        @unknown default:
            print("Unknown")
        }
    }
}

@main
struct ChineseTime_Watch_App: App {
    
    init() {
        DataContainer.shared.loadSave()
        let _ = WatchConnectivityManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            let screen: CGRect = {
                var size = WKInterfaceDevice.current().screenBounds
                size.origin.x -= max(0, size.width - 201) / 2
                size.size.height -= getStatusBarHeight(frameHeight: size.height)
                return size
            }()
            ContentView(watchFace: WatchFace(frame: screen, compact: true))
        }
    }
}

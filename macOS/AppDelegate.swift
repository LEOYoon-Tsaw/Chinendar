//
//  AppDelegate.swift
//  ChineseTime
//
//  Created by LEO Yoon-Tsaw on 9/19/21.
//

import Cocoa
import CoreLocation
import MapKit

var locManager: CLLocationManager?
var statusItem: NSStatusItem?
func updateStatusTitle(title: String) {
    if let button = statusItem?.button {
        button.title = String(title.reversed())
        statusItem?.length = button.intrinsicContentSize.width
    }
}
func updatePosition() {
    if let frame = statusItem?.button?.window?.frame {
        WatchFace.currentInstance?.moveTopCenter(to: NSMakePoint(NSMidX(frame), NSMinY(frame)))
    }
}

@main
class AppDelegate: NSObject, NSApplicationDelegate, CLLocationManagerDelegate {
    
    func applicationWillFinishLaunching(_ aNotification: Notification) {
        locManager = CLLocationManager()
        locManager?.delegate = self
        locManager?.desiredAccuracy = kCLLocationAccuracyKilometer
        statusItem = NSStatusBar.system.statusItem(withLength: 0)
        statusItem?.button?.action = #selector(self.toggleDisplay(sender:))
        statusItem?.button?.sendAction(on: [.leftMouseDown])
    }
    
    @objc func toggleDisplay(sender: NSStatusItem) {
        if let watchFace = WatchFace.currentInstance {
            if watchFace.isVisible {
                watchFace.hide()
            } else {
                watchFace.show()
                updatePosition()
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    func applicationDidResignActive(_ notification: Notification) {
        WatchFace.currentInstance?.hide()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            manager.stopUpdatingLocation()
            if let watchFace = WatchFace.currentInstance {
                watchFace._view.location = NSMakePoint(location.coordinate.latitude, location.coordinate.longitude)
                if let controller = ConfigurationViewController.currentInstance {
                    controller.updateUI()
                } else {
                    watchFace.invalidateShadow()
                    watchFace.updateSize(with: watchFace.frame)
                    watchFace._view.drawView(forceRefresh: true)
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        NSApplication.shared.presentError(error)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .denied:
            print("Denied")
        case .authorized:
            manager.startUpdatingLocation()
        case .authorizedAlways:
            manager.startUpdatingLocation()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted:
            manager.requestWhenInUseAuthorization()
        @unknown default:
            print("Unknown")
        }
    }

    func loadSave() {
        let managedContext = self.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Layout")
        if let fetchedEntities = try? managedContext.fetch(fetchRequest),
            let savedLayout = fetchedEntities.last?.value(forKey: "code") as? String {
            WatchFaceView.layoutTemplate = savedLayout
            if fetchedEntities.count > 1 {
                for i in 0..<(fetchedEntities.count-1) {
                    managedContext.delete(fetchedEntities[i])
                }
            }
        } else {
            let filePath = Bundle.main.path(forResource: "layout", ofType: "txt")!
            let defaultLayout = try! String(contentsOfFile: filePath)
            WatchFaceView.layoutTemplate = defaultLayout
        }
    }
    
    func saveLayout() -> String? {
        let managedContext = self.persistentContainer.viewContext
        managedContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        let layoutEntity = NSEntityDescription.entity(forEntityName: "Layout", in: managedContext)!
        let savedLayout = NSManagedObject(entity: layoutEntity, insertInto: managedContext)
        let encoded = WatchFace.currentInstance?._view.watchLayout.encode()
        savedLayout.setValue(encoded, forKey: "code")
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        return encoded
    }
    
    @IBAction func saveFile(_ sender: Any) {
        let panel = NSSavePanel()
        if let watchFace = WatchFace.currentInstance {
            panel.level = watchFace.level
        }
        panel.title = NSLocalizedString("Select File", comment: "Save File")
        panel.nameFieldStringValue = "new layout.txt"
        panel.begin() {
            result in
            if result == .OK, let file = panel.url {
                do {
                    let codeString = self.saveLayout()
                    try codeString?.data(using: .utf8)?.write(to: file, options: .atomicWrite)
                } catch let error {
                    let alert = NSAlert()
                    alert.messageText = NSLocalizedString("Save Failed", comment: "Save Failed")
                    alert.informativeText = error.localizedDescription
                    alert.runModal()
                }
            }
        }
    }
    
    @IBAction func openFile(_ sender: Any) {
        let panel = NSOpenPanel()
        if let watchFace = WatchFace.currentInstance {
            panel.level = watchFace.level
        }
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedFileTypes = ["txt", "yaml"]
        panel.title = NSLocalizedString("Select Layout File", comment: "Open File")
        panel.message = NSLocalizedString("Warning: The current layout will be discarded!", comment: "Warning")
        panel.begin {
            result in
            if result == .OK, let file = panel.url {
                do {
                    let content = try String(contentsOf: file)
                    if let watchFace = WatchFace.currentInstance {
                        watchFace._view.watchLayout.update(from: content)
                        watchFace.updateSize(with: watchFace.frame)
                        watchFace._view.drawView(forceRefresh: true)
                        ConfigurationViewController.currentInstance?.updateUI()
                    }
                } catch let error {
                    let alert = NSAlert()
                    alert.messageText = NSLocalizedString("Load Failed", comment: "Load Failed")
                    alert.informativeText = error.localizedDescription
                    alert.runModal()
                }
            }
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        loadSave()
        let preview = WatchFace(position: NSZeroRect)
        if locManager?.authorizationStatus == .authorized || locManager?.authorizationStatus == .authorizedAlways {
            locManager?.startUpdatingLocation()
        }
        preview.show()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    // MARK: - Core Data stack

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

    // MARK: - Core Data Saving and Undo support

    @IBAction func saveAction(_ sender: AnyObject?) {
        // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
        let context = persistentContainer.viewContext

        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
        }
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Customize this code block to include application-specific recovery steps.
                let nserror = error as NSError
                NSApplication.shared.presentError(nserror)
            }
        }
    }

    func windowWillReturnUndoManager(window: NSWindow) -> UndoManager? {
        // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
        return persistentContainer.viewContext.undoManager
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Save changes in the application's managed object context before the application terminates.
        let context = persistentContainer.viewContext
        
        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing to terminate")
            return .terminateCancel
        }
        
        if !context.hasChanges {
            return .terminateNow
        }
        
        do {
            try context.save()
        } catch {
            let nserror = error as NSError

            // Customize this code block to include application-specific recovery steps.
            let result = sender.presentError(nserror)
            if (result) {
                return .terminateCancel
            }
            
            let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
            let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
            let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
            let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
            let alert = NSAlert()
            alert.messageText = question
            alert.informativeText = info
            alert.addButton(withTitle: quitButton)
            alert.addButton(withTitle: cancelButton)
            
            let answer = alert.runModal()
            if answer == .alertSecondButtonReturn {
                return .terminateCancel
            }
        }
        // If we got here, it is time to quit.
        return .terminateNow
    }

}


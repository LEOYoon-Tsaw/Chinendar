//
//  AppDelegate.swift
//  ChineseTime
//
//  Created by LEO Yoon-Tsaw on 9/19/21.
//

import Cocoa
import CoreLocation
import MapKit
import WidgetKit

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
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationWillFinishLaunching(_ aNotification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: 0)
        statusItem?.button?.action = #selector(self.toggleDisplay(sender:))
        statusItem?.button?.sendAction(on: [.leftMouseDown])
    }
    
    @objc func toggleDisplay(sender: NSStatusItem) {
        if let watchFace = WatchFace.currentInstance {
            if watchFace.isVisible {
                WidgetCenter.shared.reloadAllTimelines()
                watchFace.hide()
            } else {
                LocationManager.shared.requestLocation() { _ in
                    watchFace._view.drawView(forceRefresh: true)
                }
                watchFace.show()
                updatePosition()
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    func applicationDidResignActive(_ notification: Notification) {
        WatchFace.currentInstance?.hide()
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        DataContainer.shared.loadSave()
        WatchFaceView.layoutTemplate = WatchLayout.shared.encode()
        let preview = WatchFace(position: NSZeroRect)
        LocationManager.shared.requestLocation() { _ in
            WatchFace.currentInstance?._view.drawView(forceRefresh: true)
        }
        preview.show()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    // MARK: - Core Data Saving and Undo support

    func windowWillReturnUndoManager(window: NSWindow) -> UndoManager? {
        // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
        return DataContainer.shared.persistentContainer.viewContext.undoManager
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Save changes in the application's managed object context before the application terminates.
        let context = DataContainer.shared.persistentContainer.viewContext
        
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


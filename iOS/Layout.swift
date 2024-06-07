//
//  Layout.swift
//  Chinendar
//
//  Created by Leo Liu on 9/23/21.
//

import SwiftUI
import Observation
import SwiftData

@Observable final class WatchLayout: MetaWatchLayout {

    @ObservationIgnored var watchConnectivity: WatchConnectivityManager?
    var textFont = UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .regular)
    var centerFont = UIFont(name: "SourceHanSansKR-Heavy", size: UIFont.systemFontSize)!

    func sendToWatch() {
        self.watchConnectivity?.send(messages: [
            "layout": self.encode(includeOffset: false)
        ])
    }

    override func autoSave() {
        withObservationTracking {
            _ = self.encode()
        } onChange: {
            Task { @MainActor in
                let context = DataSchema.container.mainContext
                self.saveDefault(context: context)
                self.sendToWatch()
                self.autoSave()
            }
        }
    }

    var monochrome: Self {
        let emptyLayout = Self.init()
        emptyLayout.update(from: self.encode(includeColor: false))
        return emptyLayout
    }

    func binding<T>(_ keyPath: ReferenceWritableKeyPath<WatchLayout, T>) -> Binding<T> {
        return Binding(get: { self[keyPath: keyPath] }, set: { self[keyPath: keyPath] = $0 })
    }
}

@Observable class WatchSetting {

    var displayTime: Date?
    var presentSetting = false
    var vertical = true
    var effectiveTime: Date {
        displayTime ?? .now
    }
}

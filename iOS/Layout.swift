//
//  Layout.swift
//  Chinendar
//
//  Created by Leo Liu on 9/23/21.
//

import SwiftUI
import Observation

@Observable final class WatchLayout: MetaWatchLayout {
    static let shared = WatchLayout()

    var textFont = UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .regular)
    var centerFont = UIFont(name: "SourceHanSansKR-Heavy", size: UIFont.systemFontSize)!
    
    private override init() {
        super.init()
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
    static let shared = WatchSetting()
    
    var displayTime: Date? = nil
    var timezone: TimeZone? = nil
    var presentSetting = false
    var vertical = true
    
    private init() {}
}

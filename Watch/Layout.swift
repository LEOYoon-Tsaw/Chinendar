//
//  Layout.swift
//  Chinendar
//
//  Created by Leo Liu on 5/11/23.
//

import SwiftUI
import Observation

@Observable final class WatchLayout: MetaWatchLayout {
    
    var textFont = UIFont.systemFont(ofSize: 14, weight: .regular)
    var centerFont = UIFont(name: "SourceHanSansKR-Heavy", size: 14)!
    var dualWatch = false
    
    override func encode(includeOffset: Bool = true, includeColor: Bool = true) -> String {
        var encoded = super.encode(includeOffset: includeOffset, includeColor: includeColor)
        encoded += "dualWatch: \(dualWatch)\n"
        return encoded
    }

    override func update(from values: [String: String], updateSize: Bool = true) {
        super.update(from: values, updateSize: updateSize)
        if let dual = values["dualWatch"]?.boolValue {
            dualWatch = dual
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

@Observable final class WatchSetting {
    
    var size: CGSize = .zero
    var displayTime: Date? = nil
    var effectiveTime: Date {
        displayTime ?? .now
    }
}

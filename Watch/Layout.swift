//
//  Layout.swift
//  Chinendar
//
//  Created by Leo Liu on 5/11/23.
//

import SwiftUI

typealias WatchLayout = ExtraLayout<BaseLayout>

struct ExtraLayout<Base>: LayoutExpressible, Equatable where Base: LayoutExpressible, Base: Equatable {
    var baseLayout: Base
    var dualWatch = false
    
    var textFont: UIFont {
        UIFont.systemFont(ofSize: 14, weight: .regular)
    }
    var centerFont: UIFont {
        UIFont(name: "SourceHanSansKR-Heavy", size: 14)!
    }
    
    init(baseLayout: Base) {
        self.baseLayout = baseLayout
    }

    func encode(includeOffset: Bool = true, includeColor: Bool = true) -> String {
        var encoded = ""
        encoded += baseLayout.encode(includeOffset: includeOffset, includeColor: includeColor)
        encoded += "dualWatch: \(dualWatch)\n"
        return encoded
    }

    @discardableResult
    mutating func update(from code: String, updateSize: Bool = true) -> [String: String] {
        let values = baseLayout.update(from: code, updateSize: updateSize)
        if let dual = values["dualWatch"]?.boolValue {
            dualWatch = dual
        }
        return values
    }
}

struct WatchSetting: Equatable {
    enum TimeadjSelection {
        case gregorian, chinese
    }
    
    var size: CGSize = .zero
    var displayTime: Date?
    var effectiveTime: Date {
        displayTime ?? .now
    }
    var selection: TimeadjSelection = .gregorian
}

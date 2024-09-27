//
//  Layout.swift
//  Chinendar
//
//  Created by Leo Liu on 9/23/21.
//

import SwiftUI
import SwiftData

typealias WatchLayout = ExtraLayout<BaseLayout>

struct ExtraLayout<Base>: LayoutExpressible, Equatable where Base: LayoutExpressible, Base: Equatable {
    var baseLayout: Base

    var textFont: UIFont {
        UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .regular)
    }
    var centerFont: UIFont {
        UIFont(name: "SourceHanSansKR-Heavy", size: UIFont.systemFontSize)!
    }

    init(baseLayout: Base) {
        self.baseLayout = baseLayout
    }

    func encode(includeOffset: Bool = true, includeColor: Bool = true) -> String {
        baseLayout.encode(includeOffset: includeOffset, includeColor: includeColor)
    }

    @discardableResult
    mutating func update(from code: String, updateSize: Bool = true) -> [String: String] {
        baseLayout.update(from: code, updateSize: updateSize)
    }
}

struct WatchSetting: Equatable {
    var displayTime: Date?
    var presentSetting = false
    var vertical = true
    var effectiveTime: Date {
        displayTime ?? .now
    }
}

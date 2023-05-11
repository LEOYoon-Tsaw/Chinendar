//
//  Layout.swift
//  ChineseTime
//
//  Created by LEO Yoon-Tsaw on 9/23/21.
//

import AppKit

class WatchLayout: MetaWatchLayout {
    static var shared: WatchLayout = WatchLayout()
    
    var textFont: NSFont
    var centerFont: NSFont
    override init() {
        textFont = NSFont.userFont(ofSize: NSFont.systemFontSize)!
        centerFont = NSFontManager.shared.font(withFamily: NSFont.userFont(ofSize: NSFont.systemFontSize)!.familyName!,
                                               traits: .boldFontMask, weight: 900, size: NSFont.systemFontSize)!
        super.init()
    }
    override func encode(includeOffset: Bool = true) -> String {
        var encoded = super.encode()
        encoded += "textFont: \(textFont.fontName)\n"
        encoded += "centerFont: \(centerFont.fontName)\n"
        return encoded
    }
    override func update(from values: Dictionary<String, String>) {
        super.update(from: values)
        if let name = values["textFont"] {
            textFont = NSFont(name: name, size: NSFont.systemFontSize) ?? textFont
        }
        if let name = values["centerFont"] {
            centerFont = NSFont(name: name, size: NSFont.systemFontSize) ?? centerFont
        }
    }
}

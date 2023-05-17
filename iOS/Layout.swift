//
//  Layout.swift
//  ChineseTime
//
//  Created by LEO Yoon-Tsaw on 9/23/21.
//

import UIKit

final class WatchLayout: MetaWatchLayout {
    static let shared = WatchLayout()

    var textFont: UIFont
    var centerFont: UIFont

    override init() {
        textFont = UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .regular)
        centerFont = UIFont(name: "SourceHanSansKR-Heavy", size: UIFont.systemFontSize)!
        super.init()
    }
}

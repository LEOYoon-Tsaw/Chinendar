//
//  WatchLayout.swift
//  Chinese Time
//
//  Created by Leo Liu on 5/11/23.
//

import SwiftUI

class WatchLayout: MetaWatchLayout, ObservableObject {
    static var shared: WatchLayout = WatchLayout()
    
    var textFont: UIFont
    var centerFont: UIFont
    @Published var refresh = false
    
    override init() {
        textFont = UIFont.systemFont(ofSize: 10, weight: .regular)
        centerFont = UIFont(name: "SourceHanSansKR-Heavy", size: 10)!
        super.init()
    }
    
    override func update(from str: String) {
        super.update(from: str)
        refresh.toggle()
    }
    
}

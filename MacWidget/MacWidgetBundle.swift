//
//  MacWidget.swift
//  MacWidget
//
//  Created by Leo Liu on 5/9/23.
//

import SwiftUI

@main
struct MacWidgetBundle: WidgetBundle {

    var body: some Widget {
        DualWatchWidget()
        FullWatchWidget()
    }
}

//
//  MacWidget.swift
//  MacWidget
//
//  Created by Leo Liu on 5/9/23.
//

import WidgetKit
import SwiftUI

@main
struct MacWidgetBundle: WidgetBundle {
    init() {
        DataContainer.shared.loadSave()
        LocationManager.shared.requestLocation(completion: nil)
    }
    
    @WidgetBundleBuilder
    var body: some Widget {
        SmallWidget()
        MediumWidget()
        LargeWidget()
    }
}

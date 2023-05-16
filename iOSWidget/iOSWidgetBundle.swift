//
//  iOSWidgetBundle.swift
//  iOSWidget
//
//  Created by Leo Liu on 5/9/23.
//

import SwiftUI

@main
struct iOSWidgetBundle: WidgetBundle {
    init() {
        DataContainer.shared.loadSave()
        LocationManager.shared.requestLocation(completion: nil)
    }

    @WidgetBundleBuilder
    var body: some Widget {
        SmallWidget()
        MediumWidget()
        LargeWidget()
        LineWidget()
        CircularWidget()
    }
}

//
//  iOSWidgetBundle.swift
//  iOSWidget
//
//  Created by Leo Liu on 5/9/23.
//

import SwiftUI

@main
struct iOSWidgetBundle: WidgetBundle {

    var body: some Widget {
        SmallWidget()
        MediumWidget()
        LargeWidget()
        LineWidget()
        CircularWidget()
        RectWidget()
        DateCardWidget()
    }
}

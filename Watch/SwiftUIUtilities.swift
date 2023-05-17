//
//  StartingPhase.swift
//  Chinese Time
//
//  Created by Leo Liu on 5/11/23.
//

import SwiftUI

struct StartingPhase {
    var zeroRing: CGFloat = 0.0
    var firstRing: CGFloat = 0.0
    var secondRing: CGFloat = 0.0
    var thirdRing: CGFloat = 0.0
    var fourthRing: CGFloat = 0.0
}

func applyGradient(gradient: WatchLayout.Gradient, startingAngle: CGFloat) -> Gradient {
    let colors: [CGColor]
    let locations: [CGFloat]
    if startingAngle >= 0 {
        colors = gradient.colors.reversed()
        locations = gradient.locations.map { 1 - $0 }.reversed()
    } else {
        colors = gradient.colors
        locations = gradient.locations
    }
    return Gradient(stops: zip(colors, locations).map { Gradient.Stop(color: Color(cgColor: $0.0), location: $0.1) })
}

//
//  Icon.swift
//  Chinendar
//
//  Created by Leo Liu on 1/29/24.
//

import SwiftUI

struct Icon: View {
    static let frameOffset: CGFloat = 0.03
    @Environment(\.colorScheme) var colorScheme
    let watchLayout: WatchLayout
    let widthScale = 1.5
    
    init(watchLayout: WatchLayout) {
        self.watchLayout = watchLayout
    }
    
    var body: some View {
        let coreColor = colorScheme == .dark ? watchLayout.innerColorDark : watchLayout.innerColor
        let backColor = colorScheme == .dark ? watchLayout.backColorDark : watchLayout.backColor
        let clearColor = CGColor(gray: 0, alpha: 0)
        let shadowDirection = 0.62
        
        GeometryReader { proxy in
            
            let size = proxy.size
            let shortEdge = min(size.width, size.height)
            let cornerSize = watchLayout.cornerRadiusRatio * shortEdge
            let outerBound = RoundedRect(rect: CGRect(origin: .zero, size: size), nodePos: cornerSize, ankorPos: cornerSize * 0.2)
            let firstRingOuter = outerBound.shrink(by: ZeroRing.width * shortEdge * widthScale)
            let secondRingOuter = firstRingOuter.shrink(by: Ring.paddedWidth * shortEdge * widthScale)
            let innerBound = secondRingOuter.shrink(by: Ring.paddedWidth * shortEdge * widthScale)
            
            ZStack {

                Ring(width: Ring.paddedWidth * widthScale, viewSize: size, compact: false, ticks: ChineseCalendar.Ticks(), startingAngle: 0, angle: 0.3, textFont: WatchFont(watchLayout.textFont), textColor: clearColor, alpha: watchLayout.shadeAlpha, majorTickAlpha: 1, minorTickAlpha: 1, majorTickColor: clearColor, minorTickColor: clearColor, backColor: backColor, gradientColor: watchLayout.firstRing, outerRing: firstRingOuter, marks: [], shadowDirection: shadowDirection, entityNotes: nil, shadowSize: watchLayout.shadowSize, highlightType: .flicker, offset: .zero)
                Ring(width: Ring.paddedWidth * widthScale, viewSize: size, compact: false, ticks: ChineseCalendar.Ticks(), startingAngle: 0, angle: 0.45, textFont: WatchFont(watchLayout.textFont), textColor: clearColor, alpha: watchLayout.shadeAlpha, majorTickAlpha: 1, minorTickAlpha: 1, majorTickColor: clearColor, minorTickColor: clearColor, backColor: backColor, gradientColor: watchLayout.secondRing, outerRing: secondRingOuter, marks: [], shadowDirection: shadowDirection, entityNotes: nil, shadowSize: watchLayout.shadowSize, highlightType: .flicker, offset: .zero)
                Core(viewSize: size, dateString: "", timeString: "", font: WatchFont(watchLayout.centerFont), maxLength: 5, textColor: watchLayout.centerFontColor, outerBound: innerBound, innerColor: coreColor, backColor: backColor, centerOffset: 0, shadowDirection: shadowDirection, shadowSize: watchLayout.shadowSize)
            }
        }
    }
}

#Preview("Icon") {
    let watchLayout = WatchLayout.shared
    watchLayout.loadStatic()
    return Icon(watchLayout: watchLayout)
        .frame(width: 120, height: 120)
}

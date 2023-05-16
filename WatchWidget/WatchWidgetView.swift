//
//  WatchWidgetFace.swift
//  WatchWidgetExtension
//
//  Created by Leo Liu on 5/11/23.
//

import SwiftUI

struct LineDescription : View {
    @State var text: String
    
    init(chineseCalendar: ChineseCalendar) {
        var text = chineseCalendar.dateString
        for solarTerm in chineseCalendar.eventInDay.oddSolarTerm {
            text += "・\(solarTerm.name)"
        }
        for solarTerm in chineseCalendar.eventInDay.evenSolarTerm {
            text += "・\(solarTerm.name)"
        }
        for moon in chineseCalendar.eventInDay.eclipse {
            text += "・\(moon.name)"
        }
        for moon in chineseCalendar.eventInDay.fullMoon {
            text += "・\(moon.name)"
        }
        text += "・\(chineseCalendar.hourString)"
        self.text = text
    }

    var body: some View {
        Text(String(text.reversed()))
    }
}

struct CircularLine: View {
    var lineWidth: CGFloat
    var start: CGFloat
    var end: CGFloat
    
    var body: some View {
        let length = end > start ? end - start : end - start + 1
        
        ZStack {
            Circle()
                .stroke(
                    Color.white.opacity(0.5),
                    lineWidth: lineWidth
                )
                .padding(lineWidth / 2)
            Circle()
                .trim(from: 0, to: length)
                .stroke(
                    Color.white,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .padding(lineWidth / 2)
                .rotationEffect(.radians(CGFloat.pi * 2.0 * (0.25 + start)))
                .scaleEffect(CGSize(width: -1, height: 1))
        }
    }
}

struct Circular : View {
    @State var size: CGSize = .zero
    var outer: (start: CGFloat, end: CGFloat)
    var inner: (start: CGFloat, end: CGFloat)
    var current: CGFloat?
    var innerDirection: CGFloat?
    var outerGradient: Gradient
    var innerGradient: Gradient
    var currentColor: Color?
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                AngularGradient(gradient: outerGradient, center: .center, angle: .degrees(90)).mask {
                    CircularLine(lineWidth: min(size.width, size.height) * 0.1, start: outer.start, end: outer.end)
                }
                AngularGradient(gradient: innerGradient, center: .center, angle: .radians((-0.25 - (innerDirection ?? 0.5)) * CGFloat.pi * 2.0)).mask {
                    CircularLine(lineWidth: min(size.width, size.height) * 0.1, start: inner.start, end: inner.end)
                        .frame(width: size.width * 0.7, height: size.height * 0.7)
                }
                if let current = current, let currentColor = currentColor {
                    currentColor
                        .clipShape(Capsule())
                        .frame(width: size.width * 0.28, height: min(size.width, size.height) * 0.1)
                        .position(CGPoint(x: size.width * 0.13, y: size.height / 2))
                        .rotationEffect(.radians((current - 0.25) * CGFloat.pi * 2.0))
                        .scaleEffect(CGSize(width: -1, height: 1))
                        .shadow(color: .black, radius: min(size.width, size.height) * 0.05)
                }
            }
            .onAppear() {
                size = proxy.size
            }
        }
    }
}

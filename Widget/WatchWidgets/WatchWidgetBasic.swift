//
//  WatchWidgetFace.swift
//  WatchWidgetExtension
//
//  Created by Leo Liu on 5/11/23.
//

import SwiftUI
import WidgetKit

struct LineDescription: View {
    let text: Text

    init(chineseCalendar: ChineseCalendar, displayDate: Bool, displayHour: Bool, displayQuarter: Bool, displayHolidays: Int, separator: String, nativeLanguage: Bool) {
        var text = [String]()
        if displayDate {
            if nativeLanguage {
                text.append(String(localized: chineseCalendar.dateStringLocalized))
            } else {
                text.append(chineseCalendar.dateString)
            }
        }
        if displayHolidays > 0 {
            let holidays = chineseCalendar.holidays
            for holiday in holidays[..<min(displayHolidays, holidays.count)] {
                if nativeLanguage {
                    text.append(Locale.translate(holiday))
                } else {
                    text.append(holiday)
                }
            }
        }
        let timeString: String
        if displayHour && displayQuarter {
            if nativeLanguage {
                timeString = String(localized: "HOUR\(chineseCalendar.hourStringLocalized)QUARTER\(chineseCalendar.shortQuarterStringLocalized)")
            } else {
                timeString = "\(chineseCalendar.hourString)\(chineseCalendar.shortQuarterString)"
            }
        } else if displayHour {
            if nativeLanguage {
                timeString = String(localized: chineseCalendar.hourStringLocalized)
            } else {
                timeString = chineseCalendar.hourString
            }
        } else {
            timeString = ""
        }
        if !timeString.isEmpty {
            text.append(timeString)
        }
        if nativeLanguage {
            self.text = Text(text.joined(separator: Locale.translate(separator)))
        } else {
            self.text = Text(String(text.joined(separator: separator).reversed()))
        }
    }

    var body: some View {
        text
            .widgetAccentable()
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

struct Circular: View {
    @Environment(\.widgetRenderingMode) var widgetRenderingMode
    var outer: (start: CGFloat, end: CGFloat)
    var inner: (start: CGFloat, end: CGFloat)
    var current: CGFloat?
    var startingPhase: (CGFloat, CGFloat)
    var innerDirection: CGFloat?
    var outerGradient: Gradient
    var innerGradient: Gradient
    var currentColor: Color?

    var body: some View {
        let fullColor = widgetRenderingMode == .fullColor
        let whiteGradient = Gradient(colors: [.white, .white])

        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                AngularGradient(gradient: fullColor ? outerGradient : whiteGradient,
                                center: .center, angle: .degrees(90))
                .mask {
                    CircularLine(lineWidth: min(size.width, size.height) * 0.1, start: outer.start, end: outer.end)
                }
                .widgetAccentable()
                .scaleEffect(x: startingPhase.0 >= 0 ? 1 : -1)
                .rotationEffect(.radians(startingPhase.0 * CGFloat.pi * 2.0))
                AngularGradient(gradient: fullColor ? innerGradient : whiteGradient,
                                center: .center, angle: .radians((-0.25 - (innerDirection ?? 0.5)) * CGFloat.pi * 2.0))
                .mask {
                    CircularLine(lineWidth: min(size.width, size.height) * 0.1, start: inner.start, end: inner.end)
                        .frame(width: size.width * 0.7, height: size.height * 0.7)
                }
                .widgetAccentable()
                .scaleEffect(x: startingPhase.1 >= 0 ? 1 : -1)
                .rotationEffect(.radians(startingPhase.1 * CGFloat.pi * 2.0))
                if let current, let currentColor {
                    (fullColor ? currentColor : .white)
                        .clipShape(Capsule())
                        .frame(width: size.width * 0.28, height: min(size.width, size.height) * 0.1)
                        .position(CGPoint(x: size.width * 0.13, y: size.height / 2))
                        .rotationEffect(.radians((startingPhase.0 + current - 0.25) * CGFloat.pi * 2.0))
                        .scaleEffect(x: startingPhase.0 >= 0 ? -1 : 1)
                        .shadow(color: .black, radius: min(size.width, size.height) * 0.05)
                }
            }
        }
    }
}

private struct RectIconStyle: ViewModifier {
    let size: CGSize

    func body(content: Content) -> some View {
        content
            .scaledToFit()
            .clipShape(.circle)
            .widgetAccentable()
            .frame(width: size.height * 0.85, height: size.height * 0.85)
            .padding(.vertical, size.height * 0.075)
    }
}

struct RectanglePanel: View {
    @Environment(\.widgetRenderingMode) var widgetRenderingMode
    @Environment(\.showsWidgetContainerBackground) private var showsWidgetContainerBackground
    var icon: IconType
    var name: Text
    var color: Color
    var start: Date?
    var end: Date?

    var body: some View {
        GeometryReader { proxy in
            HStack(alignment: .center) {
                switch icon {
                case .globalEvent(view: let view):
                    view
                        .modifier(RectIconStyle(size: proxy.size))
                case .localEvent(view: let view):
                    view
                        .modifier(RectIconStyle(size: proxy.size))
                }

                VStack(alignment: .leading) {
                    name
                        .foregroundStyle(textColor)
                        .lineLimit(1)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.5)
                    if start != nil, let end {
                        Text(end, style: .relative)
                            .fontDesign(.rounded)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("UNKNOWN_TIME")
                            .fontDesign(.rounded)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .foregroundStyle(.secondary)
                    }
                }
                .widgetAccentable()
                .frame(maxWidth: .infinity, idealHeight: proxy.size.height)
            }
        }
    }

    var textColor: Color {
        if widgetRenderingMode != .fullColor {
            .white
        } else if showsWidgetContainerBackground {
            .primary
        } else {
            color
        }
    }
}

private struct CurveIconStyle<Bar: View>: ViewModifier {
    let size: CGSize
    let bar: Bar

    init(size: CGSize, @ViewBuilder bar: () -> Bar) {
        self.size = size
        self.bar = bar()
    }

    func body(content: Content) -> some View {
        content
            .widgetAccentable()
            .frame(width: size.width, height: size.height)
            .widgetLabel { bar }
    }
}

struct Curve: View {
    @Environment(\.widgetRenderingMode) var widgetRenderingMode
    @Environment(\.showsWidgetContainerBackground) private var showsWidgetContainerBackground
    var icon: IconType
    var barColor: Color
    var start: Date?
    var end: Date?

    var body: some View {
        GeometryReader { proxy in
            let curveStyle = CurveIconStyle(size: proxy.size) {
                if let start, let end {
                    ProgressView(timerInterval: start ... end, countsDown: false) {
                        Text(end, style: .relative)
                    }
                    .tint(progressColor)
                    .widgetAccentable()
                }
            }

            switch icon {
            case .globalEvent(view: let view):
                view
                    .modifier(curveStyle)
            case .localEvent(view: let view):
                view
                    .modifier(curveStyle)
            }
        }
    }

    var progressColor: Color {
        if widgetRenderingMode != .fullColor {
            .white
        } else {
            barColor
        }
    }
}

struct CalendarBadge: View {

    let dateString: String
    let timeString: String
    let color: Gradient
    let centerFont: WatchFont
    @Environment(\.widgetRenderingMode) var widgetRenderingMode

    private func prepareText(_ text: String, size: CGFloat) -> Text {
        let attrStr = NSMutableAttributedString(string: String(text.reversed()))
        let centerFont = centerFont.font.withSize(size)
        attrStr.addAttributes([.font: centerFont, .foregroundColor: CGColor(gray: 1, alpha: 1)], range: NSRange(location: 0, length: attrStr.length))
        return Text(AttributedString(attrStr))
    }

    var body: some View {
        let fullColor = widgetRenderingMode == .fullColor
        let whiteGradient = Gradient(colors: [.white, .white])

        GeometryReader { proxy in
            VStack {
                let fontSize = min(proxy.size.width / 8, proxy.size.height / 3)
                prepareText(dateString, size: fontSize)
                    .multilineTextAlignment(.center)
                prepareText(timeString, size: fontSize)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 1)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundStyle(LinearGradient(gradient: fullColor ? color : whiteGradient,
                                            startPoint: .bottomLeading, endPoint: .topTrailing))
            .widgetAccentable()
        }
    }
}

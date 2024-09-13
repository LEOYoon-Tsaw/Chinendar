//
//  WatchFaceView.swift
//  Chinendar
//
//  Created by Leo Liu on 5/9/23.
//

import SwiftUI

struct DirectedScale: Equatable {
    let value: CGFloat
    let anchor: UnitPoint
    init(value: CGFloat = 0, anchor: UnitPoint = .center) {
        self.value = value
        self.anchor = anchor
    }
}

extension EnvironmentValues {
    @Entry var directedScale: DirectedScale = DirectedScale()
}

private func calSubhourGradient(baseLayout: BaseLayout, chineseCalendar: ChineseCalendar) -> BaseLayout.Gradient {
    let startOfDay = chineseCalendar.startOfDay
    let lengthOfDay = startOfDay.distance(to: chineseCalendar.startOfNextDay)
    let fourthRingColor = BaseLayout.Gradient(locations: [0, 1], colors: [
        baseLayout.thirdRing.interpolate(at: (startOfDay.distance(to: chineseCalendar.startHour) / lengthOfDay) %% 1.0),
        baseLayout.thirdRing.interpolate(at: (startOfDay.distance(to: chineseCalendar.endHour) / lengthOfDay) %% 1.0)
    ], loop: false)
    return fourthRingColor
}

private enum Rings {
    case date
    case time
}

private func ringMarks(for ring: Rings, baseLayout: BaseLayout, chineseCalendar: ChineseCalendar, radius: CGFloat) -> ([Marks], [Marks]) {
    switch ring {
    case .date:
        let planets = chineseCalendar.planetPosition.getValues([\.mercury, \.venus, \.mars, \.jupiter, \.saturn, \.moon])
        let planetColors = baseLayout.planetIndicator.getValues([\.mercury, \.venus, \.mars, \.jupiter, \.saturn, \.moon])
        let eventInMonth = chineseCalendar.eventInMonth
        let firstRingMarks = [Marks(outer: true, locations: planets, colors: planetColors, radius: radius)]
        let secondRingMarks = [
            Marks(outer: true, locations: eventInMonth.eclipse, colors: [baseLayout.eclipseIndicator], radius: radius),
            Marks(outer: true, locations: eventInMonth.fullMoon, colors: [baseLayout.fullmoonIndicator], radius: radius),
            Marks(outer: true, locations: eventInMonth.oddSolarTerm, colors: [baseLayout.oddStermIndicator], radius: radius),
            Marks(outer: true, locations: eventInMonth.evenSolarTerm, colors: [baseLayout.evenStermIndicator], radius: radius)
        ]
        return (firstRingMarks, secondRingMarks)

    case .time:
        let eventInDay = chineseCalendar.eventInDay
        var chineseCalendar = chineseCalendar
        let sunMoonPositions = chineseCalendar.sunMoonPositions
        let sunTimes = sunMoonPositions.solar.getValues([\.midnight, \.sunrise, \.noon, \.sunset])
        let sunColors = baseLayout.sunPositionIndicator.getValues([\.midnight, \.sunrise, \.noon, \.sunset])
        let moonTimes = sunMoonPositions.lunar.getValues([\.moonrise, \.highMoon, \.moonset])
        let moonColors = baseLayout.moonPositionIndicator.getValues([\.moonrise, \.highMoon, \.moonset])
        let thirdRingMarks = [
            Marks(outer: true, locations: eventInDay.eclipse, colors: [baseLayout.eclipseIndicator], radius: radius),
            Marks(outer: true, locations: eventInDay.fullMoon, colors: [baseLayout.fullmoonIndicator], radius: radius),
            Marks(outer: true, locations: eventInDay.oddSolarTerm, colors: [baseLayout.oddStermIndicator], radius: radius),
            Marks(outer: true, locations: eventInDay.evenSolarTerm, colors: [baseLayout.evenStermIndicator], radius: radius),
            Marks(outer: false, locations: sunTimes, colors: sunColors, radius: radius),
            Marks(outer: false, locations: moonTimes, colors: moonColors, radius: radius)
        ]
        let eventInHour = chineseCalendar.eventInHour
        let sunMoonSubhourPositions = chineseCalendar.sunMoonSubhourPositions
        let sunTimesSubhour = sunMoonSubhourPositions.solar.getValues([\.midnight, \.sunrise, \.noon, \.sunset])
        let moonTimesSubhour = sunMoonSubhourPositions.lunar.getValues([\.moonrise, \.highMoon, \.moonset])
        let fourthRingMarks = [
            Marks(outer: true, locations: eventInHour.eclipse, colors: [baseLayout.eclipseIndicator], radius: radius),
            Marks(outer: true, locations: eventInHour.fullMoon, colors: [baseLayout.fullmoonIndicator], radius: radius),
            Marks(outer: true, locations: eventInHour.oddSolarTerm, colors: [baseLayout.oddStermIndicator], radius: radius),
            Marks(outer: true, locations: eventInHour.evenSolarTerm, colors: [baseLayout.evenStermIndicator], radius: radius),
            Marks(outer: false, locations: sunTimesSubhour, colors: sunColors, radius: radius),
            Marks(outer: false, locations: moonTimesSubhour, colors: moonColors, radius: radius)
        ]
        return (thirdRingMarks, fourthRingMarks)
    }
}

struct PressState {
    private var startTime: Date?
    private var startLocation: CGPoint?
    var ended = false
    var location: CGPoint? {
        didSet {
            if (startLocation == nil && location != nil) || (startLocation != nil && location == nil) {
                startLocation = location
            }
        }
    }
    var distance: CGFloat? {
        if let location, let startLocation {
            let translation = location - startLocation
            return sqrt(pow(translation.x, 2) + pow(translation.y, 2))
        } else {
            return nil
        }
    }
    var duration: TimeInterval? {
        if let startTime, !ended {
            startTime.distance(to: .now)
        } else {
            nil
        }
    }
    var tapped: Bool {
        if let distance, let duration {
            return distance < 12 && duration < 0.3
        } else {
            return false
        }
    }
    var pressing: Bool {
        get {
            startTime != nil && !ended
        } set {
            if newValue {
                if startTime == nil {
                    startTime = .now
                }
            } else {
                startTime = nil
            }
        }
    }
}

func pressAnchor(pos: CGPoint?, size: CGSize, proxy: GeometryProxy) -> UnitPoint {
    let center = CGPoint(x: size.width / 2, y: size.height / 2)
    let tapPosition: CGPoint
    if var tapPos = pos {
        tapPos.x -= (proxy.size.width - size.width) / 2
        tapPos.y -= (proxy.size.height - size.height) / 2
        tapPosition = tapPos
    } else {
        tapPosition = center
    }
    let maxEdge = max(size.width, size.height)
    let direction = (tapPosition - center) / maxEdge
    return UnitPoint(x: 0.5 + direction.x / 2, y: 0.5 + direction.y / 2)
}

struct Watch: View {
    static let frameOffset: CGFloat = 0.03

    @Environment(\.colorScheme) var colorScheme
#if !os(visionOS)
    @Environment(\.showsWidgetContainerBackground) var showsWidgetContainerBackground
#else
    let showsWidgetContainerBackground = true
#endif
    @Environment(\.directedScale) var directedScale
    let shrink: Bool
    let displayZeroRing: Bool
    let displaySubquarter: Bool
    let compact: Bool
    let watchLayout: WatchLayout
    let markSize: CGFloat
    let widthScale: CGFloat
    let chineseCalendar: ChineseCalendar
    let centerOffset: CGFloat
    let entityNotes: EntityNotes?
    let shift: CGSize
    let highlightType: HighlightType
    var baseLayout: BaseLayout {
        watchLayout.baseLayout
    }

    init(displaySubquarter: Bool, displaySolarTerms: Bool, compact: Bool, watchLayout: WatchLayout, markSize: CGFloat, chineseCalendar: ChineseCalendar, highlightType: HighlightType, widthScale: CGFloat = 1, centerOffset: CGFloat = 0.05, entityNotes: EntityNotes? = nil, textShift: Bool = false, shrink: Bool = true) {
        self.shrink = shrink
        self.displayZeroRing = displaySolarTerms
        self.displaySubquarter = displaySubquarter
        self.compact = compact
        self.watchLayout = watchLayout
        self.markSize = markSize
        self.widthScale = widthScale
        self.chineseCalendar = chineseCalendar
        self.centerOffset = centerOffset
        self.entityNotes = entityNotes
        self.highlightType = highlightType
        self.shift = if textShift {
            CGSize(width: watchLayout.baseLayout.horizontalTextOffset, height: watchLayout.baseLayout.verticalTextOffset)
        } else {
            CGSize.zero
        }
    }

    var body: some View {
        let baseLayout = self.baseLayout
        let fourthRingColor = calSubhourGradient(baseLayout: baseLayout, chineseCalendar: chineseCalendar)

        let textColor = colorScheme == .dark ? baseLayout.fontColorDark : baseLayout.fontColor
        let majorTickColor = colorScheme == .dark ? baseLayout.majorTickColorDark : baseLayout.majorTickColor
        let minorTickColor = colorScheme == .dark ? baseLayout.minorTickColorDark : baseLayout.minorTickColor
        let coreColor = colorScheme == .dark ? baseLayout.innerColorDark : baseLayout.innerColor
        let backColor = colorScheme == .dark ? baseLayout.backColorDark : baseLayout.backColor
        let shadowDirection = chineseCalendar.currentHourInDay

        GeometryReader { proxy in

            let size = proxy.size
            let shortEdge = min(size.width, size.height)
            let cornerSize = baseLayout.cornerRadiusRatio * shortEdge
            let outerBound = RoundedRect(rect: CGRect(origin: .zero, size: size), nodePos: cornerSize, ankorPos: cornerSize * 0.2).shrink(by: (showsWidgetContainerBackground && shrink) ? Self.frameOffset * shortEdge : 0.0)
            let firstRingOuter = displayZeroRing ? outerBound.shrink(by: ZeroRing.width * shortEdge * widthScale) : outerBound
            let secondRingOuter = firstRingOuter.shrink(by: Ring.paddedWidth * shortEdge * widthScale)
            let thirdRingOuter = secondRingOuter.shrink(by: Ring.paddedWidth * shortEdge * widthScale)
            let fourthRingOuter = thirdRingOuter.shrink(by: Ring.paddedWidth * shortEdge * widthScale)
            let innerBound = fourthRingOuter.shrink(by: Ring.paddedWidth * shortEdge * widthScale)
            let (firstRingMarks, secondRingMarks) = ringMarks(for: .date, baseLayout: baseLayout, chineseCalendar: chineseCalendar, radius: Marks.markSize * shortEdge * markSize)
            let (thirdRingMarks, fourthRingMarks) = ringMarks(for: .time, baseLayout: baseLayout, chineseCalendar: chineseCalendar, radius: Marks.markSize * shortEdge * markSize)

            ZStack {
                if displayZeroRing {
                    let oddSTColor = colorScheme == .dark ? baseLayout.oddSolarTermTickColorDark : baseLayout.oddSolarTermTickColor
                    let evenSTColor = colorScheme == .dark ? baseLayout.evenSolarTermTickColorDark : baseLayout.evenSolarTermTickColor
                    ZeroRing(width: ZeroRing.width * widthScale, viewSize: size, compact: compact, textFont: WatchFont(watchLayout.textFont), outerRing: outerBound, startingAngle: baseLayout.startingPhase.zeroRing, oddTicks: chineseCalendar.oddSolarTerms.map { CGFloat($0) }, evenTicks: chineseCalendar.evenSolarTerms.map { CGFloat($0) }, oddColor: oddSTColor, evenColor: evenSTColor, oddTexts: ChineseCalendar.oddSolarTermChinese, evenTexts: ChineseCalendar.evenSolarTermChinese, offset: shift)
                }
                let _ = entityNotes?.reset()
                Ring(width: Ring.paddedWidth * widthScale, viewSize: size, compact: compact, ticks: chineseCalendar.monthTicks, startingAngle: baseLayout.startingPhase.firstRing, angle: chineseCalendar.currentDayInYear, textFont: WatchFont(watchLayout.textFont), textColor: textColor, alpha: baseLayout.shadeAlpha, majorTickAlpha: baseLayout.majorTickAlpha, minorTickAlpha: baseLayout.minorTickAlpha, majorTickColor: majorTickColor, minorTickColor: minorTickColor, backColor: backColor, gradientColor: baseLayout.firstRing, outerRing: firstRingOuter, marks: firstRingMarks, shadowDirection: shadowDirection, entityNotes: entityNotes, shadowSize: showsWidgetContainerBackground ? baseLayout.shadowSize : 0.0, highlightType: highlightType, offset: shift)
                    .scaleEffect(1 + directedScale.value * 0.25, anchor: directedScale.anchor)
                    .animation(.spring(duration: 0.5, bounce: 0.6, blendDuration: 0.2), value: directedScale)
                Ring(width: Ring.paddedWidth * widthScale, viewSize: size, compact: compact, ticks: chineseCalendar.dayTicks, startingAngle: baseLayout.startingPhase.secondRing, angle: chineseCalendar.currentDayInMonth, textFont: WatchFont(watchLayout.textFont), textColor: textColor, alpha: baseLayout.shadeAlpha, majorTickAlpha: baseLayout.majorTickAlpha, minorTickAlpha: baseLayout.minorTickAlpha, majorTickColor: majorTickColor, minorTickColor: minorTickColor, backColor: backColor, gradientColor: baseLayout.secondRing, outerRing: secondRingOuter, marks: secondRingMarks, shadowDirection: shadowDirection, entityNotes: entityNotes, shadowSize: baseLayout.shadowSize, highlightType: highlightType, offset: shift)
                    .scaleEffect(1 + directedScale.value * 0.5, anchor: directedScale.anchor)
                    .animation(.spring(duration: 0.5, bounce: 0.65, blendDuration: 0.2), value: directedScale)
                Ring(width: Ring.paddedWidth * widthScale, viewSize: size, compact: compact, ticks: chineseCalendar.hourTicks, startingAngle: baseLayout.startingPhase.thirdRing, angle: chineseCalendar.currentHourInDay, textFont: WatchFont(watchLayout.textFont), textColor: textColor, alpha: baseLayout.shadeAlpha, majorTickAlpha: baseLayout.majorTickAlpha, minorTickAlpha: baseLayout.minorTickAlpha, majorTickColor: majorTickColor, minorTickColor: minorTickColor, backColor: backColor, gradientColor: baseLayout.thirdRing, outerRing: thirdRingOuter, marks: thirdRingMarks, shadowDirection: shadowDirection, entityNotes: entityNotes, shadowSize: baseLayout.shadowSize, highlightType: highlightType, offset: shift)
                    .scaleEffect(1 + directedScale.value * 0.75, anchor: directedScale.anchor)
                    .animation(.spring(duration: 0.5, bounce: 0.7, blendDuration: 0.2), value: directedScale)
                Ring(width: Ring.paddedWidth * widthScale, viewSize: size, compact: compact, ticks: chineseCalendar.subhourTicks, startingAngle: baseLayout.startingPhase.fourthRing, angle: chineseCalendar.subhourInHour, textFont: WatchFont(watchLayout.textFont), textColor: textColor, alpha: baseLayout.shadeAlpha, majorTickAlpha: baseLayout.majorTickAlpha, minorTickAlpha: baseLayout.minorTickAlpha, majorTickColor: majorTickColor, minorTickColor: minorTickColor, backColor: backColor, gradientColor: fourthRingColor, outerRing: fourthRingOuter, marks: fourthRingMarks, shadowDirection: shadowDirection, entityNotes: entityNotes, shadowSize: baseLayout.shadowSize, highlightType: highlightType, offset: shift)
                    .scaleEffect(1 + directedScale.value * 1, anchor: directedScale.anchor)
                    .animation(.spring(duration: 0.5, bounce: 0.75, blendDuration: 0.2), value: directedScale)
                let timeString = displaySubquarter ? chineseCalendar.timeString : (chineseCalendar.hourString + chineseCalendar.shortQuarterString)
                Core(viewSize: size, dateString: chineseCalendar.dateString, timeString: timeString, font: WatchFont(watchLayout.centerFont), maxLength: 5, textColor: baseLayout.centerFontColor, outerBound: innerBound, innerColor: coreColor, backColor: backColor, centerOffset: centerOffset, shadowDirection: shadowDirection, shadowSize: baseLayout.shadowSize)
                    .scaleEffect(1 + directedScale.value * 1.25, anchor: directedScale.anchor)
                    .animation(.spring(duration: 0.5, bounce: 0.8, blendDuration: 0.2), value: directedScale)
            }
        }
    }
}

struct DateWatch: View {
    static let frameOffset: CGFloat = 0.03

    @Environment(\.directedScale) var directedScale
    @Environment(\.colorScheme) var colorScheme
#if !os(visionOS)
    @Environment(\.showsWidgetContainerBackground) var showsWidgetContainerBackground
#else
    let showsWidgetContainerBackground = true
#endif
    let shrink: Bool
    let displayZeroRing: Bool
    let compact: Bool
    let watchLayout: WatchLayout
    let markSize: CGFloat
    let widthScale: CGFloat
    let chineseCalendar: ChineseCalendar
    let centerOffset: CGFloat
    let entityNotes: EntityNotes?
    let highlightType: HighlightType
    var baseLayout: BaseLayout {
        watchLayout.baseLayout
    }

    init(displaySolarTerms: Bool, compact: Bool, watchLayout: WatchLayout, markSize: CGFloat, chineseCalendar: ChineseCalendar, highlightType: HighlightType, widthScale: CGFloat = 1, centerOffset: CGFloat = 0.05, entityNotes: EntityNotes? = nil, shrink: Bool = true) {
        self.shrink = shrink
        self.displayZeroRing = displaySolarTerms
        self.compact = compact
        self.watchLayout = watchLayout
        self.markSize = markSize
        self.widthScale = widthScale
        self.chineseCalendar = chineseCalendar
        self.centerOffset = centerOffset
        self.entityNotes = entityNotes
        self.highlightType = highlightType
    }

    var body: some View {
        let baseLayout = self.baseLayout

        let textColor = colorScheme == .dark ? baseLayout.fontColorDark : baseLayout.fontColor
        let majorTickColor = colorScheme == .dark ? baseLayout.majorTickColorDark : baseLayout.majorTickColor
        let minorTickColor = colorScheme == .dark ? baseLayout.minorTickColorDark : baseLayout.minorTickColor
        let coreColor = colorScheme == .dark ? baseLayout.innerColorDark : baseLayout.innerColor
        let backColor = colorScheme == .dark ? baseLayout.backColorDark : baseLayout.backColor
        let shadowDirection = chineseCalendar.currentHourInDay

        GeometryReader { proxy in

            let size = proxy.size
            let shortEdge = min(size.width, size.height)
            let cornerSize = baseLayout.cornerRadiusRatio * shortEdge
            let outerBound = RoundedRect(rect: CGRect(origin: .zero, size: size), nodePos: cornerSize, ankorPos: cornerSize * 0.2).shrink(by: (showsWidgetContainerBackground && shrink) ? Self.frameOffset * shortEdge : 0.0)
            let firstRingOuter = displayZeroRing ? outerBound.shrink(by: ZeroRing.width * shortEdge * widthScale) : outerBound
            let secondRingOuter = firstRingOuter.shrink(by: Ring.paddedWidth * shortEdge * widthScale)
            let innerBound = secondRingOuter.shrink(by: Ring.paddedWidth * shortEdge * widthScale)

            let (firstRingMarks, secondRingMarks) = ringMarks(for: .date, baseLayout: baseLayout, chineseCalendar: chineseCalendar, radius: Marks.markSize * shortEdge * markSize)

            ZStack {
                if displayZeroRing {
                    let oddSTColor = colorScheme == .dark ? baseLayout.oddSolarTermTickColorDark : baseLayout.oddSolarTermTickColor
                    let evenSTColor = colorScheme == .dark ? baseLayout.evenSolarTermTickColorDark : baseLayout.evenSolarTermTickColor
                    ZeroRing(width: ZeroRing.width * widthScale, viewSize: size, compact: compact, textFont: WatchFont(watchLayout.textFont), outerRing: outerBound, startingAngle: baseLayout.startingPhase.zeroRing, oddTicks: chineseCalendar.oddSolarTerms.map { CGFloat($0) }, evenTicks: chineseCalendar.evenSolarTerms.map { CGFloat($0) }, oddColor: oddSTColor, evenColor: evenSTColor, oddTexts: ChineseCalendar.oddSolarTermChinese, evenTexts: ChineseCalendar.evenSolarTermChinese)
                }
                let _ = entityNotes?.reset()
                Ring(width: Ring.paddedWidth * widthScale, viewSize: size, compact: compact, ticks: chineseCalendar.monthTicks, startingAngle: baseLayout.startingPhase.firstRing, angle: chineseCalendar.currentDayInYear, textFont: WatchFont(watchLayout.textFont), textColor: textColor, alpha: baseLayout.shadeAlpha, majorTickAlpha: baseLayout.majorTickAlpha, minorTickAlpha: baseLayout.minorTickAlpha, majorTickColor: majorTickColor, minorTickColor: minorTickColor, backColor: backColor, gradientColor: baseLayout.firstRing, outerRing: firstRingOuter, marks: firstRingMarks, shadowDirection: shadowDirection, entityNotes: entityNotes, shadowSize: showsWidgetContainerBackground ? baseLayout.shadowSize : 0.0, highlightType: highlightType)
                    .scaleEffect(1 + directedScale.value * 0.5, anchor: directedScale.anchor)
                    .animation(.spring(duration: 0.5, bounce: 0.6, blendDuration: 0.2), value: directedScale)
                Ring(width: Ring.paddedWidth * widthScale, viewSize: size, compact: compact, ticks: chineseCalendar.dayTicks, startingAngle: baseLayout.startingPhase.secondRing, angle: chineseCalendar.currentDayInMonth, textFont: WatchFont(watchLayout.textFont), textColor: textColor, alpha: baseLayout.shadeAlpha, majorTickAlpha: baseLayout.majorTickAlpha, minorTickAlpha: baseLayout.minorTickAlpha, majorTickColor: majorTickColor, minorTickColor: minorTickColor, backColor: backColor, gradientColor: baseLayout.secondRing, outerRing: secondRingOuter, marks: secondRingMarks, shadowDirection: shadowDirection, entityNotes: entityNotes, shadowSize: baseLayout.shadowSize, highlightType: highlightType)
                    .scaleEffect(1 + directedScale.value * 0.75, anchor: directedScale.anchor)
                    .animation(.spring(duration: 0.5, bounce: 0.7, blendDuration: 0.2), value: directedScale)

                Core(viewSize: size, dateString: chineseCalendar.monthString, timeString: chineseCalendar.dayString, font: WatchFont(watchLayout.centerFont), maxLength: 3, textColor: baseLayout.centerFontColor, outerBound: innerBound, innerColor: coreColor, backColor: backColor, centerOffset: centerOffset, shadowDirection: shadowDirection, shadowSize: baseLayout.shadowSize)
                    .scaleEffect(1 + directedScale.value, anchor: directedScale.anchor)
                    .animation(.spring(duration: 0.5, bounce: 0.8, blendDuration: 0.2), value: directedScale)
            }
        }
    }
}

struct TimeWatch: View {
    static let frameOffset: CGFloat = 0.03

    @Environment(\.directedScale) var directedScale
    @Environment(\.colorScheme) var colorScheme
#if !os(visionOS)
    @Environment(\.showsWidgetContainerBackground) var showsWidgetContainerBackground
#else
    let showsWidgetContainerBackground = true
#endif
    let shrink: Bool
    let displayZeroRing: Bool
    let displaySubquarter: Bool
    let compact: Bool
    let watchLayout: WatchLayout
    let markSize: CGFloat
    let widthScale: CGFloat
    let chineseCalendar: ChineseCalendar
    let centerOffset: CGFloat
    let entityNotes: EntityNotes?
    let highlightType: HighlightType
    var baseLayout: BaseLayout {
        watchLayout.baseLayout
    }

    init(matchZeroRingGap: Bool, displaySubquarter: Bool, compact: Bool, watchLayout: WatchLayout, markSize: CGFloat, chineseCalendar: ChineseCalendar, highlightType: HighlightType, widthScale: CGFloat = 1, centerOffset: CGFloat = 0.05, entityNotes: EntityNotes? = nil, shrink: Bool = true) {
        self.shrink = shrink
        self.displayZeroRing = matchZeroRingGap
        self.compact = compact
        self.displaySubquarter = displaySubquarter
        self.watchLayout = watchLayout
        self.markSize = markSize
        self.widthScale = widthScale
        self.chineseCalendar = chineseCalendar
        self.centerOffset = centerOffset
        self.entityNotes = entityNotes
        self.highlightType = highlightType
    }

    var body: some View {
        let baseLayout = self.baseLayout

        let fourthRingColor = calSubhourGradient(baseLayout: baseLayout, chineseCalendar: chineseCalendar)

        let textColor = colorScheme == .dark ? baseLayout.fontColorDark : baseLayout.fontColor
        let majorTickColor = colorScheme == .dark ? baseLayout.majorTickColorDark : baseLayout.majorTickColor
        let minorTickColor = colorScheme == .dark ? baseLayout.minorTickColorDark : baseLayout.minorTickColor
        let coreColor = colorScheme == .dark ? baseLayout.innerColorDark : baseLayout.innerColor
        let backColor = colorScheme == .dark ? baseLayout.backColorDark : baseLayout.backColor
        let shadowDirection = chineseCalendar.currentHourInDay

        GeometryReader { proxy in

            let size = proxy.size
            let shortEdge = min(size.width, size.height)
            let cornerSize = baseLayout.cornerRadiusRatio * shortEdge
            let outerBound = RoundedRect(rect: CGRect(origin: .zero, size: size), nodePos: cornerSize, ankorPos: cornerSize * 0.2).shrink(by: (showsWidgetContainerBackground && shrink) ? Self.frameOffset * shortEdge : 0.0)
            let firstRingOuter = displayZeroRing ? outerBound.shrink(by: ZeroRing.width * shortEdge * widthScale) : outerBound
            let secondRingOuter = firstRingOuter.shrink(by: Ring.paddedWidth * shortEdge * widthScale)
            let innerBound = secondRingOuter.shrink(by: Ring.paddedWidth * shortEdge * widthScale)
            let (thirdRingMarks, fourthRingMarks) = ringMarks(for: .time, baseLayout: baseLayout, chineseCalendar: chineseCalendar, radius: Marks.markSize * shortEdge * markSize)

            ZStack {
                let _ = entityNotes?.reset()
                Ring(width: Ring.paddedWidth * widthScale, viewSize: size, compact: compact, ticks: chineseCalendar.hourTicks, startingAngle: baseLayout.startingPhase.thirdRing, angle: chineseCalendar.currentHourInDay, textFont: WatchFont(watchLayout.textFont), textColor: textColor, alpha: baseLayout.shadeAlpha, majorTickAlpha: baseLayout.majorTickAlpha, minorTickAlpha: baseLayout.minorTickAlpha, majorTickColor: majorTickColor, minorTickColor: minorTickColor, backColor: backColor, gradientColor: baseLayout.thirdRing, outerRing: firstRingOuter, marks: thirdRingMarks, shadowDirection: shadowDirection, entityNotes: entityNotes, shadowSize: showsWidgetContainerBackground ? baseLayout.shadowSize : 0.0, highlightType: highlightType)
                    .scaleEffect(1 + directedScale.value * 0.5, anchor: directedScale.anchor)
                    .animation(.spring(duration: 0.5, bounce: 0.6, blendDuration: 0.2), value: directedScale)
                Ring(width: Ring.paddedWidth * widthScale, viewSize: size, compact: compact, ticks: chineseCalendar.subhourTicks, startingAngle: baseLayout.startingPhase.fourthRing, angle: chineseCalendar.subhourInHour, textFont: WatchFont(watchLayout.textFont), textColor: textColor, alpha: baseLayout.shadeAlpha, majorTickAlpha: baseLayout.majorTickAlpha, minorTickAlpha: baseLayout.minorTickAlpha, majorTickColor: majorTickColor, minorTickColor: minorTickColor, backColor: backColor, gradientColor: fourthRingColor, outerRing: secondRingOuter, marks: fourthRingMarks, shadowDirection: shadowDirection, entityNotes: entityNotes, shadowSize: baseLayout.shadowSize, highlightType: highlightType)
                    .scaleEffect(1 + directedScale.value * 0.75, anchor: directedScale.anchor)
                    .animation(.spring(duration: 0.5, bounce: 0.7, blendDuration: 0.2), value: directedScale)

                let timeString = displaySubquarter ? chineseCalendar.quarterString : chineseCalendar.shortQuarterString
                Core(viewSize: size, dateString: chineseCalendar.hourString, timeString: timeString, font: WatchFont(watchLayout.centerFont), maxLength: 3, textColor: baseLayout.centerFontColor, outerBound: innerBound, innerColor: coreColor, backColor: backColor, centerOffset: centerOffset, shadowDirection: shadowDirection, shadowSize: baseLayout.shadowSize)
                    .scaleEffect(1 + directedScale.value, anchor: directedScale.anchor)
                    .animation(.spring(duration: 0.5, bounce: 0.8, blendDuration: 0.2), value: directedScale)
            }
        }
    }
}

#Preview("Watch") {
    let baseLayout = BaseLayout()
    var watchLayout = WatchLayout(baseLayout: baseLayout)
    let config = CalendarConfigure()
    let defaultLayout = ThemeData.staticLayoutCode
    watchLayout.update(from: defaultLayout)
    let chineseCalendar = ChineseCalendar(timezone: config.effectiveTimezone, location: config.customLocation, compact: false, globalMonth: config.globalMonth, apparentTime: config.apparentTime, largeHour: config.largeHour)

    return Watch(displaySubquarter: true, displaySolarTerms: true, compact: false, watchLayout: watchLayout, markSize: 1.0, chineseCalendar: chineseCalendar, highlightType: .flicker)
        .frame(width: baseLayout.watchSize.width, height: baseLayout.watchSize.height)
}

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

struct ScaleEffectKey: EnvironmentKey {
    static let defaultValue = DirectedScale()
}

extension EnvironmentValues {
    var directedScale: DirectedScale {
        get { self[ScaleEffectKey.self] }
        set { self[ScaleEffectKey.self] = newValue }
    }
}

private func calSubhourGradient(watchLayout: WatchLayout, chineseCalendar: ChineseCalendar) -> WatchLayout.Gradient {
    let startOfDay = chineseCalendar.startOfDay
    let lengthOfDay = startOfDay.distance(to: chineseCalendar.startOfNextDay)
    let fourthRingColor = WatchLayout.Gradient(locations: [0, 1], colors: [
        watchLayout.thirdRing.interpolate(at: (startOfDay.distance(to: chineseCalendar.startHour) / lengthOfDay) % 1.0),
        watchLayout.thirdRing.interpolate(at: (startOfDay.distance(to: chineseCalendar.endHour) / lengthOfDay) % 1.0)
    ], loop: false)
    return fourthRingColor
}

private enum Rings {
    case date
    case time
}

private func ringMarks(for ring: Rings, watchLayout: WatchLayout, chineseCalendar: ChineseCalendar, radius: CGFloat) -> ([Marks], [Marks]) {
    switch ring {
    case .date:
        let eventInMonth = chineseCalendar.eventInMonth
        let firstRingMarks = [Marks(outer: true, locations: chineseCalendar.planetPosition, colors: watchLayout.planetIndicator, radius: radius)]
        let secondRingMarks = [
            Marks(outer: true, locations: eventInMonth.eclipse, colors: [watchLayout.eclipseIndicator], radius: radius),
            Marks(outer: true, locations: eventInMonth.fullMoon, colors: [watchLayout.fullmoonIndicator], radius: radius),
            Marks(outer: true, locations: eventInMonth.oddSolarTerm, colors: [watchLayout.oddStermIndicator], radius: radius),
            Marks(outer: true, locations: eventInMonth.evenSolarTerm, colors: [watchLayout.evenStermIndicator], radius: radius)
        ]
        return (firstRingMarks, secondRingMarks)
        
    case .time:
        let eventInDay = chineseCalendar.eventInDay
        let sunMoonPositions = chineseCalendar.sunMoonPositions
        let thirdRingMarks = [
            Marks(outer: true, locations: eventInDay.eclipse, colors: [watchLayout.eclipseIndicator], radius: radius),
            Marks(outer: true, locations: eventInDay.fullMoon, colors: [watchLayout.fullmoonIndicator], radius: radius),
            Marks(outer: true, locations: eventInDay.oddSolarTerm, colors: [watchLayout.oddStermIndicator], radius: radius),
            Marks(outer: true, locations: eventInDay.evenSolarTerm, colors: [watchLayout.evenStermIndicator], radius: radius),
            Marks(outer: false, locations: sunMoonPositions.solar, colors: watchLayout.sunPositionIndicator, radius: radius),
            Marks(outer: false, locations: sunMoonPositions.lunar, colors: watchLayout.moonPositionIndicator, radius: radius)
        ]
        let eventInHour = chineseCalendar.eventInHour
        let sunMoonSubhourPositions = chineseCalendar.sunMoonSubhourPositions
        let fourthRingMarks = [
            Marks(outer: true, locations: eventInHour.eclipse, colors: [watchLayout.eclipseIndicator], radius: radius),
            Marks(outer: true, locations: eventInHour.fullMoon, colors: [watchLayout.fullmoonIndicator], radius: radius),
            Marks(outer: true, locations: eventInHour.oddSolarTerm, colors: [watchLayout.oddStermIndicator], radius: radius),
            Marks(outer: true, locations: eventInHour.evenSolarTerm, colors: [watchLayout.evenStermIndicator], radius: radius),
            Marks(outer: false, locations: sunMoonSubhourPositions.solar, colors: watchLayout.sunPositionIndicator, radius: radius),
            Marks(outer: false, locations: sunMoonSubhourPositions.lunar, colors: watchLayout.moonPositionIndicator, radius: radius)
        ]
        return (thirdRingMarks, fourthRingMarks)
    }
}

struct PressState {
    private var startTime: Date?
    private var _startLocation: CGPoint?
    var ended = false
    var location: CGPoint? {
        didSet {
            if (_startLocation == nil && location != nil) || (_startLocation != nil && location == nil) {
                _startLocation = location
            }
        }
    }
    var distance: CGFloat? {
        if let location = location, let startLocation = _startLocation {
            let translation = location - startLocation
            return sqrt(pow(translation.x, 2) + pow(translation.y, 2))
        } else {
            return nil
        }
    }
    var duration: TimeInterval? {
        if let startTime = startTime, !ended {
            startTime.distance(to: .now)
        } else {
            nil
        }
    }
    var tapped: Bool {
        if let distance = distance, let duration = duration {
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
    let center = CGPointMake(size.width / 2, size.height / 2)
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
    @Environment(\.widgetRenderingMode) var widgetRenderingMode
#else
    let showsWidgetContainerBackground = true
#endif
    @Environment(\.directedScale) var directedScale
    let shrink: Bool
    let displayZeroRing: Bool
    let displaySubquarter: Bool
    let compact: Bool
    let phase = StartingPhase()
    let watchLayout: WatchLayout
    let markSize: CGFloat
    let widthScale: CGFloat
    let chineseCalendar: ChineseCalendar
    let centerOffset: CGFloat
    let entityNotes: EntityNotes?
    let shift: CGSize
    let highlightType: HighlightType
    
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
            CGSizeMake(watchLayout.horizontalTextOffset, watchLayout.verticalTextOffset)
        } else {
            CGSize.zero
        }
    }
    
    var body: some View {
        
#if !os(visionOS)
        let watchLayout = switch widgetRenderingMode {
        case .fullColor:
            self.watchLayout
        default:
            self.watchLayout.monochrome
        }
#else
        let watchLayout = self.watchLayout
#endif
        
        let fourthRingColor = calSubhourGradient(watchLayout: watchLayout, chineseCalendar: chineseCalendar)
        
        let textColor = colorScheme == .dark ? watchLayout.fontColorDark : watchLayout.fontColor
        let majorTickColor = colorScheme == .dark ? watchLayout.majorTickColorDark : watchLayout.majorTickColor
        let minorTickColor = colorScheme == .dark ? watchLayout.minorTickColorDark : watchLayout.minorTickColor
        let coreColor = colorScheme == .dark ? watchLayout.innerColorDark : watchLayout.innerColor
        let backColor = colorScheme == .dark ? watchLayout.backColorDark : watchLayout.backColor
        let shadowDirection = chineseCalendar.currentHourInDay
        
        GeometryReader { proxy in
            
            let size = proxy.size
            let shortEdge = min(size.width, size.height)
            let cornerSize = watchLayout.cornerRadiusRatio * shortEdge
            let outerBound = RoundedRect(rect: CGRect(origin: .zero, size: size), nodePos: cornerSize, ankorPos: cornerSize * 0.2).shrink(by: (showsWidgetContainerBackground && shrink) ? Self.frameOffset * shortEdge : 0.0)
            let firstRingOuter = displayZeroRing ? outerBound.shrink(by: ZeroRing.width * shortEdge * widthScale) : outerBound
            let secondRingOuter = firstRingOuter.shrink(by: Ring.paddedWidth * shortEdge * widthScale)
            let thirdRingOuter = secondRingOuter.shrink(by: Ring.paddedWidth * shortEdge * widthScale)
            let fourthRingOuter = thirdRingOuter.shrink(by: Ring.paddedWidth * shortEdge * widthScale)
            let innerBound = fourthRingOuter.shrink(by: Ring.paddedWidth * shortEdge * widthScale)
            let (firstRingMarks, secondRingMarks) = ringMarks(for: .date, watchLayout: watchLayout, chineseCalendar: chineseCalendar, radius: Marks.markSize * shortEdge * markSize)
            let (thirdRingMarks, fourthRingMarks) = ringMarks(for: .time, watchLayout: watchLayout, chineseCalendar: chineseCalendar, radius: Marks.markSize * shortEdge * markSize)
            
            ZStack {
                if displayZeroRing {
                    let oddSTColor = colorScheme == .dark ? watchLayout.oddSolarTermTickColorDark : watchLayout.oddSolarTermTickColor
                    let evenSTColor = colorScheme == .dark ? watchLayout.evenSolarTermTickColorDark : watchLayout.evenSolarTermTickColor
                    ZeroRing(width: ZeroRing.width * widthScale, viewSize: size, compact: compact, textFont: WatchFont(watchLayout.textFont), outerRing: outerBound, startingAngle: phase.zeroRing, oddTicks: chineseCalendar.oddSolarTerms.map { CGFloat($0) }, evenTicks: chineseCalendar.evenSolarTerms.map { CGFloat($0) }, oddColor: oddSTColor, evenColor: evenSTColor, oddTexts: ChineseCalendar.oddSolarTermChinese, evenTexts: ChineseCalendar.evenSolarTermChinese, offset: shift)
                }
                let _ = entityNotes?.reset()
                Ring(width: Ring.paddedWidth * widthScale, viewSize: size, compact: compact, ticks: chineseCalendar.monthTicks, startingAngle: phase.firstRing, angle: chineseCalendar.currentDayInYear, textFont: WatchFont(watchLayout.textFont), textColor: textColor, alpha: watchLayout.shadeAlpha, majorTickAlpha: watchLayout.majorTickAlpha, minorTickAlpha: watchLayout.minorTickAlpha, majorTickColor: majorTickColor, minorTickColor: minorTickColor, backColor: backColor, gradientColor: watchLayout.firstRing, outerRing: firstRingOuter, marks: firstRingMarks, shadowDirection: shadowDirection, entityNotes: entityNotes, shadowSize: showsWidgetContainerBackground ? watchLayout.shadowSize : 0.0, highlightType: highlightType, offset: shift)
                    .scaleEffect(1 + directedScale.value * 0.25, anchor: directedScale.anchor)
                    .animation(.spring(duration: 0.5, bounce: 0.6, blendDuration: 0.2), value: directedScale)
                Ring(width: Ring.paddedWidth * widthScale, viewSize: size, compact: compact, ticks: chineseCalendar.dayTicks, startingAngle: phase.secondRing, angle: chineseCalendar.currentDayInMonth, textFont: WatchFont(watchLayout.textFont), textColor: textColor, alpha: watchLayout.shadeAlpha, majorTickAlpha: watchLayout.majorTickAlpha, minorTickAlpha: watchLayout.minorTickAlpha, majorTickColor: majorTickColor, minorTickColor: minorTickColor, backColor: backColor, gradientColor: watchLayout.secondRing, outerRing: secondRingOuter, marks: secondRingMarks, shadowDirection: shadowDirection, entityNotes: entityNotes, shadowSize: watchLayout.shadowSize, highlightType: highlightType, offset: shift)
                    .scaleEffect(1 + directedScale.value * 0.5, anchor: directedScale.anchor)
                    .animation(.spring(duration: 0.5, bounce: 0.65, blendDuration: 0.2), value: directedScale)
                Ring(width: Ring.paddedWidth * widthScale, viewSize: size, compact: compact, ticks: chineseCalendar.hourTicks, startingAngle: phase.thirdRing, angle: chineseCalendar.currentHourInDay, textFont: WatchFont(watchLayout.textFont), textColor: textColor, alpha: watchLayout.shadeAlpha, majorTickAlpha: watchLayout.majorTickAlpha, minorTickAlpha: watchLayout.minorTickAlpha, majorTickColor: majorTickColor, minorTickColor: minorTickColor, backColor: backColor, gradientColor: watchLayout.thirdRing, outerRing: thirdRingOuter, marks: thirdRingMarks, shadowDirection: shadowDirection, entityNotes: entityNotes, shadowSize: watchLayout.shadowSize, highlightType: highlightType, offset: shift)
                    .scaleEffect(1 + directedScale.value * 0.75, anchor: directedScale.anchor)
                    .animation(.spring(duration: 0.5, bounce: 0.7, blendDuration: 0.2), value: directedScale)
                Ring(width: Ring.paddedWidth * widthScale, viewSize: size, compact: compact, ticks: chineseCalendar.subhourTicks, startingAngle: phase.fourthRing, angle: chineseCalendar.subhourInHour, textFont: WatchFont(watchLayout.textFont), textColor: textColor, alpha: watchLayout.shadeAlpha, majorTickAlpha: watchLayout.majorTickAlpha, minorTickAlpha: watchLayout.minorTickAlpha, majorTickColor: majorTickColor, minorTickColor: minorTickColor, backColor: backColor, gradientColor: fourthRingColor, outerRing: fourthRingOuter, marks: fourthRingMarks, shadowDirection: shadowDirection, entityNotes: entityNotes, shadowSize: watchLayout.shadowSize, highlightType: highlightType, offset: shift)
                    .scaleEffect(1 + directedScale.value, anchor: directedScale.anchor)
                    .animation(.spring(duration: 0.5, bounce: 0.75, blendDuration: 0.2), value: directedScale)
                let timeString = displaySubquarter ? chineseCalendar.timeString : (chineseCalendar.hourString + chineseCalendar.shortQuarterString)
                Core(viewSize: size, dateString: chineseCalendar.dateString, timeString: timeString, font: WatchFont(watchLayout.centerFont), maxLength: 5, textColor: watchLayout.centerFontColor, outerBound: innerBound, innerColor: coreColor, backColor: backColor, centerOffset: centerOffset, shadowDirection: shadowDirection, shadowSize: watchLayout.shadowSize)
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
    @Environment(\.widgetRenderingMode) var widgetRenderingMode
#else
    let showsWidgetContainerBackground = true
#endif
    let shrink: Bool
    let displayZeroRing: Bool
    let compact: Bool
    let phase = StartingPhase()
    let watchLayout: WatchLayout
    let markSize: CGFloat
    let widthScale: CGFloat
    let chineseCalendar: ChineseCalendar
    let centerOffset: CGFloat
    let entityNotes: EntityNotes?
    let highlightType: HighlightType
    
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
        
#if !os(visionOS)
        let watchLayout = switch widgetRenderingMode {
        case .fullColor:
            self.watchLayout
        default:
            self.watchLayout.monochrome
        }
#else
        let watchLayout = self.watchLayout
#endif

        let textColor = colorScheme == .dark ? watchLayout.fontColorDark : watchLayout.fontColor
        let majorTickColor = colorScheme == .dark ? watchLayout.majorTickColorDark : watchLayout.majorTickColor
        let minorTickColor = colorScheme == .dark ? watchLayout.minorTickColorDark : watchLayout.minorTickColor
        let coreColor = colorScheme == .dark ? watchLayout.innerColorDark : watchLayout.innerColor
        let backColor = colorScheme == .dark ? watchLayout.backColorDark : watchLayout.backColor
        let shadowDirection = chineseCalendar.currentHourInDay
        
        GeometryReader { proxy in
            
            let size = proxy.size
            let shortEdge = min(size.width, size.height)
            let cornerSize = watchLayout.cornerRadiusRatio * shortEdge
            let outerBound = RoundedRect(rect: CGRect(origin: .zero, size: size), nodePos: cornerSize, ankorPos: cornerSize * 0.2).shrink(by: (showsWidgetContainerBackground && shrink) ? Self.frameOffset * shortEdge : 0.0)
            let firstRingOuter = displayZeroRing ? outerBound.shrink(by: ZeroRing.width * shortEdge * widthScale) : outerBound
            let secondRingOuter = firstRingOuter.shrink(by: Ring.paddedWidth * shortEdge * widthScale)
            let innerBound = secondRingOuter.shrink(by: Ring.paddedWidth * shortEdge * widthScale)
            
            let (firstRingMarks, secondRingMarks) = ringMarks(for: .date, watchLayout: watchLayout, chineseCalendar: chineseCalendar, radius: Marks.markSize * shortEdge * markSize)
            
            ZStack {
                if displayZeroRing {
                    let oddSTColor = colorScheme == .dark ? watchLayout.oddSolarTermTickColorDark : watchLayout.oddSolarTermTickColor
                    let evenSTColor = colorScheme == .dark ? watchLayout.evenSolarTermTickColorDark : watchLayout.evenSolarTermTickColor
                    ZeroRing(width: ZeroRing.width * widthScale, viewSize: size, compact: compact, textFont: WatchFont(watchLayout.textFont), outerRing: outerBound, startingAngle: phase.zeroRing, oddTicks: chineseCalendar.oddSolarTerms.map { CGFloat($0) }, evenTicks: chineseCalendar.evenSolarTerms.map { CGFloat($0) }, oddColor: oddSTColor, evenColor: evenSTColor, oddTexts: ChineseCalendar.oddSolarTermChinese, evenTexts: ChineseCalendar.evenSolarTermChinese)
                }
                let _ = entityNotes?.reset()
                Ring(width: Ring.paddedWidth * widthScale, viewSize: size, compact: compact, ticks: chineseCalendar.monthTicks, startingAngle: phase.firstRing, angle: chineseCalendar.currentDayInYear, textFont: WatchFont(watchLayout.textFont), textColor: textColor, alpha: watchLayout.shadeAlpha, majorTickAlpha: watchLayout.majorTickAlpha, minorTickAlpha: watchLayout.minorTickAlpha, majorTickColor: majorTickColor, minorTickColor: minorTickColor, backColor: backColor, gradientColor: watchLayout.firstRing, outerRing: firstRingOuter, marks: firstRingMarks, shadowDirection: shadowDirection, entityNotes: entityNotes, shadowSize: showsWidgetContainerBackground ? watchLayout.shadowSize : 0.0, highlightType: highlightType)
                    .scaleEffect(1 + directedScale.value * 0.5, anchor: directedScale.anchor)
                    .animation(.spring(duration: 0.5, bounce: 0.6, blendDuration: 0.2), value: directedScale)
                Ring(width: Ring.paddedWidth * widthScale, viewSize: size, compact: compact, ticks: chineseCalendar.dayTicks, startingAngle: phase.secondRing, angle: chineseCalendar.currentDayInMonth, textFont: WatchFont(watchLayout.textFont), textColor: textColor, alpha: watchLayout.shadeAlpha, majorTickAlpha: watchLayout.majorTickAlpha, minorTickAlpha: watchLayout.minorTickAlpha, majorTickColor: majorTickColor, minorTickColor: minorTickColor, backColor: backColor, gradientColor: watchLayout.secondRing, outerRing: secondRingOuter, marks: secondRingMarks, shadowDirection: shadowDirection, entityNotes: entityNotes, shadowSize: watchLayout.shadowSize, highlightType: highlightType)
                    .scaleEffect(1 + directedScale.value * 0.75, anchor: directedScale.anchor)
                    .animation(.spring(duration: 0.5, bounce: 0.7, blendDuration: 0.2), value: directedScale)

                Core(viewSize: size, dateString: chineseCalendar.monthString, timeString: chineseCalendar.dayString, font: WatchFont(watchLayout.centerFont), maxLength: 3, textColor: watchLayout.centerFontColor, outerBound: innerBound, innerColor: coreColor, backColor: backColor, centerOffset: centerOffset, shadowDirection: shadowDirection, shadowSize: watchLayout.shadowSize)
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
    @Environment(\.widgetRenderingMode) var widgetRenderingMode
#else
    let showsWidgetContainerBackground = true
#endif
    let shrink: Bool
    let displayZeroRing: Bool
    let displaySubquarter: Bool
    let compact: Bool
    let phase = StartingPhase()
    let watchLayout: WatchLayout
    let markSize: CGFloat
    let widthScale: CGFloat
    let chineseCalendar: ChineseCalendar
    let centerOffset: CGFloat
    let entityNotes: EntityNotes?
    let highlightType: HighlightType
    
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
        
#if !os(visionOS)
        let watchLayout = switch widgetRenderingMode {
        case .fullColor:
            self.watchLayout
        default:
            self.watchLayout.monochrome
        }
#else
        let watchLayout = self.watchLayout
#endif
        
        let fourthRingColor = calSubhourGradient(watchLayout: watchLayout, chineseCalendar: chineseCalendar)
        
        let textColor = colorScheme == .dark ? watchLayout.fontColorDark : watchLayout.fontColor
        let majorTickColor = colorScheme == .dark ? watchLayout.majorTickColorDark : watchLayout.majorTickColor
        let minorTickColor = colorScheme == .dark ? watchLayout.minorTickColorDark : watchLayout.minorTickColor
        let coreColor = colorScheme == .dark ? watchLayout.innerColorDark : watchLayout.innerColor
        let backColor = colorScheme == .dark ? watchLayout.backColorDark : watchLayout.backColor
        let shadowDirection = chineseCalendar.currentHourInDay
        
        GeometryReader { proxy in
            
            let size = proxy.size
            let shortEdge = min(size.width, size.height)
            let cornerSize = watchLayout.cornerRadiusRatio * shortEdge
            let outerBound = RoundedRect(rect: CGRect(origin: .zero, size: size), nodePos: cornerSize, ankorPos: cornerSize * 0.2).shrink(by: (showsWidgetContainerBackground && shrink) ? Self.frameOffset * shortEdge : 0.0)
            let firstRingOuter = displayZeroRing ? outerBound.shrink(by: ZeroRing.width * shortEdge * widthScale) : outerBound
            let secondRingOuter = firstRingOuter.shrink(by: Ring.paddedWidth * shortEdge * widthScale)
            let innerBound = secondRingOuter.shrink(by: Ring.paddedWidth * shortEdge * widthScale)
            let (thirdRingMarks, fourthRingMarks) = ringMarks(for: .time, watchLayout: watchLayout, chineseCalendar: chineseCalendar, radius: Marks.markSize * shortEdge * markSize)
            
            ZStack {
                let _ = entityNotes?.reset()
                Ring(width: Ring.paddedWidth * widthScale, viewSize: size, compact: compact, ticks: chineseCalendar.hourTicks, startingAngle: phase.thirdRing, angle: chineseCalendar.currentHourInDay, textFont: WatchFont(watchLayout.textFont), textColor: textColor, alpha: watchLayout.shadeAlpha, majorTickAlpha: watchLayout.majorTickAlpha, minorTickAlpha: watchLayout.minorTickAlpha, majorTickColor: majorTickColor, minorTickColor: minorTickColor, backColor: backColor, gradientColor: watchLayout.thirdRing, outerRing: firstRingOuter, marks: thirdRingMarks, shadowDirection: shadowDirection, entityNotes: entityNotes, shadowSize: showsWidgetContainerBackground ? watchLayout.shadowSize : 0.0, highlightType: highlightType)
                    .scaleEffect(1 + directedScale.value * 0.5, anchor: directedScale.anchor)
                    .animation(.spring(duration: 0.5, bounce: 0.6, blendDuration: 0.2), value: directedScale)
                Ring(width: Ring.paddedWidth * widthScale, viewSize: size, compact: compact, ticks: chineseCalendar.subhourTicks, startingAngle: phase.fourthRing, angle: chineseCalendar.subhourInHour, textFont: WatchFont(watchLayout.textFont), textColor: textColor, alpha: watchLayout.shadeAlpha, majorTickAlpha: watchLayout.majorTickAlpha, minorTickAlpha: watchLayout.minorTickAlpha, majorTickColor: majorTickColor, minorTickColor: minorTickColor, backColor: backColor, gradientColor: fourthRingColor, outerRing: secondRingOuter, marks: fourthRingMarks, shadowDirection: shadowDirection, entityNotes: entityNotes, shadowSize: watchLayout.shadowSize, highlightType: highlightType)
                    .scaleEffect(1 + directedScale.value * 0.75, anchor: directedScale.anchor)
                    .animation(.spring(duration: 0.5, bounce: 0.7, blendDuration: 0.2), value: directedScale)
                
                let timeString = displaySubquarter ? chineseCalendar.quarterString : chineseCalendar.shortQuarterString
                Core(viewSize: size, dateString: chineseCalendar.hourString, timeString: timeString, font: WatchFont(watchLayout.centerFont), maxLength: 3, textColor: watchLayout.centerFontColor, outerBound: innerBound, innerColor: coreColor, backColor: backColor, centerOffset: centerOffset, shadowDirection: shadowDirection, shadowSize: watchLayout.shadowSize)
                    .scaleEffect(1 + directedScale.value, anchor: directedScale.anchor)
                    .animation(.spring(duration: 0.5, bounce: 0.8, blendDuration: 0.2), value: directedScale)
            }
        }
    }
}

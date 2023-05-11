//
//  WatchFaceView.swift
//  Chinese Time Watch
//
//  Created by Leo Liu on 5/9/23.
//

import Foundation
import SwiftUI

class WatchLayout: MetaWatchLayout, ObservableObject {
    static var shared: WatchLayout = WatchLayout()
    
    var textFont: UIFont
    var centerFont: UIFont
    @Published var refresh = false
    
    override init() {
        textFont = UIFont.systemFont(ofSize: 10, weight: .regular)
        centerFont = UIFont(name: "SourceHanSansKR-Heavy", size: 10)!
        super.init()
    }
    
    override func update(from str: String) {
        super.update(from: str)
        refresh.toggle()
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

private func allRingMarks(watchLayout: WatchLayout, chineseCalendar: ChineseCalendar, radius: CGFloat) -> ([Marks], [Marks], [Marks], [Marks]) {
    let eventInMonth = chineseCalendar.eventInMonth
    let firstRingMarks = [Marks(outer: true, locations: chineseCalendar.planetPosition, colors: watchLayout.planetIndicator, radius: radius)]
    let secondRingMarks = [
        Marks(outer: true, locations: eventInMonth.eclipse, colors: [watchLayout.eclipseIndicator], radius: radius),
        Marks(outer: true, locations: eventInMonth.fullMoon, colors:  [watchLayout.fullmoonIndicator], radius: radius),
        Marks(outer: true, locations: eventInMonth.oddSolarTerm, colors: [watchLayout.oddStermIndicator], radius: radius),
        Marks(outer: true, locations: eventInMonth.evenSolarTerm, colors: [watchLayout.evenStermIndicator], radius: radius)
    ]
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
    return (first: firstRingMarks, second: secondRingMarks, third: thirdRingMarks, fourth: fourthRingMarks)
}

struct Watch: View {
    private static let majorUpdateInterval: CGFloat = 3600
    private static let minorUpdateInterval: CGFloat = majorUpdateInterval / 12
    static let updateInterval: CGFloat = 14.4
    static let frameOffset: CGFloat = 0
    
    @State var size = CGSize.zero
    @State var refresh: Bool = false
    let compact: Bool
    let phase = StartingPhase()
    let watchLayout: WatchLayout
    let chineseCalendar: ChineseCalendar
    var displayTime: Date? = nil
    var timezone = Calendar.current.timeZone
    var realLocation: CGPoint? = nil
    
    var location: CGPoint? {
        realLocation ?? watchLayout.location
    }
    
    init(compact: Bool, refresh: Bool, watchLayout: WatchLayout, displayTime: Date? = nil, timezone: TimeZone? = nil, realLocation: CGPoint? = nil) {
        self.compact = compact
        self.watchLayout = watchLayout
        self.displayTime = displayTime
        self.timezone = timezone ?? Calendar.current.timeZone
        self.realLocation = realLocation
        self.chineseCalendar = ChineseCalendar(time: displayTime ?? Date(), timezone: self.timezone, location: realLocation ?? watchLayout.location, compact: compact)
        self.refresh = refresh
    }
    
    var body: some View {
        let shortEdge = min(self.size.width, self.size.height)
        let cornerSize = watchLayout.cornerRadiusRatio * shortEdge
        let outerBound = RoundedRect(rect: CGRect(origin: .zero, size: size), nodePos: cornerSize, ankorPos: cornerSize*0.2).shrink(by: Watch.frameOffset * shortEdge)
        let firstRingOuter = outerBound.shrink(by: ZeroRing.width * shortEdge)
        let secondRingOuter = firstRingOuter.shrink(by: Ring.paddedWidth * shortEdge)
        let thirdRingOuter = secondRingOuter.shrink(by: Ring.paddedWidth * shortEdge)
        let fourthRingOuter = thirdRingOuter.shrink(by: Ring.paddedWidth * shortEdge)
        let innerBound = fourthRingOuter.shrink(by: Ring.paddedWidth * shortEdge)
        let fourthRingColor = calSubhourGradient(watchLayout: watchLayout, chineseCalendar: chineseCalendar)
        
        let _ = chineseCalendar.update(time: displayTime ?? Date(), timezone: timezone, location: location)
        let _ = chineseCalendar.updateDate()
        
        let (firstRingMarks, secondRingMarks, thirdRingMarks, fourthRingMarks) = allRingMarks(watchLayout: watchLayout, chineseCalendar: chineseCalendar, radius: Marks.markSize * shortEdge)

        let shadowDirection = chineseCalendar.currentHourInDay
        
        GeometryReader { proxy in
            ZStack {
                ZeroRing(width: ZeroRing.width, viewSize: size, compact: compact, textFont: WatchFont(watchLayout.textFont), outerRing: outerBound, startingAngle: phase.zeroRing, oddTicks: chineseCalendar.oddSolarTerms.map{CGFloat($0)}, evenTicks: chineseCalendar.evenSolarTerms.map{CGFloat($0)}, oddColor: watchLayout.oddSolarTermTickColorDark, evenColor: watchLayout.evenSolarTermTickColorDark, oddTexts: ChineseCalendar.oddSolarTermChinese, evenTexts: ChineseCalendar.evenSolarTermChinese)
                Ring(width: Ring.paddedWidth, viewSize: size, compact: compact, cornerSize: watchLayout.cornerRadiusRatio, ticks: chineseCalendar.monthTicks, startingAngle: phase.firstRing, angle: chineseCalendar.currentDayInYear, textFont: WatchFont(watchLayout.textFont), textColor: watchLayout.fontColorDark, alpha: watchLayout.shadeAlpha, majorTickAlpha: watchLayout.majorTickAlpha, minorTickAlpha: watchLayout.minorTickAlpha, majorTickColor: watchLayout.majorTickColorDark, minorTickColor: watchLayout.minorTickColorDark, gradientColor: watchLayout.firstRing, outerRing: firstRingOuter, marks: firstRingMarks, shadowDirection: shadowDirection)
                Ring(width: Ring.paddedWidth, viewSize: size, compact: compact, cornerSize: watchLayout.cornerRadiusRatio, ticks: chineseCalendar.dayTicks, startingAngle: phase.secondRing, angle: chineseCalendar.currentDayInMonth, textFont: WatchFont(watchLayout.textFont), textColor: watchLayout.fontColorDark, alpha: watchLayout.shadeAlpha, majorTickAlpha: watchLayout.majorTickAlpha, minorTickAlpha: watchLayout.minorTickAlpha, majorTickColor: watchLayout.majorTickColorDark, minorTickColor: watchLayout.minorTickColorDark, gradientColor: watchLayout.secondRing, outerRing: secondRingOuter, marks: secondRingMarks, shadowDirection: shadowDirection)
                Ring(width: Ring.paddedWidth, viewSize: size, compact: compact, cornerSize: watchLayout.cornerRadiusRatio, ticks: chineseCalendar.hourTicks, startingAngle: phase.thirdRing, angle: chineseCalendar.currentHourInDay, textFont: WatchFont(watchLayout.textFont), textColor: watchLayout.fontColorDark, alpha: watchLayout.shadeAlpha, majorTickAlpha: watchLayout.majorTickAlpha, minorTickAlpha: watchLayout.minorTickAlpha, majorTickColor: watchLayout.majorTickColorDark, minorTickColor: watchLayout.minorTickColorDark, gradientColor: watchLayout.thirdRing, outerRing: thirdRingOuter, marks: thirdRingMarks, shadowDirection: shadowDirection)
                Ring(width: Ring.paddedWidth, viewSize: size, compact: compact, cornerSize: watchLayout.cornerRadiusRatio, ticks: chineseCalendar.subhourTicks, startingAngle: phase.fourthRing, angle: chineseCalendar.subhourInHour, textFont: WatchFont(watchLayout.textFont), textColor: watchLayout.fontColorDark, alpha: watchLayout.shadeAlpha, majorTickAlpha: watchLayout.majorTickAlpha, minorTickAlpha: watchLayout.minorTickAlpha, majorTickColor: watchLayout.majorTickColorDark, minorTickColor: watchLayout.minorTickColorDark, gradientColor: fourthRingColor, outerRing: fourthRingOuter, marks: fourthRingMarks, shadowDirection: shadowDirection)
                Core(viewSize: size, compact: compact, dateString: chineseCalendar.dateString, timeString: chineseCalendar.timeString, font: WatchFont(watchLayout.centerFont), maxLength: 5, textColor: watchLayout.centerFontColor, outerBound: innerBound, backColor: watchLayout.innerColorDark, centerOffset: 0.1, shadowDirection: shadowDirection)
            }
            .onAppear() {
                size = proxy.size
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct DualWatch: View {
    
    private static let majorUpdateInterval: CGFloat = 3600
    private static let minorUpdateInterval: CGFloat = majorUpdateInterval / 12
    static let updateInterval: CGFloat = 14.4
    static let frameOffset: CGFloat = 0
    static var timer: Timer?
    
    @State var size = CGSize.zero
    @State var refresh: Bool = false
    @State private var hideDots: Bool = true
    @State private var selectedPageIndex = 0
    let compact: Bool
    let phase = StartingPhase()
    let watchLayout: WatchLayout
    let chineseCalendar: ChineseCalendar
    var displayTime: Date? = nil
    var timezone = Calendar.current.timeZone
    var realLocation: CGPoint? = nil
    
    var location: CGPoint? {
        realLocation ?? watchLayout.location
    }
    
    init(compact: Bool, refresh: Bool, watchLayout: WatchLayout, displayTime: Date? = nil, timezone: TimeZone? = nil, realLocation: CGPoint? = nil) {
        self.compact = compact
        self.watchLayout = watchLayout
        self.displayTime = displayTime
        self.timezone = timezone ?? Calendar.current.timeZone
        self.realLocation = realLocation
        self.chineseCalendar = ChineseCalendar(time: displayTime ?? Date(), timezone: self.timezone, location: realLocation ?? watchLayout.location, compact: compact)
        self.refresh = refresh
    }
    
    var body: some View {
        
        let shortEdge = min(self.size.width, self.size.height)
        let cornerSize = watchLayout.cornerRadiusRatio * shortEdge
        let outerBound = RoundedRect(rect: CGRect(origin: .zero, size: size), nodePos: cornerSize, ankorPos: cornerSize*0.2).shrink(by: Watch.frameOffset * shortEdge)
        let firstRingOuter = outerBound.shrink(by: ZeroRing.width * shortEdge * 1.2)
        let secondRingOuter = firstRingOuter.shrink(by: Ring.paddedWidth * shortEdge * 1.3)
        let innerBound = secondRingOuter.shrink(by: Ring.paddedWidth * shortEdge * 1.3)
        let fourthRingColor = calSubhourGradient(watchLayout: watchLayout, chineseCalendar: chineseCalendar)
        
        let _ = chineseCalendar.update(time: displayTime ?? Date(), timezone: timezone, location: location)
        let _ = chineseCalendar.updateDate()
        
        let (firstRingMarks, secondRingMarks, thirdRingMarks, fourthRingMarks) = allRingMarks(watchLayout: watchLayout, chineseCalendar: chineseCalendar, radius: Marks.markSize * shortEdge * 1.5)

        let shadowDirection = chineseCalendar.currentHourInDay
        
        GeometryReader { proxy in
            TabView(selection: $selectedPageIndex) {
                ZStack {
                    ZeroRing(width: ZeroRing.width * 1.2, viewSize: size, compact: compact, textFont: WatchFont(watchLayout.textFont), outerRing: outerBound, startingAngle: phase.zeroRing, oddTicks: chineseCalendar.oddSolarTerms.map{CGFloat($0)}, evenTicks: chineseCalendar.evenSolarTerms.map{CGFloat($0)}, oddColor: watchLayout.oddSolarTermTickColorDark, evenColor: watchLayout.evenSolarTermTickColorDark, oddTexts: ChineseCalendar.oddSolarTermChinese, evenTexts: ChineseCalendar.evenSolarTermChinese)
                    Ring(width: Ring.paddedWidth * 1.3, viewSize: size, compact: compact, cornerSize: watchLayout.cornerRadiusRatio, ticks: chineseCalendar.monthTicks, startingAngle: phase.firstRing, angle: chineseCalendar.currentDayInYear, textFont: WatchFont(watchLayout.textFont), textColor: watchLayout.fontColorDark, alpha: watchLayout.shadeAlpha, majorTickAlpha: watchLayout.majorTickAlpha, minorTickAlpha: watchLayout.minorTickAlpha, majorTickColor: watchLayout.majorTickColorDark, minorTickColor: watchLayout.minorTickColorDark, gradientColor: watchLayout.firstRing, outerRing: firstRingOuter, marks: firstRingMarks, shadowDirection: shadowDirection)
                    Ring(width: Ring.paddedWidth * 1.3, viewSize: size, compact: compact, cornerSize: watchLayout.cornerRadiusRatio, ticks: chineseCalendar.dayTicks, startingAngle: phase.secondRing, angle: chineseCalendar.currentDayInMonth, textFont: WatchFont(watchLayout.textFont), textColor: watchLayout.fontColorDark, alpha: watchLayout.shadeAlpha, majorTickAlpha: watchLayout.majorTickAlpha, minorTickAlpha: watchLayout.minorTickAlpha, majorTickColor: watchLayout.majorTickColorDark, minorTickColor: watchLayout.minorTickColorDark, gradientColor: watchLayout.secondRing, outerRing: secondRingOuter, marks: secondRingMarks, shadowDirection: shadowDirection)

                    Core(viewSize: size, compact: compact, dateString: chineseCalendar.monthString, timeString: chineseCalendar.dayString, font: WatchFont(watchLayout.centerFont), maxLength: 3, textColor: watchLayout.centerFontColor, outerBound: innerBound, backColor: watchLayout.innerColorDark, centerOffset: 0.05, shadowDirection: shadowDirection)
                }
                .onAppear() {
                    size = proxy.size
                }
                .ignoresSafeArea()
                .tag(0)

                ZStack {
                    Ring(width: Ring.paddedWidth * 1.3, viewSize: size, compact: compact, cornerSize: watchLayout.cornerRadiusRatio, ticks: chineseCalendar.hourTicks, startingAngle: phase.thirdRing, angle: chineseCalendar.currentHourInDay, textFont: WatchFont(watchLayout.textFont), textColor: watchLayout.fontColorDark, alpha: watchLayout.shadeAlpha, majorTickAlpha: watchLayout.majorTickAlpha, minorTickAlpha: watchLayout.minorTickAlpha, majorTickColor: watchLayout.majorTickColorDark, minorTickColor: watchLayout.minorTickColorDark, gradientColor: watchLayout.thirdRing, outerRing: firstRingOuter, marks: thirdRingMarks, shadowDirection: shadowDirection)
                    Ring(width: Ring.paddedWidth * 1.3, viewSize: size, compact: compact, cornerSize: watchLayout.cornerRadiusRatio, ticks: chineseCalendar.subhourTicks, startingAngle: phase.fourthRing, angle: chineseCalendar.subhourInHour, textFont: WatchFont(watchLayout.textFont), textColor: watchLayout.fontColorDark, alpha: watchLayout.shadeAlpha, majorTickAlpha: watchLayout.majorTickAlpha, minorTickAlpha: watchLayout.minorTickAlpha, majorTickColor: watchLayout.majorTickColorDark, minorTickColor: watchLayout.minorTickColorDark, gradientColor: fourthRingColor, outerRing: secondRingOuter, marks: fourthRingMarks, shadowDirection: shadowDirection)

                    Core(viewSize: size, compact: compact, dateString: chineseCalendar.hourString, timeString: chineseCalendar.quarterString, font: WatchFont(watchLayout.centerFont), maxLength: 3, textColor: watchLayout.centerFontColor, outerBound: innerBound, backColor: watchLayout.innerColorDark, centerOffset: 0.05, shadowDirection: shadowDirection)
                }
                .onAppear() {
                    size = proxy.size
                }
                .ignoresSafeArea()
                .tag(1)
            }
            .onChange(of: selectedPageIndex) { _ in
                hideDots = false
                DualWatch.timer?.invalidate()
                DualWatch.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                    hideDots = true
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: hideDots ? .never : .automatic))
        }
    }
}

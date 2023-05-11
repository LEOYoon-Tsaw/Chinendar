//
//  WatchFaceView.swift
//  MacWidgetExtension
//
//  Created by Leo Liu on 5/9/23.
//

import Foundation
import SwiftUI

private func calSubhourGradient(watchLayout: WatchLayout, chineseCalendar: ChineseCalendar) -> WatchLayout.Gradient {
    let startOfDay = chineseCalendar.startOfDay
    let lengthOfDay = startOfDay.distance(to: chineseCalendar.startOfNextDay)
    let fourthRingColor = WatchLayout.Gradient(locations: [0, 1], colors: [
        watchLayout.thirdRing.interpolate(at: (startOfDay.distance(to: chineseCalendar.startHour) / lengthOfDay) % 1.0),
        watchLayout.thirdRing.interpolate(at: (startOfDay.distance(to: chineseCalendar.endHour) / lengthOfDay) % 1.0)
    ], loop: false)
    return fourthRingColor
}

enum Rings {
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
            Marks(outer: true, locations: eventInMonth.fullMoon, colors:  [watchLayout.fullmoonIndicator], radius: radius),
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

struct Watch: View {
    @Environment(\.colorScheme) var colorScheme
    static let frameOffset: CGFloat = 0.05
    
    @State var size = CGSize.zero
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
    
    init(compact: Bool, displayTime: Date) {
        self.compact = compact
        self.displayTime = displayTime
        self.watchLayout = WatchLayout.shared
        self.realLocation = LocationManager.shared.location
        self.chineseCalendar = ChineseCalendar(time: displayTime, timezone: self.timezone, location: realLocation ?? LocationManager.shared.location, compact: compact)
    }
    
    var body: some View {
        let shortEdge = min(self.size.width, self.size.height)
        let cornerSize = watchLayout.cornerRadiusRatio * shortEdge
        let outerBound = RoundedRect(rect: CGRect(origin: .zero, size: size), nodePos: cornerSize, ankorPos: cornerSize*0.2).shrink(by: Self.frameOffset * shortEdge)
        let firstRingOuter = outerBound.shrink(by: ZeroRing.width * shortEdge * 0.8)
        let secondRingOuter = firstRingOuter.shrink(by: Ring.paddedWidth * shortEdge * 0.8)
        let thirdRingOuter = secondRingOuter.shrink(by: Ring.paddedWidth * shortEdge * 0.8)
        let fourthRingOuter = thirdRingOuter.shrink(by: Ring.paddedWidth * shortEdge * 0.8)
        let innerBound = fourthRingOuter.shrink(by: Ring.paddedWidth * shortEdge * 0.8)
        let fourthRingColor = calSubhourGradient(watchLayout: watchLayout, chineseCalendar: chineseCalendar)
        
        let _ = chineseCalendar.update(time: displayTime ?? Date(), timezone: timezone, location: location)
        let _ = chineseCalendar.updateDate()
        
        let (firstRingMarks, secondRingMarks) = ringMarks(for: .date, watchLayout: watchLayout, chineseCalendar: chineseCalendar, radius: Marks.markSize * shortEdge * 0.7)
        let (thirdRingMarks, fourthRingMarks) = ringMarks(for: .time, watchLayout: watchLayout, chineseCalendar: chineseCalendar, radius: Marks.markSize * shortEdge * 0.7)

        let shadowDirection = chineseCalendar.currentHourInDay

        let oddSTColor = colorScheme == .dark ? watchLayout.oddSolarTermTickColorDark : watchLayout.oddSolarTermTickColor
        let evenSTColor = colorScheme == .dark ? watchLayout.evenSolarTermTickColorDark : watchLayout.evenSolarTermTickColor
        let textColor = colorScheme == .dark ? watchLayout.fontColorDark : watchLayout.fontColor
        let majorTickColor = colorScheme == .dark ? watchLayout.majorTickColorDark : watchLayout.majorTickColor
        let minorTickColor = colorScheme == .dark ? watchLayout.minorTickColorDark : watchLayout.minorTickColor
        let coreColor = colorScheme == .dark ? watchLayout.innerColorDark : watchLayout.innerColor
        
        GeometryReader { proxy in
            ZStack {
                ZeroRing(width: ZeroRing.width * 0.8, viewSize: size, compact: compact, textFont: WatchFont(watchLayout.textFont), outerRing: outerBound, startingAngle: phase.zeroRing, oddTicks: chineseCalendar.oddSolarTerms.map{CGFloat($0)}, evenTicks: chineseCalendar.evenSolarTerms.map{CGFloat($0)}, oddColor: oddSTColor, evenColor: evenSTColor, oddTexts: ChineseCalendar.oddSolarTermChinese, evenTexts: ChineseCalendar.evenSolarTermChinese)
                Ring(width: Ring.paddedWidth * 0.8, viewSize: size, compact: compact, cornerSize: watchLayout.cornerRadiusRatio, ticks: chineseCalendar.monthTicks, startingAngle: phase.firstRing, angle: chineseCalendar.currentDayInYear, textFont: WatchFont(watchLayout.textFont), textColor: textColor, alpha: watchLayout.shadeAlpha, majorTickAlpha: watchLayout.majorTickAlpha, minorTickAlpha: watchLayout.minorTickAlpha,
                     majorTickColor: majorTickColor, minorTickColor: minorTickColor, gradientColor: watchLayout.firstRing, outerRing: firstRingOuter, marks: firstRingMarks, shadowDirection: shadowDirection)
                Ring(width: Ring.paddedWidth * 0.8, viewSize: size, compact: compact, cornerSize: watchLayout.cornerRadiusRatio, ticks: chineseCalendar.dayTicks, startingAngle: phase.secondRing, angle: chineseCalendar.currentDayInMonth, textFont: WatchFont(watchLayout.textFont), textColor: textColor, alpha: watchLayout.shadeAlpha, majorTickAlpha: watchLayout.majorTickAlpha, minorTickAlpha: watchLayout.minorTickAlpha, majorTickColor: majorTickColor, minorTickColor: minorTickColor, gradientColor: watchLayout.secondRing, outerRing: secondRingOuter, marks: secondRingMarks, shadowDirection: shadowDirection)
                Ring(width: Ring.paddedWidth * 0.8, viewSize: size, compact: compact, cornerSize: watchLayout.cornerRadiusRatio, ticks: chineseCalendar.hourTicks, startingAngle: phase.thirdRing, angle: chineseCalendar.currentHourInDay, textFont: WatchFont(watchLayout.textFont), textColor: textColor, alpha: watchLayout.shadeAlpha, majorTickAlpha: watchLayout.majorTickAlpha, minorTickAlpha: watchLayout.minorTickAlpha, majorTickColor: majorTickColor, minorTickColor: minorTickColor, gradientColor: watchLayout.thirdRing, outerRing: thirdRingOuter, marks: thirdRingMarks, shadowDirection: shadowDirection)
                Ring(width: Ring.paddedWidth * 0.8, viewSize: size, compact: compact, cornerSize: watchLayout.cornerRadiusRatio, ticks: chineseCalendar.subhourTicks, startingAngle: phase.fourthRing, angle: chineseCalendar.subhourInHour, textFont: WatchFont(watchLayout.textFont), textColor: textColor, alpha: watchLayout.shadeAlpha, majorTickAlpha: watchLayout.majorTickAlpha, minorTickAlpha: watchLayout.minorTickAlpha, majorTickColor: majorTickColor, minorTickColor: minorTickColor, gradientColor: fourthRingColor, outerRing: fourthRingOuter, marks: fourthRingMarks, shadowDirection: shadowDirection)
                Core(viewSize: size, compact: compact, dateString: chineseCalendar.dateString, timeString: chineseCalendar.timeString, font: WatchFont(watchLayout.centerFont), maxLength: 5, textColor: watchLayout.centerFontColor, outerBound: innerBound, backColor: coreColor, centerOffset: 0.1, shadowDirection: shadowDirection)
            }
            .onAppear() {
                size = proxy.size
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct DateWatch: View {
    @Environment(\.colorScheme) var colorScheme
    static let frameOffset: CGFloat = 0.07
    
    @State var size = CGSize.zero
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
    
    init(compact: Bool, displayTime: Date) {
        self.compact = compact
        self.displayTime = displayTime
        self.watchLayout = WatchLayout.shared
        self.realLocation = LocationManager.shared.location
        self.chineseCalendar = ChineseCalendar(time: displayTime, timezone: self.timezone, location: realLocation ?? LocationManager.shared.location, compact: compact)
    }
    
    var body: some View {
        let shortEdge = min(self.size.width, self.size.height)
        let cornerSize = watchLayout.cornerRadiusRatio * shortEdge
        let outerBound = RoundedRect(rect: CGRect(origin: .zero, size: size), nodePos: cornerSize, ankorPos: cornerSize*0.2).shrink(by: Self.frameOffset * shortEdge)
        let firstRingOuter = outerBound
        let secondRingOuter = firstRingOuter.shrink(by: Ring.paddedWidth * shortEdge * 1.3)
        let innerBound = secondRingOuter.shrink(by: Ring.paddedWidth * shortEdge * 1.3)
        
        let _ = chineseCalendar.update(time: displayTime ?? Date(), timezone: timezone, location: location)
        let _ = chineseCalendar.updateDate()
        
        let (firstRingMarks, secondRingMarks) = ringMarks(for: .date, watchLayout: watchLayout, chineseCalendar: chineseCalendar, radius: Marks.markSize * shortEdge * 1.5)

        let shadowDirection = chineseCalendar.currentHourInDay

        let textColor = colorScheme == .dark ? watchLayout.fontColorDark : watchLayout.fontColor
        let majorTickColor = colorScheme == .dark ? watchLayout.majorTickColorDark : watchLayout.majorTickColor
        let minorTickColor = colorScheme == .dark ? watchLayout.minorTickColorDark : watchLayout.minorTickColor
        let coreColor = colorScheme == .dark ? watchLayout.innerColorDark : watchLayout.innerColor
        
        GeometryReader { proxy in
            ZStack {
                Ring(width: Ring.paddedWidth * 1.3, viewSize: size, compact: compact, cornerSize: watchLayout.cornerRadiusRatio, ticks: chineseCalendar.monthTicks, startingAngle: phase.firstRing, angle: chineseCalendar.currentDayInYear, textFont: WatchFont(watchLayout.textFont), textColor: textColor, alpha: watchLayout.shadeAlpha, majorTickAlpha: watchLayout.majorTickAlpha, minorTickAlpha: watchLayout.minorTickAlpha,
                     majorTickColor: majorTickColor, minorTickColor: minorTickColor, gradientColor: watchLayout.firstRing, outerRing: firstRingOuter, marks: firstRingMarks, shadowDirection: shadowDirection)
                Ring(width: Ring.paddedWidth * 1.3, viewSize: size, compact: compact, cornerSize: watchLayout.cornerRadiusRatio, ticks: chineseCalendar.dayTicks, startingAngle: phase.secondRing, angle: chineseCalendar.currentDayInMonth, textFont: WatchFont(watchLayout.textFont), textColor: textColor, alpha: watchLayout.shadeAlpha, majorTickAlpha: watchLayout.majorTickAlpha, minorTickAlpha: watchLayout.minorTickAlpha, majorTickColor: majorTickColor, minorTickColor: minorTickColor, gradientColor: watchLayout.secondRing, outerRing: secondRingOuter, marks: secondRingMarks, shadowDirection: shadowDirection)
                Core(viewSize: size, compact: compact, dateString: chineseCalendar.monthString, timeString: chineseCalendar.dayString, font: WatchFont(watchLayout.centerFont), maxLength: 3, textColor: watchLayout.centerFontColor, outerBound: innerBound, backColor: coreColor, centerOffset: 0.1, shadowDirection: shadowDirection)
            }
            .onAppear() {
                size = proxy.size
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct TimeWatch: View {
    @Environment(\.colorScheme) var colorScheme
    static let frameOffset: CGFloat = 0.07
    
    @State var size = CGSize.zero
    let compact: Bool
    let phase = StartingPhase()
    let watchLayout: WatchLayout
    let chineseCalendar: ChineseCalendar
    var displayTime: Date? = nil
    var timezone = Calendar.current.timeZone
    var realLocation: CGPoint? = nil
    
    var location: CGPoint? {
        LocationManager.shared.location ?? watchLayout.location
    }
    
    init(compact: Bool, displayTime: Date) {
        self.compact = compact
        self.displayTime = displayTime
        self.watchLayout = WatchLayout.shared
        self.realLocation = LocationManager.shared.location
        self.chineseCalendar = ChineseCalendar(time: displayTime, timezone: self.timezone, location: realLocation ?? LocationManager.shared.location, compact: compact)
    }
    
    var body: some View {
        let shortEdge = min(self.size.width, self.size.height)
        let cornerSize = watchLayout.cornerRadiusRatio * shortEdge
        let outerBound = RoundedRect(rect: CGRect(origin: .zero, size: size), nodePos: cornerSize, ankorPos: cornerSize*0.2).shrink(by: Self.frameOffset * shortEdge)
        let firstRingOuter = outerBound
        let secondRingOuter = firstRingOuter.shrink(by: Ring.paddedWidth * shortEdge * 1.3)
        let innerBound = secondRingOuter.shrink(by: Ring.paddedWidth * shortEdge * 1.3)
        let fourthRingColor = calSubhourGradient(watchLayout: watchLayout, chineseCalendar: chineseCalendar)
        
        let _ = chineseCalendar.update(time: displayTime ?? Date(), timezone: timezone, location: location)
        let _ = chineseCalendar.updateDate()
        
        let (firstRingMarks, secondRingMarks) = ringMarks(for: .time, watchLayout: watchLayout, chineseCalendar: chineseCalendar, radius: Marks.markSize * shortEdge * 1.5)
        
        let shadowDirection = chineseCalendar.currentHourInDay
        
        let textColor = colorScheme == .dark ? watchLayout.fontColorDark : watchLayout.fontColor
        let majorTickColor = colorScheme == .dark ? watchLayout.majorTickColorDark : watchLayout.majorTickColor
        let minorTickColor = colorScheme == .dark ? watchLayout.minorTickColorDark : watchLayout.minorTickColor
        let coreColor = colorScheme == .dark ? watchLayout.innerColorDark : watchLayout.innerColor
        
        GeometryReader { proxy in
            ZStack {
                Ring(width: Ring.paddedWidth * 1.3, viewSize: size, compact: compact, cornerSize: watchLayout.cornerRadiusRatio, ticks: chineseCalendar.hourTicks, startingAngle: phase.thirdRing, angle: chineseCalendar.currentHourInDay, textFont: WatchFont(watchLayout.textFont), textColor: textColor, alpha: watchLayout.shadeAlpha, majorTickAlpha: watchLayout.majorTickAlpha, minorTickAlpha: watchLayout.minorTickAlpha, majorTickColor: majorTickColor, minorTickColor: minorTickColor, gradientColor: watchLayout.thirdRing, outerRing: firstRingOuter, marks: firstRingMarks, shadowDirection: shadowDirection)
                Ring(width: Ring.paddedWidth * 1.3, viewSize: size, compact: compact, cornerSize: watchLayout.cornerRadiusRatio, ticks: chineseCalendar.subhourTicks, startingAngle: phase.fourthRing, angle: chineseCalendar.subhourInHour, textFont: WatchFont(watchLayout.textFont), textColor: textColor, alpha: watchLayout.shadeAlpha, majorTickAlpha: watchLayout.majorTickAlpha, minorTickAlpha: watchLayout.minorTickAlpha, majorTickColor: majorTickColor, minorTickColor: minorTickColor, gradientColor: fourthRingColor, outerRing: secondRingOuter, marks: secondRingMarks, shadowDirection: shadowDirection)
                Core(viewSize: size, compact: compact, dateString: chineseCalendar.hourString, timeString: chineseCalendar.quarterString, font: WatchFont(watchLayout.centerFont), maxLength: 3, textColor: watchLayout.centerFontColor, outerBound: innerBound, backColor: coreColor, centerOffset: 0.1, shadowDirection: shadowDirection)
            }
            .onAppear() {
                size = proxy.size
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

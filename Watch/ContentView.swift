//
//  ContentView.swift
//  ChineseTime Watch App
//
//  Created by Leo Liu on 5/3/23.
//

import SwiftUI

struct ContentView: View {
    
    @Environment(\.scenePhase) var scenePhase
    @StateObject var locationManager = LocationManager.shared
    @StateObject var watchLayout = WatchLayout.shared
    
    let timer = Timer.publish(every: Watch.updateInterval, on: .main, in: .common).autoconnect()
    @State var cornerRadius: CGFloat = 0
    @State var adjustTime: Date?
    @State var adjustTimeTarget: Bool = true
    @State var size: CGSize = .zero
    @State var refresh = false
    @State var displayTime: Date?

    var body: some View {

        return GeometryReader { proxy in
            NavigationStack() {
                ScrollView {
                    VStack(spacing: 10) {
                        Watch(compact: true, refresh: refresh,
                              watchLayout: watchLayout, displayTime: displayTime, timezone: Calendar.current.timeZone, realLocation: locationManager.location
                        )
                            .frame(width: size.width, height: size.height)
                            .navigationTitle(NSLocalizedString("華曆", comment: "App Name"))
                            .navigationBarTitleDisplayMode(.inline)
                            .onReceive(timer) { input in
                                refresh.toggle()
                            }
                            .onChange(of: scenePhase) { newPhase in
                                if newPhase == .active {
                                    WatchConnectivityManager.shared.requestLayout()
                                }
                            }
                            .onAppear() {
                                locationManager.requestLocation()
                            }
                        Spacer(minLength: 10)
                        VStack(spacing: 0) {
                            Text(NSLocalizedString("圓角比例", comment: "Corner radius ratio"))
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            HStack {
                                Image(systemName: "minus")
                                    .font(Font.system(.title3, design: .rounded, weight: .black))
                                    .padding()
                                    .foregroundColor(.black)
                                    .background {
                                        Circle()
                                            .fill(Color.pink)
                                            .frame(width: 35, height: 35)
                                    }
                                    .onTapGesture() {
                                        cornerRadius = max(0.3, cornerRadius - 0.1)
                                        watchLayout.cornerRadiusRatio = cornerRadius
                                        refresh.toggle()
                                        let _ = DataContainer.shared.saveLayout(watchLayout.encode())
                                    }
                                Text(String(format: "%.1f", cornerRadius))
                                    .onAppear() {
                                        cornerRadius = watchLayout.cornerRadiusRatio
                                    }
                                    .font(Font.system(.title, design: .rounded, weight: .black))
                                    .padding()
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                Image(systemName: "plus")
                                    .font(Font.system(.title3, design: .rounded, weight: .black))
                                    .padding()
                                    .foregroundColor(.black)
                                    .background {
                                        Circle()
                                            .fill(Color.pink)
                                            .frame(width: 35, height: 35)
                                    }
                                    .onTapGesture() {
                                        cornerRadius = min(0.9, cornerRadius + 0.1)
                                        watchLayout.cornerRadiusRatio = cornerRadius
                                        refresh.toggle()
                                        let _ = DataContainer.shared.saveLayout(watchLayout.encode())
                                    }
                            }
                        }
                        NavigationLink(NSLocalizedString("調時", comment: "Change Time")) {
                            ScrollView {
                                VStack(spacing: 10) {
                                    Text(adjustTime?.formatted(date: .numeric, time: .omitted) ?? "")
                                        .font(Font.system(.title3, design: .rounded, weight: .bold))
                                        .frame(maxWidth: .infinity, minHeight: 25)
                                        .lineLimit(1)
                                        .padding()
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(Color.green, lineWidth: adjustTimeTarget ? 0 : 1)
                                                .padding(.all, 1)
                                        )
                                        .onTapGesture {
                                            adjustTimeTarget = false
                                        }
                                    Text(adjustTime?.formatted(date: .omitted, time: .shortened) ?? "")
                                        .font(Font.system(.title3, design: .rounded, weight: .bold))
                                        .frame(maxWidth: .infinity, minHeight: 25)
                                        .lineLimit(1)
                                        .padding()
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(Color.green, lineWidth: adjustTimeTarget ? 1 : 0)
                                                .padding(.all, 1)
                                        )
                                        .onTapGesture {
                                            adjustTimeTarget = true
                                        }
                                    HStack {
                                        Button(action: {
                                            adjustTime = adjustTime?.advanced(by: adjustTimeTarget ? -3600 : -3600 * 24)
                                            displayTime = adjustTime
                                        }) {
                                            Image(systemName: "minus")
                                                .font(Font.system(.title3, design: .rounded, weight: .black))
                                                .foregroundColor(.black)
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(Color.pink)
                                        .buttonBorderShape(.capsule)
                                        Button(action: {
                                            adjustTime = adjustTime?.advanced(by: adjustTimeTarget ? 3600 : 3600 * 24)
                                            displayTime = adjustTime
                                        }) {
                                            Image(systemName: "plus")
                                                .font(Font.system(.title3, design: .rounded, weight: .black))
                                                .foregroundColor(.black)
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(Color.pink)
                                        .buttonBorderShape(.capsule)
                                    }
                                    Button(action: {
                                        adjustTime = Date()
                                        displayTime = nil
                                    }) {
                                        Image(systemName: "arrow.clockwise")
                                            .font(Font.system(.title3, design: .rounded, weight: .black))
                                            .foregroundColor(.black)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(Color.pink)
                                    .buttonBorderShape(.capsule)
                                }
                                .navigationTitle(NSLocalizedString("調時", comment: "Change Time"))
                                .onAppear() {
                                    adjustTime = displayTime ?? Date()
                                }
                                .onDisappear() {
                                    adjustTime = nil
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color.pink)
                        Text(NSLocalizedString("更多設置請移步 iOS App，可於手機與手錶間自動同步", comment: "Hint for syncing between watch and phone"))
                            .frame(maxWidth: .infinity)
                            .font(Font.footnote)
                            .foregroundColor(Color.secondary)
                    }
                }
            }
            .onAppear() {
                size = proxy.size
            }
        }
        .ignoresSafeArea(edges: [.bottom, .horizontal])
    }
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
    
    func calSubhourGradient() -> WatchLayout.Gradient {
        let startOfDay = chineseCalendar.startOfDay
        let lengthOfDay = startOfDay.distance(to: chineseCalendar.startOfNextDay)
        let fourthRingColor = WatchLayout.Gradient(locations: [0, 1], colors: [
            watchLayout.thirdRing.interpolate(at: (startOfDay.distance(to: chineseCalendar.startHour) / lengthOfDay) % 1.0),
            watchLayout.thirdRing.interpolate(at: (startOfDay.distance(to: chineseCalendar.endHour) / lengthOfDay) % 1.0)
        ], loop: false)
        return fourthRingColor
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
        let fourthRingColor = calSubhourGradient()
        
        let _ = chineseCalendar.update(time: displayTime ?? Date(), timezone: timezone, location: location)
        let _ = chineseCalendar.updateDate()
        
        let eventInMonth = chineseCalendar.eventInMonth
        let firstRingMarks = [Marks(outer: true, locations: chineseCalendar.planetPosition, colors: watchLayout.planetIndicator, radius: Marks.markSize * shortEdge)]
        let secondRingMarks = [
            Marks(outer: true, locations: eventInMonth.eclipse, colors: [watchLayout.eclipseIndicator], radius: Marks.markSize * shortEdge),
            Marks(outer: true, locations: eventInMonth.fullMoon, colors:  [watchLayout.fullmoonIndicator], radius: Marks.markSize * shortEdge),
            Marks(outer: true, locations: eventInMonth.oddSolarTerm, colors: [watchLayout.oddStermIndicator], radius: Marks.markSize * shortEdge),
            Marks(outer: true, locations: eventInMonth.evenSolarTerm, colors: [watchLayout.evenStermIndicator], radius: Marks.markSize * shortEdge)
        ]
        let eventInDay = chineseCalendar.eventInDay
        let sunMoonPositions = chineseCalendar.sunMoonPositions
        let thirdRingMarks = [
            Marks(outer: true, locations: eventInDay.eclipse, colors: [watchLayout.eclipseIndicator], radius: Marks.markSize * shortEdge),
            Marks(outer: true, locations: eventInDay.fullMoon, colors: [watchLayout.fullmoonIndicator], radius: Marks.markSize * shortEdge),
            Marks(outer: true, locations: eventInDay.oddSolarTerm, colors: [watchLayout.oddStermIndicator], radius: Marks.markSize * shortEdge),
            Marks(outer: true, locations: eventInDay.evenSolarTerm, colors: [watchLayout.evenStermIndicator], radius: Marks.markSize * shortEdge),
            Marks(outer: false, locations: sunMoonPositions.solar, colors: watchLayout.sunPositionIndicator, radius: Marks.markSize * shortEdge),
            Marks(outer: false, locations: sunMoonPositions.lunar, colors: watchLayout.moonPositionIndicator, radius: Marks.markSize * shortEdge)
        ]
        let eventInHour = chineseCalendar.eventInHour
        let sunMoonSubhourPositions = chineseCalendar.sunMoonSubhourPositions
        let fourthRingMarks = [
            Marks(outer: true, locations: eventInHour.eclipse, colors: [watchLayout.eclipseIndicator], radius: Marks.markSize * shortEdge),
            Marks(outer: true, locations: eventInHour.fullMoon, colors: [watchLayout.fullmoonIndicator], radius: Marks.markSize * shortEdge),
            Marks(outer: true, locations: eventInHour.oddSolarTerm, colors: [watchLayout.oddStermIndicator], radius: Marks.markSize * shortEdge),
            Marks(outer: true, locations: eventInHour.evenSolarTerm, colors: [watchLayout.evenStermIndicator], radius: Marks.markSize * shortEdge),
            Marks(outer: false, locations: sunMoonSubhourPositions.solar, colors: watchLayout.sunPositionIndicator, radius: Marks.markSize * shortEdge),
            Marks(outer: false, locations: sunMoonSubhourPositions.lunar, colors: watchLayout.moonPositionIndicator, radius: Marks.markSize * shortEdge)
        ]
        let shadowDirection = chineseCalendar.currentHourInDay
        
        GeometryReader { proxy in
            ZStack {
                ZeroRing(viewSize: size, compact: compact, textFont: watchLayout.textFont, outerRing: outerBound, startingAngle: phase.zeroRing, oddTicks: chineseCalendar.oddSolarTerms.map{CGFloat($0)}, evenTicks: chineseCalendar.evenSolarTerms.map{CGFloat($0)}, oddColor: watchLayout.oddSolarTermTickColorDark, evenColor: watchLayout.evenSolarTermTickColorDark, oddTexts: ChineseCalendar.oddSolarTermChinese, evenTexts: ChineseCalendar.evenSolarTermChinese)
                Ring(viewSize: size, compact: compact, cornerSize: watchLayout.cornerRadiusRatio, ticks: chineseCalendar.monthTicks, startingAngle: phase.firstRing, angle: chineseCalendar.currentDayInYear, textFont: watchLayout.textFont, textColor: watchLayout.fontColorDark, alpha: watchLayout.shadeAlpha, majorTickAlpha: watchLayout.majorTickAlpha, minorTickAlpha: watchLayout.minorTickAlpha, majorTickColor: watchLayout.majorTickColorDark, minorTickColor: watchLayout.minorTickColorDark, gradientColor: watchLayout.firstRing, outerRing: firstRingOuter, marks: firstRingMarks, shadowDirection: shadowDirection)
                Ring(viewSize: size, compact: compact, cornerSize: watchLayout.cornerRadiusRatio, ticks: chineseCalendar.dayTicks, startingAngle: phase.secondRing, angle: chineseCalendar.currentDayInMonth, textFont: watchLayout.textFont, textColor: watchLayout.fontColorDark, alpha: watchLayout.shadeAlpha, majorTickAlpha: watchLayout.majorTickAlpha, minorTickAlpha: watchLayout.minorTickAlpha, majorTickColor: watchLayout.majorTickColorDark, minorTickColor: watchLayout.minorTickColorDark, gradientColor: watchLayout.secondRing, outerRing: secondRingOuter, marks: secondRingMarks, shadowDirection: shadowDirection)
                Ring(viewSize: size, compact: compact, cornerSize: watchLayout.cornerRadiusRatio, ticks: chineseCalendar.hourTicks, startingAngle: phase.thirdRing, angle: chineseCalendar.currentHourInDay, textFont: watchLayout.textFont, textColor: watchLayout.fontColorDark, alpha: watchLayout.shadeAlpha, majorTickAlpha: watchLayout.majorTickAlpha, minorTickAlpha: watchLayout.minorTickAlpha, majorTickColor: watchLayout.majorTickColorDark, minorTickColor: watchLayout.minorTickColorDark, gradientColor: watchLayout.thirdRing, outerRing: thirdRingOuter, marks: thirdRingMarks, shadowDirection: shadowDirection)
                Ring(viewSize: size, compact: compact, cornerSize: watchLayout.cornerRadiusRatio, ticks: chineseCalendar.subhourTicks, startingAngle: phase.fourthRing, angle: chineseCalendar.subhourInHour, textFont: watchLayout.textFont, textColor: watchLayout.fontColorDark, alpha: watchLayout.shadeAlpha, majorTickAlpha: watchLayout.majorTickAlpha, minorTickAlpha: watchLayout.minorTickAlpha, majorTickColor: watchLayout.majorTickColorDark, minorTickColor: watchLayout.minorTickColorDark, gradientColor: fourthRingColor, outerRing: fourthRingOuter, marks: fourthRingMarks, shadowDirection: shadowDirection)
                Core(viewSize: size, compact: compact, dateString: chineseCalendar.dateString, timeString: chineseCalendar.timeString, font: watchLayout.centerFont, textColor: watchLayout.centerFontColor, outerBound: innerBound, backColor: watchLayout.innerColorDark, centerOffset: watchLayout.centerTextOffset, shadowDirection: shadowDirection)
            }
            .onAppear() {
                size = proxy.size
            }
        }
        .ignoresSafeArea(edges: .bottom)
        
    }
}

struct ContentView_Previews: PreviewProvider {
    
    init() {
        DataContainer.shared.loadSave()
    }
    
    static var previews: some View {
        Watch(compact: true, refresh: false, watchLayout: WatchLayout.shared)
            .previewDevice(PreviewDevice(rawValue: "Apple Watch Series 8 (41mm)"))
            .previewDisplayName("41mm")
        Watch(compact: true, refresh: false, watchLayout: WatchLayout.shared)
            .previewDevice(PreviewDevice(rawValue: "Apple Watch Series 8 (45mm)"))
            .previewDisplayName("45mm")
        Watch(compact: true, refresh: false, watchLayout: WatchLayout.shared)
            .previewDevice(PreviewDevice(rawValue: "Apple Watch Ultra (49mm)"))
            .previewDisplayName("49mm")
    }
}

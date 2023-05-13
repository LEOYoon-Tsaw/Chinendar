//
//  WatchWidgetBundle.swift
//  WatchWidgetExtension
//
//  Created by Leo Liu on 5/11/23.
//

import WidgetKit
import SwiftUI

@main
struct WatchWidgetBundle: WidgetBundle {
    init() {
        DataContainer.shared.loadSave()
        LocationManager.shared.requestLocation(completion: nil)
    }

    @WidgetBundleBuilder
    var body: some Widget {
        LineWidget()
        CircularWidget()
        CurveWidget()
    }
}

struct Curve: View {
    enum Icon {
        case solarTerm(view: SolarTerm)
        case moon(view: MoonPhase)
        case sunrise(view: Sun)
    }
    
    @State var size: CGSize = .zero
    var icon: Icon
    var barColor: Color
    var start: Date?
    var end: Date?
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                switch(icon) {
                case .solarTerm(view: let view):
                    view
                case .moon(view: let view):
                    view
                case .sunrise(view: let view):
                    view
                }
            }
            .frame(width: size.width, height: size.height)
            .widgetLabel {
                if let start = start, let end = end {
                    ProgressView(timerInterval: start...end, countsDown: false) {
                        Text(end, style: .relative)
                    }
                    .tint(barColor)
                }
            }
            .onAppear() {
                size = proxy.size
            }
        }
    }
}


struct CurveProvider: IntentTimelineProvider {
    func placeholder(in context: Context) -> CurveEntry {
        let chineseCalendar = ChineseCalendar(time: Date(), timezone: Calendar.current.timeZone, location: LocationManager.shared.location ?? WatchLayout.shared.location, compact: true)
        return CurveEntry(date: Date(), configuration: CurveIntent(), chinsesCalendar: chineseCalendar)
    }

    func getSnapshot(for configuration: CurveIntent, in context: Context, completion: @escaping (CurveEntry) -> ()) {
        let chineseCalendar = ChineseCalendar(time: Date(), timezone: Calendar.current.timeZone, location: LocationManager.shared.location ?? WatchLayout.shared.location, compact: true)
        let entry = CurveEntry(date: Date(), configuration: configuration, chinsesCalendar: chineseCalendar)
        completion(entry)
    }

    func getTimeline(for configuration: CurveIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [CurveEntry] = []
        DataContainer.shared.loadSave()
        LocationManager.shared.requestLocation(completion: nil)

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        let chineseCalendar = ChineseCalendar(time: currentDate, timezone: Calendar.current.timeZone, location: LocationManager.shared.location ?? WatchLayout.shared.location, compact: true)
        for hourOffset in 0 ..< 12 {
            let entryDate: Date
            switch configuration.target {
            case .moonriseSet, .sunriseSet:
                entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
                chineseCalendar.update(time: entryDate, timezone: chineseCalendar.calendar.timeZone, location: chineseCalendar.location)
            default:
                let targetDate = Calendar.current.date(byAdding: .day, value: hourOffset, to: currentDate)!
                chineseCalendar.update(time: targetDate, timezone: chineseCalendar.calendar.timeZone, location: chineseCalendar.location)
                entryDate = chineseCalendar.startOfNextDay
                chineseCalendar.update(time: entryDate, timezone: chineseCalendar.calendar.timeZone, location: chineseCalendar.location)
            }
            
            let entry = CurveEntry(date: entryDate, configuration: configuration, chinsesCalendar: chineseCalendar.copy)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    func recommendations() -> [IntentRecommendation<CurveIntent>] {
        let solarTerms = {let intent = CurveIntent(); intent.target = .solarTerms; return intent}()
        let lunarPhases = {let intent = CurveIntent(); intent.target = .lunarPhases; return intent}()
        let sunriseSet = {let intent = CurveIntent(); intent.target = .sunriseSet; return intent}()
        let moonriseSet = {let intent = CurveIntent(); intent.target = .moonriseSet; return intent}()

        return [
            IntentRecommendation(intent: solarTerms, description: "次節氣"),
            IntentRecommendation(intent: lunarPhases, description: "次朔望"),
            IntentRecommendation(intent: sunriseSet, description: "日出入"),
            IntentRecommendation(intent: moonriseSet, description: "月出入")
        ]
    }
}

struct CurveEntry: TimelineEntry {
    let date: Date
    let configuration: CurveIntent
    let chinsesCalendar: ChineseCalendar
}

struct CurveEntryView : View {
    var entry: CurveProvider.Entry
    
    private func find(in dates: [ChineseCalendar.NamedDate], at date: Date) -> (previous: ChineseCalendar.NamedDate?, next: ChineseCalendar.NamedDate?) {
        if dates.count > 1 {
            let atDate = ChineseCalendar.NamedDate(name: "", date: date)
            let index = dates.insertionIndex(of: atDate, comparison: { $0.date < $1.date })
            if index > 0 && index < dates.count {
                return (previous: dates[index - 1], next: dates[index])
            } else if index < dates.count {
                return (previous: nil, next: dates[index])
            } else {
                return (previous: dates[index - 1], next: nil)
            }
        } else {
            return (previous: nil, next: nil)
        }
    }
    private func findSolarTerm(_ solarTerm: String) -> Int {
        if let even = ChineseCalendar.evenSolarTermChinese.firstIndex(of: solarTerm) {
            return even * 2
        } else if let odd = ChineseCalendar.oddSolarTermChinese.firstIndex(of: solarTerm) {
            return odd * 2 + 1
        } else {
            return -1
        }
    }

    var body: some View {
        let layout = WatchLayout.shared
        switch entry.configuration.target {
        case .lunarPhases:
            let (previous, next) = find(in: entry.chinsesCalendar.moonPhases, at: entry.chinsesCalendar.time)
            if let next = next, let previous = previous {
                let color = next.name == ChineseCalendar.MoonPhases[0] ? layout.eclipseIndicator : layout.fullmoonIndicator
                Curve(icon: .moon(view: MoonPhase(angle: next.name == ChineseCalendar.MoonPhases[0] ? 0.05 : 0.5, color: color)),
                      barColor: Color(cgColor: layout.secondRing.interpolate(at: entry.chinsesCalendar.currentDayInMonth)),
                      start: previous.date, end: next.date)
            }
        case .sunriseSet:
            let sunriseAndSet = entry.chinsesCalendar.sunTimes.filter { $0.name == ChineseCalendar.dayTimeName[1] || $0.name == ChineseCalendar.dayTimeName[3] }
            let (previous, next) = find(in: sunriseAndSet, at: entry.chinsesCalendar.time)
            if let next = next, let previous = previous {
                let color = next.name == ChineseCalendar.dayTimeName[1] ? layout.sunPositionIndicator[1] : layout.sunPositionIndicator[3]
                Curve(icon: .sunrise(view: Sun(color: color, rise: next.name == ChineseCalendar.dayTimeName[1])),
                      barColor: Color(cgColor: layout.thirdRing.interpolate(at: entry.chinsesCalendar.currentHourInDay)),
                      start: previous.date, end: next.date)
            } else {
                Curve(icon: .sunrise(view: Sun(color: layout.sunPositionIndicator[2], rise: nil)),
                      barColor: Color(cgColor: layout.thirdRing.interpolate(at: entry.chinsesCalendar.currentHourInDay)),
                      start: nil, end: nil)
            }
        case .moonriseSet:
            let moonriseAndSet = entry.chinsesCalendar.moonTimes.filter { $0.name == ChineseCalendar.moonTimeName[0] || $0.name == ChineseCalendar.moonTimeName[2] }
            let (previous, next) = find(in: moonriseAndSet, at: entry.chinsesCalendar.time)
            if let next = next, let previous = previous {
                let color = next.name == ChineseCalendar.moonTimeName[0] ? layout.moonPositionIndicator[0] : layout.moonPositionIndicator[2]
                Curve(icon: .moon(view: MoonPhase(angle: entry.chinsesCalendar.currentDayInMonth, color: color, rise: next.name == ChineseCalendar.moonTimeName[0])),
                      barColor: Color(cgColor: layout.secondRing.interpolate(at: entry.chinsesCalendar.currentDayInMonth)),
                      start: previous.date, end: next.date)
            } else {
                Curve(icon: .moon(view: MoonPhase(angle: entry.chinsesCalendar.currentDayInMonth, color: layout.moonPositionIndicator[1], rise: nil)),
                     barColor: Color(cgColor: layout.thirdRing.interpolate(at: entry.chinsesCalendar.currentDayInMonth)),
                     start: nil, end: nil)
            }
        default:
            let (previous, next) = find(in: entry.chinsesCalendar.solarTerms, at: entry.chinsesCalendar.time)
            if let next = next, let previous = previous {
                let color = ChineseCalendar.evenSolarTermChinese.contains(next.name) ? layout.evenStermIndicator : layout.oddStermIndicator
                let index = findSolarTerm(next.name)
                if index >= 0 {
                    Curve(icon: .solarTerm(view: SolarTerm(angle: CGFloat(index) / 24.0, color: color)),
                          barColor: Color(cgColor: layout.firstRing.interpolate(at: entry.chinsesCalendar.currentDayInYear)),
                          start: previous.date, end: next.date)
                }
            }
        }
    }
}

struct CurveWidget: Widget {
    let kind: String = "Curve"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: CurveIntent.self, provider: CurveProvider()) { entry in
            CurveEntryView(entry: entry)
        }
        .configurationDisplayName("Curve")
        .description("Curve View.")
        .supportedFamilies([.accessoryCorner])
    }
}

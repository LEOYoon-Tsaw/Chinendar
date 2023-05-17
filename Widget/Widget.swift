//
//  Widget.swift
//  iOSWidgetExtension
//
//  Created by Leo Liu on 5/9/23.
//

import Intents
import SwiftUI
import WidgetKit

struct SmallProvider: IntentTimelineProvider {
    func placeholder(in context: Context) -> SmallEntry {
        let chineseCalendar = ChineseCalendar(time: Date(), timezone: Calendar.current.timeZone, location: LocationManager.shared.location ?? WatchLayout.shared.location, compact: true)
        return SmallEntry(date: Date(), configuration: SmallIntent(), chineseCalendar: chineseCalendar)
    }

    func getSnapshot(for configuration: SmallIntent, in context: Context, completion: @escaping (SmallEntry) -> ()) {
        let chineseCalendar = ChineseCalendar(time: Date(), timezone: Calendar.current.timeZone, location: LocationManager.shared.location ?? WatchLayout.shared.location, compact: true)
        let entry = SmallEntry(date: Date(), configuration: configuration, chineseCalendar: chineseCalendar)
        completion(entry)
    }

    func getTimeline(for configuration: SmallIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SmallEntry] = []
        DataContainer.shared.loadSave()
        LocationManager.shared.requestLocation(completion: nil)

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        switch configuration.mode {
        case .time:
#if os(macOS)
            let count = 50
#else
            let count = 15
#endif
            let chineseCalendar = ChineseCalendar(time: currentDate, timezone: Calendar.current.timeZone, location: LocationManager.shared.location ?? WatchLayout.shared.location, compact: true)
            for offset in 0 ..< count {
                let entryDate = currentDate + Double(offset * 864) // 14.4min
                chineseCalendar.update(time: entryDate, timezone: chineseCalendar.calendar.timeZone, location: chineseCalendar.location)
                let entry = SmallEntry(date: entryDate, configuration: configuration, chineseCalendar: chineseCalendar.copy)
                entries.append(entry)
            }
        default:
#if os(macOS)
            let count = 24
#else
            let count = 15
#endif
            let chineseCalendar = ChineseCalendar(time: currentDate, timezone: Calendar.current.timeZone, location: LocationManager.shared.location ?? WatchLayout.shared.location, compact: true)
            for offset in 0 ..< count {
                let entryDate = Calendar.current.date(byAdding: .hour, value: offset, to: currentDate)!
                chineseCalendar.update(time: entryDate, timezone: chineseCalendar.calendar.timeZone, location: chineseCalendar.location)
                let entry = SmallEntry(date: entryDate, configuration: configuration, chineseCalendar: chineseCalendar.copy)
                entries.append(entry)
            }
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct MediumProvider: IntentTimelineProvider {
    func placeholder(in context: Context) -> MediumEntry {
        let chineseCalendar = ChineseCalendar(time: Date(), timezone: Calendar.current.timeZone, location: LocationManager.shared.location ?? WatchLayout.shared.location, compact: true)
        return MediumEntry(date: Date(), configuration: MediumIntent(), chineseCalendar: chineseCalendar)
    }

    func getSnapshot(for configuration: MediumIntent, in context: Context, completion: @escaping (MediumEntry) -> ()) {
        let chineseCalendar = ChineseCalendar(time: Date(), timezone: Calendar.current.timeZone, location: LocationManager.shared.location ?? WatchLayout.shared.location, compact: true)
        let entry = MediumEntry(date: Date(), configuration: configuration, chineseCalendar: chineseCalendar)
        completion(entry)
    }

    func getTimeline(for configuration: MediumIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [MediumEntry] = []
        DataContainer.shared.loadSave()
        LocationManager.shared.requestLocation(completion: nil)

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()

#if os(macOS)
        let count = 50
#else
        let count = 15
#endif
        let chineseCalendar = ChineseCalendar(time: currentDate, timezone: Calendar.current.timeZone, location: LocationManager.shared.location ?? WatchLayout.shared.location, compact: true)
        for offset in 0 ..< count {
            let entryDate = currentDate + Double(offset * 864) // 14.4min
            chineseCalendar.update(time: entryDate, timezone: chineseCalendar.calendar.timeZone, location: chineseCalendar.location)
            let entry = MediumEntry(date: entryDate, configuration: configuration, chineseCalendar: chineseCalendar.copy)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct LargeProvider: IntentTimelineProvider {
    func placeholder(in context: Context) -> LargeEntry {
        let chineseCalendar = ChineseCalendar(time: Date(), timezone: Calendar.current.timeZone, location: LocationManager.shared.location ?? WatchLayout.shared.location, compact: false)
        return LargeEntry(date: Date(), configuration: LargeIntent(), chineseCalendar: chineseCalendar)
    }

    func getSnapshot(for configuration: LargeIntent, in context: Context, completion: @escaping (LargeEntry) -> ()) {
        let chineseCalendar = ChineseCalendar(time: Date(), timezone: Calendar.current.timeZone, location: LocationManager.shared.location ?? WatchLayout.shared.location, compact: false)
        let entry = LargeEntry(date: Date(), configuration: configuration, chineseCalendar: chineseCalendar)
        completion(entry)
    }

    func getTimeline(for configuration: LargeIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [LargeEntry] = []
        DataContainer.shared.loadSave()
        LocationManager.shared.requestLocation(completion: nil)

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
#if os(macOS)
        let count = 50
#else
        let count = 15
#endif
        let chineseCalendar = ChineseCalendar(time: currentDate, timezone: Calendar.current.timeZone, location: LocationManager.shared.location ?? WatchLayout.shared.location, compact: false)
        for offset in 0 ..< count {
            let entryDate = currentDate + Double(offset * 864) // 14.4min
            chineseCalendar.update(time: entryDate, timezone: chineseCalendar.calendar.timeZone, location: chineseCalendar.location)
            let entry = LargeEntry(date: entryDate, configuration: configuration, chineseCalendar: chineseCalendar.copy)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SmallEntry: TimelineEntry {
    let date: Date
    let configuration: SmallIntent
    let chineseCalendar: ChineseCalendar
}

struct MediumEntry: TimelineEntry {
    let date: Date
    let configuration: MediumIntent
    let chineseCalendar: ChineseCalendar
}

struct LargeEntry: TimelineEntry {
    let date: Date
    let configuration: LargeIntent
    let chineseCalendar: ChineseCalendar
}

struct SmallWidgetEntryView: View {
    var entry: SmallProvider.Entry

    init(entry: SmallEntry) {
        self.entry = entry
    }

    var body: some View {
        ZStack {
            if let opacity = entry.configuration.backAlpha?.doubleValue {
                Color.gray.opacity(opacity)
            }
            switch entry.configuration.mode {
            case .time:
                TimeWatch(compact: true, chineseCalendar: entry.chineseCalendar)
            default:
                DateWatch(compact: true, chineseCalendar: entry.chineseCalendar)
            }
        }
    }
}

struct MediumWidgetEntryView: View {
    var entry: MediumProvider.Entry

    init(entry: MediumEntry) {
        self.entry = entry
    }

    var body: some View {
        ZStack {
            if let opacity = entry.configuration.backAlpha?.doubleValue {
                Color.gray.opacity(opacity)
            }
            switch entry.configuration.order {
            case .dateRight:
                HStack(spacing: 15) {
                    TimeWatch(compact: true, chineseCalendar: entry.chineseCalendar)
                    DateWatch(compact: true, chineseCalendar: entry.chineseCalendar)
                }
                .padding(.horizontal, 5)
            default:
                HStack(spacing: 15) {
                    DateWatch(compact: true, chineseCalendar: entry.chineseCalendar)
                    TimeWatch(compact: true, chineseCalendar: entry.chineseCalendar)
                }
                .padding(.horizontal, 5)
            }
        }
    }
}

struct LargeWidgetEntryView: View {
    var entry: LargeProvider.Entry

    init(entry: LargeEntry) {
        self.entry = entry
    }

    var body: some View {
        ZStack {
            if let opacity = entry.configuration.backAlpha?.doubleValue {
                Color.gray.opacity(opacity)
            }
            Watch(compact: false, chineseCalendar: entry.chineseCalendar)
        }
    }
}

struct SmallWidget: Widget {
    let kind: String = "Small"

    init() {
        DataContainer.shared.loadSave()
        LocationManager.shared.manager.requestWhenInUseAuthorization()
    }

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: SmallIntent.self, provider: SmallProvider()) { entry in
            SmallWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Compact")
        .description("Compact watch face to display either Date or Time.")
        .supportedFamilies([.systemSmall])
    }
}

struct MediumWidget: Widget {
    let kind: String = "Medium"

    init() {
        DataContainer.shared.loadSave()
        LocationManager.shared.manager.requestWhenInUseAuthorization()
    }

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: MediumIntent.self, provider: MediumProvider()) { entry in
            MediumWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Dual")
        .description("Display both Date and Time as separate watches, whose order is at your choice.")
        .supportedFamilies([.systemMedium])
    }
}

struct LargeWidget: Widget {
    let kind: String = "Large"

    init() {
        DataContainer.shared.loadSave()
        LocationManager.shared.manager.requestWhenInUseAuthorization()
    }

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: LargeIntent.self, provider: LargeProvider()) { entry in
            LargeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Full")
        .description("Display full information with both Date and Time.")
        .supportedFamilies([.systemLarge])
    }
}

struct Widget_Previews: PreviewProvider {
    static var previews: some View {
        let chineseCalendar = ChineseCalendar(time: Date(), timezone: Calendar.current.timeZone, location: LocationManager.shared.location ?? WatchLayout.shared.location, compact: true)
        SmallWidgetEntryView(entry: SmallEntry(date: Date(), configuration: SmallIntent(), chineseCalendar: chineseCalendar))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

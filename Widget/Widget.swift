//
//  Widget.swift
//  iOSWidgetExtension
//
//  Created by Leo Liu on 5/9/23.
//

import WidgetKit
import SwiftUI
import Intents

struct SmallProvider: IntentTimelineProvider {
    func placeholder(in context: Context) -> SmallEntry {
        SmallEntry(date: Date(), configuration: SmallIntent(), watchLayout: WatchLayout.shared)
    }

    func getSnapshot(for configuration: SmallIntent, in context: Context, completion: @escaping (SmallEntry) -> ()) {
        let entry = SmallEntry(date: Date(), configuration: configuration, watchLayout: WatchLayout.shared)
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
            for offset in 0 ..< count {
                let entryDate = currentDate + Double(offset * 432) // 7.2min
                let entry = SmallEntry(date: entryDate, configuration: configuration, watchLayout: WatchLayout.shared)
                entries.append(entry)
            }
        default:
#if os(macOS)
            let count = 24
#else
            let count = 15
#endif
            for offset in 0 ..< count {
                let entryDate = Calendar.current.date(byAdding: .hour, value: offset, to: currentDate)!
                let entry = SmallEntry(date: entryDate, configuration: configuration, watchLayout: WatchLayout.shared)
                entries.append(entry)
            }
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct MediumProvider: IntentTimelineProvider {
    func placeholder(in context: Context) -> MediumEntry {
        MediumEntry(date: Date(), configuration: MediumIntent(), watchLayout: WatchLayout.shared)
    }

    func getSnapshot(for configuration: MediumIntent, in context: Context, completion: @escaping (MediumEntry) -> ()) {
        let entry = MediumEntry(date: Date(), configuration: configuration, watchLayout: WatchLayout.shared)
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
        for offset in 0 ..< count {
            let entryDate = currentDate + Double(offset * 432) // 7.2min
            let entry = MediumEntry(date: entryDate, configuration: configuration, watchLayout: WatchLayout.shared)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct LargeProvider: TimelineProvider {
    func placeholder(in context: Context) -> LargeEntry {
        LargeEntry(date: Date(), watchLayout: WatchLayout.shared)
    }

    func getSnapshot(in context: Context, completion: @escaping (LargeEntry) -> ()) {
        let entry = LargeEntry(date: Date(), watchLayout: WatchLayout.shared)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
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
        for offset in 0 ..< count {
            let entryDate = currentDate + Double(offset * 432) // 7.2min
            let entry = LargeEntry(date: entryDate, watchLayout: WatchLayout.shared)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SmallEntry: TimelineEntry {
    let date: Date
    let configuration: SmallIntent
    let watchLayout: WatchLayout
}

struct MediumEntry: TimelineEntry {
    let date: Date
    let configuration: MediumIntent
    let watchLayout: WatchLayout
}

struct LargeEntry: TimelineEntry {
    let date: Date
    let watchLayout: WatchLayout
}

struct SmallWidgetEntryView : View {
    var entry: SmallProvider.Entry
    
    init(entry: SmallEntry) {
        self.entry = entry
    }

    var body: some View {
        ZStack {
            Color.gray.opacity(0.2)
            switch entry.configuration.mode {
            case .time:
                TimeWatch(compact: true, displayTime: entry.date)
            default:
                DateWatch(compact: true, displayTime: entry.date)
            }
        }
    }
}

struct MediumWidgetEntryView : View {
    var entry: MediumProvider.Entry
    
    init(entry: MediumEntry) {
        self.entry = entry
    }

    var body: some View {
        ZStack {
            Color.gray.opacity(0.2)
            switch entry.configuration.order {
            case .dateRight:
                HStack(spacing: 15) {
                    TimeWatch(compact: true, displayTime: entry.date)
                    DateWatch(compact: true, displayTime: entry.date)
                }
                .padding(.horizontal, 5)
            default:
                HStack(spacing: 15) {
                    DateWatch(compact: true, displayTime: entry.date)
                    TimeWatch(compact: true, displayTime: entry.date)
                }
                .padding(.horizontal, 5)
            }
        }
    }
}

struct LargeWidgetEntryView : View {
    var entry: LargeProvider.Entry
    
    init(entry: LargeEntry) {
        self.entry = entry
    }

    var body: some View {
        ZStack {
            Color.gray.opacity(0.2)
            Watch(compact: false, displayTime: entry.date)
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
        StaticConfiguration(kind: kind, provider: LargeProvider()) { entry in
            LargeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Full")
        .description("Display full information with both Date and Time.")
        .supportedFamilies([.systemLarge])
    }
}

struct MacWidget_Previews: PreviewProvider {

    static var previews: some View {
        SmallWidgetEntryView(entry: SmallEntry(date: Date(), configuration: SmallIntent(), watchLayout: WatchLayout.shared))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

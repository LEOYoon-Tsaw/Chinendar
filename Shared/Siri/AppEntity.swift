//
//  AppEntity.swift
//  Chinendar
//
//  Created by Leo Liu on 8/6/24.
//

import AppIntents
import GeoToolbox
import SwiftData

struct OpenApp: AppIntent {
    static let title = LocalizedStringResource("LAUNCH_CHINENDAR")
    static let description = IntentDescription("LAUNCH_CHINENDAR_MSG")
    static let openAppWhenRun = true

    @Parameter(title: "SELECT_CALENDAR")
    var calendarConfig: ConfigIntent?

    static var parameterSummary: some ParameterSummary {
        Summary("LAUNCH_CHINENDAR") {
            \.$calendarConfig
        }
    }

    func perform() async throws -> some IntentResult {
        if let calendarConfig {
            try await LocalDataModel.shared.updateConfig(config: calendarConfig.config)
        }
        return .result()
    }
}

#if os(iOS) || os(macOS) || os(watchOS)
extension OpenApp: ControlConfigurationIntent {}
#endif

struct ConfigIntent: AppEntity {
    let id: String
    let name: String
    let config: CalendarConfigure

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "SELECT_CALENDAR"
    static let defaultQuery = ConfigQuery()

    var displayRepresentation: DisplayRepresentation {
        if name != AppInfo.defaultName {
            DisplayRepresentation(title: "\(name)")
        } else {
            DisplayRepresentation("DEFAULT_NAME")
        }
    }

    struct ConfigQuery: EntityQuery {
        func entities(for identifiers: [String]) async throws -> [ConfigIntent] {
            var results = try await DataModel.shared.getAllConfigIntent(ids: identifiers)
            let localConfig = await LocalDataModel.shared.getLocalConfigIntent()
            if identifiers.contains(localConfig.id) {
                results.append(localConfig)
            }
            return results
        }

        func suggestedEntities() async throws -> [ConfigIntent] {
            let sharedConfigs = try await DataModel.shared.getAllConfigIntent()
            let localConfig = await LocalDataModel.shared.getLocalConfigIntent()
            return [localConfig] + sharedConfigs
        }
    }
}

enum NextEventType: String, AppEnum {
    case solarTerms, lunarPhases, sunriseSet, moonriseSet, chineseHoliday

    static let typeDisplayRepresentation: TypeDisplayRepresentation = .init(name: "EVENT_TYPE")
    static let caseDisplayRepresentations: [NextEventType: DisplayRepresentation] = [
        .solarTerms: .init(title: "ET_ST"),
        .lunarPhases: .init(title: "ET_MP"),
        .chineseHoliday: .init(title: "ET_HOLIDAY"),
        .sunriseSet: .init(title: "SUNRISE_SET"),
        .moonriseSet: .init(title: "MOONRISE_SET")
    ]
}

#if os(iOS) || os(macOS) || os(visionOS)
@AppEntity(schema: .calendar.calendar)
struct ChinendarCalendarEntity {
    static let defaultQuery = CalendarQuery()

    var id: String
    var title: String

    init(id: String, title: String) {
        self.id = id
        self.title = title
    }

    static let chinendar = ChinendarCalendarEntity(id: "chinendar", title: String(localized: "REMINDERS_LIST"))

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }

    struct CalendarQuery: EntityQuery {
        func entities(for identifiers: [String]) async throws -> [ChinendarCalendarEntity] {
            identifiers.contains(ChinendarCalendarEntity.chinendar.id) ? [.chinendar] : []
        }

        func suggestedEntities() async throws -> [ChinendarCalendarEntity] {
            [.chinendar]
        }
    }
}

@AppEnum(schema: .calendar.attendeeStatus)
enum ParticipantStatus: String {
    case accepted, declined, tentative

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .accepted: "CALENDAR_ACCEPTED",
        .declined: "CALENDAR_DECLINED",
        .tentative: "CALENDAR_TENTATIVE"
    ]
}

@AppEnum(schema: .calendar.attendeeType)
enum AttendeeType: String {
    case required, optional

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .required: "CALENDAR_REQUIRED",
        .optional: "CALENDAR_OPTIONAL"
    ]
}

@AppEntity(schema: .calendar.attendee)
struct AttendeeEntity {
    static let defaultQuery = AttendeeQuery()

    var id: String
    var person: IntentPerson
    var status: ParticipantStatus?
    var isAttendanceOptional: Bool
    var type: AttendeeType?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "CALENDAR_ATTENDEE")
    }

    struct AttendeeQuery: EntityQuery {
        func entities(for identifiers: [String]) async throws -> [AttendeeEntity] {
            []
        }
    }
}

@UnionValue
enum EventLocationCases {
    case place(PlaceDescriptor)
    case name(String)
}

@UnionValue
enum EventAlarmCases {
    case offset(Duration)
    case date(Date)
}

@AppEnum(schema: .calendar.eventStatus)
enum CalendarEventStatus: String {
    case confirmed, tentative, cancelled

    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .confirmed: "CALENDAR_CONFIRMED",
        .tentative: "CALENDAR_TENTATIVE",
        .cancelled: "CALENDAR_CANCELLED"
    ]
}

@AppEntity(schema: .calendar.event)
struct CalendarEvent {
    static let defaultQuery = EventQuery()

    var id: String
    var calendar: ChinendarCalendarEntity
    var title: String
    var startDate: Date
    var endDate: Date
    var isAllDay: Bool
    var recurrence: Calendar.RecurrenceRule?
    var note: AttributedString?
    var travelTime: Duration?
    var location: EventLocationCases?
    var virtualLocation: URL?
    var status: CalendarEventStatus?
    var alarms: [EventAlarmCases]
    var organizers: [IntentPerson]
    var attendees: [AttendeeEntity]

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)", subtitle: "\(startDate.formatted(date: .abbreviated, time: .shortened))")
    }

    init(id: String, title: String, reminderDate: Date, eventDate: Date, calendar: ChinendarCalendarEntity = .chinendar) {
        self.id = id
        self.calendar = calendar
        self.title = title
        self.startDate = eventDate
        self.endDate = eventDate
        self.isAllDay = false
        self.recurrence = nil
        self.note = nil
        self.travelTime = nil
        self.location = nil
        self.virtualLocation = nil
        self.status = .tentative
        self.alarms = [.date(reminderDate)]
        self.organizers = []
        self.attendees = []
    }

    struct EventQuery: EntityStringQuery {
        func entities(for identifiers: [String]) async throws -> [CalendarEvent] {
            let identifierSet = Set(identifiers)
            return try await suggestedEntities().filter { identifierSet.contains($0.id) }
        }

        func entities(matching string: String) async throws -> [CalendarEvent] {
            let events = try await suggestedEntities()
            guard !string.isEmpty else { return events }
            return events.filter { $0.title.localizedCaseInsensitiveContains(string) }
        }

        func suggestedEntities() async throws -> [CalendarEvent] {
            let remindersList = try await DataModel.shared.getReminders()
            let config = await LocalDataModel.shared.getLocalConfig()
            let chineseCalendar = await AsyncLocalModels(compact: false, config: config).chineseCalendar

            return remindersList.flatMap { list -> [CalendarEvent] in
                guard list.enabled else { return [] }
                return list.reminders.compactMap { reminder in
                    guard reminder.enabled, let eventDate = reminder.nextEvent(in: chineseCalendar), let reminderDate = reminder.nextReminder(in: chineseCalendar) else { return nil }
                    return CalendarEvent(id: reminder.id.uuidString, title: reminder.name, reminderDate: reminderDate, eventDate: eventDate)
                }
            }
            .sorted { $0.endDate < $1.endDate }
        }
    }
}
#endif

private func find(in dates: [ChineseCalendar.NamedDate], at date: Date) -> (ChineseCalendar.NamedDate?, ChineseCalendar.NamedDate?) {
    if dates.count > 1 {
        let dates = dates.sorted { $0.date < $1.date }
        let atDate = ChineseCalendar.NamedDate(name: "", date: date)
        let index = dates.insertionIndex(of: atDate, comparison: { $0.date < $1.date })
        if index > 0 && index < dates.count {
            let previous = dates[index - 1]
            let next = dates[index]
            if Date.now.distance(to: date) < 30 || previous.date.distance(to: date) < date.distance(to: next.date) {
                return (previous: previous, next: next)
            } else {
                return (previous: next, next: index+1 < dates.count ? dates[index + 1] : nil)
            }
        } else if index < dates.count {
            return (previous: nil, next: dates[index])
        } else {
            return (previous: dates[index - 1], next: nil)
        }
    } else {
        return (previous: nil, next: nil)
    }
}

func next(_ eventType: NextEventType, in chineseCalendar: ChineseCalendar) -> (prev: ChineseCalendar.NamedDate?, next: ChineseCalendar.NamedDate?) {
    var prev: ChineseCalendar.NamedDate?
    var next: ChineseCalendar.NamedDate?
    switch eventType {
    case .lunarPhases:
        (prev, next) = find(in: chineseCalendar.moonPhases, at: chineseCalendar.time)

    case .solarTerms:
        (prev, next) = find(in: chineseCalendar.solarTerms, at: chineseCalendar.time)

    case .chineseHoliday:
        var previousYearCalendar = chineseCalendar
        previousYearCalendar.update(time: chineseCalendar.solarTerms[0].date - 1)
        var nextYearCalendar = chineseCalendar
        nextYearCalendar.update(time: chineseCalendar.solarTerms[24].date + 1)
        (prev, next) = find(in: [previousYearCalendar.lunarHolidays.last!] + chineseCalendar.lunarHolidays + [nextYearCalendar.lunarHolidays.first!], at: chineseCalendar.time)

    case .moonriseSet:
        var chineseCalendar = chineseCalendar
        let currentTimes = chineseCalendar.getMoonTimes(for: .current)
        let previousTimes = chineseCalendar.getMoonTimes(for: .previous)
        let nextTimes = chineseCalendar.getMoonTimes(for: .next)
        let moonriseAndSet = [previousTimes.moonrise, previousTimes.moonset, currentTimes.moonrise, currentTimes.moonset, nextTimes.moonrise, nextTimes.moonset].compactMap { $0 }
        (prev, next) = find(in: moonriseAndSet, at: chineseCalendar.time)

    case .sunriseSet:
        var chineseCalendar = chineseCalendar
        let currentTimes = chineseCalendar.getSunTimes(for: .current)
        let previousTimes = chineseCalendar.getSunTimes(for: .previous)
        let nextTimes = chineseCalendar.getSunTimes(for: .next)
        let sunriseAndSet = [previousTimes.sunrise, previousTimes.sunset, currentTimes.sunrise, currentTimes.sunset, nextTimes.sunrise, nextTimes.sunset].compactMap { $0 }
        (prev, next) = find(in: sunriseAndSet, at: chineseCalendar.time)
    }

    return (prev: prev, next: next)
}

struct AsyncLocalModels {
    let chineseCalendar: ChineseCalendar
    let config: CalendarConfigure
    let layout: WatchLayout

    init(compact: Bool = true, config: CalendarConfigure? = nil) async {
        layout = await LocalDataModel.shared.getLocalTheme()
        if let config {
            self.config = config
        } else {
            self.config = await LocalDataModel.shared.getLocalConfig()
        }

        let location = await self.config.location(maxWait: .seconds(2))
        chineseCalendar = ChineseCalendar(timezone: self.config.effectiveTimezone, location: location, compact: compact, globalMonth: self.config.globalMonth, apparentTime: self.config.apparentTime, largeHour: self.config.largeHour)
    }
}

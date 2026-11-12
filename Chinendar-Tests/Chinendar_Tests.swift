//
//  Chinendar_Tests.swift
//  Chinendar-Tests
//
//  Created by Leo Liu on 9/26/24.
//

import Testing
import Foundation

extension Date {
    static func from(year: Int, month: Int, day: Int, hour: Int, minute: Int, timezone: TimeZone?) -> Date? {
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = hour
        dateComponents.minute = minute
        if let timezone {
            dateComponents.timeZone = timezone
        }
        return Calendar(identifier: .iso8601).date(from: dateComponents)
    }

    static func from(year: Int, month: Int, day: Int, hour: Int=0, minute: Int=0) -> Date {
        Date.from(year: year, month: month, day: day, hour: hour, minute: minute, timezone: TimeZone(identifier: "America/New_York")!)!
    }
}

struct Chinendar_Tests {
    let timeZone = TimeZone(identifier: "America/New_York")!
    let location = GeoLocation(lat: 40, lon: -74)

    @Test("Calendar updates preserve an omitted timezone across year boundaries", arguments: [
        (Date.from(year: 2024, month: 10, day: 9), Date.from(year: 2024, month: 10, day: 10)),
        (Date.from(year: 2024, month: 12, day: 20), Date.from(year: 2024, month: 12, day: 23)),
        (Date.from(year: 2024, month: 12, day: 31), Date.from(year: 2025, month: 1, day: 1))
    ])
    func updateWithoutTimezone(start: Date, target: Date) {
        var updated = ChineseCalendar(time: start, timezone: timeZone, location: location, globalMonth: true, apparentTime: false, largeHour: true)
        updated.update(time: target)
        let expected = ChineseCalendar(time: target, timezone: timeZone, location: location, globalMonth: true, apparentTime: false, largeHour: true)
        #expect(updated == expected)
    }

    @Test("Calendar updates apply an explicitly changed timezone")
    func updateWithTimezoneChange() {
        let time = Date.from(year: 2024, month: 10, day: 9, hour: 18, minute: 30)
        let targetZone = TimeZone(identifier: "Asia/Shanghai")!
        var updated = ChineseCalendar(time: time, timezone: timeZone, location: location, globalMonth: true, apparentTime: false, largeHour: true)
        updated.update(time: time, timezone: targetZone)
        let expected = ChineseCalendar(time: time, timezone: targetZone, location: location, globalMonth: true, apparentTime: false, largeHour: true)
        #expect(updated == expected)
    }

    @Test("Apparent time derives its timezone from longitude", arguments: [-180.0, -74, 0, 108.94, 180])
    func apparentTimezone(longitude: Double) {
        let selectedZone = TimeZone(identifier: "Asia/Shanghai")!
        let location = GeoLocation(lat: 40, lon: longitude)
        let dates = [
            Date.from(year: 2026, month: 2, day: 17, hour: 12, minute: 1, timezone: .gmt)!,
            Date.from(year: 2026, month: 3, day: 8, hour: 7, minute: 0, timezone: .gmt)!,
            Date.from(year: 2026, month: 11, day: 1, hour: 6, minute: 0, timezone: .gmt)!
        ]
        for date in dates {
            var calendar = ChineseCalendar(time: date, timezone: selectedZone, location: location, globalMonth: true, apparentTime: true, largeHour: true)
            #expect(calendar.calendar.timeZone.secondsFromGMT(for: date) == Int((longitude * 240).rounded()))
            #expect(!calendar.calendar.timeZone.isDaylightSavingTime(for: date))
            #expect(calendar.startOfDay <= date && date < calendar.startOfNextDay)
            #expect(calendar.startOfLargeHour <= date && date < calendar.endOfLargeHour)
            calendar.update(time: date + 86400)
            let expected = ChineseCalendar(time: date + 86400, timezone: selectedZone, location: location, globalMonth: true, apparentTime: true, largeHour: true)
            #expect(calendar == expected)
        }
    }

    @Test("Apparent-time lunar date search tolerates a mismatched civil timezone")
    func apparentDateSearch() throws {
        let date = Date.from(year: 2026, month: 10, day: 21, hour: 16, minute: 0, timezone: .gmt)!
        var calendar = ChineseCalendar(time: date, timezone: TimeZone(identifier: "Asia/Shanghai")!, location: location, globalMonth: true, apparentTime: true, largeHour: true)
        let dateTime = ChineseCalendar.ChineseDateTime(date: .init(month: 1, day: 1), time: .init(largeHour: 4, quarter: 2))
        let next = try #require(calendar.findNext(chineseDateTime: dateTime))
        #expect(next > date)
        calendar.update(time: next)
        #expect(calendar.chineseDate == dateTime.date)
        #expect(calendar.startOfLargeHour <= next && next < calendar.endOfLargeHour)
    }

    @Test("Apparent days bracket early and late solar midnight", arguments: [
        (-180.0, -43200), (-74.0, -17760), (0.0, 0), (108.94, 26146), (180.0, 43200)
    ])
    func apparentDayBoundaries(longitude: Double, gmtOffset: Int) {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(secondsFromGMT: gmtOffset)!
        let location = GeoLocation(lat: 40, lon: longitude)
        for month in [2, 5, 8, 11] {
            let noon = calendar.date(from: DateComponents(year: 2026, month: month, day: 15, hour: 12))!
            // Noon identifies each solar day without depending on midnight selection at its boundary.
            let starts = (-1...2).map { offset in
                let day = calendar.date(byAdding: .day, value: offset, to: noon)!
                return calendar.startOfDay(for: day, apparent: true, location: location)
            }
            let start = starts[1]
            let next = starts[2]
            let before = Date(timeIntervalSinceReferenceDate: start.timeIntervalSinceReferenceDate.nextDown)
            let after = Date(timeIntervalSinceReferenceDate: start.timeIntervalSinceReferenceDate.nextUp)
            for input in [start - 1, before, start, after, start + 1,
                          start + 23 * 3600 - 1, start + 23 * 3600, start + 23.5 * 3600,
                          next - 1, next, next + 1] {
                let expected = starts.last(where: { $0 <= input })!
                let upper = starts.first(where: { $0 > expected })!
                let actual = calendar.startOfDay(for: input, apparent: true, location: location)
                #expect(actual == expected)
                #expect(actual <= input && input < upper)
                #expect(calendar.startOfDay(for: actual, apparent: true, location: location) == actual)
                #expect(calendar.startOfDay(for: actual + 129600, apparent: true, location: location) == upper)
            }
            #expect(calendar.startOfDay(for: next, apparent: true, location: location) == next)
            #expect(calendar.startOfDay(for: noon, apparent: false, location: location) == calendar.startOfDay(for: noon))
            #expect(calendar.startOfDay(for: noon, apparent: true, location: nil) == calendar.startOfDay(for: noon))
        }
    }

    @Test("Apparent midnight initializes and updates both hour modes", arguments: [false, true])
    func apparentMidnightUpdate(largeHour: Bool) {
        let date = Date.from(year: 2026, month: 11, day: 24, hour: 4, minute: 43, timezone: .gmt)!
        let baseline = Date.from(year: 2026, month: 11, day: 22, hour: 7, minute: 23, timezone: .gmt)!
        let expected = ChineseCalendar(time: date, timezone: timeZone, location: location, globalMonth: true, apparentTime: true, largeHour: largeHour)
        var updated = ChineseCalendar(time: baseline, timezone: timeZone, location: location, globalMonth: true, apparentTime: true, largeHour: largeHour)
        updated.update(time: date)
        #expect(updated == expected)
        #expect(expected.startOfDay <= date && date < expected.startOfNextDay)
        #expect(expected.startOfLargeHour <= date && date < expected.endOfLargeHour)
    }

    @Test("Apparent day traversal preserves calendar and hour boundaries", arguments: [false, true])
    func apparentDayTraversal(largeHour: Bool) {
        for direction in [1, -1] {
            let baseline = Date.from(year: 2026, month: 11, day: direction > 0 ? 22 : 24, hour: 12, minute: 0, timezone: .gmt)!
            var calendar = ChineseCalendar(time: baseline, timezone: timeZone, location: location, globalMonth: true, apparentTime: true, largeHour: largeHour)
            for _ in 0..<2 {
                let date = direction > 0 ? calendar.startOfNextDay + 1 : calendar.startOfDay - 1
                calendar.update(time: date)
                let expected = ChineseCalendar(time: date, timezone: timeZone, location: location, globalMonth: true, apparentTime: true, largeHour: largeHour)
                #expect(calendar == expected)
                #expect(calendar.startOfDay <= date && date < calendar.startOfNextDay)
                #expect(calendar.startOfLargeHour <= date && date < calendar.endOfLargeHour)
            }
        }
    }

    @Test("Find date, Month 11 before winter solstice", arguments: [
        (ChineseCalendar.ChineseDate(month: 11, day: 20), Date.from(year: 2024, month: 12, day: 20)),
        (ChineseCalendar.ChineseDate(month: 11, day: 21), Date.from(year: 2024, month: 12, day: 21)),
        (ChineseCalendar.ChineseDate(month: 11, day: 22), Date.from(year: 2024, month: 12, day: 22))

    ])
    func find_1(chineseDate: ChineseCalendar.ChineseDate, targetDate: Date) async throws {
        let testDate = Date.from(year: 2024, month: 12, day: 20, hour: 0, minute: 0, timezone: timeZone)!
        let chineseCalendar = ChineseCalendar(time: testDate, timezone: timeZone, location: location, globalMonth: true, apparentTime: false, largeHour: true)
        let start = chineseCalendar.find(chineseDate: chineseDate)?.time ?? .distantPast
        let calendar = chineseCalendar.calendar
        #expect(calendar.isDate(start, equalTo: targetDate, toGranularity: .day))
    }

    @Test("Find date, Month 11 after winter solstice", arguments: [
        (ChineseCalendar.ChineseDate(month: 11, day: 20), Date.from(year: 2024, month: 12, day: 20)),
        (ChineseCalendar.ChineseDate(month: 11, day: 21), Date.from(year: 2024, month: 12, day: 21)),
        (ChineseCalendar.ChineseDate(month: 11, day: 22), Date.from(year: 2024, month: 12, day: 22))

    ])
    func find_2(chineseDate: ChineseCalendar.ChineseDate, targetDate: Date) async throws {
        let testDate = Date.from(year: 2024, month: 12, day: 22, hour: 0, minute: 0, timezone: timeZone)!
        let chineseCalendar = ChineseCalendar(time: testDate, timezone: timeZone, location: location, globalMonth: true, apparentTime: false, largeHour: true)
        let start = chineseCalendar.find(chineseDate: chineseDate)?.time ?? .distantPast
        let calendar = chineseCalendar.calendar
        #expect(calendar.isDate(start, equalTo: targetDate, toGranularity: .day))
    }

    @Test("Previous year in Chinendar", arguments: [
        (Date.from(year: 2024, month: 12, day: 20), Date.from(year: 2023, month: 12, day: 31)),
        (Date.from(year: 2024, month: 12, day: 21), Date.from(year: 2024, month: 1, day: 1)),
        (Date.from(year: 2024, month: 2, day: 9), Date.from(year: 2023, month: 1, day: 21))

    ])
    func prevYear(testDate: Date, targetDate: Date) async throws {
        let chineseCalendar = ChineseCalendar(time: testDate, timezone: timeZone, location: location, globalMonth: true, apparentTime: false, largeHour: true)
        let start = chineseCalendar.previousYear() ?? .distantPast
        let calendar = chineseCalendar.calendar
        #expect(calendar.isDate(start, equalTo: targetDate, toGranularity: .day))
    }

    @Test("Next year in Chinendar", arguments: [
        (Date.from(year: 2023, month: 12, day: 31), Date.from(year: 2024, month: 12, day: 20)),
        (Date.from(year: 2024, month: 1, day: 1), Date.from(year: 2024, month: 12, day: 21)),
        (Date.from(year: 2023, month: 1, day: 21), Date.from(year: 2024, month: 2, day: 9))

    ])
    func nextYear(testDate: Date, targetDate: Date) async throws {
        let chineseCalendar = ChineseCalendar(time: testDate, timezone: timeZone, location: location, globalMonth: true, apparentTime: false, largeHour: true)
        let start = chineseCalendar.nextYear() ?? .distantPast
        let calendar = chineseCalendar.calendar
        #expect(calendar.isDate(start, equalTo: targetDate, toGranularity: .day))
    }

    @Test("Previous month in Chinendar", arguments: [
        (Date.from(year: 2024, month: 12, day: 20), Date.from(year: 2024, month: 11, day: 20)),
        (Date.from(year: 2024, month: 12, day: 21), Date.from(year: 2024, month: 11, day: 21)),
        (Date.from(year: 2024, month: 2, day: 9), Date.from(year: 2024, month: 1, day: 11)),
        (Date.from(year: 2024, month: 1, day: 11), Date.from(year: 2023, month: 12, day: 12))

    ])
    func prevMonth(testDate: Date, targetDate: Date) async throws {
        let chineseCalendar = ChineseCalendar(time: testDate, timezone: timeZone, location: location, globalMonth: true, apparentTime: false, largeHour: true)
        let start = chineseCalendar.previousMonth() ?? .distantPast
        let calendar = chineseCalendar.calendar
        #expect(calendar.isDate(start, equalTo: targetDate, toGranularity: .day))
    }

    @Test("Next month in Chinendar", arguments: [
        (Date.from(year: 2024, month: 11, day: 20), Date.from(year: 2024, month: 12, day: 20)),
        (Date.from(year: 2024, month: 11, day: 21), Date.from(year: 2024, month: 12, day: 21)),
        (Date.from(year: 2024, month: 1, day: 11), Date.from(year: 2024, month: 2, day: 9)),
        (Date.from(year: 2023, month: 12, day: 12), Date.from(year: 2024, month: 1, day: 11))

    ])
    func nextMonth(testDate: Date, targetDate: Date) async throws {
        let chineseCalendar = ChineseCalendar(time: testDate, timezone: timeZone, location: location, globalMonth: true, apparentTime: false, largeHour: true)
        let start = chineseCalendar.nextMonth() ?? .distantPast
        let calendar = chineseCalendar.calendar
        #expect(calendar.isDate(start, equalTo: targetDate, toGranularity: .day))
    }

    @Test("Date conversion", arguments: [
        (TimeZone(identifier: "America/New_York")!, GeoLocation(lat: 40, lon: -74), false, "九月八日巳時七刻四"),
        (TimeZone(identifier: "Asia/Seoul")!, GeoLocation(lat: 40, lon: 135), false, "九月八日子時二刻五"),
        (TimeZone(identifier: "Asia/Shanghai")!, GeoLocation(lat: 40, lon: 116), false, "九月七日亥時七刻四"),
        (TimeZone(identifier: "Asia/Shanghai")!, GeoLocation(lat: 34.52, lon: 108.94), true, "九月七日亥時五刻三")
    ])
    func dateString(timezone: TimeZone, location: GeoLocation, apparentTime: Bool, targetString: String) async throws {
        let testDate = Date.from(year: 2024, month: 10, day: 9, hour: 11, minute: 43, timezone: timeZone)!
        let chineseCalendar = ChineseCalendar(time: testDate, timezone: timezone, location: location, globalMonth: true, apparentTime: apparentTime, largeHour: true)
        #expect("\(chineseCalendar.dateString)\(chineseCalendar.timeString)" == targetString)
    }

    @Test("Find date, Month 11 before winter solstice", arguments: [
        (ChineseCalendar.ChineseDate(month: 8, day: 15), Date.from(year: 2025, month: 10, day: 5)),
        (ChineseCalendar.ChineseDate(month: 12, day: 8), Date.from(year: 2026, month: 1, day: 25)),
        (ChineseCalendar.ChineseDate(month: 12, day: 30), Date.from(year: 2026, month: 2, day: 16)),
        (ChineseCalendar.ChineseDate(month: 1, day: 1), Date.from(year: 2026, month: 2, day: 17))

    ])
    func find_next(chineseDate: ChineseCalendar.ChineseDate, targetDate: Date) async throws {
        let testDate = Date.from(year: 2025, month: 1, day: 29, hour: 0, minute: 0, timezone: timeZone)!
        let chineseCalendar = ChineseCalendar(time: testDate, timezone: timeZone, location: location, globalMonth: true, apparentTime: false, largeHour: true)
        let chineseDateTime = ChineseCalendar.ChineseDateTime(date: chineseDate, time: .init())
        let start = chineseCalendar.findNext(chineseDateTime: chineseDateTime) ?? .distantPast
        let calendar = chineseCalendar.calendar
        #expect(calendar.isDate(start, equalTo: targetDate, toGranularity: .day))
    }

}

//
//  Chinendar_Tests.swift
//  Chinendar-Tests
//
//  Created by Leo Liu on 9/26/24.
//

import Testing
import Foundation

extension Date {
    static func from(year: Int, month: Int, day: Int, hour: Int=0, minute: Int=0) -> Date {
        Date.from(year: year, month: month, day: day, hour: hour, minute: minute, timezone: TimeZone(identifier: "America/New_York")!)!
    }
}

struct Chinendar_Tests {
    let timeZone = TimeZone(identifier: "America/New_York")!
    let location = GeoLocation(lat: 40, lon: -74)

    @Test("Find date, Month 11 before winter solstice", arguments: [
        (ChineseCalendar.ChineseDate(month: 11, day: 20), Date.from(year: 2024, month: 12, day: 20)),
        (ChineseCalendar.ChineseDate(month: 11, day: 21), Date.from(year: 2024, month: 12, day: 21)),
        (ChineseCalendar.ChineseDate(month: 11, day: 22), Date.from(year: 2024, month: 12, day: 22))

    ])
    func find_1(chineseDate: ChineseCalendar.ChineseDate, targetDate: Date) async throws {
        let testDate = Date.from(year: 2024, month: 12, day: 20, hour: 0, minute: 0, timezone: timeZone)!
        let chineseCalendar = ChineseCalendar(time: testDate, timezone: timeZone, location: location, globalMonth: true, apparentTime: false, largeHour: true)
        let start = chineseCalendar.find(chineseDate: chineseDate) ?? .distantPast
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
        let start = chineseCalendar.find(chineseDate: chineseDate) ?? .distantPast
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
}

//
//  Model.swift
//  Chinendar
//
//  Created by Leo Liu on 9/21/21.
//

import Foundation

extension Calendar {
    static let beijingTime = TimeZone(identifier: "Asia/Shanghai")!
    static let utcCalendar: Self = {
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = TimeZone(abbreviation: "UTC")!
        return cal
    }()

    func startOfDay(for day: Date, apparent: Bool, location: GeoLocation?) -> Date {
        let startToday = startOfDay(for: day)
        if let location, apparent {
            let apparentStart = dayStart(around: startToday, at: location)
            if apparentStart <= day {
                return apparentStart
            } else {
                return dayStart(around: self.date(byAdding: .day, value: -1, to: startToday)!, at: location)
            }
        } else {
            return startToday
        }
    }

    private func dayStart(around time: Date, at loc: GeoLocation, iteration: Int = 0) -> Date {
        let solarSystem = SolarSystem(time: time, loc: loc, targets: .sun)
        let planet = solarSystem.planets.sun
        let offset = Double.pi
        let timeUntilMidnight = SolarSystem.normalize(radian: planet.loc.ra - solarSystem.localSiderialTime! + offset)

        let dTime = timeUntilMidnight / Double.pi * 43082.04
        if abs(dTime) < 1 {
            return time
        } else {
            return dayStart(around: time + dTime, at: loc, iteration: iteration + 1)
        }
    }
}

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
}

// MARK: ChineseCalendar
struct ChineseCalendar: Sendable, Equatable {
    static let updateInterval: CGFloat = 14.4 // Seconds
    static let month_chinese = ["正月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "冬月", "臘月" ]
    static let month_chinese_localized: [LocalizedStringResource] = ["M1", "M2", "M3", "M4", "M5", "M6", "M7", "M8", "M9", "M10", "M11", "M12" ]
    static let month_chinese_compact = ["㋀", "㋁", "㋂", "㋃", "㋄", "㋅", "㋆", "㋇", "㋈", "㋉", "㋊", "㋋"]
    static let day_chinese = ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十", "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十", "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"]
    static let day_chinese_localized: [LocalizedStringResource] = ["D1", "D2", "D3", "D4", "D5", "D6", "D7", "D8", "D9", "D10", "D11", "D12", "D13", "D14", "D15", "D16", "D17", "D18", "D19", "D20", "D21", "D22", "D23", "D24", "D25", "D26", "D27", "D28", "D29", "D30"]
    static let day_chinese_compact = ["㏠", "㏡", "㏢", "㏣", "㏤", "㏥", "㏦", "㏧", "㏨", "㏩", "㏪", "㏫", "㏬", "㏭", "㏮", "㏯", "㏰", "㏱", "㏲", "㏳", "㏴", "㏵", "㏶", "㏷", "㏸", "㏹", "㏺", "㏻", "㏼", "㏽"]
    static let terrestrial_branches = ["子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥"]
    static let terrestrial_branches_localized: [LocalizedStringResource] = ["TB0", "TB1", "TB2", "TB3", "TB4", "TB5", "TB6", "TB7", "TB8", "TB9", "TB10", "TB11"]
    static let sub_hour_name = ["初", "正"]
    static let sub_hour_name_localized: [LocalizedStringResource] = ["H_prelude", "H_proper"]
    static let chinese_numbers = ["初", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十", "十一", "十二", "十三", "十四", "十五", "十六"]
    static let chinese_numbers_localized: [LocalizedStringResource] = ["N0", "N1", "N2", "N3", "N4", "N5", "N6", "N7", "N8", "N9", "N10", "N11", "N12", "N13", "N14", "N15", "N16"]
    static let evenSolarTermChinese = ["冬　至", "大　寒", "雨　水", "春　分", "穀　雨", "小　滿", "夏　至", "大　暑", "處　暑", "秋　分", "霜　降", "小　雪"]
    static let oddSolarTermChinese = ["小　寒", "立　春", "驚　蟄", "清　明", "立　夏", "芒　種", "小　暑", "立　秋", "白　露", "寒　露", "立　冬", "大　雪"]
    static let leapLabel = "閏"
    static let leapLabel_localized: LocalizedStringResource = "LEAP"
    static let alternativeMonthName = ["閏正月": "閏一月"]
    static let dayTimeName = (midnight: "夜中", sunrise: "日出", noon: "日中", sunset: "日入")
    static let moonTimeName = (moonrise: "月出", highMoon: "月中", moonset: "月入")
    static let moonPhases = (newmoon: "朔", fullmoon: "望")
    static let planetNames = (mercury: "辰星", venus: "太白", mars: "熒惑", jupiter: "歲星", saturn: "填星", moon: "太陰")
    static let holidays = [ChineseDate(month: 1, day: 1): "元旦", ChineseDate(month: 1, day: 15): "上元", ChineseDate(month: 2, day: 2): "春社",
                           ChineseDate(month: 3, day: 3): "上巳", ChineseDate(month: 5, day: 5): "端午", ChineseDate(month: 7, day: 7): "七夕",
                           ChineseDate(month: 7, day: 15): "中元", ChineseDate(month: 9, day: 9): "重陽", ChineseDate(month: 8, day: 15): "中秋",
                           ChineseDate(month: 10, day: 15): "下元", ChineseDate(month: 12, day: 8): "臘祭", ChineseDate(month: 12, day: 1, reverseCount: true): "除夕"]
    static let start: Date = {
        var components = DateComponents()
        components.year = 1901
        components.month = 12
        components.day = 23
        components.timeZone = TimeZone.gmt
        return Calendar.utcCalendar.date(from: components)!
    }()
    static let end: Date = {
        var components = DateComponents()
        components.year = 2999
        components.month = 12
        components.day = 20
        components.timeZone = TimeZone.gmt
        return Calendar.utcCalendar.date(from: components)!
    }()

    private let _compact: Bool
    private var _globalMonth: Bool = false
    private var _apparentTime: Bool = false
    private var _largeHour: Bool = false
    private var _time: Date = .distantPast
    private var _calendar: Calendar = .utcCalendar
    private var _location: GeoLocation?
    private var _year: Int = 0
    private var _numberOfMonths: Int = 0
    private var _year_length: Double = 0
    private var _solarTerms: [Date] = []
    private var _evenSolarTerms: [Date] = []
    private var _oddSolarTerms: [Date] = []
    private var _moonEclipses: [Date] = []
    private var _fullMoons: [Date] = []
    private var _month: Int = -1
    private var _precise_month: Int = -1
    private var _leap_month: Int = -1
    private var _day: Int = -1
    private var _planets: Planets<NamedPosition>!
    private var _sunTimes: [DateType: Solar<NamedDate?>] = [:]
    private var _moonTimes: [DateType: Lunar<NamedDate?>] = [:]
    private var _startHour: Date = .distantPast
    private var _endHour: Date = .distantFuture
    private var _hourNames: [NamedHour] = []
    private var _hourNamesInCurrentHour: [NamedHour] = []
    private var _subhours: [Date] = []
    private var _subhourMinors: [Date] = []
    private var _hour: Hour = Hour(hour: -1, format: .full)
    private var _quarter: SubHour = SubHour(majorTick: -1, minorTick: -1)

    init(time: Date = .now, timezone: TimeZone? = nil, location: GeoLocation? = nil, compact: Bool = false, globalMonth: Bool = false, apparentTime: Bool = false, largeHour: Bool = false) {
        let boundedTime: Date
        if time < ChineseCalendar.start {
            print("Time must be after \(ChineseCalendar.start).")
            boundedTime = ChineseCalendar.start
        } else if time > ChineseCalendar.end {
            print("Time must be before \(ChineseCalendar.end).")
            boundedTime = ChineseCalendar.end
        } else {
            boundedTime = time
        }
        self._compact = compact
        self._time = boundedTime
        var calendar = Calendar.current
        calendar.timeZone = timezone ?? calendar.timeZone
        self._calendar = calendar
        self._location = location
        self._globalMonth = globalMonth
        self._apparentTime = apparentTime
        self._largeHour = largeHour
        updateYear()
        updateDate()
        updateHour()
        updateSubHour()
        updatePlanets()
    }

    mutating func update(time: Date = .now, timezone: TimeZone? = nil, location: GeoLocation?? = Optional(nil), globalMonth: Bool? = nil, apparentTime: Bool? = nil, largeHour: Bool? = nil) {
        guard time >= ChineseCalendar.start && time <= ChineseCalendar.end else { return }
        let oldTimezone = _calendar.timeZone
        let oldLocation = _location
        let oldGlobalMonth = _globalMonth
        let oldApparentTime = _apparentTime
        _time = time
        _calendar.timeZone = timezone ?? _calendar.timeZone
        _location = location ?? _location
        _globalMonth = globalMonth ?? _globalMonth
        _apparentTime = apparentTime ?? _apparentTime
        _largeHour = largeHour ?? _largeHour

        if (_location == nil && oldLocation != nil) || (_location != nil && oldLocation == nil) {
            updateYear()
        } else if let newLocation = _location, let oldLocation = oldLocation,
                  sqrt(pow(newLocation.lat - oldLocation.lat, 2) + pow(newLocation.lon - oldLocation.lon, 2)) > 1 {
            updateYear()
        } else if timezone != oldTimezone || oldGlobalMonth != _globalMonth || oldApparentTime != _apparentTime {
            updateYear()
        } else {
            let year = _calendar.component(.year, from: time)
            if !(((year == _year) && (_solarTerms[24] > time)) || ((year == _year - 1) && (_solarTerms[0] <= time))) {
                updateYear()
            }
        }
        updateDate()
        updateHour()
        updateSubHour()
        updatePlanets()
    }
}

// MARK: Basic Properties
extension ChineseCalendar {
    var currentDayInYear: Double {
        _solarTerms[0].distance(to: _time) / _year_length
    }

    var currentDayInMonth: Double {
        if _globalMonth {
            let monthLength = _moonEclipses[_precise_month].distance(to: _moonEclipses[_precise_month + 1])
            return _moonEclipses[_precise_month].distance(to: _time) / monthLength
        } else {
            let monthStart = calendar.startOfDay(for: _moonEclipses[_month], apparent: apparentTime, location: location)
            let monthEnd = calendar.startOfDay(for: _moonEclipses[_month + 1], apparent: apparentTime, location: location)
            return monthStart.distance(to: _time) / monthStart.distance(to: monthEnd)
        }
    }

    var currentHourInDay: Double {
        startOfDay.distance(to: _time) / startOfDay.distance(to: startOfNextDay)
    }

    var subhourInHour: Double {
        startOfLargeHour.distance(to: _time) / startOfLargeHour.distance(to: endOfLargeHour)
    }

    var apparentTime: Bool {
        _apparentTime && _location != nil
    }
    var globalMonth: Bool {
        _globalMonth
    }
    var largeHour: Bool {
        _largeHour
    }

    var monthString: String {
        let month = (isLeapMonth ? Self.leapLabel : "") + Self.month_chinese[nominalMonth-1]
        return Self.alternativeMonthName[month] ?? month
    }
    var monthStringLocalized: LocalizedStringResource {
        if isLeapMonth {
            let month: LocalizedStringResource = "LEAP\(Self.leapLabel_localized)MONTH\(Self.month_chinese_localized[nominalMonth-1])"
            return month
        } else {
            return Self.month_chinese_localized[nominalMonth-1]
        }
    }

    var dayString: String {
        let chinese_day = Self.day_chinese[_day]
        if chinese_day.count > 1 {
            return chinese_day
        } else {
            return "\(chinese_day)日"
        }
    }
    var dayStringLocalized: LocalizedStringResource {
        "\(Self.day_chinese_localized[_day])DAY"
    }

    var dateString: String {
        "\(monthString)\(dayString)"
    }
    var dateStringLocalized: LocalizedStringResource {
        "MONTH\(monthStringLocalized)DAY\(dayStringLocalized)"
    }

    var timeString: String {
        let _hour_string = _hour.string
        let _quarter_string = _quarter.string
        if _hour_string.count < 2 && _hour_string.count + _quarter_string.count < 5 {
            return "\(_hour_string)時\(_quarter_string)"
        } else {
            return "\(_hour_string)\(_quarter_string)"
        }
    }
    var timeStringLocalized: LocalizedStringResource {
        "HOUR\(_hour.stringLocalized)QUARTER\(_quarter.stringLocalized)"
    }

    var hourString: String {
        let _hour_string = _hour.string
        if _hour_string.count < 2 {
            return "\(_hour_string)時"
        } else {
            return _hour_string
        }
    }
    var hourStringLocalized: LocalizedStringResource {
        _hour.stringLocalized
    }

    var quarterString: String {
        _quarter.string
    }
    var quarterStringLocalized: LocalizedStringResource {
        _quarter.stringLocalized
    }

    var shortQuarterString: String {
        _quarter.shortString
    }
    var shortQuarterStringLocalized: LocalizedStringResource {
        _quarter.shortStringLocalized
    }

    var calendar: Calendar {
        return _calendar
    }

    var evenSolarTerms: [Double] {
        var evenSolarTermsPositions = _evenSolarTerms.map { _solarTerms[0].distance(to: $0) / _year_length as Double }
        evenSolarTermsPositions = evenSolarTermsPositions.filter { ($0 < 1) && ($0 > 0) }
        return [0] + evenSolarTermsPositions
    }

    var oddSolarTerms: [Double] {
        var oddSolarTermsPositions = _oddSolarTerms.map { _solarTerms[0].distance(to: $0) / _year_length as Double }
        oddSolarTermsPositions = oddSolarTermsPositions.filter { ($0 < 1) && ($0 > 0) }
        return oddSolarTermsPositions
    }

    var solarTerms: [NamedDate] {
        var terms = [NamedDate]()
        for i in 0..<_solarTerms.count {
            let name: String
            if (i %% 2) == 0 {
                name = Self.evenSolarTermChinese[(i / 2) %% Self.evenSolarTermChinese.count]
            } else {
                name = Self.oddSolarTermChinese[(i / 2) %% Self.oddSolarTermChinese.count]
            }
            terms.append(NamedDate(name: name, date: _solarTerms[i]))
        }
        return terms
    }

    var moonPhases: [NamedDate] {
        var phases = [NamedDate]()
        for i in 0..<max(_moonEclipses.count, _fullMoons.count) {
            if i < _moonEclipses.count {
                phases.append(NamedDate(name: Self.moonPhases.newmoon, date: _moonEclipses[i]))
            }
            if i < _fullMoons.count {
                phases.append(NamedDate(name: Self.moonPhases.fullmoon, date: _fullMoons[i]))
            }
        }
        return phases
    }

    var monthNames: [String] {
        var names = [String]()
        let all_names = _compact ? Self.month_chinese_compact : Self.month_chinese
        for i in 0..<_numberOfMonths {
            let name = if _leap_month >= 0 && i > _leap_month {
                all_names[(i - 3) %% 12]
            } else if _leap_month >= 0 && i == _leap_month {
                Self.leapLabel + all_names[(i - 3) %% 12]
            } else {
                all_names[(i - 2) %% 12]
            }
            names.append(Self.alternativeMonthName[name] ?? name)
        }
        return names
    }

    var location: GeoLocation? {
        _location
    }

    var timezone: Int {
        _calendar.timeZone.secondsFromGMT(for: _time)
    }

    var year: Int {
        _year
    }

    var month: Int {
        _month
    }

    var preciseMonth: Int {
        _globalMonth ? _precise_month : _month
    }

    var nominalMonth: Int {
        let inLeapMonth = _leap_month >= 0 && _month >= _leap_month
        return ((_month + (inLeapMonth ? 0 : 1) - 3) %% 12) + 1
    }
    var leapMonth: Int? {
        if _leap_month >= 0 {
            _leap_month
        } else {
            nil
        }
    }

    var isLeapMonth: Bool {
        _leap_month >= 0 && _month == _leap_month
    }

    var day: Int {
        _day + 1
    }

    var hour: Int {
        switch _hour.format {
        case .full:
            _hour.hour * 2
        case .partial(index: let index):
            (_hour.hour * 2 + index - 1) %% 24
        }
    }

    var quarterMajor: Int {
        _quarter.majorTick
    }

    var quarterMinor: Int {
        _quarter.minorTick
    }

    var time: Date {
        _time
    }

    var subquarter: Double {
        startOfDay.distance(to: time) / 144
    }

    var numberOfMonths: Int {
        _numberOfMonths
    }

    var numberOfDaysInMonth: Int {
        let month = _globalMonth ? _precise_month : _month
        let monthStartDate = _calendar.startOfDay(for: _moonEclipses[month], apparent: apparentTime, location: location)
        let monthEndDate = _calendar.startOfDay(for: _moonEclipses[month + 1], apparent: apparentTime, location: location)
        return Int(round(monthStartDate.distance(to: monthEndDate) / 86400))
    }

    var maxQuarterMajor: Int {
        let startOfDay = startOfDay
        let hourStart = startOfDay.distance(to: startOfHour)
        let hourEnd = startOfDay.distance(to: startOfNextHour) - 1
        return Int(hourEnd /% 864) - Int(hourStart /% 864) + 1
    }

    var maxQuarterMinor: Int {
        let startOfDay = startOfDay
        let hourStart = startOfDay.distance(to: startOfHour)
        let hourEnd = startOfDay.distance(to: startOfNextHour) - 1
        let current = startOfDay.distance(to: _time)
        if Int(current /% 864) <= Int(hourStart /% 864) {
            let startRemainder = (hourStart /% 864 + 1.0) * 864.0 - hourStart - 1
            return Int(startRemainder /% 144) + 1
        } else if Int(current /% 864) >= Int(hourEnd /% 864) {
            return Int((hourEnd %% 864.0) /% 144) + 1
        } else {
            return 6
        }
    }

    var lunarHoliday: String? {
        for holiday in Self.holidays.keys where self.equals(date: holiday) {
            return Self.holidays[holiday]
        }
        return nil
    }

    var lunarHolidays: [NamedDate] {
        Self.holidays.compactMap { chineseDate, name in
            if let date = self.find(chineseDate: chineseDate) {
                NamedDate(name: name, date: date)
            } else {
                nil
            }
        }.sorted {
            $0.date < $1.date
        }
    }

    var holidays: [String] {
        var holidays: [String] = []
        if let holiday = self.lunarHoliday {
            holidays.append(holiday)
        }
        for solarTerm in self.eventInDay.oddSolarTerm {
            holidays.append(solarTerm.name)
        }
        for solarTerm in self.eventInDay.evenSolarTerm {
            holidays.append(solarTerm.name)
        }
        for moon in self.eventInDay.eclipse {
            holidays.append(moon.name)
        }
        for moon in self.eventInDay.fullMoon {
            holidays.append(moon.name)
        }
        return holidays
    }
}

// MARK: Celestial Events
extension ChineseCalendar {
    func nextHours(count: Int) -> [Date] {
        let startOfDay = startOfDay
        let aHourSec = startOfDay.distance(to: startOfNextDay) / (_largeHour ? 12 : 24)
        let aHoutInt = _largeHour ? 2 : 1
        var tickTime = time
        var i = 0
        var hours = [Date]()
        while i < count {
            if tickTime > time {
                hours.append(tickTime)
                i += 1
            }
            if apparentTime {
                let hoursPast = floor(startOfDay.distance(to: tickTime) / aHourSec)
                tickTime = startOfDay + (hoursPast + 1) * aHourSec + 1
            } else {
                var components = _calendar.dateComponents([.timeZone, .year, .month, .day, .hour], from: tickTime)
                components.hour = components.hour.map { hour in
                    (hour / aHoutInt + 1) * aHoutInt
                }
                if let newTime = _calendar.date(from: components) {
                    tickTime = newTime
                }
            }
        }
        return hours
    }

    func nextQuarters(count: Int) -> [Date] {
        var tickTime = startOfDay - 864 * 6
        var i = 0
        var quarters = [Date]()
        let quartersInHour = _largeHour ? 8 : 4
        let hours = nextHours(count: count / quartersInHour + 1)
        var j = 0
        while i < count && j < hours.count {
            if tickTime > time {
                if tickTime > hours[j] {
                    if tickTime > hours[j] + 16 {
                        quarters.append(hours[j])
                    }
                    j += 1
                }
                if j >= hours.count || tickTime < hours[j] - 16 {
                    quarters.append(tickTime)
                    i += 1
                }
            }
            tickTime += 864
        }
        return quarters
    }

    var planetPosition: Planets<NamedPosition> {
        _planets
    }

    var eventInMonth: CelestialEvent {
        let monthStart: Date
        let monthLength: Double
        if _globalMonth {
            monthStart = _moonEclipses[_precise_month]
            monthLength = _moonEclipses[_precise_month].distance(to: _moonEclipses[_precise_month + 1])
        } else {
            monthStart = _calendar.startOfDay(for: _moonEclipses[_month], apparent: apparentTime, location: location)
            let monthEnd = _calendar.startOfDay(for: _moonEclipses[_month + 1], apparent: apparentTime, location: location)
            monthLength = monthStart.distance(to: monthEnd)
        }
        var event = CelestialEvent()
        if !_globalMonth {
            event.eclipse = _moonEclipses.map { date in
                NamedPosition(name: Self.moonPhases.newmoon, pos: monthStart.distance(to: date) / monthLength)
            }.filter { $0.pos >= 0 && $0.pos < 1 }
        }
        event.fullMoon = _fullMoons.map { date in
            NamedPosition(name: Self.moonPhases.fullmoon, pos: monthStart.distance(to: date) / monthLength)
        }.filter { $0.pos >= 0 && $0.pos < 1 }
        event.evenSolarTerm = _evenSolarTerms.enumerated().map { offset, date in
            let name = String(Self.evenSolarTermChinese[(offset - 1) %% Self.evenSolarTermChinese.count].replacingOccurrences(of: "　", with: ""))
            return NamedPosition(name: name, pos: monthStart.distance(to: date) / monthLength)
        }.filter { $0.pos >= 0 && $0.pos < 1 }
        event.oddSolarTerm = _oddSolarTerms.enumerated().map { offset, date in
            let name = String(Self.oddSolarTermChinese[(offset - 1) %% Self.oddSolarTermChinese.count].replacingOccurrences(of: "　", with: ""))
            return NamedPosition(name: name, pos: monthStart.distance(to: date) / monthLength)
        }.filter { $0.pos >= 0 && $0.pos < 1 }
        return event
    }

    var eventInDay: CelestialEvent {
        let startOfDay = startOfDay
        let lengthOfDay = startOfDay.distance(to: startOfNextDay)
        var event = CelestialEvent()
        event.eclipse = _moonEclipses.map { date in
            NamedPosition(name: Self.moonPhases.newmoon, pos: startOfDay.distance(to: date) / lengthOfDay)
        }.filter { $0.pos >= 0 && $0.pos < 1 }
        event.fullMoon = _fullMoons.map { date in
            NamedPosition(name: Self.moonPhases.fullmoon, pos: startOfDay.distance(to: date) / lengthOfDay)
        }.filter { $0.pos >= 0 && $0.pos < 1 }
        event.evenSolarTerm = _evenSolarTerms.enumerated().map { offset, date in
            let name = String(Self.evenSolarTermChinese[(offset - 1) %% Self.evenSolarTermChinese.count].replacingOccurrences(of: "　", with: ""))
            return NamedPosition(name: name, pos: startOfDay.distance(to: date) / lengthOfDay)
        }.filter { $0.pos >= 0 && $0.pos < 1 }
        event.oddSolarTerm = _oddSolarTerms.enumerated().map { offset, date in
            let name = String(Self.oddSolarTermChinese[(offset - 1) %% Self.oddSolarTermChinese.count].replacingOccurrences(of: "　", with: ""))
            return NamedPosition(name: name, pos: startOfDay.distance(to: date) / lengthOfDay)
        }.filter { $0.pos >= 0 && $0.pos < 1 }
        return event
    }

    var eventInHour: CelestialEvent {
        var event = CelestialEvent()
        let hourLength = startOfLargeHour.distance(to: endOfLargeHour)
        event.eclipse = _moonEclipses.map { date in
            NamedPosition(name: Self.moonPhases.newmoon, pos: startOfLargeHour.distance(to: date) / hourLength)
        }.filter { $0.pos >= 0 && $0.pos < 1 }
        event.fullMoon = _fullMoons.map { date in
            NamedPosition(name: Self.moonPhases.fullmoon, pos: startOfLargeHour.distance(to: date) / hourLength)
        }.filter { $0.pos >= 0 && $0.pos < 1 }
        event.evenSolarTerm = _evenSolarTerms.enumerated().map { offset, date in
            let name = String(Self.evenSolarTermChinese[(offset - 1) %% Self.evenSolarTermChinese.count].replacingOccurrences(of: "　", with: ""))
            return NamedPosition(name: name, pos: startOfLargeHour.distance(to: date) / hourLength)
        }.filter { $0.pos >= 0 && $0.pos < 1 }
        event.oddSolarTerm = _oddSolarTerms.enumerated().map { offset, date in
            let name = String(Self.oddSolarTermChinese[(offset - 1) %% Self.oddSolarTermChinese.count].replacingOccurrences(of: "　", with: ""))
            return NamedPosition(name: name, pos: startOfLargeHour.distance(to: date) / hourLength)
        }.filter { $0.pos >= 0 && $0.pos < 1 }
        return event
    }

    mutating func getSunTimes(for dateType: DateType) -> Solar<NamedDate?> {
        if let existing = _sunTimes[dateType] {
            return existing
        }
        var event = Solar<NamedDate?>(midnight: nil, sunrise: nil, noon: nil, sunset: nil)
        if let location {
            let (start, end) = getStartEnd(type: dateType)
            let mid = start + start.distance(to: end) / 2
            if !apparentTime {
                if let midnight = meridianTime(around: start, at: location, type: .midnight), midnight >= start && midnight < end {
                    event.midnight = .init(name: Self.dayTimeName.midnight, date: midnight)
                } else if let midnight = meridianTime(around: end, at: location, type: .midnight), midnight >= start && midnight < end {
                    event.midnight = .init(name: Self.dayTimeName.midnight, date: midnight)
                }
                if let noon = meridianTime(around: mid, at: location, type: .noon), noon >= start && noon < end {
                    event.noon = .init(name: Self.dayTimeName.noon, date: noon)
                }
            }
            if let sunrise = riseSetTime(around: mid, at: location, type: .sunrise), sunrise >= start && sunrise < end {
                event.sunrise = .init(name: Self.dayTimeName.sunrise, date: sunrise)
            }
            if let sunset = riseSetTime(around: mid, at: location, type: .sunset), sunset >= start && sunset < end {
                event.sunset = .init(name: Self.dayTimeName.sunset, date: sunset)
            }
        }
        _sunTimes[dateType] = event
        return event
    }

    mutating func getMoonTimes(for dateType: DateType) -> Lunar<NamedDate?> {
        if let existing = _moonTimes[dateType] {
            return existing
        }
        var event = Lunar<NamedDate?>(moonrise: nil, highMoon: nil, moonset: nil)
        if let location {
            let (start, end) = getStartEnd(type: dateType)
            if let moonrise = riseSetTime(around: start, at: location, type: .moonrise), moonrise >= start && moonrise < end {
                event.moonrise = .init(name: Self.moonTimeName.moonrise, date: moonrise)
            } else if let moonrise = riseSetTime(around: end, at: location, type: .moonrise), moonrise >= start && moonrise < end {
                event.moonrise = .init(name: Self.moonTimeName.moonrise, date: moonrise)
            }
            if let highMoon = meridianTime(around: start, at: location, type: .highMoon), highMoon >= start && highMoon < end {
                event.highMoon = .init(name: Self.moonTimeName.highMoon, date: highMoon)
            } else if let highMoon = meridianTime(around: end, at: location, type: .highMoon), highMoon >= start && highMoon < end {
                event.highMoon = .init(name: Self.moonTimeName.highMoon, date: highMoon)
            }
            if let moonset = riseSetTime(around: start, at: location, type: .moonset), moonset >= start && moonset < end {
                event.moonset = .init(name: Self.moonTimeName.moonset, date: moonset)
            } else if let moonset = riseSetTime(around: end, at: location, type: .moonset), moonset >= start && moonset < end {
                event.moonset = .init(name: Self.moonTimeName.moonset, date: moonset)
            }
        }
        _moonTimes[dateType] = event
        return event
    }

    var sunMoonPositions: DailyEvent {
        mutating get {
            var dailyEvent = DailyEvent()
            if location != nil {
                let start = startOfDay
                let end = startOfNextDay
                // sun
                let sunEvent = getSunTimes(for: .current)
                dailyEvent.solar = Solar<NamedPosition?>(midnight: nil, sunrise: nil, noon: nil, sunset: nil)
                dailyEvent.solar.midnight = sunEvent.midnight?.toPositionBetween(start: start, end: end)
                dailyEvent.solar.sunrise = sunEvent.sunrise?.toPositionBetween(start: start, end: end)
                dailyEvent.solar.noon = sunEvent.noon?.toPositionBetween(start: start, end: end)
                dailyEvent.solar.sunset = sunEvent.sunset?.toPositionBetween(start: start, end: end)
                // moon
                let moonEvent = getMoonTimes(for: .current)
                dailyEvent.lunar = Lunar<NamedPosition?>(moonrise: nil, highMoon: nil, moonset: nil)
                dailyEvent.lunar.moonrise = moonEvent.moonrise?.toPositionBetween(start: start, end: end)
                dailyEvent.lunar.highMoon = moonEvent.highMoon?.toPositionBetween(start: start, end: end)
                dailyEvent.lunar.moonset = moonEvent.moonset?.toPositionBetween(start: start, end: end)
            }
            return dailyEvent
        }
    }

    var sunMoonSubhourPositions: DailyEvent {
        mutating get {
            var dailyEvent = DailyEvent()
            if location != nil {
                let start = startOfLargeHour
                let end = endOfLargeHour
                // sun
                let sunEvent = getSunTimes(for: .current)
                dailyEvent.solar = Solar<NamedPosition?>(midnight: nil, sunrise: nil, noon: nil, sunset: nil)
                dailyEvent.solar.midnight = sunEvent.midnight?.toPositionBetween(start: start, end: end)
                dailyEvent.solar.sunrise = sunEvent.sunrise?.toPositionBetween(start: start, end: end)
                dailyEvent.solar.noon = sunEvent.noon?.toPositionBetween(start: start, end: end)
                dailyEvent.solar.sunset = sunEvent.sunset?.toPositionBetween(start: start, end: end)
                // moon
                let moonEvent = getMoonTimes(for: .current)
                dailyEvent.lunar = Lunar<NamedPosition?>(moonrise: nil, highMoon: nil, moonset: nil)
                dailyEvent.lunar.moonrise = moonEvent.moonrise?.toPositionBetween(start: start, end: end)
                dailyEvent.lunar.highMoon = moonEvent.highMoon?.toPositionBetween(start: start, end: end)
                dailyEvent.lunar.moonset = moonEvent.moonset?.toPositionBetween(start: start, end: end)
            }
            return dailyEvent
        }
    }
}

// MARK: Chinese Date
extension ChineseCalendar {
    var startOfLargeHour: Date {
        _startHour
    }

    var endOfLargeHour: Date {
        _endHour
    }

    var startOfHour: Date {
        return _hourNames.last {
            $0.hour <= self.time
        }!.hour
    }

    var startOfNextHour: Date {
        _hourNames.first {
            $0.hour > self.time
        }!.hour
    }

    var startOfDay: Date {
        _calendar.startOfDay(for: _time, apparent: apparentTime, location: location)
    }

    var startOfNextDay: Date {
        let nextDay = startOfDay + 86400 * 1.5
        return _calendar.startOfDay(for: nextDay, apparent: apparentTime, location: location)
    }

    var chineseDate: ChineseDate {
        ChineseDate(month: nominalMonth, day: day, leap: isLeapMonth, hour: hour, quarter: quarterMajor, subQuarter: quarterMinor)
    }

    func find(chineseDate: ChineseDate) -> Date? {
        guard (1...12).contains(chineseDate.month) && (1...30).contains(chineseDate.day) else {
            return nil
        }
        var chineseCalendar = self
        if chineseCalendar.month >= chineseCalendar.numberOfMonths {
            chineseCalendar.update(time: chineseCalendar._solarTerms[24] + 1)
        }
        if chineseDate.leap && chineseCalendar._numberOfMonths < 13 {
            return nil
        }
        let monthIndex = chineseDate.monthIndex(in: chineseCalendar) - 1
        chineseCalendar.update(time: chineseCalendar._moonEclipses[monthIndex])

        guard chineseCalendar.nominalMonth == chineseDate.month && chineseCalendar.isLeapMonth == chineseDate.leap else {
            return nil
        }

        var targetDay = chineseDate.day
        if targetDay > chineseCalendar.numberOfDaysInMonth {
            targetDay = chineseCalendar.numberOfDaysInMonth
        }
        if chineseDate.reverseCount {
            targetDay = chineseCalendar.numberOfDaysInMonth + 1 - targetDay
        }
        if targetDay != chineseCalendar.day,
           let newDate = chineseCalendar.calendar.date(byAdding: .day, value: targetDay - chineseCalendar.day, to: chineseCalendar.time) {
            chineseCalendar.update(time: newDate)
        }
        guard chineseCalendar.equals(date: chineseDate) else { return nil }
        let startOfDay = chineseCalendar.startOfDay

        var distance: Double = 0
        var distanceCap: Double = 0
        let step = chineseCalendar.largeHour ? 2 : 1
        if chineseCalendar.apparentTime {
            let endOfDay = chineseCalendar.startOfNextDay
            distance = startOfDay.distance(to: endOfDay) * Double(chineseDate.hour) / 24.0
            distanceCap = startOfDay.distance(to: endOfDay) * Double(chineseDate.hour + step) / 24.0
        } else {
            var targetTime = chineseCalendar._calendar.date(byAdding: .day, value: chineseDate.hour /% 24, to: startOfDay)!
            targetTime = chineseCalendar._calendar.date(bySetting: .hour, value: chineseDate.hour %% 24, of: targetTime)!
            distance = startOfDay.distance(to: targetTime)

            var targetTimeNext = chineseCalendar._calendar.date(byAdding: .day, value: (chineseDate.hour + step) /% 24, to: startOfDay)!
            targetTimeNext = chineseCalendar._calendar.date(bySetting: .hour, value: (chineseDate.hour + step) %% 24, of: targetTimeNext)!
            distanceCap = startOfDay.distance(to: targetTimeNext)
        }

        let newQuarterDistance = (distance /% 864 + Double(chineseDate.quarter)) * 864.0
        distance = min(distanceCap - 1, max(distance, newQuarterDistance))
        distanceCap = min(distanceCap, newQuarterDistance + 864.0)

        let newQuarterMinorDistance = (distance /% 144 + Double(chineseDate.subQuarter)) * 144.0
        distance = min(distanceCap - 1, max(distance, newQuarterMinorDistance))

        return startOfDay + distance
    }

    func findNext(chineseDate: ChineseDate) -> Date? {
        if let date = find(chineseDate: chineseDate), date > self.time {
            return date
        } else {
            var nextDate = self
            if month >= nominalMonth {
                nextDate.update(time: nextDate._solarTerms[24] + 1)
            }
            nextDate.update(time: nextDate._solarTerms[24] + 1)
            return nextDate.find(chineseDate: chineseDate)
        }
    }

    func nextMonth() -> Date? {
        var chineseDate = chineseDate
        let monthIndex = chineseDate.monthIndex(in: self)
        var chineseCalendar = self
        if monthIndex < chineseCalendar.numberOfMonths {
            chineseDate.update(monthIndex: monthIndex + 1, in: chineseCalendar)
        } else {
            if chineseCalendar.month >= chineseCalendar.numberOfMonths {
                chineseCalendar.update(time: chineseCalendar._solarTerms[24] + 1)
            }
            chineseCalendar.update(time: chineseCalendar._solarTerms[24] + 1)
            chineseDate.update(monthIndex: 1, in: chineseCalendar)
        }
        return chineseCalendar.find(chineseDate: chineseDate)
    }
    func previousMonth() -> Date? {
        var chineseCalendar = self
        var chineseDate = chineseDate
        let monthIndex = chineseDate.monthIndex(in: chineseCalendar)
        if monthIndex > 1 {
            chineseDate.update(monthIndex: monthIndex - 1, in: chineseCalendar)
        } else {
            if chineseCalendar.month >= chineseCalendar.numberOfMonths {
                chineseCalendar.update(time: chineseCalendar._moonEclipses[chineseCalendar.numberOfMonths] - 100000)
            } else {
                chineseCalendar.update(time: chineseCalendar._moonEclipses[0] - 100000)
            }
            chineseDate.update(monthIndex: chineseCalendar.numberOfMonths, in: chineseCalendar)
        }
        return chineseCalendar.find(chineseDate: chineseDate)
    }

    func nextYear() -> Date? {
        var chineseCalendar = self
        var chineseDate = chineseDate
        if chineseCalendar.month >= chineseCalendar.numberOfMonths {
            chineseCalendar.update(time: chineseCalendar._solarTerms[24] + 1)
        }
        chineseCalendar.update(time: chineseCalendar._solarTerms[24] + 1)

        if let date = chineseCalendar.find(chineseDate: chineseDate) {
            return date
        } else if chineseDate.leap {
            chineseDate.leap = false
        }
        return chineseCalendar.find(chineseDate: chineseDate)
    }
    func previousYear() -> Date? {
        var chineseCalendar = self
        var chineseDate = chineseDate
        if chineseCalendar.month >= chineseCalendar.numberOfMonths {
            chineseCalendar.update(time: chineseCalendar._moonEclipses[chineseCalendar.numberOfMonths] - 100000)
        } else {
            chineseCalendar.update(time: chineseCalendar._moonEclipses[0] - 100000)
        }
        if let date = chineseCalendar.find(chineseDate: chineseDate) {
            return date
        } else if chineseDate.leap {
            chineseDate.leap = false
        }
        return chineseCalendar.find(chineseDate: chineseDate)
    }
}

// MARK: Ticks
extension ChineseCalendar {
    var monthTicks: Ticks {
        let months = self.monthNames
        var ticks = Ticks()
        var monthDivides: [Double]
        if _globalMonth {
            monthDivides = _moonEclipses.map { _solarTerms[0].distance(to: $0) / _year_length }
        } else {
            monthDivides = _moonEclipses.map { _solarTerms[0].distance(to: _calendar.startOfDay(for: $0, apparent: apparentTime, location: location)) / _year_length }
        }
        monthDivides = monthDivides.filter { $0 > 0 && $0 <= 1 }
        guard months.count == monthDivides.count else { return ticks }
        var previousMonthDivide = 0.0
        var monthNames = [Ticks.TickName]()
        let minMonthLength: Double = (_compact ? 0.009 : 0.006)
        for i in 0..<monthDivides.count {
            let position = (monthDivides[i] + previousMonthDivide) / 2
            if position - previousMonthDivide > minMonthLength * Double(months[i].count) {
                monthNames.append(Ticks.TickName(
                    pos: position,
                    name: months[i],
                    active: previousMonthDivide <= currentDayInYear
                ))
            }
            previousMonthDivide = monthDivides[i]
        }
        if let lastDivide = monthDivides.last, lastDivide < 1 {
            let position = (1 + previousMonthDivide) / 2
            if position - previousMonthDivide > minMonthLength * Double(months[0].count) {
                monthNames.append(Ticks.TickName(
                    pos: position,
                    name: months[0],
                    active: previousMonthDivide <= currentDayInYear
                ))
            }
        } else {
            _ = monthDivides.popLast()
        }

        ticks.majorTicks = [0] + monthDivides
        ticks.majorTickNames = monthNames
        ticks.minorTicks = _fullMoons.map { _solarTerms[0].distance(to: $0) / _year_length }.filter { ($0 < 1) && ($0 > 0) }
        return ticks
    }

    var dayTicks: Ticks {
        var ticks = Ticks()

        let monthStart: Date
        let monthEnd: Date
        var date: Date
        if _globalMonth {
            monthStart = _moonEclipses[_precise_month]
            monthEnd = _moonEclipses[_precise_month + 1]
            date = _calendar.startOfDay(for: monthStart, apparent: apparentTime, location: location)
        } else {
            monthStart = _calendar.startOfDay(for: _moonEclipses[_month], apparent: apparentTime, location: location)
            monthEnd = _calendar.startOfDay(for: _moonEclipses[_month + 1], apparent: apparentTime, location: location)
            date = monthStart
        }

        var dayDivides = [Date]()
        while date < monthEnd {
            if apparentTime {
                date += 86400 * 1.5
                date = _calendar.startOfDay(for: date, apparent: apparentTime, location: location)
            } else {
                date = _calendar.date(byAdding: .day, value: 1, to: date)!
            }
            dayDivides.append(date)
        }
        let majorTicks: [Double] = dayDivides.map { monthStart.distance(to: $0) / monthStart.distance(to: monthEnd) }.filter { $0 > 0 && $0 < 1 }

        let allDayNames: [String]
        if _compact {
            allDayNames = Self.day_chinese_compact.slice(to: numberOfDaysInMonth) + [Self.day_chinese_compact[0]]
        } else {
            allDayNames = Self.day_chinese.slice(to: numberOfDaysInMonth) + [Self.day_chinese[0]]
        }

        var dayNames = [Ticks.TickName]()
        var previousDayDivide = 0.0
        let minDayLength = (_compact ? 0.009 : 0.006)
        for i in 0..<majorTicks.count {
            let position = (majorTicks[i] + previousDayDivide) / 2
            if position - previousDayDivide > minDayLength * Double(allDayNames[i].count) {
                dayNames.append(Ticks.TickName(
                    pos: position,
                    name: allDayNames[i],
                    active: previousDayDivide <= currentDayInMonth
                ))
            }
            previousDayDivide = majorTicks[i]
        }
        let position = (1 + previousDayDivide) / 2
        if position - previousDayDivide > minDayLength * Double(allDayNames[majorTicks.count].count) {
            dayNames.append(Ticks.TickName(
                pos: position,
                name: allDayNames[majorTicks.count],
                active: previousDayDivide <= currentDayInMonth
            ))
        }
        ticks.majorTicks = [0] + majorTicks
        ticks.majorTickNames = dayNames
        return ticks
    }

    var hourTicks: Ticks {
        let startOfDay = startOfDay
        let startOfNextDay = startOfNextDay
        var ticks = Ticks()
        var hourDivides = [Double]()
        var quarterTick = [Double]()
        var quarter = 0.0
        while quarter < 1.0 {
            quarterTick.append(quarter)
            quarter += 864 / startOfDay.distance(to: startOfNextDay)
        }
        quarterTick = Array(Set(quarterTick).subtracting(hourDivides)).sorted()
        var hourNames = [Ticks.TickName]()
        var hourStart = startOfDay

        for namedHour in _hourNames {
            if namedHour.hour >= startOfDay && namedHour.hour < startOfNextDay {
                let dividePos = startOfDay.distance(to: namedHour.hour) / startOfDay.distance(to: startOfNextDay)
                if !namedHour.longName.isEmpty {
                    hourDivides.append(dividePos)
                }
                if _largeHour || !namedHour.shortName.isEmpty {
                    if _largeHour {
                        hourStart = namedHour.hour
                    }
                    hourNames.append(Ticks.TickName(
                        pos: dividePos,
                        name: namedHour.shortName,
                        active: hourStart <= _time
                    ))
                } else {
                    if !namedHour.longName.isEmpty {
                        hourStart = namedHour.hour
                    }
                }
            }
        }
        ticks.majorTicks = hourDivides
        ticks.majorTickNames = hourNames
        ticks.minorTicks = quarterTick
        return ticks
    }

    var subhourTicks: Ticks {
        let startHour = startOfLargeHour
        let endHour = endOfLargeHour
        var ticks = Ticks()
        var subHourTicks = Set<Double>()
        var majorTickNames = [String]()
        for namedHour in _hourNamesInCurrentHour {
            majorTickNames.append(namedHour.longName)
            let distPos = startHour.distance(to: namedHour.hour) / startHour.distance(to: endHour)
            if distPos >= 0.0 && distPos < 1.0 {
                subHourTicks.insert(distPos)
            }
        }

        let majorTicks = subHourTicks
        for tickTime in _subhours {
            let distPos = startHour.distance(to: tickTime) / startHour.distance(to: endHour)
            if distPos >= 0.0 && distPos < 1.0 {
                subHourTicks.insert(distPos)
            }
        }

        let minimumSubhourLength = _compact ? 0.045 : 0.03
        var subHourNames = [Ticks.TickName]()
        var count = 1
        var j = 0
        let subHourTick = Array(subHourTicks).sorted()
        for i in 0..<subHourTick.count {
            if majorTicks.contains(subHourTick[i]) {
                subHourNames.append(Ticks.TickName(
                    pos: subHourTick[i],
                    name: majorTickNames[j],
                    active: subHourTick[i] <= subhourInHour
                ))
                j += 1
                count = 1
            } else {
                if min((subHourTick[i] - subHourTick[(i - 1) %% subHourTick.count]) %% 1.0, (subHourTick[(i + 1) %% subHourTick.count] - subHourTick[i]) %% 1.0) > minimumSubhourLength {
                    subHourNames.append(Ticks.TickName(
                        pos: subHourTick[i],
                        name: Self.chinese_numbers[count],
                        active: subHourTick[i] <= subhourInHour
                    ))
                }
                count += 1
            }
        }

        var subQuarterTicks = Set<Double>()
        for tickTime in _subhourMinors {
            subQuarterTicks.insert(startHour.distance(to: tickTime) / startHour.distance(to: endHour))
        }
        subQuarterTicks = subQuarterTicks.subtracting(subHourTicks)
        let subQuarterTick = Array(subQuarterTicks).sorted()

        ticks.majorTicks = subHourTick
        ticks.majorTickNames = subHourNames
        ticks.minorTicks = subQuarterTick
        return ticks
    }
}

// MARK: Nested Structs
extension ChineseCalendar {
    struct ChineseDate: Hashable, Equatable {
        var month: Int = 1
        var day: Int = 1
        var leap = false
        var reverseCount = false
        var hour: Int = 0
        var quarter: Int = 0
        var subQuarter: Int = 0
    }

    struct Hour: Equatable {
        enum HourFormat: Equatable {
            case full
            case partial(index: Int)
        }
        var hour: Int
        var format: HourFormat
        var string: String {
            guard (0..<ChineseCalendar.terrestrial_branches.count).contains(hour) else { return "" }
            switch format {
            case .full:
                return ChineseCalendar.terrestrial_branches[hour]
            case .partial(let index):
                guard (0..<ChineseCalendar.sub_hour_name.count).contains(index) else { return "" }
                return "\(ChineseCalendar.terrestrial_branches[hour])\(ChineseCalendar.sub_hour_name[index])"
            }
        }
        var stringLocalized: LocalizedStringResource {
            guard (0..<ChineseCalendar.terrestrial_branches_localized.count).contains(hour) else { return "" }
            switch format {
            case .full:
                return "\(ChineseCalendar.terrestrial_branches_localized[hour])HOUR"
            case .partial(let index):
                guard (0..<ChineseCalendar.sub_hour_name_localized.count).contains(index) else { return "" }
                return "\(ChineseCalendar.terrestrial_branches_localized[hour])HOUR,PRELUDE/PROPER\(ChineseCalendar.sub_hour_name_localized[index])"
            }
        }
    }
    struct SubHour: Equatable {
        var majorTick: Int
        var minorTick: Int
        var shortString: String {
            guard (0..<ChineseCalendar.chinese_numbers.count).contains(majorTick) else { return "" }
            return "\(ChineseCalendar.chinese_numbers[majorTick])刻"
        }
        var shortStringLocalized: LocalizedStringResource {
            guard (0..<ChineseCalendar.chinese_numbers_localized.count).contains(majorTick) else { return "" }
            return "\(ChineseCalendar.chinese_numbers_localized[majorTick])QUARTER"
        }
        var string: String {
            guard (0..<ChineseCalendar.chinese_numbers.count).contains(majorTick) && (0..<ChineseCalendar.chinese_numbers.count).contains(minorTick) else { return "" }
            var str = "\(ChineseCalendar.chinese_numbers[majorTick])刻"
            if minorTick > 0 {
                str += ChineseCalendar.chinese_numbers[minorTick]
            }
            return str
        }
        var stringLocalized: LocalizedStringResource {
            guard (0..<ChineseCalendar.chinese_numbers_localized.count).contains(majorTick) && (0..<ChineseCalendar.chinese_numbers_localized.count).contains(minorTick) else { return "" }
            if minorTick > 0 {
                return "\(ChineseCalendar.chinese_numbers_localized[majorTick])QUARTER_AND\(ChineseCalendar.chinese_numbers_localized[minorTick])"
            } else {
                return "\(ChineseCalendar.chinese_numbers_localized[majorTick])QUARTER"
            }
        }
    }

    struct NamedHour: Equatable {
        let hour: Date
        let shortName: String
        let longName: String
    }

    struct NamedPosition: NamedPoint {
        let name: String
        let pos: Double
    }

    struct NamedDate: Equatable {
        let name: String
        let date: Date
        func toPositionBetween(start: Date, end: Date) -> NamedPosition? {
            guard date >= start && date < end else { return nil }
            let position = start.distance(to: date) / start.distance(to: end)
            return NamedPosition(name: name, pos: position)
        }
    }

    struct CelestialEvent: Equatable {
        var eclipse = [NamedPosition]()
        var fullMoon = [NamedPosition]()
        var oddSolarTerm = [NamedPosition]()
        var evenSolarTerm = [NamedPosition]()
    }

    struct DailyEvent: Equatable {
        var solar = Solar<NamedPosition?>(midnight: nil, sunrise: nil, noon: nil, sunset: nil)
        var lunar = Lunar<NamedPosition?>(moonrise: nil, highMoon: nil, moonset: nil)
    }

    enum DateType {
        case current, previous, next
    }

    struct Ticks: Equatable {
        struct TickName: NamedPoint {
            var pos: Double = 0.0
            var name: String = ""
            var active: Bool = false
        }

        var majorTicks = [Double]()
        var majorTickNames = [TickName]()
        var minorTicks = [Double]()
    }
}

extension ChineseCalendar.ChineseDate {
    func monthIndex(in chineseCalendar: ChineseCalendar) -> Int {
        if let leapMonth = chineseCalendar.leapMonth,
           (month + 1) %% 12 >= leapMonth || (leap && (month + 1) %% 12 == leapMonth - 1) {
            return (month + 2) %% 13 + 1
        } else {
            return (month + 1) %% 12 + 1
        }
    }

    mutating func update(monthIndex: Int? = nil, in chineseCalendar: ChineseCalendar) {
        if let monthIndex {
            month = (monthIndex - 3) %% 12 + 1
            leap = false
            if let leapMonth = chineseCalendar.leapMonth {
                if monthIndex >= leapMonth + 1 {
                    if monthIndex == leapMonth + 1 {
                        leap = true
                    }
                    month = (month - 2) %% 12 + 1
                }
            }
        }
    }

    init(monthIndex: Int, day: Int = 1, reverseCount: Bool = false, hour: Int = 0, quarter: Int = 0, subquarter: Int = 0, in chineseCalendar: ChineseCalendar) {
        self.init(day: day, reverseCount: reverseCount, hour: hour, quarter: quarter, subQuarter: subquarter)
        self.update(monthIndex: monthIndex, in: chineseCalendar)
    }
}

// MARK: Mutating Updates - Private
private extension ChineseCalendar {
    mutating func updateYear() {
        var year = calendar.component(.year, from: time)
        var solar_terms = solar_terms_in_year(year + 1)
        if solar_terms[0] <= time {
            year += 1
            solar_terms += solar_terms_in_year(year + 1)[0...4]
        } else {
            var solar_terms_current_year = solar_terms_in_year(year)
            solar_terms_current_year += solar_terms[0...4]
            solar_terms = solar_terms_current_year
        }
        let solar_terms_previous_year = solar_terms_in_year(year - 1)

        let (moon_phase_previous_year, first_event) = moon_phase_in_year(year - 1)
        var (moon_phase, _) = moon_phase_in_year(year)
        let (moon_phase_next_year, _) = moon_phase_in_year(year + 1)
        moon_phase = moon_phase_previous_year + moon_phase + moon_phase_next_year
        var eclipse = moon_phase.slice(from: Int(first_event), step: 2)
        var fullMoon = moon_phase.slice(from: Int(1 - first_event), step: 2)
        var start: Int?, end: Int?
        for i in 0..<eclipse.count {
            let eclipseDate: Date
            if _globalMonth {
                eclipseDate = eclipse[i]
            } else {
                eclipseDate = calendar.startOfDay(for: eclipse[i], apparent: apparentTime, location: location)
            }
            if start == nil, eclipseDate >= solar_terms[0] {
                start = i - 1
            }
            if end == nil, eclipseDate > solar_terms[24] {
                end = i
            }
        }
        eclipse = eclipse.slice(from: start!, to: end! + 2)
        fullMoon = fullMoon.filter { $0 < eclipse.last! && $0 > eclipse[0] }
        let evenSolarTerms = solar_terms.slice(step: 2)

        var i = 0
        var j = 0
        var count = 0
        var solatice_in_month = [Int]()
        var monthCount = Set<Date>()
        while i + 1 < eclipse.count, j < evenSolarTerms.count {
            let thisEclipse: Date
            let nextEclipse: Date
            if _globalMonth {
                thisEclipse = eclipse[i]
                nextEclipse = eclipse[i + 1]
            } else {
                thisEclipse = calendar.startOfDay(for: eclipse[i], apparent: apparentTime, location: location)
                nextEclipse = calendar.startOfDay(for: eclipse[i + 1], apparent: apparentTime, location: location)
            }
            if thisEclipse <= evenSolarTerms[j], nextEclipse > evenSolarTerms[j] {
                count += 1
                j += 1
            } else {
                solatice_in_month.append(count)
                count = 0
                i += 1
            }
            if thisEclipse > solar_terms[0], thisEclipse <= solar_terms[24] {
                monthCount.insert(thisEclipse)
            }
        }

        var leap_month = -1
        if monthCount.count > 12 {
            for i in 0..<solatice_in_month.count {
                if solatice_in_month[i] == 0, leap_month < 0 {
                    leap_month = i
                    break
                }
            }
        }

        _solarTerms = Array(solar_terms[0...24])
        _year_length = solar_terms[0].distance(to: solar_terms[24])
        var evenSolar = solar_terms.slice(from: 0, step: 2)
        evenSolar.insert(solar_terms_previous_year[solar_terms_previous_year.count - 2], at: 0)
        _evenSolarTerms = evenSolar
        var oddSolar = solar_terms.slice(from: 1, step: 2)
        oddSolar.insert(solar_terms_previous_year[solar_terms_previous_year.count - 1], at: 0)
        _oddSolarTerms = oddSolar
        _moonEclipses = eclipse
        _fullMoons = fullMoon
        _leap_month = leap_month
        _year = year
        _numberOfMonths = monthCount.count
    }

    mutating func updateDate() {
        var i = 0
        while i < _moonEclipses.count - 1 {
            let startOfEclipse = _calendar.startOfDay(for: _moonEclipses[i], apparent: apparentTime, location: location)
            let startOfDate = _calendar.startOfDay(for: _time, apparent: apparentTime, location: location)
            if startOfEclipse > startOfDate {
                break
            }
            i += 1
        }
        var j = 0
        while j < _moonEclipses.count - 1 {
            if _moonEclipses[j] > _time {
                break
            }
            j += 1
        }
        let previousEclipse = _calendar.startOfDay(for: _moonEclipses[i - 1], apparent: apparentTime, location: location)
        let startOfDate = _calendar.startOfDay(for: _time, apparent: apparentTime, location: location)
        let date_diff = Int(round(previousEclipse.distance(to: startOfDate) / 86400))
        _month = i - 1
        _precise_month = j - 1
        _day = date_diff
    }

    mutating func updateHour() {
        let startOfDay = startOfDay
        let startOfNextDay = startOfNextDay
        var tempStartHour: Date?
        var tempEndHour: Date?
        var hour = if apparentTime {
            startOfDay - 2 * startOfDay.distance(to: startOfNextDay) / 24
        } else {
            _calendar.date(byAdding: .hour, value: -2, to: startOfDay)!
        }
        let end = if apparentTime {
            startOfNextDay + 2 * startOfDay.distance(to: startOfNextDay) / 24
        } else {
            _calendar.date(byAdding: .hour, value: 2, to: startOfNextDay)!
        }
        _hourNames = []
        var prevHourName = ""
        var prevOffsetHourName = ""
        var prevLongName = ""
        while hour < end {
            let hourIndex = if apparentTime {
                Int(round(startOfDay.distance(to: hour) / startOfDay.distance(to: startOfNextDay) * 24))
            } else {
                _calendar.component(.hour, from: hour)
            }
            let hourName = Self.terrestrial_branches[(hourIndex /% 2) %% 12]
            let offsetHourName = Self.terrestrial_branches[((hourIndex + 1) /% 2) %% 12]
            if !_largeHour || hourName != prevHourName {
                let shortName = if hourName != prevHourName {
                    ChineseCalendar.terrestrial_branches[(hourIndex /% 2) %% 12]
                } else {
                    ""
                }
                let longName: String
                if _largeHour {
                    if hourName != prevHourName {
                        longName = Self.terrestrial_branches[(hourIndex /% 2) %% 12]
                    } else {
                        longName = ""
                    }
                } else {
                    let name = Self.terrestrial_branches[((hourIndex + 1) /% 2) %% 12] + Self.sub_hour_name[(hourIndex + 1) %% 2]
                    if name != prevLongName {
                        prevLongName = name
                        longName = name
                    } else {
                        longName = ""
                    }
                }
                _hourNames.append(NamedHour(hour: hour, shortName: shortName, longName: longName))
            }
            if hour <= _time {
                if _largeHour {
                    _hour = Hour(hour: (hourIndex /% 2) %% 12, format: .full)
                } else {
                    _hour = Hour(hour: ((hourIndex + 1) /% 2) %% 12, format: .partial(index: (hourIndex + 1) %% 2))
                }
            }
            let changeOfHour = if _largeHour {
                hourName != prevHourName
            } else {
                offsetHourName != prevOffsetHourName
            }
            if changeOfHour, hour <= _time {
                tempStartHour = hour
            }
            if changeOfHour, hour > _time, tempEndHour == nil {
                tempEndHour = hour
            }
            if apparentTime {
                hour += startOfDay.distance(to: startOfNextDay) / 24
            } else {
                hour = _calendar.date(byAdding: .hour, value: 1, to: hour)!
            }
            prevHourName = hourName
            prevOffsetHourName = offsetHourName
        }
        _startHour = tempStartHour!
        _endHour = tempEndHour!
        _sunTimes = [:]
        _moonTimes = [:]
    }

    mutating func updateSubHour() {
        _hourNamesInCurrentHour = []
        _subhours = []
        _subhourMinors = []

        var currentSmallHour = startOfLargeHour
        for namedHour in _hourNames {
            if !namedHour.longName.isEmpty && namedHour.hour >= startOfLargeHour && namedHour.hour < endOfLargeHour {
                _hourNamesInCurrentHour.append(namedHour)
                if namedHour.hour <= _time {
                    currentSmallHour = namedHour.hour
                }
            }
        }

        var majorTickCount = 0
        var tickTime = startOfDay - 864 * 6
        var currentSubhour = currentSmallHour
        while tickTime < endOfLargeHour - 16 {
            if tickTime > startOfLargeHour + 16 {
                _subhours.append(tickTime)
            }
            if tickTime > currentSmallHour && time >= tickTime {
                currentSubhour = tickTime
                majorTickCount += 1
            }
            tickTime += 864
        }

        var minorTickCount = 0
        tickTime = startOfDay - 864 * 6
        while tickTime < endOfLargeHour {
            if tickTime > startOfLargeHour {
                _subhourMinors.append(tickTime)
            }
            if tickTime > currentSubhour && time >= tickTime {
                minorTickCount += 1
            }
            tickTime += 144
        }
        _quarter = SubHour(majorTick: majorTickCount, minorTick: minorTickCount)
    }

    mutating func updatePlanets() {
        let solarSystem = SolarSystem(time: _time, loc: location, targets: .all)
        let offset = currentDayInYear - solarSystem.planets.sun.loc.ra / Double.pi / 2
        let planets = Planets<NamedPosition>(
            moon: .init(name: Self.planetNames.moon, pos: ((solarSystem.planets.moon.loc.ra) / Double.pi / 2 + offset) %% 1.0),
            mercury: .init(name: Self.planetNames.mercury, pos: ((solarSystem.planets.mercury.loc.ra) / Double.pi / 2 + offset) %% 1.0),
            venus: .init(name: Self.planetNames.venus, pos: ((solarSystem.planets.venus.loc.ra) / Double.pi / 2 + offset) %% 1.0),
            mars: .init(name: Self.planetNames.mars, pos: ((solarSystem.planets.mars.loc.ra) / Double.pi / 2 + offset) %% 1.0),
            jupiter: .init(name: Self.planetNames.jupiter, pos: ((solarSystem.planets.jupiter.loc.ra) / Double.pi / 2 + offset) %% 1.0),
            saturn: .init(name: Self.planetNames.saturn, pos: ((solarSystem.planets.saturn.loc.ra) / Double.pi / 2 + offset) %% 1.0)
        )
        _planets = planets
    }

    func getStartEnd(type: DateType) -> (start: Date, end: Date) {
        let start: Date
        let end: Date
        switch type {
        case .current:
            start = startOfDay
            end = startOfNextDay
        case .previous:
            end = startOfDay
            start = _calendar.startOfDay(for: end - 3600, apparent: apparentTime, location: location)
        case .next:
            start = startOfNextDay
            end = _calendar.startOfDay(for: start + 90000, apparent: apparentTime, location: location)
        }
        return (start: start, end: end)
    }

    func equals(date: ChineseDate) -> Bool {
        let effectiveDay = min(date.day, numberOfDaysInMonth)
        let dayMatch = if date.reverseCount {
            effectiveDay == numberOfDaysInMonth - day + 1
        } else {
            effectiveDay == day
        }
        return date.leap == isLeapMonth && date.month == nominalMonth && dayMatch
    }
}

// MARK: Underlying Model - Private
private extension ChineseCalendar {
    func getJD(yyyy: Int, mm: Int, dd: Int) -> Double {
        var m1 = mm
        var yy = yyyy
        if m1 <= 2 {
            m1 += 12
            yy -= 1
        }
        // Gregorian calendar
        let b = yy / 400 - yy / 100 + yy / 4
        let jd = Double(365 * yy - 679004 + b) + floor(30.6001 * Double(m1 + 1)) + Double(dd) + 2400000.5
        return jd
    }

    func DeltaT_spline_y(_ y: Double) -> Double {
        func phase(x: Double) -> Double {
            let t = x - 1825
            return 0.00314115 * t * t + 284.8435805251424 * cos(0.4487989505128276 * (0.01 * t + 0.75))
        }
        if y < -720 {
            let const = 1.007739546148514
            return phase(x: y) + const
        } else if y > 2019 {
            let const: Double = -150.263031657016
            return phase(x: y) + const
        }
        let n = [-720, -100, 400, 1000, 1150, 1300, 1500, 1600, 1650, 1720, 1800, 1810, 1820, 1830, 1840, 1850, 1855, 1860, 1865, 1870, 1875, 1880, 1885, 1890, 1895, 1900, 1905, 1910, 1915, 1920, 1925, 1930, 1935, 1940, 1945, 1950, 1953, 1956, 1959, 1962, 1965, 1968, 1971, 1974, 1977, 1980, 1983, 1986, 1989, 1992, 1995, 1998, 2001, 2004, 2007, 2010, 2013, 2016]

        var l = n.count - 1
        while l >= 0 && !(y >= Double(n[l])) {
            l -= 1
        }

        let year_splits = [-100, 400, 100, 1150, 1300, 1500, 1600, 1650, 1720, 1800, 1810, 1820, 1830, 1840, 1850, 1855, 1860, 1865, 1870, 1875, 1880, 1885, 1890, 1895, 1900, 1905, 1910, 1915, 1920, 1925, 1930, 1935, 1940, 1945, 1950, 1953, 1956, 1959, 1962, 1965, 1968, 1971, 1974, 1977, 1980, 1983, 1986, 1989, 1992, 1995, 1998, 2001, 2004, 2007, 2010, 2013, 2016, 2019]
        let r = (y - Double(n[l])) / Double(year_splits[l] - n[l])
        let coef1: [Double] = [20371.848, 11557.668, 6535.116, 1650.393, 1056.647, 681.149, 292.343, 109.127, 43.952, 12.068, 18.367, 15.678, 16.516, 10.804, 7.634, 9.338, 10.357, 9.04, 8.255, 2.371, -1.126, -3.21, -4.388, -3.884, -5.017, -1.977, 4.923, 11.142, 17.479, 21.617, 23.789, 24.418, 24.164, 24.426, 27.05, 28.932, 30.002, 30.76, 32.652, 33.621, 35.093, 37.956, 40.951, 44.244, 47.291, 50.361, 52.936, 54.984, 56.373, 58.453, 60.678, 62.898, 64.083, 64.553, 65.197, 66.061, 66.92, 68.109]
        let coef2: [Double] = [-9999.586, -5822.27, -5671.519, -753.21, -459.628, -421.345, -192.841, -78.697, -68.089, 2.507, -3.481, 0.021, -2.157, -6.018, -0.416, 1.642, -0.486, -0.591, -3.456, -5.593, -2.314, -1.893, 0.101, -0.531, 0.134, 5.715, 6.828, 6.33, 5.518, 3.02, 1.333, 0.052, -0.419, 1.645, 2.499, 1.127, 0.737, 1.409, 1.577, 0.868, 2.275, 3.035, 3.157, 3.199, 3.069, 2.878, 2.354, 1.577, 1.648, 2.235, 2.324, 1.804, 0.674, 0.466, 0.804, 0.839, 1.007, 1.277]
        let coef3: [Double] = [776.247, 1303.151, -298.291, 184.811, 108.771, 61.953, -6.572, 10.505, 38.333, 41.731, -1.126, 4.629, -6.806, 2.944, 2.658, 0.261, -2.389, 2.284, -5.148, 3.011, 0.269, 0.152, 1.842, -2.474, 3.138, 2.443, -1.329, 0.831, -1.643, -0.856, -0.831, -0.449, -0.022, 2.086, -1.232, 0.22, -0.61, 1.282, -1.115, 0.406, 1.002, -0.242, 0.364, -0.323, 0.193, -0.384, -0.14, -0.637, 0.708, -0.121, 0.21, -0.729, -0.402, 0.194, 0.144, -0.109, 0.277, -0.007]
        let coef4: [Double] = [409.16, -503.433, 1085.087, -25.346, -24.641, -29.414, 16.197, 3.018, -2.127, -37.939, 1.918, -3.812, 3.25, -0.096, -0.539, -0.883, 1.558, -2.477, 2.72, -0.914, -0.039, 0.563, -1.438, 1.871, -0.232, -1.257, 0.72, -0.825, 0.262, 0.008, 0.127, 0.142, 0.702, -1.106, 0.614, -0.277, 0.631, -0.799, 0.507, 0.199, -0.414, 0.202, -0.229, 0.172, -0.192, 0.081, -0.165, 0.448, -0.276, 0.11, -0.313, 0.109, 0.199, -0.017, -0.084, 0.128, -0.095, -0.139]
        return coef1[l] + r * (coef2[l] + r * (coef3[l] + r * coef4[l]))
    }

    // UT -> TT
    func DeltaT(T: Double) -> Double {
        let t = 36525 * T + 2451545
        if t > 2459580.5 || t < 2441317.5 {
            return DeltaT_spline_y(t >= 2299160.5 ? (t - 2451544.5) / 365.2425 + 2000 : (t + 0.5) / 365.25 - 4712) / 86400.0
        }
        let l: [Double] = [2457754.5, 2457204.5, 2456109.5, 2454832.5, 2453736.5, 2451179.5, 2450630.5, 2450083.5, 2449534.5, 2449169.5, 2448804.5, 2448257.5, 2447892.5, 2447161.5, 2446247.5, 2445516.5, 2445151.5, 2444786.5, 2444239.5, 2443874.5, 2443509.5, 2443144.5, 2442778.5, 2442413.5, 2442048.5, 2441683.5, 2441499.5, 2441133.5]
        let n = l.count
        var DT = 42.184
        for i in 0..<n {
            if t > l[i] {
                DT += Double(n - i - 1)
                break
            }
        }
        return DT / 86400.0
    }

    func mod2pi_de(x: Double) -> Double {
        return x - 2 * Double.pi * floor(0.5 * x / Double.pi + 0.5)
    }

    func decode_solar_terms(y: Int, istart: Int, offset_comp: Int, solar_comp: [Int8]) -> [Date] {
        let jd0 = getJD(yyyy: y - 1, mm: 12, dd: 31) - 1.0 / 3
        let delta_T = DeltaT(T: (jd0 - 2451545 + 365.25 * 0.5) / 36525)
        let offset = 2451545 - jd0 - delta_T
        let w: [Double] = [2 * Double.pi, 6.282886, 12.565772, 0.337563, 83.99505, 77.712164, 5.7533, 3.9301]
        let poly_coefs: [Double]
        let amp: [Double]
        let ph: [Double]
        if y > 2500 {
            poly_coefs = [-10.60617210417765, 365.2421759265393, -2.701502510496315e-08, 2.303900971263569e-12]
            amp = [0.1736157870707964, 1.914572713893651, 0.0113716862045686, 0.004885711219368455, 0.0004032584498264633, 0.001736052092601642, 0.002035081600709588, 0.001360448706185977]
            ph = [-2.012792258215681, 2.824063083728992, -0.4826844382278376, 0.9488391363261893, 2.646697770061209, -0.2675341497460084, 0.9646288791219602, -1.808852094435626]
        } else if y > 1500 {
            poly_coefs = [-10.6111079510509, 365.2421925947405, -3.888654930760874e-08, -5.434707919089998e-12]
            amp = [0.1633918030382493, 1.95409759473169, 0.01184405584067255, 0.004842563463555804, 0.0004137082581449113, 0.001732513547029885, 0.002025850272284684, 0.001363226024948773]
            ph = [-1.767045717746641, 2.832417615687159, -0.465176623256009, 0.9461667782644696, 2.713020913181211, -0.2031148059020781, 0.9980808019332812, -1.832536089597202]
        } else {
            poly_coefs = []
            amp = []
            ph = []
        }

        var sterm = [Date]()
        for i in 0..<solar_comp.count {
            let Ls = Double(y - 2000) + Double(i + istart) / 24.0
            var s = poly_coefs[0] + offset + Ls * (poly_coefs[1] + Ls * (poly_coefs[2] + Ls * poly_coefs[3]))
            for j in 0..<8 {
                let ang = mod2pi_de(x: w[j] * Ls) + ph[j]
                s += amp[j] * sin(ang)
            }
            let s1 = Int((s - floor(s)) * 1440 + 0.5)
            let datetime = s1 + 1441 * Int(floor(s)) + Int(solar_comp[i]) - offset_comp
            let day = datetime.quotient(rhs: 1441)
            let hourminute = datetime - 1441 * day
            let hour = hourminute.quotient(rhs: 60)
            let minute = hourminute - 60 * hour

            let timezone = Calendar.beijingTime
            let the_date = Date.from(year: y, month: 1, day: day, hour: hour, minute: minute, timezone: timezone)
            sterm.append(the_date!)
        }
        return sterm
    }

    func decode_moon_phases(y: Int, offset_comp: Int, lunar_comp: [Int8], dp: Double) -> [Date] {
        let w = [2 * Double.pi, 6.733776, 13.467552, 0.507989, 0.0273143, 0.507984, 20.201328, 6.225791, 7.24176, 5.32461, 12.058386, 0.901181, 5.832595, 12.56637061435917, 19.300146, 11.665189, 18.398965, 6.791174, 13.636974, 1.015968, 6.903198, 13.07437, 1.070354, 6.340578614359172]
        let poly_coefs: [Double]
        let amp: [Double]
        let ph: [Double]
        if y > 2500 {
            poly_coefs = [5.093879710922470, 29.53058981687484, 2.670339910922144e-11, 1.807808217274283e-15]
            amp = [0.00306380948959271, 6.08567588841838, 0.3023856209133756, 0.07481389897992345, 0.0001587661348338354, 0.1740759063081489, 0.0004131985233772993, 0.005796584475300004, 0.008268929076163079, 0.003256244384807976, 0.000520983165608148, 0.003742624708965854, 1.709506053530008, 28216.70389751519, 1.598844831045378, 0.314745599206173, 6.602993931108911, 0.0003387269181720862, 0.009226112317341887, 0.00196073145843697, 0.001457643607929487, 6.467401779992282e-05, 0.0007716739483064076, 0.001378880922256705]
            ph = [-0.0001879456766404132, -2.745704167588171, -2.348884895288619, 1.420037528559222, -2.393586904955103, -0.3914194006325855, 1.183088056748942, -2.782692143601458, 0.4430565056744425, -0.4357413971405519, -3.081209195003025, 0.7945051912707899, -0.4010911170136437, 3.003035462639878e-10, 0.4040070684461441, 2.351831380989509, 2.748612213507844, 3.133002890683667, -0.6902922380876192, 0.09563473131477442, 2.056490394534053, 2.017507533465959, 2.394015964756036, -0.3466427504049927]
        } else if y > 1500 {
            poly_coefs = [5.097475813506625, 29.53058886049267, 1.095399949433705e-10, -6.926279905270773e-16]
            amp = [0.003064332812182054, 0.8973816160666801, 0.03119866094731004, 0.07068988004978655, 0.0001583070735157395, 0.1762683983928151, 0.0004131592685474231, 0.005950873973350208, 0.008489324571543966, 0.00334306526160656, 0.00052946042568393, 0.003743585488835091, 0.2156913373736315, 44576.30467073629, 0.1050203948601217, 0.01883710371633125, 0.380047745859265, 0.0003472930592917774, 0.009225665415301823, 0.002061407071938891, 0.001454599562245767, 5.856419090840883e-05, 0.0007688706809666596, 0.001415547168551922]
            ph = [-0.0003231124735555465, 0.380955331199635, 0.762645225819612, 1.4676293538949, -2.15595770830073, -0.3633370464549665, 1.134950591549256, -2.808169363709888, 0.422381840383887, -0.4226859182049138, -3.091797336860658, 0.7563140142610324, -0.3787677293480213, 1.863828515720658e-10, 0.3794794147818532, -0.7671105159156101, -0.3850942687637987, -3.098506117162865, -0.6738173539748421, 0.09011906278589261, 2.089832317302934, 2.160228985413543, -0.6734226930504117, -0.3333652792566645]
        } else {
            poly_coefs = []
            amp = []
            ph = []
        }

        let jd0 = getJD(yyyy: y - 1, mm: 12, dd: 31) - 1.0 / 3
        let delta_T = DeltaT(T: (jd0 - 2451545 + 365.25 * 0.5) / 36525)
        let offset = 2451545 - jd0 - delta_T
        let lsyn = 29.5306
        let p0 = lunar_comp[0]
        let jdL0 = 2451550.259469 + 0.5 * Double(p0) * lsyn

        // Find the lunation number of the first moon phase in the year
        var Lm0 = floor((jd0 + 1 - jdL0) / lsyn) - 1
        var Lm: Double = 0
        var s: Double = 0
        var s1 = 0
        for i in 0..<10 {
            Lm = Lm0 + 0.5 * Double(p0) + Double(i)
            s = poly_coefs[0] + offset + Lm * (poly_coefs[1] + Lm * (poly_coefs[2] + Lm * poly_coefs[3]))
            for j in 0..<24 {
                let ang = mod2pi_de(x: w[j] * Lm) + ph[j]
                s += amp[j] * sin(ang)
            }
            s1 = Int((s - floor(s)) * 1440 + 0.5)
            s = Double(s1) + 1441 * floor(s) + Double(lunar_comp[1]) - Double(offset_comp)
            if s > 1440 {
                break
            }
        }
        Lm0 = Lm
        var mphase = [Date]()
        // Now decompress the remaining moon-phase times
        for i in 1..<lunar_comp.count {
            Lm = Lm0 + Double(i - 1) * dp
            s = poly_coefs[0] + offset + Lm * (poly_coefs[1] + Lm * (poly_coefs[2] + Lm * poly_coefs[3]))
            for j in 0..<24 {
                let ang = mod2pi_de(x: w[j] * Lm) + ph[j]
                s += amp[j] * sin(ang)
            }
            s1 = Int((s - floor(s)) * 1440 + 0.5)
            let datetime = s1 + 1441 * Int(floor(s)) + Int(lunar_comp[i]) - offset_comp
            let day = datetime.quotient(rhs: 1441)
            let hourminute = datetime - 1441 * day
            let hour = hourminute.quotient(rhs: 60)
            let minute = hourminute - 60 * hour
            let timezone = Calendar.beijingTime

            let the_date = Date.from(year: y, month: 1, day: day, hour: hour, minute: minute, timezone: timezone)
            mphase.append(the_date!)
        }
        return mphase
    }

    func solar_terms_in_year(_ year: Int) -> [Date] {
        // year in [1900, 3000]
        return decode_solar_terms(y: year, istart: 0, offset_comp: 5, solar_comp: sunData[year - 1900])
    }

    func moon_phase_in_year(_ year: Int) -> ([Date], Int8) {
        // year in [1900, 3000]
        return (decode_moon_phases(y: year, offset_comp: 5, lunar_comp: moonData[year - 1900], dp: 0.5), moonData[year - 1900][0])
    }
}

// MARK: Planet Model - Private
private extension ChineseCalendar {
    enum RiseSetType {
        case sunrise, sunset, moonrise, moonset
    }
    enum MeridianType {
        case noon, midnight, highMoon, lowMoon
    }

    func riseSetTime(around time: Date, at loc: GeoLocation, type: RiseSetType, iteration: Int = 0) -> Date? {
        let solarSystem: SolarSystem
        let planet: SolarSystem.Planet
        switch type {
        case .sunrise, .sunset:
            solarSystem = SolarSystem(time: time, loc: loc, targets: .sun)
            planet = solarSystem.planets.sun
        case .moonrise, .moonset:
            solarSystem = SolarSystem(time: time, loc: loc, targets: .sunMoon)
            planet = solarSystem.planets.moon
        }
        let timeUntilNoon = SolarSystem.normalize(radian: planet.loc.ra - solarSystem.localSiderialTime!)
        let solarHeight = -planet.diameter / 2 - SolarSystem.aeroAdj
        let localHourAngle = (sin(solarHeight) - sin(loc.lat / 180 * Double.pi) * sin(planet.loc.decl)) / (cos(loc.lat / 180 * Double.pi) * cos(planet.loc.decl))

        if abs(localHourAngle) < 1 || iteration < 3 {
            let netTime = switch type {
            case .sunrise, .moonrise:
                timeUntilNoon - acos(min(1, max(-1, localHourAngle)))
            case .sunset, .moonset:
                timeUntilNoon + acos(min(1, max(-1, localHourAngle)))
            }
            let dTime = netTime / Double.pi * 43082.04
            if abs(dTime) < 14.4 && abs(localHourAngle) < 1 {
                return time
            } else {
                return riseSetTime(around: time + dTime, at: loc, type: type, iteration: iteration + 1)
            }
        } else {
            return nil
        }
    }

    func meridianTime(around time: Date, at loc: GeoLocation, type: MeridianType, iteration: Int = 0) -> Date? {
        let solarSystem: SolarSystem
        let planet: SolarSystem.Planet
        switch type {
        case .noon, .midnight:
            solarSystem = SolarSystem(time: time, loc: loc, targets: .sun)
            planet = solarSystem.planets.sun
        case .highMoon, .lowMoon:
            solarSystem = SolarSystem(time: time, loc: loc, targets: .sunMoon)
            planet = solarSystem.planets.moon
        }
        let offset = switch type {
        case .noon, .highMoon:
            0.0
        case .midnight, .lowMoon:
            Double.pi
        }
        let timeUntilNoon = SolarSystem.normalize(radian: planet.loc.ra - solarSystem.localSiderialTime! + offset)

        let dTime = timeUntilNoon / Double.pi * 43082.04
        if abs(dTime) < 14.4 {
            let latInRadian = loc.lat * Double.pi / 180
            let localHourAngle = solarSystem.localSiderialTime! - planet.loc.ra
            let solarHeightSin = sin(latInRadian) * sin(planet.loc.decl) + cos(latInRadian) * cos(planet.loc.decl) * cos(localHourAngle)
            let solarHeight = asin(solarHeightSin)
            let solarHeightMin = -planet.diameter / 2 - SolarSystem.aeroAdj
            switch type {
            case .noon, .highMoon:
                if solarHeight >= solarHeightMin {
                    return time
                } else {
                    return nil
                }
            case .midnight, .lowMoon:
                if solarHeight < solarHeightMin {
                    return time
                } else {
                    return nil
                }
            }
        } else {
            return meridianTime(around: time + dTime, at: loc, type: type, iteration: iteration + 1)
        }
    }
}

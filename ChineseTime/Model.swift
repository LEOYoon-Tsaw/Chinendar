//
//  Model.swift
//  ChineseTime
//
//  Created by LEO Yoon-Tsaw on 9/21/21.
//

import Foundation

extension Date {
    static func from(year: Int, month: Int, day: Int, hour: Int, minute: Int, timezone: TimeZone?) -> Date? {
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = hour
        dateComponents.minute = minute
        if let timezone = timezone {
            dateComponents.timeZone = timezone
        }
        return Calendar.current.date(from: dateComponents)
    }
    
    func toDate(in timezone: TimeZone?) -> Date? {
        var calendar = Calendar.current
        if let timezone = timezone {
            calendar.timeZone = timezone
        }
        return calendar.date(bySettingHour: 0, minute: 0, second: 0, of: self)
    }
}

extension Int {
    func quotient(rhs: Int) -> Int {
        if self < 0 {
            return (self - (rhs - 1)) / rhs
        } else {
            return self / rhs
        }
    }
}

extension Array {
    func slice(from: Int = 0, to: Int? = nil, step: Int = 1) -> Self {
        var sliced = Self()
        var i = from
        let limit = to ?? self.count
        while i < limit {
            sliced.append(self[i])
            i += step
        }
        return sliced
    }
}

class ChineseCalendar {
    
    static let beijingTime = TimeZone(identifier: "Asia/Shanghai")
    static let month_chinese = ["冬月", "臘月", "正月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月"]
    static let day_chinese = ["初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十" ,"十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十", "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"]
    static let terrestrial_branches = ["子","丑","寅","卯","辰","巳","午","未","申","酉","戌","亥"]
    static let sub_hour_name = ["初", "正"]
    static let chinese_numbers = ["初", "一", "二", "三", "四", "五"]
    static let evenSolarTermChinese = ["冬　至", "大　寒", "雨　水", "春　分", "穀　雨", "小　滿", "夏　至", "大　暑", "處　暑", "秋　分", "霜　降", "小　雪"]
    static let oddSolarTermChinese = ["小　寒", "立　春", "驚　蟄", "清　明", "立　夏", "芒　種", "小　暑", "立　秋", "白　露", "寒　露", "立　冬", "大　雪"]
    static var globalMonth = false
    
    private let _time: Date
    private let _timezone: TimeZone
    private let _year_length: Double
    private let _month: Int
    private let _day: Int
    private var _evenSolarTerms: [Date]
    private var _oddSolarTerms: [Date]
    private var _moonEclipses: [Date]
    private var _fullMoons: [Date]
    private var _monthNames: [String]
    private var _year_start: Date
    
    private static func getJD(yyyy: Int, mm: Int, dd: Int) -> CGFloat {
        var m1 = mm
        var yy = yyyy
        if m1 <= 2 {
            m1 = m1 + 12
            yy = yy - 1
        }
      // Gregorian calendar
        let b = yy / 400 - yy / 100 + yy / 4
        let jd = CGFloat(365 * yy - 679004 + b) + floor(30.6001 * CGFloat(m1 + 1)) + CGFloat(dd) + 2400000.5
        return jd
    }

    private static func DeltaT_spline_y(_ y: CGFloat) -> CGFloat {
        func phase(x: CGFloat) -> CGFloat {
            let t = x - 1825
            return 0.00314115 * t * t + 284.8435805251424 * cos(0.4487989505128276 * (0.01 * t + 0.75))
        }
        if (y < -720) {
            let const: CGFloat = 1.007739546148514
            return phase(x: y) + const
        } else if (y > 2019) {
            let const: CGFloat = -150.263031657016
            return phase(x: y) + const
        }
        let n = [-720, -100, 400, 1000, 1150, 1300, 1500, 1600, 1650, 1720, 1800, 1810, 1820, 1830, 1840, 1850, 1855, 1860, 1865, 1870, 1875, 1880, 1885, 1890, 1895, 1900, 1905, 1910, 1915, 1920, 1925, 1930, 1935, 1940, 1945, 1950, 1953, 1956, 1959, 1962, 1965, 1968, 1971, 1974, 1977, 1980, 1983, 1986, 1989, 1992, 1995, 1998, 2001, 2004, 2007, 2010, 2013, 2016]

        var l = n.count
        while l >= 0 && !(y >= CGFloat(n[l])) {
            l -= 1
        }
        
        let year_splits = [-100, 400, 100, 1150, 1300, 1500, 1600, 1650, 1720, 1800, 1810, 1820, 1830, 1840, 1850, 1855, 1860, 1865, 1870, 1875, 1880, 1885, 1890, 1895, 1900, 1905, 1910, 1915, 1920, 1925, 1930, 1935, 1940, 1945, 1950, 1953, 1956, 1959, 1962, 1965, 1968, 1971, 1974, 1977, 1980, 1983, 1986, 1989, 1992, 1995, 1998, 2001, 2004, 2007, 2010, 2013, 2016, 2019]
        let r = (y - CGFloat(n[l])) / CGFloat(year_splits[l] - n[l])
        let coef1: [CGFloat] = [20371.848, 11557.668, 6535.116, 1650.393, 1056.647, 681.149, 292.343, 109.127, 43.952, 12.068, 18.367, 15.678, 16.516, 10.804, 7.634, 9.338, 10.357, 9.04, 8.255, 2.371, -1.126, -3.21, -4.388, -3.884, -5.017, -1.977, 4.923, 11.142, 17.479, 21.617, 23.789, 24.418, 24.164, 24.426, 27.05, 28.932, 30.002, 30.76, 32.652, 33.621, 35.093, 37.956, 40.951, 44.244, 47.291, 50.361, 52.936, 54.984, 56.373, 58.453, 60.678, 62.898, 64.083, 64.553, 65.197, 66.061, 66.92, 68.109]
        let coef2: [CGFloat] = [-9999.586, -5822.27, -5671.519, -753.21, -459.628, -421.345, -192.841, -78.697, -68.089, 2.507, -3.481, 0.021, -2.157, -6.018, -0.416, 1.642, -0.486, -0.591, -3.456, -5.593, -2.314, -1.893, 0.101, -0.531, 0.134, 5.715, 6.828, 6.33, 5.518, 3.02, 1.333, 0.052, -0.419, 1.645, 2.499, 1.127, 0.737, 1.409, 1.577, 0.868, 2.275, 3.035, 3.157, 3.199, 3.069, 2.878, 2.354, 1.577, 1.648, 2.235, 2.324, 1.804, 0.674, 0.466, 0.804, 0.839, 1.007, 1.277]
        let coef3: [CGFloat] = [776.247, 1303.151, -298.291, 184.811, 108.771, 61.953, -6.572, 10.505, 38.333, 41.731, -1.126, 4.629, -6.806, 2.944, 2.658, 0.261, -2.389, 2.284, -5.148, 3.011, 0.269, 0.152, 1.842, -2.474, 3.138, 2.443, -1.329, 0.831, -1.643, -0.856, -0.831, -0.449, -0.022, 2.086, -1.232, 0.22, -0.61, 1.282, -1.115, 0.406, 1.002, -0.242, 0.364, -0.323, 0.193, -0.384, -0.14, -0.637, 0.708, -0.121, 0.21, -0.729, -0.402, 0.194, 0.144, -0.109, 0.277, -0.007]
        let coef4: [CGFloat] = [409.16, -503.433, 1085.087, -25.346, -24.641, -29.414, 16.197, 3.018, -2.127, -37.939, 1.918, -3.812, 3.25, -0.096, -0.539, -0.883, 1.558, -2.477, 2.72, -0.914, -0.039, 0.563, -1.438, 1.871, -0.232, -1.257, 0.72, -0.825, 0.262, 0.008, 0.127, 0.142, 0.702, -1.106, 0.614, -0.277, 0.631, -0.799, 0.507, 0.199, -0.414, 0.202, -0.229, 0.172, -0.192, 0.081, -0.165, 0.448, -0.276, 0.11, -0.313, 0.109, 0.199, -0.017, -0.084, 0.128, -0.095, -0.139]
        return coef1[l] + r * (coef2[l] + r * (coef3[l] + r * coef4[l]))
    }
    // UT -> TT
    private static func DeltaT(T: CGFloat) -> CGFloat {
        let t = 36525 * T + 2451545
        if (t > 2459580.5 || t < 2441317.5) {
            return DeltaT_spline_y(t >= 2299160.5 ? (t - 2451544.5) / 365.2425 + 2000 : (t + 0.5) / 365.25 - 4712) / 86400.0
        }
        let l: [CGFloat] = [2457754.5, 2457204.5, 2456109.5, 2454832.5, 2453736.5, 2451179.5, 2450630.5, 2450083.5, 2449534.5, 2449169.5, 2448804.5, 2448257.5, 2447892.5, 2447161.5, 2446247.5, 2445516.5, 2445151.5, 2444786.5, 2444239.5, 2443874.5, 2443509.5, 2443144.5, 2442778.5, 2442413.5, 2442048.5, 2441683.5, 2441499.5, 2441133.5]
        let n = l.count
        var DT: CGFloat = 42.184
        for i in 0..<n {
            if (t > l[i]) {
                DT += CGFloat(n - i - 1)
                break
            }
        }
        return DT/86400.0
    }

    private static func mod2pi_de(x: CGFloat) -> CGFloat {
        return x - 2 * CGFloat.pi * floor(0.5 * x/CGFloat.pi + 0.5)
    }
    
    private static func decode_solar_terms(y: Int, istart: Int, offset_comp: Int, solar_comp: [Int8]) -> [Date] {
        let jd0 = getJD(yyyy: y-1,mm: 12,dd: 31) - 1.0/3
        let delta_T = DeltaT(T: (jd0-2451545 + 365.25*0.5)/36525)
        let offset = 2451545 - jd0 - delta_T
        let w: [CGFloat] = [2*CGFloat.pi, 6.282886, 12.565772, 0.337563, 83.99505, 77.712164, 5.7533, 3.9301]
        let poly_coefs: [CGFloat]
        let amp: [CGFloat]
        let ph: [CGFloat]
        if (y > 2500) {
            poly_coefs = [-10.60617210417765, 365.2421759265393, -2.701502510496315e-08, 2.303900971263569e-12]
            amp = [0.1736157870707964, 1.914572713893651, 0.0113716862045686, 0.004885711219368455, 0.0004032584498264633, 0.001736052092601642, 0.002035081600709588, 0.001360448706185977]
            ph = [-2.012792258215681, 2.824063083728992, -0.4826844382278376, 0.9488391363261893, 2.646697770061209, -0.2675341497460084, 0.9646288791219602, -1.808852094435626]
        } else if (y > 1500) {
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
            let Ls = CGFloat(y - 2000) + CGFloat(i + istart)/24.0
            var s = poly_coefs[0] + offset + Ls*(poly_coefs[1] + Ls*(poly_coefs[2] + Ls*poly_coefs[3]))
            for j in 0..<8 {
                let ang = mod2pi_de(x: w[j] * Ls) + ph[j]
                s += amp[j] * sin(ang)
            }
            let s1 = Int((s-floor(s))*1440 + 0.5)
            let datetime = s1 + 1441 * Int(floor(s)) + Int(solar_comp[i]) - offset_comp
            let day = datetime.quotient(rhs: 1441)
            let hourminute = datetime - 1441 * day
            let hour = hourminute.quotient(rhs: 60)
            let minute = hourminute - 60 * hour
            
            let timezone = beijingTime
            let the_date = Date.from(year: y, month: 1, day: day, hour: hour, minute: minute, timezone: timezone)
            sterm.append(the_date!)
        }
        return sterm
    }

    private static func decode_moon_phases(y: Int, offset_comp: Int, lunar_comp: [Int8], dp: CGFloat) -> [Date] {
        let w = [2*CGFloat.pi, 6.733776, 13.467552, 0.507989, 0.0273143, 0.507984, 20.201328, 6.225791, 7.24176, 5.32461, 12.058386, 0.901181, 5.832595, 12.56637061435917, 19.300146, 11.665189, 18.398965, 6.791174, 13.636974, 1.015968, 6.903198, 13.07437, 1.070354, 6.340578614359172]
        let poly_coefs: [CGFloat]
        let amp: [CGFloat]
        let ph: [CGFloat]
        if (y > 2500) {
            poly_coefs = [5.093879710922470, 29.53058981687484, 2.670339910922144e-11, 1.807808217274283e-15]
            amp = [0.00306380948959271, 6.08567588841838, 0.3023856209133756, 0.07481389897992345, 0.0001587661348338354, 0.1740759063081489, 0.0004131985233772993, 0.005796584475300004, 0.008268929076163079, 0.003256244384807976, 0.000520983165608148, 0.003742624708965854, 1.709506053530008, 28216.70389751519, 1.598844831045378, 0.314745599206173, 6.602993931108911, 0.0003387269181720862, 0.009226112317341887, 0.00196073145843697, 0.001457643607929487, 6.467401779992282e-05, 0.0007716739483064076, 0.001378880922256705]
            ph = [-0.0001879456766404132, -2.745704167588171, -2.348884895288619, 1.420037528559222, -2.393586904955103, -0.3914194006325855, 1.183088056748942, -2.782692143601458, 0.4430565056744425, -0.4357413971405519, -3.081209195003025, 0.7945051912707899, -0.4010911170136437, 3.003035462639878e-10, 0.4040070684461441, 2.351831380989509, 2.748612213507844, 3.133002890683667, -0.6902922380876192, 0.09563473131477442, 2.056490394534053, 2.017507533465959, 2.394015964756036, -0.3466427504049927]
        } else if (y > 1500) {
            poly_coefs = [5.097475813506625, 29.53058886049267, 1.095399949433705e-10, -6.926279905270773e-16]
            amp = [0.003064332812182054, 0.8973816160666801, 0.03119866094731004, 0.07068988004978655, 0.0001583070735157395, 0.1762683983928151, 0.0004131592685474231, 0.005950873973350208, 0.008489324571543966, 0.00334306526160656, 0.00052946042568393, 0.003743585488835091, 0.2156913373736315, 44576.30467073629, 0.1050203948601217, 0.01883710371633125, 0.380047745859265, 0.0003472930592917774, 0.009225665415301823, 0.002061407071938891, 0.001454599562245767, 5.856419090840883e-05, 0.0007688706809666596, 0.001415547168551922]
            ph = [-0.0003231124735555465, 0.380955331199635, 0.762645225819612, 1.4676293538949, -2.15595770830073, -0.3633370464549665, 1.134950591549256, -2.808169363709888, 0.422381840383887, -0.4226859182049138, -3.091797336860658, 0.7563140142610324, -0.3787677293480213, 1.863828515720658e-10, 0.3794794147818532, -0.7671105159156101, -0.3850942687637987, -3.098506117162865, -0.6738173539748421, 0.09011906278589261, 2.089832317302934, 2.160228985413543, -0.6734226930504117, -0.3333652792566645]
        } else {
            poly_coefs = []
            amp = []
            ph = []
        }

        let jd0 = getJD(yyyy: y-1,mm: 12,dd: 31) - 1.0/3
        let delta_T = DeltaT(T: (jd0-2451545 + 365.25*0.5)/36525)
        let offset = 2451545 - jd0 - delta_T
        let lsyn: CGFloat = 29.5306
        let p0 = lunar_comp[0]
        let jdL0 = 2451550.259469 + 0.5*CGFloat(p0)*lsyn

        // Find the lunation number of the first moon phase in the year
        var Lm0 = floor((jd0 + 1 - jdL0)/lsyn)-1
        var Lm: CGFloat = 0
        var s: CGFloat = 0
        var s1: Int = 0
        for i in 0..<10 {
            Lm = Lm0 + 0.5*CGFloat(p0) + CGFloat(i)
            s = poly_coefs[0] + offset + Lm*(poly_coefs[1] + Lm*(poly_coefs[2] + Lm*poly_coefs[3]))
            for j in 0..<24 {
                let ang = mod2pi_de(x: w[j]*Lm) + ph[j]
                s += amp[j] * sin(ang)
            }
            s1 = Int((s-floor(s))*1440 + 0.5)
            s = CGFloat(s1) + 1441*floor(s) + CGFloat(lunar_comp[1]) - CGFloat(offset_comp)
            if (s > 1440) {
                break
            }
        }
        Lm0 = Lm
        var mphase = [Date]()
        // Now decompress the remaining moon-phase times
        for i in 1..<lunar_comp.count {
            Lm = Lm0 + CGFloat((i-1))*dp
            s = poly_coefs[0] + offset + Lm*(poly_coefs[1] + Lm*(poly_coefs[2] + Lm*poly_coefs[3]))
            for j in 0..<24 {
                let ang = mod2pi_de(x: w[j]*Lm) + ph[j]
                s += amp[j] * sin(ang)
            }
            s1 = Int((s-floor(s))*1440 + 0.5)
            let datetime = s1 + 1441 * Int(floor(s)) + Int(lunar_comp[i]) - offset_comp
            let day = datetime.quotient(rhs: 1441)
            let hourminute = datetime - 1441 * day
            let hour = hourminute.quotient(rhs: 60)
            let minute = hourminute - 60 * hour
            let timezone = beijingTime
            
            let the_date = Date.from(year: y, month: 1, day: day, hour: hour, minute: minute, timezone: timezone)
            mphase.append(the_date!)
        }
        return mphase
    }

    private static func solar_terms_in_year(_ year: Int) -> [Date] {
        // year in [1900, 3000]
        return decode_solar_terms(y: year, istart: 0, offset_comp: 5, solar_comp: sunData[year - 1900])
    }

    private static func moon_phase_in_year(_ year: Int) -> ([Date], Int8) {
        // year in [1900, 3000]
        return (decode_moon_phases(y: year, offset_comp: 5, lunar_comp: moonData[year - 1900], dp: 0.5), moonData[year - 1900][0])
    }

    private static func ranked_index(date: Date, dates: [Date], timezone: TimeZone) -> (Int, Int) {
        var i = 0
        while i < dates.count {
            if dates[i].toDate(in: timezone)! > date.toDate(in: timezone)! {
                break
            }
            i += 1
        }
        let date_diff = dates[i - 1].toDate(in: timezone)!.distance(to: date.toDate(in: timezone)!)
        return (i - 1, Int(floor(date_diff / 3600 / 24 + 0.5)))
    }

    private static func to_chinese_cal_local(month: Int, day: Int, chineseCal: ChineseCalendar) -> String {
        let chinese_month = chineseCal.monthNames[month]
        let chinese_day = day_chinese[day]
        return chinese_month + chinese_day
    }

    private static func time_description_chinese(time: Date, timezone: TimeZone) -> String {
        let time_in_seconds = CGFloat(time.toDate(in: timezone)!.distance(to: time))
        let time_in_chinese_minutes = Int(time_in_seconds / 144)
        let chinese_hour_index = time_in_chinese_minutes / 25
        var residual = time_in_chinese_minutes  - chinese_hour_index * 25
        residual += chinese_hour_index % 6
        let percent_day = residual / 6
        let chinese_half_hours = ["初", "正"]
        let chinese_hour = terrestrial_branches[((chinese_hour_index + 1) % 24) / 2] + chinese_half_hours[(chinese_hour_index + 1) % 2]
        let residual_minutes: Int
        let percent_day_chinese = chinese_numbers[percent_day] + "刻"
        if (percent_day > 0) {
            residual_minutes = time_in_chinese_minutes % 6
        } else {
            residual_minutes = time_in_chinese_minutes % 25
        }
        var residual_minutes_chinese = ""
        if (residual_minutes > 0) {
            residual_minutes_chinese = chinese_numbers[residual_minutes]
        }
      return chinese_hour + percent_day_chinese + residual_minutes_chinese
    }
    
    init(time: Date, timezone: TimeZone) {
        self._time = time
        self._timezone = timezone
        var year = Calendar.current.component(.year, from: time)
        var solar_terms = Self.solar_terms_in_year(year + 1)
        if solar_terms[0] <= time {
            year += 1
            solar_terms += Self.solar_terms_in_year(year + 1)[0..<3]
        } else {
            var solar_terms_current_year = Self.solar_terms_in_year(year)
            solar_terms_current_year += solar_terms[0..<3]
            solar_terms = solar_terms_current_year
        }
        let solar_terms_previous_year = Self.solar_terms_in_year(year - 1)
        
        let (moon_phase_previous_year, first_event) = Self.moon_phase_in_year(year - 1)
        var (moon_phase, _) = Self.moon_phase_in_year(year)
        let (moon_phase_next_year, _) = Self.moon_phase_in_year(year + 1)
        moon_phase = moon_phase_previous_year + moon_phase + moon_phase_next_year
        var eclipse = moon_phase.slice(from: Int(first_event), step: 2)
        var fullMoon = moon_phase.slice(from: Int(1-first_event), step: 2)
        var start: Int? = nil, end: Int? = nil
        for i in 0..<eclipse.count {
            if (start == nil) && (eclipse[i] > solar_terms[0]) {
                start = i-1
            }
            if (end == nil) && (eclipse[i].toDate(in: timezone)! > solar_terms[24]) {
                end = i
            }
        }
        eclipse = Array(eclipse[start!...end!])
        fullMoon = fullMoon.filter { $0 < eclipse.last! && $0 > eclipse[0] }
        let evenSolarTerms = solar_terms.slice(step: 2)
        
        var months = [String]()
        var i = 0
        var j = 0
        var count = 0
        var solatice_in_month = [Int]()
        while (i+1 < eclipse.count) && (j < evenSolarTerms.count) {
            let thisEclipse: Date
            let nextEclipse: Date
            if Self.globalMonth {
                thisEclipse = eclipse[i]
                nextEclipse = eclipse[i+1]
            } else {
                thisEclipse = eclipse[i].toDate(in: _timezone)!
                nextEclipse = eclipse[i+1].toDate(in: _timezone)!
            }
            if ((thisEclipse <= evenSolarTerms[j]) && (nextEclipse > evenSolarTerms[j])) {
                count += 1
                j += 1
            } else {
                solatice_in_month.append(count)
                count = 0
                i += 1
            }
        }
        let eclipseInYear = eclipse.filter { date in
            let localDate: Date
            if Self.globalMonth {
                localDate = date
            } else {
                localDate = date.toDate(in: timezone)!
            }
            return localDate >= solar_terms[0] && localDate < solar_terms[24]
        }
        if eclipseInYear.count == 12 {
            months = (Self.month_chinese + Self.month_chinese).slice(to: eclipse.count)
        } else {
            solatice_in_month.append(count) // May not be accurate, but inaccuracy will be in next year
            var leap = 0
            var leapLabel = ""
            for i in 0..<solatice_in_month.count {
                if ((solatice_in_month[i] == 0) && leap == 0) {
                    leap = 1
                    leapLabel = "閏"
                } else {
                    leapLabel = ""
                }
                var month_name = leapLabel + Self.month_chinese[(i - leap) % 12]
                if (month_name == "閏正月") {
                    month_name = "閏一月"
                }
                months.append(month_name)
            }
        }
        
        let (month_index, day_index) = Self.ranked_index(date: time, dates: eclipse, timezone: timezone)
        
        self._year_length = solar_terms[0].distance(to: solar_terms[24])
        self._evenSolarTerms = solar_terms.slice(from: 0, step: 2)
        self._evenSolarTerms.insert(solar_terms_previous_year[solar_terms_previous_year.count-2], at: 0)
        self._oddSolarTerms = solar_terms.slice(from: 1, step: 2)
        self._oddSolarTerms.insert(solar_terms_previous_year[solar_terms_previous_year.count-1], at: 0)
        self._moonEclipses = eclipse
        self._monthNames = months
        self._fullMoons = fullMoon
        self._month = month_index
        self._day = day_index
        self._year_start = solar_terms[0]
    }
    var dateString: String {
        Self.to_chinese_cal_local(month: _month, day: _day, chineseCal: self)
    }
    var timeString: String {
        Self.time_description_chinese(time: _time, timezone: _timezone)
    }
    var evenSolarTerms: [CGFloat] {
        var evenSolarTermsPositions = _evenSolarTerms.map { CGFloat(_year_start.distance(to: $0) / _year_length) }
        evenSolarTermsPositions = evenSolarTermsPositions.filter { ($0 < 1) && ($0 > 0) }
        return [0] + evenSolarTermsPositions
    }
    var oddSolarTerms: [CGFloat] {
        var oddSolarTermsPositions = _oddSolarTerms.map { CGFloat(_year_start.distance(to: $0) / _year_length) }
        oddSolarTermsPositions = oddSolarTermsPositions.filter { ($0 < 1) && ($0 > 0) }
        return oddSolarTermsPositions
    }
    var monthDivides: [CGFloat] {
        var monthSplitPositions: [CGFloat]
        if Self.globalMonth {
            monthSplitPositions = _moonEclipses.map { CGFloat(_year_start.distance(to: $0) / _year_length) }
        } else {
            monthSplitPositions = _moonEclipses.map { CGFloat(_year_start.distance(to: $0.toDate(in: _timezone)!) / _year_length) }
        }
        monthSplitPositions = monthSplitPositions.filter { ($0 < 1) && ($0 > 0) }
        return monthSplitPositions
    }
    var fullmoon: [CGFloat] {
        _fullMoons.map { CGFloat(_year_start.distance(to: $0) / _year_length) }
    }
    var monthNames: [String] {
        return _monthNames
    }
    var currentDayInYear: CGFloat {
        CGFloat(_year_start.distance(to: _time) / _year_length)
    }
    var currentHour: CGFloat {
        CGFloat(_time.toDate(in: _timezone)!.distance(to: _time)) / 3600
    }
    var currentDay: Int {
        _day + 1
    }
    var daysInMonth: Int {
        Int(_moonEclipses[_month].toDate(in: _timezone)!.distance(to: _moonEclipses[_month+1].toDate(in: _timezone)!) / 3600 / 24 + 0.5)
    }
    var eventInMonth: WatchFaceView.CelestialEvent {
        let monthStart = _moonEclipses[_month].toDate(in: _timezone)!
        let monthLength = 3600 * 24 * daysInMonth
        var event = WatchFaceView.CelestialEvent()
        event.eclipse = _moonEclipses.map { date in
            CGFloat(monthStart.distance(to: date)) / CGFloat(monthLength)
        }.filter { 0 <= $0 && 1 > $0 }
        event.fullMoon = _fullMoons.map { date in
            CGFloat(monthStart.distance(to: date)) / CGFloat(monthLength)
        }.filter { 0 <= $0 && 1 > $0 }
        event.evenSolarTerm = _evenSolarTerms.map { date in
            CGFloat(monthStart.distance(to: date)) / CGFloat(monthLength)
        }.filter { 0 <= $0 && 1 > $0 }
        event.oddSolarTerm = _oddSolarTerms.map { date in
            CGFloat(monthStart.distance(to: date)) / CGFloat(monthLength)
        }.filter { 0 <= $0 && 1 > $0 }
        return event
    }
    var eventInDay: WatchFaceView.CelestialEvent {
        let dayStart = _time.toDate(in: _timezone)!
        var event = WatchFaceView.CelestialEvent()
        event.eclipse = _moonEclipses.map { date in
            CGFloat(dayStart.distance(to: date)) / 3600 / 24
        }.filter { 0 <= $0 && 1 > $0 }
        event.fullMoon = _fullMoons.map { date in
            CGFloat(dayStart.distance(to: date)) / 3600 / 24
        }.filter { 0 <= $0 && 1 > $0 }
        event.evenSolarTerm = _evenSolarTerms.map { date in
            CGFloat(dayStart.distance(to: date)) / 3600 / 24
        }.filter { 0 <= $0 && 1 > $0 }
        event.oddSolarTerm = _oddSolarTerms.map { date in
            CGFloat(dayStart.distance(to: date)) / 3600 / 24
        }.filter { 0 <= $0 && 1 > $0 }
        return event
    }
    var eventInHour: WatchFaceView.CelestialEvent {
        let dayStart = _time.toDate(in: _timezone)!
        let hourStart = dayStart.addingTimeInterval(Double(floor(self.currentHour / 2) * 7200))
        var event = WatchFaceView.CelestialEvent()
        event.eclipse = _moonEclipses.map { date in
            CGFloat(hourStart.distance(to: date)) / 7200
        }.filter { 0 <= $0 && 1 > $0 }
        event.fullMoon = _fullMoons.map { date in
            CGFloat(hourStart.distance(to: date)) / 7200
        }.filter { 0 <= $0 && 1 > $0 }
        event.evenSolarTerm = _evenSolarTerms.map { date in
            CGFloat(hourStart.distance(to: date)) / 7200
        }.filter { 0 <= $0 && 1 > $0 }
        event.oddSolarTerm = _oddSolarTerms.map { date in
            CGFloat(hourStart.distance(to: date)) / 7200
        }.filter { 0 <= $0 && 1 > $0 }
        return event
    }
}

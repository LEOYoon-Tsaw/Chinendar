//
//  Locale.swift
//  Chinendar
//
//  Created by Leo Liu on 8/18/23.
//

import Foundation

extension Locale {
    static var isEastAsian: Bool {
        let languages = Locale.preferredLanguages
        var isEastAsian = true
        for language in languages {
            let flag = language[language.startIndex..<language.index(language.startIndex, offsetBy: 2)]
            if flag == "en" {
                isEastAsian = false
                break
            } else if ["zh", "ko", "ja"].contains(flag) {
                isEastAsian = true
                break
            }
        }
        return isEastAsian
    }

    private static let translation: [String: LocalizedStringResource] = [
        "夜中": "夜中", "日出": "日出", "日中": "日中", "日入": "日入",
        "月出": "月出", "月中": "月中", "月入": "月入",
        "朔": "朔", "望": "望",
        "冬至": "冬至", "大寒": "大寒", "雨水": "雨水", "春分": "春分", "穀雨": "穀雨", "小滿": "小滿", "夏至": "夏至", "大暑": "大暑", "處暑": "處暑", "秋分": "秋分", "霜降": "霜降", "小雪": "小雪",
        "小寒": "小寒", "立春": "立春", "驚蟄": "驚蟄", "清明": "清明", "立夏": "立夏", "芒種": "芒種", "小暑": "小暑", "立秋": "立秋", "白露": "白露", "寒露": "寒露", "立冬": "立冬", "大雪": "大雪",
        "辰星": "辰星", "太白": "太白", "熒惑": "熒惑", "歲星": "歲星", "填星": "填星", "太陰": "太陰",
        "元旦": "元旦", "上元": "上元", "春社": "春社", "上巳": "上巳", "端午": "端午", "七夕": "七夕", "中元": "中元", "重陽": "重陽", "中秋": "中秋", "下元": "下元", "臘祭": "臘祭", "除夕": "除夕",
    ]
    
    static func translate(_ original: String) -> String {
        var processed = original
        if ChineseCalendar.oddSolarTermChinese.contains(processed) || ChineseCalendar.evenSolarTermChinese.contains(processed) {
            processed = processed.replacingOccurrences(of: "　", with: "")
        }
        return if let translated = translation[processed] {
            String(localized: translated)
        } else {
            processed
        }
    }
}

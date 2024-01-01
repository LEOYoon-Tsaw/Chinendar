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
    
    static let translation: [String : String] = [
        "夜中": NSLocalizedString("夜中", comment: ""), "日出": NSLocalizedString("日出", comment: ""), "日中": NSLocalizedString("日中", comment: ""), "日入": NSLocalizedString("日入", comment: ""),
        "月出": NSLocalizedString("月出", comment: ""), "月中": NSLocalizedString("月中", comment: ""), "月入": NSLocalizedString("月入", comment: ""),
        "朔": NSLocalizedString("朔", comment: ""), "望": NSLocalizedString("望", comment: ""),
        "冬至": NSLocalizedString("冬至", comment: ""), "大寒": NSLocalizedString("大寒", comment: ""), "雨水": NSLocalizedString("雨水", comment: ""), "春分": NSLocalizedString("春分", comment: ""), "穀雨": NSLocalizedString("穀雨", comment: ""), "小滿": NSLocalizedString("小滿", comment: ""), "夏至": NSLocalizedString("夏至", comment: ""), "大暑": NSLocalizedString("大暑", comment: ""), "處暑": NSLocalizedString("處暑", comment: ""), "秋分": NSLocalizedString("秋分", comment: ""), "霜降": NSLocalizedString("霜降", comment: ""), "小雪": NSLocalizedString("小雪", comment: ""),
        "小寒": NSLocalizedString("小寒", comment: ""), "立春": NSLocalizedString("立春", comment: ""), "驚蟄": NSLocalizedString("驚蟄", comment: ""), "清明": NSLocalizedString("清明", comment: ""), "立夏": NSLocalizedString("立夏", comment: ""), "芒種": NSLocalizedString("芒種", comment: ""), "小暑": NSLocalizedString("小暑", comment: ""), "立秋": NSLocalizedString("立秋", comment: ""), "白露": NSLocalizedString("白露", comment: ""), "寒露": NSLocalizedString("寒露", comment: ""), "立冬": NSLocalizedString("立冬", comment: ""), "大雪": NSLocalizedString("大雪", comment: ""),
        "辰": NSLocalizedString("辰", comment: ""), "太白": NSLocalizedString("太白", comment: ""), "熒惑": NSLocalizedString("熒惑", comment: ""), "歲": NSLocalizedString("歲", comment: ""), "填": NSLocalizedString("填", comment: ""), "月": NSLocalizedString("月", comment: "")

    ]
}

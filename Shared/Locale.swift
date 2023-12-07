//
//  Locale.swift
//  Chinendar
//
//  Created by Leo Liu on 8/18/23.
//

import Foundation

extension Locale {
    static var isChinese: Bool {
        let languages = Locale.preferredLanguages
        var isChinese = true
        for language in languages {
            let flag = language[language.startIndex..<language.index(language.startIndex, offsetBy: 2)]
            if flag == "en" {
                isChinese = false
                break
            } else if flag == "zh" {
                isChinese = true
                break
            }
        }
        return isChinese
    }
    
    static let translation = [
        "夜中": "Midnight", "日出": "Sunrise", "日中": "Solar Noon", "日入": "Sunset",
        "月出": "Moonrise", "月中": "Lunar Noon", "月入": "Moonset",
        "朔": "New Moon", "望": "Full Moon",
        "冬至": "Winter Solstice", "大寒": "Win Sol + 2", "雨水": "Ver Eqn - 2", "春分": "Vernal Equinox", "穀雨": "Ver Eqn + 2", "小滿": "Sum Sol - 2", "夏至": "Summer Solstice", "大暑": "Sum Sol + 2", "處暑": "Aut Eqn - 2", "秋分": "Autumnal Equinox", "霜降": "Aut Eqn + 2", "小雪": "Win Sol - 2",
        "小寒": "Win Sol + 1", "立春": "Spring Begins", "驚蟄": "Ver Eqn - 1", "清明": "Ver Eqn + 1", "立夏": "Summer Begins", "芒種": "Sum Sol - 1", "小暑": "Sum Sol + 1", "立秋": "Autumn Begins", "白露": "Aut Eqn - 1", "寒露": "Aut Eqn + 1", "立冬": "Winter Begins", "大雪": "Win Sol - 1",
        "辰": "Mercury", "太白": "Venus", "熒惑": "Mars", "歲": "Jupiter", "填": "Saturn", "月": "Moon"
    ]
}

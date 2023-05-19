//
//  MarkdownParser.swift
//  Chinese Time
//
//  Created by Leo Liu on 4/29/23.
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
    static let evenSolarTermChinese = ["冬　至", "大　寒", "雨　水", "春　分", "穀　雨", "小　滿", "夏　至", "大　暑", "處　暑", "秋　分", "霜　降", "小　雪"]
    static let oddSolarTermChinese = ["小　寒", "立　春", "驚　蟄", "清　明", "立　夏", "芒　種", "小　暑", "立　秋", "白　露", "寒　露", "立　冬", "大　雪"]
    
    static let dayTimeName = ["夜中", "日出", "日中", "日入"]
    static let moonTimeName = ["月出", "月中", "月入"]
    static let MoonPhases = ["朔", "望"]
    
    static let translation = [
        "夜中": "Midnight", "日出": "Sunrise", "日中": "Solar Noon", "日入": "Sunset",
        "月出": "Moonrise", "月中": "Lunar Noon", "月入": "Moonset",
        "朔": "New Moon", "望": "Full Moon",
        "冬至": "Winter Solstice", "大寒": "Winter Solstice + 2", "雨水": "Vernal Equinox - 2", "春分": "Vernal Equinox", "穀雨": "Vernal Equinox + 2", "小滿": "Summer Solstice - 2", "夏至": "Summer Solstice", "大暑": "Summer Solstice + 2", "處暑": "Autumnal Equinox - 2", "秋分": "Autumnal Equinox", "霜降": "Autumnal Equinox + 2", "小雪": "Winter Solstice - 2",
        "小寒": "Winter Solstice + 1", "立春": "Start of Spring", "驚蟄": "Vernal Equinox - 1", "清明": "Vernal Equinox + 1", "立夏": "Start of Summer", "芒種": "Summer Solstice - 1", "小暑": "Summer Solstice + 1", "立秋": "Start of Autumn", "白露": "Autumnal Equinox - 1", "寒露": "Autumnal Equinox + 1", "立冬": "Start of Winter", "大雪": "Winter Solstice - 1",
        "辰": "Mercury", "太白": "Venus", "熒惑": "Mars", "歲": "Jupiter", "填": "Saturn", "月": "Moon"
    ]
}

let helpString: String = NSLocalizedString("介紹全文", comment: "Markdown formatted Wiki")

enum MarkdownElement {
    case heading(level: Int, text: String)
    case paragraph(text: String)
}

final class MarkdownParser {
    func parse(_ markdownString: String) -> [MarkdownElement] {
        var elements: [MarkdownElement] = []
        var lines = markdownString.components(separatedBy: .newlines)
        var currentParagraph: String?
        
        while !lines.isEmpty {
            let line = lines.removeFirst()
            
            if let headingLevel = headingLevel(for: line) {
                if let paragraph = currentParagraph {
                    elements.append(.paragraph(text: paragraph))
                    currentParagraph = nil
                }
                elements.append(.heading(level: headingLevel, text: headingText(for: line, with: headingLevel)))
            } else {
                if currentParagraph == nil {
                    currentParagraph = line
                } else {
                    currentParagraph?.append("\n\(line)")
                }
            }
        }
        
        if let paragraph = currentParagraph {
            elements.append(.paragraph(text: paragraph))
        }
        
        return elements
    }
    
    private func headingLevel(for line: String) -> Int? {
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let firstCharacter = trimmedLine.first else { return nil }
        guard firstCharacter == "#" else { return nil }
        
        var count = 0
        for char in trimmedLine {
            if char == "#" {
                count += 1
            } else {
                break
            }
        }
        
        return min(count, 6)
    }
    
    private func headingText(for line: String, with level: Int) -> String {
        let startIndex = line.index(line.startIndex, offsetBy: level)
        let trimmedLine = line[startIndex...].trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedLine
    }
}

extension String {
    var boldRanges: [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var startIndex = self.startIndex
        while startIndex < endIndex, let range = self[startIndex...].range(of: "**") {
            startIndex = range.upperBound
            if let range2 = self[startIndex...].range(of: "**") {
                ranges.append(range.upperBound..<range2.lowerBound)
                startIndex = range2.upperBound
            }
        }
        return ranges
    }
}

final class DataTree: CustomStringConvertible {
    var nodeName: String
    private var offsprings: [DataTree]
    private var registry: [String: Int]
    
    init(name: String) {
        nodeName = name
        offsprings = []
        registry = [:]
    }
    
    func add(element: String) -> DataTree {
        let data: DataTree
        if let index = registry[element] {
            data = offsprings[index]
        } else {
            registry[element] = offsprings.count
            offsprings.append(DataTree(name: element))
            data = offsprings.last!
        }
        return data
    }
    
    func contains(element: String) -> Bool {
        return registry[element] != nil
    }
    
    var count: Int {
        offsprings.count
    }
    
    subscript(element: String) -> DataTree? {
        if let index = registry[element] {
            return offsprings[index]
        } else {
            return nil
        }
    }

    func index(of element: String) -> Int? {
        return registry[element]
    }

    subscript(index: Int) -> DataTree? {
        if (0..<offsprings.count).contains(index) {
            return offsprings[index]
        } else {
            return nil
        }
    }
    
    var maxLevel: Int {
        if offsprings.count == 0 {
            return 0
        } else {
            return offsprings.map { $0.maxLevel }.reduce(0) { max($0, $1) } + 1
        }
    }
    
    var description: String {
        var string: String
        if offsprings.count > 0 {
            string = "{\(nodeName): "
        } else {
            string = "\(nodeName)"
        }
        for offspring in offsprings {
            string += offspring.description
        }
        if offsprings.count > 0 {
            string += "}, "
        } else {
            string += ","
        }
        return string
    }
}

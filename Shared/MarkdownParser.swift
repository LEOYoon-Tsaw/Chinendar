//
//  MarkdownParser.swift
//  Chinese Time
//
//  Created by Leo Liu on 4/29/23.
//

import Foundation

enum MarkdownElement {
    case heading(level: Int, text: String)
    case paragraph(text: String)
}

class MarkdownParser {
    
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
        while startIndex < self.endIndex, let range = self[startIndex...].range(of: "**") {
            startIndex = range.upperBound
            if let range2 = self[startIndex...].range(of: "**") {
                ranges.append(range.upperBound..<range2.lowerBound)
                startIndex = range2.upperBound
            }
        }
        return ranges
    }

}
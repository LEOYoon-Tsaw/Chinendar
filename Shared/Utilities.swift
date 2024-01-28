//
//  Utilities.swift
//  Chinendar
//
//  Created by Leo Liu on 4/29/23.
//

import Foundation

let helpString: String = NSLocalizedString("介紹全文", comment: "Markdown formatted Wiki")

enum MarkdownElement {
    case heading(_: AttributedString)
    case paragraph(_: [AttributedString])
}

final class MarkdownParser {
    func parse(_ markdownString: String) -> [MarkdownElement] {
        var elements: [MarkdownElement] = []
        var currentParagraph: [AttributedString] = []
        let scanner = Scanner(string: markdownString)
        while !scanner.isAtEnd {
            if let line = scanner.scanUpToCharacters(from: .newlines), let attrLine = try? AttributedString(markdown: line) {
                if headingLevel(for: line) > 0 {
                    if !currentParagraph.isEmpty {
                        elements.append(.paragraph(currentParagraph))
                        currentParagraph = []
                    }
                    elements.append(.heading(attrLine))
                } else {
                    currentParagraph.append(attrLine)
                }
            }
        }
        
        if !currentParagraph.isEmpty {
            elements.append(.paragraph(currentParagraph))
        }
        
        return elements
    }
    
    private func headingLevel(for line: String) -> Int {
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedLine.count > 0 else { return 0 }
        var index = trimmedLine.startIndex
        var count = 0
        while index < trimmedLine.endIndex && trimmedLine[index] == "#" {
            count += 1
            index = trimmedLine.index(after: index)
        }
        return min(count, 6)
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
    
    var nextLevel: [DataTree] {
        get {
            offsprings
        }
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

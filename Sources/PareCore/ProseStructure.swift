import Foundation

enum ProseStructure {
    static func linesToBlocks(_ rawLines: [String]) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        var paragraph: [String] = []

        func flushParagraph() {
            guard !paragraph.isEmpty else { return }
            let text = paragraph.joined(separator: " ")
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            paragraph = []
            let trimmed = text.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return }
            if case .paragraph(let last)? = blocks.last, last == trimmed {
                return
            }
            blocks.append(.paragraph(trimmed))
        }

        var index = 0
        while index < rawLines.count {
            let line = rawLines[index].trimmingCharacters(in: .whitespaces)
            index += 1

            if line.isEmpty {
                flushParagraph()
                continue
            }
            if let marker = bulletMarker(in: line) {
                flushParagraph()
                let text = String(line.dropFirst(marker.count)).trimmingCharacters(in: .whitespaces)
                if !text.isEmpty { blocks.append(.bullet(text: text, level: 0)) }
                continue
            }
            if let headingLevel = headingLevel(for: line, lines: rawLines, at: index - 1) {
                flushParagraph()
                blocks.append(.heading(level: headingLevel, text: cleanHeading(line)))
                continue
            }
            if let text = orderedItem(in: line) {
                flushParagraph()
                blocks.append(.ordered(text: text, level: 0))
                continue
            }
            if line == "---" || line == "***" || line == "___" {
                flushParagraph()
                blocks.append(.divider)
                continue
            }

            merge(line: line, into: &paragraph, lines: rawLines, at: index - 1)
        }
        flushParagraph()
        return blocks
    }

    private static func merge(line: String, into paragraph: inout [String], lines: [String], at index: Int) {
        if paragraph.isEmpty {
            paragraph.append(line)
            return
        }
        if line.hasPrefix("-") {
            paragraph.append(line)
            return
        }
        let previous = paragraph.last ?? ""
        if previous.hasSuffix("-"),
           let firstChar = line.first,
           firstChar.isLowercase {
            paragraph[paragraph.count - 1] = String(previous.dropLast())
            paragraph[paragraph.count - 1] += line
        } else {
            paragraph.append(line)
        }
    }

    static func bulletMarker(in line: String) -> String? {
        let markers = ["•", "▪", "◦", "‣", "·", "- ", "* ", "– "]
        for marker in markers where line.hasPrefix(marker) {
            return String(marker.dropLast())
        }
        return nil
    }

    static func orderedItem(in line: String) -> String? {
        guard let match = line.firstRange(of: "^\\d{1,3}[.)]\\s+", options: .regularExpression) else {
            return nil
        }
        return String(line[match.upperBound...]).trimmingCharacters(in: .whitespaces)
    }

    static func headingLevel(for line: String, lines: [String], at index: Int) -> Int? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 3, trimmed.count <= 90 else { return nil }
        if trimmed.hasSuffix(".") || trimmed.hasSuffix(",") || trimmed.hasSuffix(";") {
            return nil
        }

        let lowered = trimmed.lowercased()
        for prefix in ["chapter", "section", "part", "appendix", "table of contents"] {
            if lowered.hasPrefix(prefix) {
                return trimmed.count <= 80 ? 2 : nil
            }
        }
        if trimmed.range(of: "^\\d{1,2}(\\.\\d{1,2})+[\\s.:)]+\\S", options: .regularExpression) != nil {
            let depth = trimmed.prefix(while: { $0 == "." || $0.isNumber }).filter { $0 == "." }.count
            return min(4, depth + 1)
        }
        if isAllCaps(trimmed), trimmed.count <= 70 {
            return 2
        }

        let next = index + 1 < lines.count
            ? lines[index + 1].trimmingCharacters(in: .whitespaces)
            : ""
        let previous = index > 0
            ? lines[index - 1].trimmingCharacters(in: .whitespaces)
            : ""
        if next.isEmpty, previous.isEmpty, isTitleCaseSentence(trimmed), trimmed.count <= 60 {
            return 3
        }
        return nil
    }

    static func cleanHeading(_ line: String) -> String {
        line.trimmingCharacters(in: CharacterSet(charactersIn: " .:-\t"))
    }

    private static func isAllCaps(_ text: String) -> Bool {
        let letters = text.filter { $0.isLetter }
        guard letters.count >= 4 else { return false }
        let uppers = letters.filter { $0.isUppercase }
        return uppers.count == letters.count && letters.contains(where: { $0.isUppercase })
    }

    private static func isTitleCaseSentence(_ text: String) -> Bool {
        let words = text.split(separator: " ")
        guard (2...10).contains(words.count) else { return false }
        let significant = words.filter { $0.count > 3 }
        guard !significant.isEmpty else { return false }
        let capitalized = significant.filter { word in
            let first = word.first
            return first?.isUppercase == true
        }
        return Double(capitalized.count) >= Double(significant.count) * 0.7
    }
}

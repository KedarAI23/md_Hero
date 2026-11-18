import Foundation

public enum MarkdownRenderer {
    public static func render(_ blocks: [MarkdownBlock]) -> String {
        var lines: [String] = []
        var orderedCounters: [Int: Int] = [:]
        var previousWasOrdered = false

        for block in blocks {
            switch block {
            case .heading(let level, let text):
                previousWasOrdered = false
                orderedCounters = [:]
                let clamped = max(1, min(6, level))
                lines.append("\(String(repeating: "#", count: clamped)) \(text)")
            case .paragraph(let text):
                previousWasOrdered = false
                lines.append(text)
            case .bullet(let text, let level):
                previousWasOrdered = false
                orderedCounters = [:]
                lines.append("\(indent(for: level))- \(text)")
            case .ordered(let text, let level):
                if !previousWasOrdered {
                    orderedCounters = [:]
                }
                let next = (orderedCounters[level] ?? 0) + 1
                orderedCounters[level] = next
                previousWasOrdered = true
                lines.append("\(indent(for: level))\(next). \(text)")
            case .table(let rows):
                previousWasOrdered = false
                orderedCounters = [:]
                lines.append(tableLines(rows).joined(separator: "\n"))
            case .quote(let text):
                previousWasOrdered = false
                lines.append("> \(text)")
            case .divider:
                previousWasOrdered = false
                lines.append("---")
            }
        }

        return lines.joined(separator: "\n\n") + "\n"
    }

    static func indent(for level: Int) -> String {
        String(repeating: "  ", count: max(0, level))
    }

    static func tableLines(_ rows: [[String]]) -> [String] {
        guard let first = rows.first, !rows.isEmpty else { return [] }
        let columnCount = rows.map { $0.count }.max() ?? first.count
        let normalized = rows.map { row -> [String] in
            var padded = row
            while padded.count < columnCount { padded.append("") }
            return padded.map { escapeCell($0) }
        }

        var lines: [String] = []
        lines.append("| " + normalized[0].joined(separator: " | ") + " |")
        lines.append("|" + Array(repeating: " --- ", count: columnCount).joined(separator: "|") + "|")
        for row in normalized.dropFirst() {
            lines.append("| " + row.joined(separator: " | ") + " |")
        }
        return lines
    }

    static func escapeCell(_ text: String) -> String {
        text
            .replacingOccurrences(of: "|", with: "\\|")
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespaces)
    }
}

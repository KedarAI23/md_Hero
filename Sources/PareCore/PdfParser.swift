import Foundation
import PDFKit

public enum PdfParser {
    public static func parse(url: URL, stripHeadersFooters: Bool) throws -> [MarkdownBlock] {
        guard let document = PDFDocument(url: url) else {
            throw ConversionError.unreadable("Not a readable PDF")
        }
        guard document.pageCount > 0 else {
            throw ConversionError.unreadable("PDF contains no pages")
        }

        var pageLines: [[String]] = []
        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex), let text = page.string else {
                pageLines.append([])
                continue
            }
            pageLines.append(
                text
                    .components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespaces) }
            )
        }

        if stripHeadersFooters, pageLines.count > 1 {
            pageLines = Self.stripRepeatingLines(pageLines)
        }

        let lines = pageLines.flatMap { $0 }
            .filter { !Self.isLonePageNumber($0) }
        return ProseStructure.linesToBlocks(lines)
    }

    static func stripRepeatingLines(_ pageLines: [[String]]) -> [[String]] {
        let pageCount = pageLines.count
        guard pageCount > 1 else { return pageLines }

        var frequency: [String: Int] = [:]
        for lines in pageLines {
            for line in lines where !line.isEmpty {
                let key = normalize(line)
                if !key.isEmpty {
                    frequency[key, default: 0] += 1
                }
            }
        }

        let threshold = max(2, Int(Double(pageCount) * 0.5))
        let repeatedKeys = Set(
            frequency
                .filter { $0.value >= threshold }
                .map { $0.key }
        )
        guard !repeatedKeys.isEmpty else { return pageLines }

        return pageLines.map { lines in
            lines.filter { line in
                line.isEmpty || !repeatedKeys.contains(normalize(line))
            }
        }
    }

    static func isLonePageNumber(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.range(of: "^\\p{N}{1,4}$", options: .regularExpression) != nil {
            return true
        }
        return trimmed.range(
            of: "^page\\s+\\p{N}{1,4}(\\s*(of|/)\\s*\\p{N}{1,4})?$",
            options: [ .regularExpression, .caseInsensitive ]
        ) != nil
    }

    private static func normalize(_ line: String) -> String {
        let digitsReplaced = line.replacingOccurrences(
            of: "\\p{N}+",
            with: "#",
            options: .regularExpression
        )
        return digitsReplaced
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }
}

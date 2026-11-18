import AppKit
import Foundation
import PDFKit
import Vision

public enum PdfParser {
    public static func parse(
        url: URL,
        stripHeadersFooters: Bool,
        performOCR: Bool = true
    ) throws -> [MarkdownBlock] {
        guard let document = PDFDocument(url: url) else {
            throw ConversionError.unreadable("Not a readable PDF")
        }
        guard document.pageCount > 0 else {
            throw ConversionError.unreadable("PDF contains no pages")
        }

        var pageLines: [[String]] = []
        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else {
                pageLines.append([])
                continue
            }

            let extractedText = page.string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let pageText: String
            if extractedText.isEmpty && performOCR {
                pageText = recognizeText(on: page) ?? ""
            } else {
                pageText = extractedText
            }

            pageLines.append(
                pageText
                    .components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
            )
        }

        if stripHeadersFooters, pageLines.count > 1 {
            pageLines = Self.stripRepeatingLines(pageLines)
        }

        var blocks: [MarkdownBlock] = []
        for (index, lines) in pageLines.enumerated() {
            blocks.append(.heading(level: 2, text: "Page \(index + 1)"))
            let visibleLines = lines.filter { !Self.isLonePageNumber($0) }
            if visibleLines.isEmpty {
                blocks.append(.paragraph("[No extractable text detected on this page. It may be blank, scanned, or protected.]"))
            } else {
                blocks.append(contentsOf: ProseStructure.linesToBlocks(visibleLines))
            }
        }
        return blocks
    }

    private static func recognizeText(on page: PDFPage) -> String? {
        let thumbnail = page.thumbnail(of: CGSize(width: 1800, height: 2400), for: .mediaBox)
        var proposedRect = CGRect(origin: .zero, size: thumbnail.size)
        guard let cgImage = thumbnail.cgImage(
            forProposedRect: &proposedRect,
            context: nil,
            hints: nil
        ) else {
            return nil
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        do {
            try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
        } catch {
            return nil
        }

        let recognized = request.results?
            .compactMap { $0.topCandidates(1).first?.string }
            .filter { !$0.isEmpty } ?? []
        return recognized.isEmpty ? nil : recognized.joined(separator: "\n")
    }

    static func stripRepeatingLines(_ pageLines: [[String]]) -> [[String]] {
        let pageCount = pageLines.count
        guard pageCount > 1 else { return pageLines }

        var frequency: [String: Int] = [:]
        for lines in pageLines {
            guard let first = lines.first, let last = lines.last else { continue }
            for line in [first, last] {
                let key = normalize(line)
                if !key.isEmpty {
                    frequency[key, default: 0] += 1
                }
            }
        }

        let threshold = max(2, Int((Double(pageCount) * 0.5).rounded(.up)))
        let repeatedKeys = Set(
            frequency
                .filter { $0.value >= threshold }
                .map { $0.key }
        )
        guard !repeatedKeys.isEmpty else { return pageLines }

        return pageLines.map { lines -> [String] in
            guard let lastIndex = lines.indices.last else { return lines }
            return lines.enumerated().compactMap { index, line -> String? in
                if index == 0 || index == lastIndex,
                   !line.isEmpty,
                   repeatedKeys.contains(normalize(line)) {
                    return nil
                }
                return line
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

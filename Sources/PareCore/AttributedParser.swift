import Foundation
import AppKit

public enum AttributedParser {
    public enum SourceType {
        case rtf
        case html
    }

    public static func parse(data: Data, type: SourceType, baseURL: URL?) throws -> [MarkdownBlock] {
        let documentType: NSAttributedString.DocumentType = type == .rtf ? .rtf : .html
        let readWork = { () -> NSAttributedString? in
            try? NSAttributedString(
                data: data,
                options: [.documentType: documentType],
                documentAttributes: nil
            )
        }
        let attributed: NSAttributedString?
        if type == .html, !Thread.isMainThread {
            attributed = DispatchQueue.main.sync(execute: readWork)
        } else {
            attributed = readWork()
        }
        guard let attributed, attributed.length > 0 else {
            throw ConversionError.parseFailed("Could not interpret \(type == .rtf ? "RTF" : "HTML") content")
        }

        let lines = attributed.string.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        var blocks = Self.blocksWithFonts(from: attributed)
        if blocks.isEmpty {
            blocks = ProseStructure.linesToBlocks(lines)
        }
        return blocks
    }

    static func blocksWithFonts(from attributed: NSAttributedString) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        var paragraphRanges: [(range: NSRange, text: String)] = []
        attributed.string.enumerateSubstrings(
            in: NSRange(location: 0, length: attributed.length),
            options: [.byParagraphs, .substringNotRequired]
        ) { _, range, _, _ in
            paragraphRanges.append((range, ""))
        }

        var baseSize: CGFloat = 0
        var sizes: [CGFloat] = []
        for (range, _) in paragraphRanges {
            if range.location < attributed.length {
                if let font = attributed.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont {
                    sizes.append(font.pointSize)
                }
            }
        }
        if let median = sizes.sorted().first(where: { $0 > 8 }) {
            baseSize = median
        }
        guard baseSize > 0 else { return [] }

        for (range, _) in paragraphRanges {
            let text = attributed
                .attributedSubstring(from: range)
                .string
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else { continue }

            if let font = attributed.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont {
                let traits = font.fontDescriptor.symbolicTraits
                let isBold = traits.contains(.bold)
                let ratio = font.pointSize / baseSize
                if isBold, ratio >= 1.6 {
                    blocks.append(.heading(level: 1, text: text))
                    continue
                }
                if isBold, ratio >= 1.35 {
                    blocks.append(.heading(level: 2, text: text))
                    continue
                }
                if isBold, ratio >= 1.15, text.count <= 80 {
                    blocks.append(.heading(level: 3, text: text))
                    continue
                }
            }

            if let marker = ProseStructure.bulletMarker(in: text) {
                let body = String(text.dropFirst(marker.count)).trimmingCharacters(in: .whitespaces)
                if !body.isEmpty {
                    blocks.append(.bullet(text: body, level: 0))
                    continue
                }
            }
            if let ordered = ProseStructure.orderedItem(in: text) {
                blocks.append(.ordered(text: ordered, level: 0))
                continue
            }
            blocks.append(.paragraph(text))
        }
        return blocks
    }
}

import CryptoKit
import Foundation

public enum DocumentConverter {
    public static let supportedExtensions: Set<String> = [
        "docx", "odt", "pdf", "rtf", "html", "htm", "txt", "text", "md", "markdown"
    ]

    public static func convert(url: URL, options: ConvertOptions) throws -> ConversionResult {
        switch fileExtension(url) {
        case "docx":
            let data = try read(url)
            return try finalize(try DocxParser.parse(data: data), options: options)
        case "odt":
            let data = try read(url)
            return try finalize(try OdtParser.parse(data: data), options: options)
        case "pdf":
            let blocks = try PdfParser.parse(
                url: url,
                stripHeadersFooters: options.stripHeadersFooters,
                performOCR: options.performOCR
            )
            return try finalize(blocks, options: options)
        case "rtf":
            let data = try read(url)
            return try finalize(try AttributedParser.parse(data: data, type: .rtf, baseURL: url.deletingLastPathComponent()), options: options)
        case "html", "htm":
            let data = try read(url)
            return try finalize(try AttributedParser.parse(data: data, type: .html, baseURL: url.deletingLastPathComponent()), options: options)
        case "txt", "text":
            let text = try String(contentsOf: url, encoding: .utf8)
            return try finalize(PlaintextParser.parse(text), options: options)
        case "md", "markdown":
            let text = try String(contentsOf: url, encoding: .utf8)
            return try finalizePassThrough(text, options: options)
        default:
            throw ConversionError.unsupportedFormat(
                "Unsupported format .\(fileExtension(url)). Supported: docx, odt, pdf, rtf, html, txt, md. Convert legacy .doc files to .docx first."
            )
        }
    }

    public static func outputURL(
        for sourceURL: URL,
        outputFolder: URL?,
        existingNames: Set<String> = []
    ) -> URL {
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let targetDirectory = outputFolder ?? sourceURL.deletingLastPathComponent()
        var candidate = targetDirectory.appendingPathComponent("\(baseName).md")
        var suffix = 2
        while existingNames.contains(candidate.lastPathComponent) {
            candidate = targetDirectory.appendingPathComponent("\(baseName) (\(suffix)).md")
            suffix += 1
        }
        return candidate
    }

    public static func write(_ result: ConversionResult, to url: URL) throws {
        try result.markdown.write(to: url, atomically: true, encoding: .utf8)
    }

    public static func writeManifest(
        for result: ConversionResult,
        sourceURL: URL,
        markdownURL: URL,
        options: ConvertOptions
    ) throws {
        let sourceData = try Data(contentsOf: sourceURL)
        let digest = SHA256.hash(data: sourceData)
            .map { String(format: "%02x", $0) }
            .joined()

        let manifest = ConversionManifest(
            schemaVersion: 1,
            appVersion: "2.0.0-beta.1",
            sourceFilename: sourceURL.lastPathComponent,
            sourceFormat: sourceURL.pathExtension.lowercased(),
            sourceSHA256: digest,
            convertedAt: ISO8601DateFormatter().string(from: Date()),
            markdownFilename: markdownURL.lastPathComponent,
            statistics: result.stats,
            options: options,
            knownLimitations: [
                "Token counts are heuristic estimates based on approximately four characters per token.",
                "Structured parser-level extraction warnings are not yet available in this beta.",
                "PDF OCR is attempted on pages with no extractable text; mixed text-and-image pages are not OCR-enhanced."
            ]
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(manifest)
        let manifestURL = markdownURL
            .deletingPathExtension()
            .appendingPathExtension("manifest.json")
        try data.write(to: manifestURL, options: .atomic)
    }

    private struct ConversionManifest: Encodable {
        let schemaVersion: Int
        let appVersion: String
        let sourceFilename: String
        let sourceFormat: String
        let sourceSHA256: String
        let convertedAt: String
        let markdownFilename: String
        let statistics: ConversionStats
        let options: ConvertOptions
        let knownLimitations: [String]
    }

    private static func finalize(_ blocks: [MarkdownBlock], options: ConvertOptions) throws -> ConversionResult {
        guard !blocks.isEmpty else {
            throw ConversionError.parseFailed("No extractable content found")
        }
        let markdown = Cleaner.clean(MarkdownRenderer.render(blocks), options: options)
        guard !markdown.isEmpty else {
            throw ConversionError.parseFailed("Document produced empty Markdown output")
        }
        return result(markdown: markdown, rawText: rawText(of: blocks))
    }

    private static func finalizePassThrough(_ text: String, options: ConvertOptions) throws -> ConversionResult {
        let markdown = Cleaner.clean(text, options: options)
        guard !markdown.isEmpty else {
            throw ConversionError.parseFailed("Document is empty")
        }
        return result(markdown: markdown, rawText: text)
    }

    private static func result(markdown: String, rawText: String) -> ConversionResult {
        let stats = ConversionStats(
            rawCharacterCount: rawText.count,
            markdownCharacterCount: markdown.count,
            wordCount: TokenEstimator.wordCount(markdown),
            rawTokenEstimate: TokenEstimator.estimate(rawText),
            markdownTokenEstimate: TokenEstimator.estimate(markdown)
        )
        return ConversionResult(markdown: markdown, stats: stats)
    }

    private static func rawText(of blocks: [MarkdownBlock]) -> String {
        blocks.map { block -> String in
            switch block {
            case .heading(_, let text), .paragraph(let text), .bullet(let text, _),
                 .ordered(let text, _), .quote(let text):
                return text
            case .table(let rows):
                return rows.map { $0.joined(separator: " ") }.joined(separator: " ")
            case .divider:
                return ""
            }
        }
        .joined(separator: "\n")
    }

    private static func read(_ url: URL) throws -> Data {
        do {
            return try Data(contentsOf: url)
        } catch {
            throw ConversionError.unreadable(error.localizedDescription)
        }
    }

    private static func fileExtension(_ url: URL) -> String {
        url.pathExtension.lowercased()
    }
}

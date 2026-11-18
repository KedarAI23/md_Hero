import Foundation

public enum MarkdownBlock: Equatable, Sendable {
    case heading(level: Int, text: String)
    case paragraph(String)
    case bullet(text: String, level: Int)
    case ordered(text: String, level: Int)
    case table(rows: [[String]])
    case quote(String)
    case divider
}

public struct ConvertOptions: Sendable, Equatable, Codable {
    public var stripHeadersFooters: Bool
    public var removeImages: Bool
    public var removeLinkURLs: Bool
    public var compactWhitespace: Bool
    public var performOCR: Bool

    public init(
        stripHeadersFooters: Bool = true,
        removeImages: Bool = false,
        removeLinkURLs: Bool = false,
        compactWhitespace: Bool = true,
        performOCR: Bool = true
    ) {
        self.stripHeadersFooters = stripHeadersFooters
        self.removeImages = removeImages
        self.removeLinkURLs = removeLinkURLs
        self.compactWhitespace = compactWhitespace
        self.performOCR = performOCR
    }
}

public struct ConversionStats: Sendable, Equatable, Codable {
    public let rawCharacterCount: Int
    public let markdownCharacterCount: Int
    public let wordCount: Int
    public let rawTokenEstimate: Int
    public let markdownTokenEstimate: Int

    public var tokenSavingsPercent: Int {
        guard rawTokenEstimate > 0 else { return 0 }
        return max(0, (rawTokenEstimate - markdownTokenEstimate) * 100 / rawTokenEstimate)
    }
}

public struct ConversionResult: Sendable {
    public let markdown: String
    public let stats: ConversionStats
}

public enum ConversionError: LocalizedError {
    case unreadable(String)
    case unsupportedFormat(String)
    case parseFailed(String)

    public var errorDescription: String? {
        switch self {
        case .unreadable(let message): return "Could not read file: \(message)"
        case .unsupportedFormat(let message): return message
        case .parseFailed(let message): return "Conversion failed: \(message)"
        }
    }
}

public enum TokenEstimator {
    public static func estimate(_ text: String) -> Int {
        max(1, (text.count + 3) / 4)
    }

    public static func wordCount(_ text: String) -> Int {
        let words = text.split { $0.isWhitespace || $0.isNewline }
        return words.count
    }
}

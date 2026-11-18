import Foundation

public enum Cleaner {
    public static func clean(_ markdown: String, options: ConvertOptions) -> String {
        var text = markdown

        if options.removeImages {
            text = text.replacingOccurrences(
                of: "!\\[[^\\]]*\\]\\([^)]*\\)",
                with: "",
                options: .regularExpression
            )
        }
        if options.removeLinkURLs {
            text = text.replacingOccurrences(
                of: "!?\\[([^\\]]*)\\]\\([^)]*\\)",
                with: "$1",
                options: .regularExpression
            )
        }

        let trimmedLines = text
            .components(separatedBy: "\n")
            .map { trimTrailingWhitespace($0) }
        text = trimmedLines.joined(separator: "\n")

        if options.compactWhitespace {
            text = text.replacingOccurrences(
                of: "\\n{3,}",
                with: "\n\n",
                options: .regularExpression
            )
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "" : trimmed + "\n"
    }

    static func trimTrailingWhitespace(_ line: String) -> String {
        var result = line
        while let last = result.last, last == " " || last == "\t" {
            result.removeLast()
        }
        return result
    }
}

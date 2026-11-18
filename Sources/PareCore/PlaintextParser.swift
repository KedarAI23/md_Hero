import Foundation

public enum PlaintextParser {
    public static func parse(_ text: String) -> [MarkdownBlock] {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        return ProseStructure.linesToBlocks(lines)
    }

    public static func passthrough(_ text: String) -> String {
        text
    }
}

import Foundation

public enum OdtParser {
    public static func parse(data: Data) throws -> [MarkdownBlock] {
        guard let archive = ZipArchive(data: data) else {
            throw ConversionError.parseFailed("Not a valid ODT (OpenDocument) package")
        }
        guard let xml = archive.data(forEntry: "content.xml") else {
            throw ConversionError.parseFailed("ODT package is missing content.xml")
        }
        let delegate = Delegate()
        let parser = XMLParser(data: xml)
        parser.delegate = delegate
        guard parser.parse(), let blocks = delegate.blocks else {
            let reason = parser.parserError?.localizedDescription ?? "malformed content.xml"
            throw ConversionError.parseFailed(reason)
        }
        return blocks
    }

    private final class Delegate: NSObject, XMLParserDelegate {
        private(set) var blocks: [MarkdownBlock]?

        private var collected: [MarkdownBlock] = []
        private var paragraphDepth = 0
        private var runText = ""
        private var isHeading = false
        private var headingLevel = 1

        private var listDepth = 0
        private var inListItem = false

        private var tableDepth = 0
        private var tableRows: [[String]] = []
        private var tableRow: [String] = []
        private var cellText = ""

        func parser(
            _ parser: XMLParser,
            didStartElement elementName: String,
            namespaceURI: String?,
            qualifiedName qName: String?,
            attributes attributeDict: [String: String] = [:]
        ) {
            let name = Self.localName(elementName)
            switch name {
            case "h":
                paragraphDepth += 1
                runText = ""
                isHeading = true
                let levelKey = attributeDict.first { $0.key.hasSuffix("outline-level") }
                headingLevel = max(1, min(6, Int(levelKey?.value ?? "1") ?? 1))
            case "p":
                paragraphDepth += 1
                if paragraphDepth == 1 {
                    runText = ""
                    isHeading = false
                }
            case "list":
                listDepth += 1
            case "list-item":
                inListItem = true
            case "s":
                appendToText(" ")
            case "tab":
                appendToText(" ")
            case "line-break":
                appendToText(" ")
            case "table":
                tableDepth += 1
                if tableDepth == 1 {
                    tableRows = []
                    tableRow = []
                }
            case "table-row":
                if tableDepth == 1 { tableRow = [] }
            case "table-cell":
                if tableDepth == 1 { cellText = "" }
            case "annotation":
                break
            default:
                break
            }
        }

        func parser(_ parser: XMLParser, foundCharacters string: String) {
            appendToText(string)
        }

        func parser(
            _ parser: XMLParser,
            didEndElement elementName: String,
            namespaceURI: String?,
            qualifiedName qName: String?
        ) {
            let name = Self.localName(elementName)
            switch name {
            case "h":
                paragraphDepth -= 1
                finishParagraph(isHeading: true)
            case "p":
                paragraphDepth = max(0, paragraphDepth - 1)
                if tableDepth > 0 || paragraphDepth == 0 {
                    finishParagraph(isHeading: false)
                }
            case "list":
                listDepth = max(0, listDepth - 1)
            case "list-item":
                inListItem = false
            case "table-cell":
                if tableDepth == 1 {
                    tableRow.append(cellText.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            case "table-row":
                if tableDepth == 1, !tableRow.isEmpty {
                    tableRows.append(tableRow)
                }
            case "table":
                tableDepth -= 1
                if tableDepth == 0 {
                    if tableRows.contains(where: { $0.count > 1 }) {
                        collected.append(.table(rows: tableRows))
                    } else {
                        for row in tableRows {
                            let text = row.joined(separator: ", ")
                            if !text.isEmpty { collected.append(.paragraph(text)) }
                        }
                    }
                    tableRows = []
                }
            default:
                break
            }
        }

        func parserDidEndDocument(_ parser: XMLParser) {
            blocks = collected
        }

        private func appendToText(_ string: String) {
            if paragraphDepth > 0 {
                runText += string
            }
        }

        private func finishParagraph(isHeading: Bool) {
            if tableDepth > 0 {
                cellText += collapseWhitespace(runText)
                if !runText.isEmpty { cellText += " " }
                runText = ""
                return
            }
            let text = collapseWhitespace(runText)
            runText = ""
            guard !text.isEmpty else { return }

            if isHeading {
                collected.append(.heading(level: headingLevel, text: text))
            } else if inListItem {
                collected.append(.bullet(text: text, level: max(0, listDepth - 1)))
            } else {
                collected.append(.paragraph(text))
            }
        }

        private static func localName(_ qName: String) -> String {
            qName.split(separator: ":").last.map(String.init) ?? qName
        }

        private static func collapseWhitespace(_ text: String) -> String {
            text.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        }
    }
}

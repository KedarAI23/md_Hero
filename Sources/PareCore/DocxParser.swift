import Foundation

public enum DocxParser {
    public static func parse(data: Data) throws -> [MarkdownBlock] {
        guard let archive = ZipArchive(data: data) else {
            throw ConversionError.parseFailed("Not a valid DOCX (Office Open XML) package")
        }
        guard let xml = archive.data(forEntry: "word/document.xml") else {
            throw ConversionError.parseFailed("DOCX package is missing word/document.xml")
        }
        let delegate = Delegate()
        let parser = XMLParser(data: xml)
        parser.delegate = delegate
        guard parser.parse(), let blocks = delegate.blocks else {
            let reason = parser.parserError?.localizedDescription ?? "malformed document.xml"
            throw ConversionError.parseFailed(reason)
        }
        return blocks
    }

    private final class Delegate: NSObject, XMLParserDelegate {
        private(set) var blocks: [MarkdownBlock]?

        private var collected: [MarkdownBlock] = []
        private var paragraphDepth = 0
        private var runText = ""
        private var styleValue = ""
        private var inNumbering = false
        private var listLevel = 0
        private var hasNumbering = false

        private var tableDepth = 0
        private var tableRows: [[String]] = []
        private var tableRow: [String] = []
        private var cellText = ""

        private var drawingDepth = 0
        private var instrDepth = 0

        func parser(
            _ parser: XMLParser,
            didStartElement elementName: String,
            namespaceURI: String?,
            qualifiedName qName: String?,
            attributes attributeDict: [String: String] = [:]
        ) {
            let name = Self.localName(elementName)
            switch name {
            case "p":
                paragraphDepth += 1
                if paragraphDepth == 1 {
                    runText = ""
                    styleValue = ""
                    inNumbering = false
                    hasNumbering = false
                    listLevel = 0
                }
            case "tbl":
                tableDepth += 1
                if tableDepth == 1 {
                    tableRows = []
                    tableRow = []
                }
            case "tr":
                if tableDepth == 1 { tableRow = [] }
            case "tc":
                if tableDepth == 1 { cellText = "" }
            case "pStyle":
                styleValue = attributeDict["w:val"] ?? attributeDict["val"] ?? ""
            case "numPr":
                inNumbering = true
                hasNumbering = true
            case "ilvl":
                if inNumbering {
                    let raw = attributeDict["w:val"] ?? attributeDict["val"] ?? "0"
                    listLevel = max(0, min(5, Int(raw) ?? 0))
                }
            case "t":
                break
            case "tab", "br", "cr":
                appendToText(" ")
            case "drawing", "pict", "object":
                drawingDepth += 1
            case "instrText", "delText", "endnote", "footnote":
                instrDepth += 1
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
            case "p":
                paragraphDepth = max(0, paragraphDepth - 1)
                if paragraphDepth == 0, tableDepth == 0 {
                    finishParagraph()
                } else if tableDepth > 0 {
                    finishParagraph()
                }
            case "tc":
                if tableDepth == 1 {
                    tableRow.append(cellText.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            case "tr":
                if tableDepth == 1, !tableRow.isEmpty {
                    tableRows.append(tableRow)
                }
            case "tbl":
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
            case "numPr":
                inNumbering = false
            case "drawing", "pict", "object":
                drawingDepth = max(0, drawingDepth - 1)
            case "instrText", "delText", "endnote", "footnote":
                instrDepth = max(0, instrDepth - 1)
            default:
                break
            }
        }

        func parserDidEndDocument(_ parser: XMLParser) {
            blocks = collected
        }

        private func appendToText(_ string: String) {
            guard drawingDepth == 0, instrDepth == 0 else { return }
            if paragraphDepth > 0 {
                runText += string
            }
        }

        private func finishParagraph() {
            if tableDepth > 0 {
                cellText += Self.collapseWhitespace(runText)
                if !runText.isEmpty { cellText += " " }
                runText = ""
                return
            }
            let text = Self.collapseWhitespace(runText)
            runText = ""
            guard !text.isEmpty else {
                styleValue = ""
                hasNumbering = false
                return
            }
            emitBlock(for: text)
            styleValue = ""
            hasNumbering = false
        }

        private func emitBlock(for text: String) {
            let style = styleValue.lowercased()
            if style == "title" {
                collected.append(.heading(level: 1, text: text))
            } else if style == "subtitle" {
                collected.append(.heading(level: 2, text: text))
            } else if style.hasPrefix("heading") {
                let level = Int(style.dropFirst("heading".count)) ?? 1
                collected.append(.heading(level: max(1, min(6, level)), text: text))
            } else if style.hasPrefix("listnumber") {
                collected.append(.ordered(text: text, level: listLevel))
            } else if style.hasPrefix("listbullet") || style.hasPrefix("listparagraph") || hasNumbering {
                collected.append(.bullet(text: text, level: listLevel))
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

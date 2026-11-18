import XCTest
@testable import PareCore

final class PareTests: XCTestCase {
    private func fixtureURL(_ name: String) -> URL {
        let bundle = Bundle.module
        guard let url = bundle.url(forResource: name, withExtension: nil, subdirectory: "Fixtures")
            ?? bundle.url(forResource: name, withExtension: nil) else {
            fatalError("Missing test fixture: \(name)")
        }
        return url
    }

    private func convert(_ name: String, options: ConvertOptions = ConvertOptions()) throws -> ConversionResult {
        try DocumentConverter.convert(url: fixtureURL(name), options: options)
    }

    private func loadData(_ name: String) throws -> Data {
        try Data(contentsOf: fixtureURL(name))
    }

    func testDocxParsesHeadingsListsAndTables() throws {
        let blocks = try DocxParser.parse(data: try loadData("sample.docx"))

        XCTAssertTrue(blocks.contains {
            if case .heading(let level, let text) = $0 { return level == 1 && text == "Quarterly Financial Review" }
            return false
        })
        XCTAssertTrue(blocks.contains {
            if case .heading(let level, let text) = $0 { return level == 2 && text == "Revenue Overview" }
            return false
        })
        XCTAssertTrue(blocks.contains {
            if case .bullet(let text, _) = $0 { return text == "Enterprise renewals increased retention" }
            return false
        })
        XCTAssertTrue(blocks.contains {
            if case .ordered(let text, _) = $0 { return text == "Audit the trailing twelve month numbers" }
            return false
        })

        let tables = blocks.compactMap { block -> [[String]]? in
            if case .table(let rows) = block { return rows }
            return nil
        }
        XCTAssertEqual(tables.count, 1)
        XCTAssertEqual(tables.first?.first, ["Region", "Revenue", "Margin"])
        XCTAssertEqual(tables.first?.last, ["EMEA", "$4.2M", "31%"])
    }

    func testOdtParsesHeadingsAndLists() throws {
        let blocks = try OdtParser.parse(data: try loadData("sample.odt"))

        XCTAssertTrue(blocks.contains {
            if case .heading(let level, let text) = $0 { return level == 1 && text == "Project Phoenix Status" }
            return false
        })
        XCTAssertTrue(blocks.contains {
            if case .heading(let level, let text) = $0 { return level == 2 && text == "Milestones" }
            return false
        })
        XCTAssertTrue(blocks.contains {
            if case .bullet(let text, _) = $0 { return text == "Database cutover finished" }
            return false
        })
    }

    func testRtfConversion() throws {
        let result = try convert("sample.rtf")
        XCTAssertTrue(result.markdown.contains("Quarterly Financial Review"))
        XCTAssertTrue(result.markdown.contains("Revenue Overview"))
        XCTAssertTrue(result.markdown.contains("New logo bookings flattened in Q3"))
    }

    func testHtmlConversion() throws {
        let result = try convert("sample.html")
        XCTAssertTrue(result.markdown.contains("Release Notes 2.4"))
        XCTAssertTrue(result.markdown.contains("Fixed login loop on Safari"))
        XCTAssertTrue(result.markdown.contains("documentation"))
    }

    func testPdfConversionStripsRepeatingPageFurniture() throws {
        let result = try convert("sample.pdf")
        XCTAssertFalse(result.markdown.contains("Confidential"))
        XCTAssertFalse(result.markdown.range(of: "Page \\d", options: .regularExpression) != nil)
        XCTAssertTrue(result.markdown.contains("Quarterly Report"))
        XCTAssertTrue(result.markdown.contains("enterprise renewals"))
    }

    func testRendererProducesGfmTable() {
        let rendered = MarkdownRenderer.render([
            .table(rows: [["A", "B"], ["1", "2"]])
        ])
        let renderedLines = rendered.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        XCTAssertEqual(renderedLines, [
            "| A | B |",
            "| --- | --- |",
            "| 1 | 2 |",
            ""
        ])
    }

    func testRendererNumbersConsecutiveOrderedItems() {
        let rendered = MarkdownRenderer.render([
            .ordered(text: "first", level: 0),
            .ordered(text: "second", level: 0),
            .paragraph("break"),
            .ordered(text: "third", level: 0)
        ])
        XCTAssertTrue(rendered.contains("1. first"))
        XCTAssertTrue(rendered.contains("2. second"))
        XCTAssertTrue(rendered.contains("1. third"))
    }

    func testCleanerRemovesImagesAndCollapsesBlankLines() {
        let cleaned = Cleaner.clean(
            "Top\n\n![](x.png)\n\n\n\n\nBottom   \n",
            options: ConvertOptions()
        )
        XCTAssertFalse(cleaned.contains("x.png"))
        XCTAssertFalse(cleaned.contains("\n\n\n"))
        XCTAssertTrue(cleaned.hasSuffix("Bottom\n"))
    }

    func testCleanerStripsLinkURLsWhenRequested() {
        let cleaned = Cleaner.clean(
            "[the docs](https://example.com/very/long/path)",
            options: ConvertOptions(removeLinkURLs: true)
        )
        XCTAssertEqual(cleaned, "the docs\n")
    }

    func testCleanerKeepsLinkURLsByDefault() {
        let cleaned = Cleaner.clean(
            "[the docs](https://example.com/x)",
            options: ConvertOptions()
        )
        XCTAssertTrue(cleaned.contains("https://example.com/x"))
    }

    func testStatsReportTokenSavings() throws {
        let result = try convert("sample.pdf")
        XCTAssertGreaterThan(result.stats.rawTokenEstimate, 0)
        XCTAssertGreaterThan(result.stats.markdownTokenEstimate, 0)
        XCTAssertGreaterThan(result.stats.tokenSavingsPercent, 0)
    }

    func testOutputURLNamesAreUniquified() {
        let source = URL(fileURLWithPath: "/tmp/report.docx")
        let first = DocumentConverter.outputURL(for: source, outputFolder: nil, existingNames: ["report.md"])
        XCTAssertEqual(first.lastPathComponent, "report (2).md")
        let second = DocumentConverter.outputURL(for: source, outputFolder: nil, existingNames: ["report.md", "report (2).md"])
        XCTAssertEqual(second.lastPathComponent, "report (3).md")
    }

    func testZipArchiveReadsDeflatedEntry() throws {
        let archive = ZipArchive(data: try loadData("sample.docx"))
        XCTAssertNotNil(archive)
        let xml = archive?.data(forEntry: "word/document.xml")
        XCTAssertNotNil(xml)
        let text = String(data: xml ?? Data(), encoding: .utf8) ?? ""
        XCTAssertTrue(text.contains("Quarterly Financial Review"))
    }
}

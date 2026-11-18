# md_Hero

**A native macOS document-to-Markdown converter designed for LLM workflows.**

md_Hero extracts supported document content, renders Markdown and reports indicative word/token estimates. Document processing is local.

## Beta 2.0.0-beta.1

The first 2.0 beta focuses on a reliable installable macOS build and safer conversion defaults.

### Current format support
| Format | Current implementation |
|---|---|
| DOCX | Built-in OOXML parser: headings, lists, tables and hyperlinks |
| ODT | Built-in OpenDocument parser |
| PDF | PDFKit text extraction, page markers and Vision OCR fallback for pages with no extractable text |
| RTF | NSAttributedString extraction |
| HTML | NSAttributedString extraction |
| TXT | Heuristic text structuring |
| MD | Pass-through and cleaning |

XLSX and PPTX are not supported in this beta. PDF OCR is a fallback for pages without an extractable text layer; it does not perform layout-aware OCR on mixed text-and-image pages.

### Beta conversion behaviour
- Images and Markdown image placeholders are preserved by default.
- OCR for scanned PDF pages is enabled by default and can be disabled in Options.
- PDF page boundaries are retained as Markdown headings.
- Each successful conversion writes a companion `.manifest.json` with source SHA-256, app version, conversion timestamp, options and heuristic statistics.
- Token counts remain approximate (roughly four characters per token), not model-specific.

## Build and test (macOS)
Requirements: macOS 13+ and Xcode 15 / compatible Swift 5.9+ toolchain.

```bash
swift test
./scripts/make_app.sh release 2.0.0-beta.1
./scripts/make_dmg.sh release 2.0.0-beta.1
```

The DMG is created under `build/md_Hero-2.0.0-beta.1.dmg`. The app is ad-hoc signed for local beta testing and is not Developer ID notarised. On first launch, macOS may require Control-click / right-click → Open.

## 2.0 engineering plan
See the [architecture](docs/architecture/TECHNICAL_ARCHITECTURE.md), [source change specification](docs/architecture/SOURCE_CHANGE_SPEC.md), [QA plan](docs/testing/TEST_CORPUS_AND_QA.md) and [backlog](docs/roadmap/MH2_BACKLOG.md).

## Privacy
The product requirement is local processing. Document contents and derived assets must not be transmitted to remote services.

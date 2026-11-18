# md_Hero

**A native macOS document-to-Markdown converter designed for LLM workflows.**

md_Hero extracts supported document content, renders clean Markdown and reports basic word/token estimates. The current implementation is a foundation for the 2.0 upgrade; planned capabilities must not be presented as shipped until implemented and tested.

## Current format support

| Format | Current implementation |
|---|---|
| DOCX | Built-in OOXML parser: headings, lists, tables and hyperlinks |
| ODT | Built-in OpenDocument parser |
| PDF | PDFKit text extraction with reading-order and repeated-header/footer heuristics |
| RTF | NSAttributedString extraction |
| HTML | NSAttributedString extraction |
| TXT | Heuristic text structuring |
| MD | Pass-through and cleaning |

Scanned/image-only PDFs require OCR, which is not yet implemented. XLSX and PPTX are not yet supported.

## Current token estimate

The current release uses a rough character-based estimate (approximately four characters per token). This is not a model-specific tokenizer and should be treated as indicative only.

## md_Hero 2.0 direction

The 2.0 objective is trustworthy, local-first Markdown packages for LLM ingestion, with information fidelity taking precedence over token reduction.

Planned capabilities include:
- PDF page provenance, OCR, table and figure handling.
- Improved DOCX relationship, image and footnote extraction.
- XLSX worksheets, formulas, cached values and ranges.
- PPTX slides, notes, tables and images.
- Faithful, LLM Optimised and Research profiles.
- A versioned document representation, conversion manifest and quality warnings.
- Model-specific tokenisation where a suitable local tokenizer is available.

See the [2.0 architecture](docs/architecture/TECHNICAL_ARCHITECTURE.md), [source change specification](docs/architecture/SOURCE_CHANGE_SPEC.md), [QA plan](docs/testing/TEST_CORPUS_AND_QA.md) and [prioritised backlog](docs/roadmap/MH2_BACKLOG.md).

## Build and test

Requirements: macOS 13+ and Xcode 14+ or compatible Xcode Command Line Tools.

```bash
swift build
swift test
./scripts/make_app.sh
./scripts/make_dmg.sh
```

## Privacy objective

Document processing is intended to remain local. Document contents and derived assets must not be sent to remote services. Offline behaviour must be verified after all required resources have been provisioned.

## Contribution rule

Do not silently discard substantive content. When an element cannot be extracted, preserve a reference where possible and record a structured warning. Use synthetic or redistributable test fixtures only; never commit confidential business documents.

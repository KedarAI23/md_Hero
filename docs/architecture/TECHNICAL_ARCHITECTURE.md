# md_Hero 2.0 — Technical architecture

## Objective
Convert PDF, DOCX, XLSX, PPTX and HTML into trustworthy, structured Markdown packages for LLM ingestion. Processing is local. Information fidelity takes precedence over token reduction.

## Principles
1. Preserve the existing native SwiftUI app and Swift conversion core.
2. Separate extraction, document modelling, Markdown rendering and optimisation.
3. Parse each format into a common, versioned Document Intermediate Representation (IR).
4. Preserve provenance: PDF page, PPTX slide, XLSX worksheet/cell range, source file and warnings.
5. Never silently discard images, tables, footnotes, formulas or other substantive content.
6. Keep MVP optimisation deterministic; no LLM rewriting or summarisation.
7. Keep originals immutable and processing local.

## Target architecture
```text
SwiftUI app (Pare)
  ├─ file intake / batch queue / progress / cancellation
  ├─ conversion profile / output settings
  └─ preview / quality report
        |
        v
PareCore orchestration
  ├─ format detection and validation
  ├─ PDF / DOCX / XLSX / PPTX / HTML parsers
  ├─ common Document IR with provenance
  ├─ asset extraction and relationship handling
  ├─ normalisation and Markdown renderer
  ├─ deterministic optimiser and validator
  └─ token estimator interface
        |
        v
document.md + manifest.json + conversion-report.md + assets/
```

Do not add a Python/Docling sidecar by default. First test whether native Swift, PDFKit, Vision and focused OOXML/HTML parsers meet the corpus quality bar. A separate extraction engine may be benchmarked later against the same fixtures.

## Document IR
The IR is the stable parser/renderer contract. It must be Codable, versioned and parser-independent. It should include:
- document metadata: source filename, format, hash, title and page/slide/sheet counts;
- typed blocks: heading, paragraph, nested list, table, figure, hyperlink, footnote, page break, slide break, worksheet break and code;
- assets: stable ID, relative path, media type, caption/alt text and source location;
- warnings: unsupported element, extraction failure, OCR uncertainty and fidelity limitation;
- provenance: page/slide/worksheet/cell range and parser locator where available.

Use an explicit tagged Codable representation for enum cases with associated values.

## Parser contract
Each parser declares formats, validates input, returns IR plus structured warnings, preserves source order/boundaries, extracts assets into an app-managed workspace, supports cancellation and fails explicitly when extraction is impossible.

## Format strategy
### PDF
Retain PDFKit. Add page-aware extraction and Vision OCR for pages with insufficient text. Distinguish born-digital and scanned pages. Add layout-aware reading order and table extraction incrementally. Extract figures where feasible. Record limitations rather than promising exact visual-layout reproduction.

### DOCX
Extend current OOXML parser. Resolve relationships for images and hyperlinks; include footnotes/endnotes; preserve heading styles, nested lists, tables and merged-cell semantics. Warn on unsupported drawings/objects.

### XLSX
Parse workbook relationships, shared strings, styles, worksheets and cell references. Preserve sheet names/order, ranges, merged cells, formulas and cached values separately. Do not calculate formulas. Export very large ranges to CSV assets with Markdown references. Expose explicit handling for hidden content.

### PPTX
Parse presentation relationships, slide order, titles/text, notes and tables. Extract images and chart data where available. Keep slide boundaries. Warn on unsupported SmartArt, embedded workbooks and complex charts.

### HTML
Prefer semantic content. Preserve headings, paragraphs, lists, tables, links, code and image alt text. Never execute scripts or automatically fetch remote assets. Remove navigation chrome only through explicit tested rules.

## Profiles
- **Faithful:** preserve substantive content, structure, tables, captions, links, footnotes and provenance; minimal cleanup.
- **LLM Optimised:** remove only confidently identified redundant layout noise; preserve meaning, units, dates, caveats, citations and figure references. No paraphrasing or summarisation.
- **Research:** faithful content plus explicit page/slide/sheet/cell provenance, captions, footnotes and detailed warnings.

Profiles are transformations over the same IR, not separate parser implementations.

## Token analytics
Replace chars/4 with a tokenizer abstraction. Heuristic results must be labelled approximate. Use exact local model tokenisation only when a maintained tokenizer is available. Record tokenizer and version. Count text separately from assets. Treat image-token cost as unknown unless a selected model-specific estimator and ingestion method support it. Compare identical extracted-text scopes before/after optimisation; never compare against a guessed PDF upload cost.

`reduction_pct = (before_tokens - after_tokens) / before_tokens * 100`

Omit percentage when before_tokens is zero.

## Output package
```text
<SourceName>_md_Hero/
├── document.md
├── manifest.json
├── conversion-report.md
└── assets/
```
Manifest fields: schema/app/parser versions, source name/format/size/SHA-256, timestamp, profile/options, page/slide/sheet counts, block/table/asset counts, OCR usage, tokenizer identity/count and warnings.

## Local security
No document contents or derived assets leave the device. No remote OCR or cloud conversion. Logs must not contain extracted text. Clean temporary files on success/failure/cancellation. Enforce archive size/decompression limits; defend against ZIP bombs, path traversal, malformed XML and oversized images. Keep original files read-only. Treat HTML as untrusted. Use security-scoped bookmarks where needed. Any future update checks must be isolated and disclosed.

## Observability
Record stage, elapsed time, parser, pages/slides/sheets, OCR pages, blocks/tables/assets, warnings and failures without logging document text.

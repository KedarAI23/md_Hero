# Changelog

## 2.0.0-beta.1
- Preserve images by default; image removal is now opt-in.
- Add PDF page markers.
- Add on-device Vision OCR fallback for PDF pages with no extractable text.
- Add per-conversion JSON manifest with source hash, version, timestamp, options and statistics.
- Add beta UI label and OCR option.
- Add versioned app bundle and DMG packaging scripts with SHA-256 sidecar.

Known beta limitations:
- XLSX/PPTX not supported.
- OCR fallback only runs when a page has no extractable text.
- Token statistics are heuristic estimates.
- App is ad-hoc signed and not Developer ID notarised.

## 1.0
- Initial native macOS document-to-Markdown application.
- Initial support for DOCX, ODT, PDF, RTF, HTML, TXT and Markdown.
- Batch conversion, basic cleaning options and approximate token statistics.

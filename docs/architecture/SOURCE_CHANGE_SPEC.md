# md_Hero 2.0 — Source change specification

## Reviewed baseline
The draft source PR contains SwiftUI module `Pare`, core `PareCore`, PDF/DOCX/HTML/RTF/ODT/TXT/MD handlers, common Markdown blocks/renderer, cleaner, ZIP reader, batch conversion and a character-based token estimate. Confirm all symbols and paths against the current branch before coding.

## Guardrails
Keep the app/core boundary, add capabilities behind protocols/options, avoid a wholesale rewrite, preserve existing APIs where practical, add tests before changing behaviour, and never silently change content-retention defaults.

## A — Core model and validation (P0)
Add Document IR, metadata, provenance, assets, structured extraction warnings, conversion profiles and a validator. Ensure model encode/decode tests and warning taxonomy. Renderer should consume IR through an adapter if necessary.

## B — PDF fidelity (P1)
Modify existing PDF parser. Add page classifier, Vision OCR service, asset extractor and incremental layout reconstructor. Add fixtures for born-digital, scanned, multicolumn and table-heavy PDFs.
Acceptance: page markers preserved; scanned pages OCR when enabled; OCR confidence/warnings exposed; figures extracted or explicitly warned; no page silently omitted.

## C — DOCX completeness (P1)
Extend OOXML relationships for images and hyperlinks; extract footnotes/endnotes; represent merged-cell semantics.
Acceptance: synthetic fixtures verify all supported elements; unsupported drawings/embedded objects produce warnings.

## D — XLSX (P1)
Add workbook, worksheet and cell readers plus CSV exporter. Use current ZIP foundation only after ZIP64 and archive-safety coverage, or adopt a maintained Swift library after licence review.
Acceptance: sheet names/order, cell refs, merged ranges, formula text and cached values retained distinctly; large ranges export as CSV; no formula recalculation is implied.

## E — PPTX (P1)
Add presentation, slide, notes and asset readers.
Acceptance: slide order/boundaries retained; text, tables, notes and images extracted where supported; unsupported charts/SmartArt warned.

## F — Token analytics (P1)
Add TokenEstimator protocol; retain heuristic only as explicitly approximate; add a local model-specific tokenizer adapter only after dependency/licence review.
Acceptance: deterministic count for same tokenizer/version; identical before/after text scope; assets separately counted; image cost never fabricated.

## G — Output packages and profiles (P0/P1)
Add package writer, manifest and conversion report. Profiles: Faithful, LLM Optimised, Research.
Acceptance: deterministic outputs; no silent image loss; safe paths/no source overwrite; manifest includes parser/options/hash/warnings.

## H — UI (P1)
Add profile selector, OCR setting, asset preservation, per-file progress, warnings, token metrics, open Markdown and reveal package actions.
Acceptance: responsive UI, cancellation, batch partial-failure reporting and accessible controls.

## Recommended order
1. A: IR/provenance/validator.
2. G minimal: package writer/manifest.
3. B: PDF page preservation/OCR.
4. C: DOCX relationships/images/footnotes.
5. D: XLSX.
6. E: PPTX.
7. F: token estimation.
8. G profiles and H interface.
Keep each package in its own PR with fixtures and tests.

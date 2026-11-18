# md_Hero 2.0 — Test corpus and QA plan

## Purpose and data policy
Build a repeatable non-confidential corpus to measure extraction fidelity, structure preservation, asset handling, token analytics and offline behaviour. Use synthetic, public-domain or explicitly redistributable fixtures only. Never commit borrower, customer, employee or confidential regulatory documents.

## Minimum corpus (15–20 fixtures)
| ID | Format | Fixture | Main risk |
|---|---|---|---|
| PDF-01 | PDF | Born-digital single column | Text order/headings |
| PDF-02 | PDF | Multi-column report | Reading order |
| PDF-03 | PDF | Scanned report | OCR |
| PDF-04 | PDF | Financial tables | Cells/units |
| PDF-05 | PDF | Repeated headers/footers | Safe noise removal |
| DOCX-01 | DOCX | Headings/nested lists | Hierarchy |
| DOCX-02 | DOCX | Merged-cell tables | Table fidelity |
| DOCX-03 | DOCX | Images/captions/links/footnotes | Relationships/assets |
| XLSX-01 | XLSX | Multiple sheets | Sheet separation |
| XLSX-02 | XLSX | Formulas/cached values | Formula/value distinction |
| XLSX-03 | XLSX | Merged cells/hidden rows | Spreadsheet semantics |
| XLSX-04 | XLSX | Large range | CSV asset export |
| PPTX-01 | PPTX | Slide titles/text boxes | Order/boundaries |
| PPTX-02 | PPTX | Tables/charts/images | Visual assets |
| PPTX-03 | PPTX | Speaker notes | Notes extraction |
| HTML-01 | HTML | Semantic article | Main content |
| HTML-02 | HTML | Nav/scripts/styles around article | Chrome removal |
| HTML-03 | HTML | Nested lists/tables/links | Structure/URLs |

For each fixture keep input, expected IR or Markdown, expected manifest fields, warning set and human-review notes. Prefer semantic assertions over brittle whitespace byte-comparisons.

## Fidelity checks
General: no substantive paragraph silently omitted; source order, heading hierarchy and list nesting preserved; tables retain row/column relationships and units; images extracted or warned; URLs retained; provenance present where available; unsupported elements warned.

PDF: page count matches; text assigned to correct page; OCR only where required/requested; OCR uncertainty surfaced; multicolumn order manually reviewed; header/footer filtering does not erase body text.

DOCX: heading styles and nested lists preserved; tables retain cell order; footnotes/endnotes included or warned; embedded image relationships resolve.

XLSX: worksheet names/order, cell refs and values preserved; formula text distinct from cached value; merged ranges recorded; date/number formats not misrepresented; hidden content follows explicit settings.

PPTX: slide order/numbering preserved; text/tables stay with slide; notes not mixed with body; assets extracted or warned.

HTML: scripts not executed; URLs retained; table headers/cells associated; chrome removal deterministic.

## Token tests
Record tokenizer/version; deterministic repeat counts; same text scope before/after; whitespace-only changes must not create misleading claims; assets excluded from text token count; image cost unavailable unless supported; heuristic clearly approximate.

## Resilience/security tests
Corrupt ZIP, ZIP path traversal, high compression-ratio archive, malformed XML, oversized image, encrypted/unsupported PDF, HTML scripts/remote references, unsafe filenames, cancellation, unwritable output, duplicate names and source-file immutability.

## Offline acceptance
After app resources/OCR models are provisioned: disable network; launch; convert a fixture for every supported format; verify outputs; inspect network activity; verify no runtime model download is attempted.

## Release gates
Unit/integration/corpus tests pass; no silent-loss failures in reviewed fixtures; warnings correct; source immutable; offline behaviour verified; temporary files cleaned; declared minimum macOS build succeeds.

## Test record
```text
Build / Commit / macOS / Hardware / Fixture ID / Input SHA-256
Parser version / Profile / Expected / Actual / Warnings / Assets
Manual fidelity review / Pass-Fail / Reviewer notes
```

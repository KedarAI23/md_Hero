# md_Hero 2.0 — Prioritised engineering backlog

Priority: **P0** safety and credible foundations; **P1** agreed product scope; **P2** quality/usability; **P3** post-2.0.

| ID | Priority | Work item | Evidence |
|---|---|---|---|
| MH2-001 | P0 | Inventory branches, targets and package boundaries | Architecture inventory |
| MH2-002 | P0 | Versioned Document IR and provenance | Codable tests |
| MH2-003 | P0 | Structured extraction warnings | Validator tests |
| MH2-004 | P0 | Output package writer and manifest | Integration tests |
| MH2-005 | P0 | No silent asset loss | Cleaner tests |
| MH2-006 | P0 | ZIP safety limits and archive tests | Malformed/ZIP64 tests |
| MH2-007 | P1 | PDF page boundaries/provenance | PDF fixtures |
| MH2-008 | P1 | Vision OCR for image-only pages | Scanned PDF fixture |
| MH2-009 | P1 | PDF reading order and tables | Multi-column/table fixtures |
| MH2-010 | P1 | DOCX images and relationships | DOCX asset fixture |
| MH2-011 | P1 | DOCX footnotes/endnotes/URLs | DOCX fidelity fixture |
| MH2-012 | P1 | XLSX workbook/worksheet parser | XLSX golden tests |
| MH2-013 | P1 | XLSX formulas/cached values/merged ranges | Formula/merge fixtures |
| MH2-014 | P1 | PPTX slides/text/tables | PPTX golden tests |
| MH2-015 | P1 | PPTX notes and images | PPTX assets fixture |
| MH2-016 | P1 | Faithful/LLM Optimised/Research profiles | Profile tests |
| MH2-017 | P1 | Tokenizer abstraction replacing chars/4 | Deterministic tests |
| MH2-018 | P1 | Quality/warning UI | UI acceptance test |
| MH2-019 | P2 | Model-specific local tokenizer adapters | Model matrix |
| MH2-020 | P2 | CSV export for large spreadsheet ranges | Large XLSX fixture |
| MH2-021 | P2 | Batch cancellation/retry | UI/integration tests |
| MH2-022 | P2 | Finder Quick Action | Finder smoke test |
| MH2-023 | P2 | Performance/memory benchmarks | Benchmark report |
| MH2-024 | P2 | Signed/notarised release pipeline | Verified release |
| MH2-025 | P3 | Optional local chart descriptions | Opt-in feature |
| MH2-026 | P3 | Document collections/local search | Separate spec |

## Milestones
- M0 repository/source inventory and governance.
- M1 trustworthy core: IR, warnings, manifest, archive safety and provenance.
- M2 PDF/DOCX fidelity.
- M3 XLSX/PPTX.
- M4 profiles, token analytics and reporting.
- M5 batch, Finder integration, performance and release packaging.

## Definition of done per parser task
Synthetic fixture added; expected output reviewed; provenance retained where supported; unsupported-content warning tested; errors/cancellation tested; no network dependency; source immutable; docs updated.

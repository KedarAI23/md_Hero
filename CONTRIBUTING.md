# Contributing to md_Hero

## Development principles
- Preserve substantive information. Never silently discard content to reduce tokens.
- Keep document processing local.
- Make unsupported content and extraction uncertainty visible.
- Keep parser, document model, renderer and optimisation responsibilities separate.
- Prefer small, focused pull requests.

## Before submitting
1. Read the 2.0 architecture and source change specification.
2. Add or update synthetic test fixtures.
3. Run `swift test` on macOS.
4. Review generated Markdown and extracted assets manually for parser changes.
5. Document limitations and warnings.

## Test data
Use synthetic, public-domain or explicitly redistributable documents. Do not commit confidential reports, borrower data, customer information, employee records or private correspondence.

## Pull requests
Use the pull request template. Explain what was preserved, what remains unsupported, and how the change was tested. Do not claim a format or fidelity capability based only on a happy-path sample.

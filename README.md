# md_Hero

Converts input docs to md for LLMs — conserves tokens without sacrificing any information.

A native macOS app (SwiftUI) that turns documents into clean, token-light Markdown, ready to paste or upload to AI models.

**Documents in → Markdown out, with as few wasted tokens as possible.**

## Install (DMG)

The easiest way to beta test is the prebuilt DMG from CI:

1. Open the repo's **Actions → Build DMG** run (or the latest **Releases** page) and download `md_Hero-1.0.dmg`.
   - On a tag push (`v*`) the DMG is attached to a GitHub Release automatically; any manual run (**workflow_dispatch**) also publishes it as a downloadable build artifact.
2. Open the DMG and drag **md_Hero.app** to the **Applications** shortcut inside it.
3. First launch: the app is ad-hoc signed, so macOS Gatekeeper may ask for confirmation — right-click the app and choose **Open** once, or allow it in System Settings → Privacy & Security.

To build the DMG yourself on a Mac:

```bash
./scripts/make_dmg.sh        # test, build release .app, produce build/md_Hero-1.0.dmg
```

## Why

Raw exports from Word/PDF tools are full of repeated page headers, page numbers, image artifacts, link URLs, and redundant whitespace. Feeding that to an AI costs tokens on every request. md_Hero extracts the actual content and renders it as tight GFM (GitHub-Flavored Markdown).

## Supported formats

| Format | Engine |
| --- | --- |
| `.docx` | Built-in OOXML parser (headings, bullet/numbered lists, tables, hyperlinks) |
| `.odt` | Built-in OpenDocument parser (headings, lists, tables) |
| `.pdf` | PDFKit + heuristics: repeating headers/footers and lone page numbers are stripped, hyphenated line breaks are re-joined, flow text is reparagraphed, numbered / ALL-CAPS / standalone-title lines are promoted to headings |
| `.rtf` | NSAttributedString; heading levels detected from font size/weight |
| `.html` / `.htm` | NSAttributedString |
| `.txt` | Heuristic structuring |
| `.md` / `.markdown` | Passed through and cleaned |

Legacy binary `.doc` is not supported — save it as `.docx` first. Scanned (image-only) PDFs contain no text layer and need OCR before conversion.

## Token-saving options

- **Strip repeated headers, footers and page numbers** — detects lines that repeat on ≥ half of PDF pages (e.g. confidentiality banners), page-number-only lines.
- **Remove image placeholders** — drops `![…](…)` markup (images cost tokens, carry no text).
- **Strip link URLs, keep link text** — `[terms](https://…/very/long/url)` → `terms`.
- **Compact blank lines and whitespace** — collapses runs of blank lines and trailing spaces.

The app reports per-file word count and an estimated token count (≈ 4 characters per token), plus how many tokens were saved versus the raw extracted text.

## Build & run

Requirements: macOS 13+ and Xcode 14+ (or the Xcode Command Line Tools).

### Xcode

Open `Package.swift` in Xcode (`File → Open…`), select the `Pare` scheme (the executable product), and run. Distribution / drag-and-drop workflows are smoother with a bundled app:

```bash
./scripts/make_app.sh        # builds and assembles build/md_Hero.app (release)
open build/md_Hero.app
```

The script compiles with SwiftPM and wraps the executable in a minimal, ad-hoc signed `.app` bundle — no Xcode project file required. If you prefer an `.xcodeproj`, install [XcodeGen](https://github.com/yonaskolb/XcodeGen) and run `xcodegen` against this package.

### Command line

```bash
swift build                 # debug build of the app
swift run Pare              # build and launch the GUI
swift test                  # full test suite
```

## Usage

1. Drop files onto the window (or **Choose Files…**).
2. Optional: set an output folder (default: `.md` written next to each source file; name collisions are auto-uniquified, e.g. `report (2).md`).
3. **Convert.**
4. Per file: **Copy** puts the Markdown on the clipboard, **Reveal** shows the written file in Finder.

## Tests

```bash
swift test
```

The suite (in `Tests/PareTests`) converts real fixture documents (committed under `Tests/PareTests/Fixtures`) and asserts heading/list/table structure, header/footer stripping behavior, cleaner options, renderer output, and ZIP decoding.

### CI

`.github/workflows/dmg.yml` runs the test suite on a macOS GitHub Actions runner, packages `build/md_Hero.app` into a DMG (via `scripts/make_dmg.sh`), uploads it as a workflow artifact, and attaches it to a GitHub Release on `v*` tags.

## Project layout

```
Sources/PareCore      conversion engine (no UI dependency except PDFKit/AppKit for content reading)
  DocumentConverter   entry point, format dispatch, stats
  ZipArchive          minimal ZIP reader (stored + deflate via Apple's Compression)
  DocxParser          WordprocessingML → blocks
  OdtParser           OpenDocument XML → blocks
  PdfParser           PDFKit → lines → header/footer stripping → blocks
  AttributedParser    RTF/HTML → blocks (font-based heading detection)
  ProseStructure      line-based heading/bullet/paragraph heuristics
  MarkdownRenderer    blocks → GFM
  Cleaner             token-saving post-processing
Sources/Pare          SwiftUI app (window, drop zone, queue, options, stats)
Tests/PareTests       XCTest suite + fixtures
```

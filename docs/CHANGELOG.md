# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.1.0] - 2026-10-27

Publications made of many maps, folders and topic types now build as valid EPUB 3.3: the DITA-OT 4.4.1 user guide
(234 topics) passes EPUBCheck with no errors or warnings. See [EPUB33_CONFORMANCE.md](EPUB33_CONFORMANCE.md) for
the conformance review behind several of the fixes.

### Added
- **More DITA content rendered**: nested topics and multi-topic (`<dita>`) files, definition and parameter lists,
  simple tables (with key columns), simple lists, examples, divisions, task blocks, related links, and the
  programming, software, user interface, XML mention and highlighting domains. Review comments, data and foreign
  content are not published
- **XSpec tests** of the XSLT modules (`xspecTest` Gradle suite, run by `check`), on Saxon-HE 12.9 as in DITA-OT 4.4.1
- **`verifyPluginVersion`** check: the version is set once, in `build.gradle.kts`, and the build fails when
  `plugin.xml` or `plugin-info.xml` declares another one

### Changed
- **Accessibility metadata** follows EPUB Accessibility 1.1 and describes the generated content: access modes,
  features, hazards and a summary. Conformance is claimed only when the bookmap declares it with its evaluator
  (`accessibility-conformance` and `accessibility-certifier` data elements)
- **Package metadata** is read from the publication's own metadata (bookmap `bookmeta` or map `topicmeta`), not
  from key definitions, and no placeholder creator or publisher is written
- **Fallback identifier**: a UUID derived from the title, language and map file name, the same on every build
- **Content file names** have no spaces or characters OCF forbids; names of generated pages get a `topic-` prefix,
  and names that clash ignoring case are based on the topic path
- **Images**: only the images the publication references are packaged, `data:` images are kept as they are, remote
  images become links (EPUB requires images inside the publication), and DITA-OT no longer copies images into the
  output folder
- The viewport `meta` element is written for fixed layout only

### Deprecated
- `epub.accessibility` has no effect; it is kept so that existing build scripts keep working

### Fixed
- Only the root map is transformed; external links, non-DITA resources, key definitions and relationship tables are
  no longer treated as topics
- Cross-references across folders resolve to the flattened content documents, including links to elements and to
  topics of multi-topic files; a link whose target is not in the publication keeps its text
- Block content inside paragraphs produces valid XHTML; duplicate ids within a content document are dropped
- Index anchors for index terms in the topic prolog
- Image paths, and image sizes in units other than pixels (written as CSS)
- The font obfuscation key keeps the hyphens of the identifier (EPUB 3.3 OCF)
- Valid manifest ids; a TOC heading cut by `epub.toc.depth` links to its first topic
- `file:` URLs in cross-references are kept as text (EPUB 3.3 forbids them)
- NCX: a topic referenced twice keeps the `playOrder` of its first reference (EPUBCheck `RSC-005` on KDP builds)

## [2.0.0] - 2026-03-09

### Added
- **Theme System**: `epub.theme` parameter with 5 built-in themes (`default`, `academic`, `fiction`, `technical`, `training`)
  - CSS-only themes via `:root` variable overrides — no duplication of base rules
  - Cascade order: `epub-default.css` → `epub-theme-*.css` → `epub-platform-*.css` → `epub-fonts.css` → custom CSS → `epub-fxl.css`
  - Theme CSS automatically added to OPF manifest and all XHTML pages
  - Parameter validation with fallback to `default` for unrecognized values
- **Platform Variants**: `epub.platform` parameter (`generic`, `kdp`, `apple`, `kobo`)
  - **Amazon KDP**: forced NCX generation, expanded `<guide>` element, KDP-safe CSS overlay, SVG/cover/font warnings
  - **Apple Books**: `ibooks:specified-fonts` and `ibooks:version` OPF metadata with `prefix` attribute
  - **Kobo**: standard EPUB3 with cover validation warnings
  - New `epub3-platform.xsl` module for platform-specific logic
  - NCX generation now conditional (forced for KDP, optional via `epub.generate.ncx`)
- **Fixed Layout EPUB**: `epub.layout` parameter (`reflowable`, `fixed`)
  - `epub.fxl.width`, `epub.fxl.height` viewport dimensions with numeric validation
  - `epub.fxl.orientation` (`auto`, `portrait`, `landscape`) and `epub.fxl.spread` (`auto`, `both`, `landscape`, `none`)
  - OPF rendition metadata: `rendition:layout` (pre-paginated), `rendition:orientation`, `rendition:spread`
  - Fixed-layout CSS overlay (`epub-fxl.css`): viewport-filling pages, disabled reflow features
  - `<meta name="viewport">` with exact pixel dimensions on all XHTML pages
- **CSS Foundation**: Refactored to CSS custom properties for theme overridability
  - CSS logical properties for RTL support (`border-inline-start`, `padding-inline-start`, `text-align: start`)
  - Arabic, Hebrew, Farsi, Urdu font stacks with `:lang()` selectors
  - `--spacing-section` variable for section spacing
- **Global Figure/Table Numbering**: Cross-topic sequential numbering via `xsl:iterate` offset pre-computation

### Fixed
- OPF `<guide>` element removed for non-KDP platforms (deprecated in EPUB 3.3)
- `epub:is-true('wcag-aa')` now correctly evaluates as truthy for accessibility viewport
- `dpubAria` metadata now conditional on `epub.aria.landmarks`
- `epub.generate.ncx`, `epub.generate.index`, `epub.generate.glossary` now passed from Ant to XSLT
- CJK drop-cap override uses logical `padding-inline-end` instead of physical `padding-right`
- `inset-inline-start` fallback with `left:` for limited EPUB reader support
- Theme CSS variable name mismatches (`--color-code-bg` → `--color-background-code`, `--syntax-*` → `--color-syntax-*`)

## [1.5.0] - 2026-03-05

### Added
- **DPUB-ARIA Roles**: `doc-chapter`, `doc-appendix`, `doc-foreword`, `doc-preface`, `doc-dedication`,
  `doc-colophon`, `doc-copyright`, `doc-errata`, `doc-glossary`, `doc-acknowledgments`, `doc-introduction`,
  `doc-epilogue` roles on `<article>` elements derived from `epub:type`
  - `dpubAria` accessibility feature declared in OPF metadata
  - Footnote aside corrected from `role="doc-footnote"` to `role="doc-endnotes"`
- **RTL Language Support**: Arabic, Hebrew, Farsi, Urdu text direction
  - `epub:is-rtl()` and `epub:get-dir()` utility functions
  - `dir` attribute on all `<html>` elements (content, nav, cover, title, copyright, index, glossary)
  - RTL-aware CSS: mirrored note borders, sidebar float, list padding, pull quote borders
- **CSS Hyphenation**: `hyphens: auto` on `p`, `li`, `dd`, `blockquote`; `hyphens: none` on `pre`, `code`
  - `lang` attribute on `<p>` elements for hyphenation engine
- **Arabic/Hebrew i18n Labels**: All ~30 i18n choose blocks updated with Arabic and Hebrew translations
  - Note labels (tip, important, warning, caution, danger, note)
  - Figure and table numbering labels
  - Navigation labels (TOC, landmarks, bodymatter, glossary, index, preface, dedication, appendix, colophon, copyright)
  - Title page labels (By, Translation, Licensed under)
  - Copyright page labels (All rights reserved, Published by, Licensed under)
- **List of Figures (LOF)**: `lof.xhtml` with `<nav epub:type="loi">`
  - Collects all `<fig>` with titles via `document()` calls
  - Conditional generation: `epub.generate.lof` param (no/yes/auto)
  - OPF manifest/spine, TOC and landmarks entries
  - `listOfIllustrations` accessibility feature
  - Full i18n headings (12 languages)
- **List of Tables (LOT)**: `lot.xhtml` with `<nav epub:type="lot">`
  - Same pattern as LOF for tables with titles
  - `epub.generate.lot` param (no/yes/auto)
  - `listOfTables` accessibility feature
- **Extended Image Descriptions**: `aria-describedby` linking to hidden `<div>` for `<desc>` siblings
  - Decorative images: `@outputclass='decorative'` or `@alt=''` → `alt="" role="presentation"`
  - Missing alt text: `xsl:message` warning + empty alt fallback
- **CJK Typography CSS**: `word-break: keep-all`, `overflow-wrap: break-word`, `line-break: strict`
  - Japanese: Hiragino Mincho ProN / Yu Mincho font stack
  - Chinese: PingFang SC / Heiti SC font stack
  - Drop caps and hyphenation disabled for CJK languages
- **Locale-Aware Quotation Marks**: `epub:get-quotes()` function with per-language quote pairs
  - `epub.locale.quotes=yes`: `<span class="q">` with explicit Unicode quote chars
  - `epub.locale.quotes=no` (default): standard `<q>` element
  - Supports: fr «», de „", ja 「」, zh "", ar/he «», es/it «», pt/en ""
- **Visually Hidden CSS Class**: `.visually-hidden` for screen-reader-only content

### Parameters Added
- `epub.hyphenation` (enum: auto/yes/no, default: auto) — CSS hyphenation mode
- `epub.locale.quotes` (enum: yes/no, default: no) — Locale-aware quotation marks

### Parameters Activated
- `epub.generate.lof` (enum: no/yes/auto, default: no) — List of Figures generation
- `epub.generate.lot` (enum: no/yes/auto, default: no) — List of Tables generation

## [1.4.0] - 2026-03-05

### Added
- **ISBN/ASIN Identifier Support**: Extract ISBN from bookmap `<bookid><isbn>` or override via `epub.isbn` parameter
  - ONIX codelist5 identifier-type refinement: ISBN-13 (15), ISBN-10 (02), ASIN (01)
  - Fallback to UUID when no ISBN is present
- **Series Metadata**: `belongs-to-collection` with `collection-type` and `group-position`
  - Parameters: `epub.series.name`, `epub.series.position`
  - Also reads from bookmap `<data name="series">` and `<data name="series-position">`
- **Multiple Contributor Roles**: MARC relator code lookup for all contributor types
  - `epub:marc-relator()` function maps human-readable roles to MARC codes
  - Extracts translators (`trl`) and editors (`edt`) from bookmeta `<data>` elements
  - Supports: author, editor, translator, illustrator, reviewer, narrator, photographer, designer, foreword, afterword
- **BISAC/ONIX Subject Classifications**: Comma-separated BISAC codes via `epub.bisac.codes` parameter
  - Also reads from bookmap `<data name="bisac">` elements
- **Frontmatter/Backmatter epub:type Expansion**: Full EPUB Structural Semantics support
  - `dedication`, `colophon`, `copyright-page`, `errata`, `acknowledgments`, `halftitlepage`, `introduction`, `epilogue`
  - `@type` attribute override on topicrefs for explicit epub:type mapping
- **Extended Landmarks Navigation**: Conditional entries for preface, dedication, appendix, colophon, copyright page
  - All labels i18n-aware (10 languages) following existing pattern
- **Auto-Generated Copyright Page**: `copyright.xhtml` from bookmap metadata
  - `epub.copyright.page` parameter: `auto` (default), `yes`, `no`
  - Includes title, copyright notice, "All rights reserved", publisher, license, ISBN
  - Added to OPF manifest/spine after title page

### Parameters Added
- `epub.isbn` (string, default: empty) — ISBN override
- `epub.series.name` (string, default: empty) — Series/collection name
- `epub.series.position` (string, default: empty) — Volume position in series
- `epub.bisac.codes` (string, default: empty) — Comma-separated BISAC subject codes
- `epub.copyright.page` (enum: auto/yes/no, default: auto) — Generate copyright page

## [1.3.0] - 2026-03-05

### Added
- **Custom CSS Injection**: New `epub.custom.css` parameter to include publisher's custom stylesheet
- **Auto @font-face CSS**: Automatic `@font-face` CSS generation from embedded font files
  - Font family, weight, style, and format detection from filenames
  - `epub-fonts.css` auto-generated in styles directory
  - New `epub.generate.font.css` parameter (default: yes)
- **Footnotes/Endnotes**: EPUB 3 `epub:type="footnote"` / `noteref` support
  - Inline superscript reference markers with backlinks
  - End-of-topic footnote sections with `role="doc-endnotes"`
  - Popup support in Apple Books and Kobo
- **Figure Auto-Numbering**: Automatic "Figure N." labels on `<fig>` elements
  - Global sequential numbering via `epub.figure.numbering` parameter
  - Language-aware labels (Figure/Abbildung/Figura/...)
- **Table Auto-Numbering**: Automatic "Table N." labels on `<table>` captions
  - Global sequential numbering via `epub.table.numbering` parameter
- **Table Enhancements**: colspan, rowspan, alignment from colspec, zebra striping
  - `@morerows` → `rowspan`, `@namest`/`@nameend` → `colspan`
  - `colspec/@align` → `text-align` inline style
  - `.row-odd` / `.row-even` classes via `epub.table.zebra` parameter
- **Code Block Enhancements**: Language CSS class and optional line numbers
  - `@outputclass` → `class="language-{outputclass}"` on `<code>` and `<pre>`
  - Line number wrapping via `epub.code.line.numbers` parameter
  - Base syntax highlight CSS classes (.keyword, .string, .comment, .number, .tag)
- **Drop Caps**: Decorative first-letter styling on chapter opening paragraphs
  - `epub.drop.caps` parameter (default: no)
- **Pull Quotes**: `<lq>` elements rendered as styled blockquotes with attribution
- **Sidebars**: `<section outputclass="sidebar">` rendered as floating `<aside>` boxes
- **Typography Showcase**: New test topic exercising all v1.3 features

### Fixed
- **Note Labels i18n**: Replaced hardcoded French note labels with language-aware labels
  - All 10 supported languages: en, fr, de, es, it, pt, nl, ja, zh + fallback
  - All note types: tip, important, warning, caution, danger, note/notice

### Parameters Added
- `epub.custom.css` (file, default: empty)
- `epub.generate.font.css` (enum: yes/no, default: yes)
- `epub.figure.numbering` (enum: global/none, default: global)
- `epub.table.numbering` (enum: global/none, default: global)
- `epub.table.zebra` (enum: yes/no, default: yes)
- `epub.code.line.numbers` (enum: yes/no, default: no)
- `epub.code.syntax.classes` (enum: yes/no, default: yes)
- `epub.drop.caps` (enum: yes/no, default: no)

## [1.2.0] - 2026-03-05

### Added
- **Font Obfuscation**: Adobe/IDPF font obfuscation algorithm per EPUB OCF 3.3 Section 4.2
  - SHA-1 key derivation from unique identifier
  - XOR first 1040 bytes of each font file
  - `META-INF/encryption.xml` generation
  - New `FontObfuscator.java` utility
- **Image Optimization**: JPEG quality reduction, PNG metadata stripping, optional resize
  - Configurable JPEG quality (0.0-1.0, default 0.8)
  - Maximum width constraint with aspect ratio preservation
  - Size threshold (50KB) to skip small icons
  - New `ImageOptimizer.java` utility
- **Language Support**: Added Italian (it), Portuguese (pt), Dutch (nl), Japanese (ja), Chinese (zh) to all navigation labels
  - Landmarks heading, TOC label, bodymatter label
  - Glossary and index labels in landmarks, TOC, and page titles
  - Appendices navtitle
  - Title page labels (By, Translation, Licensed under)
- **Font Manifest**: Dynamic font manifest generation from actual font files via Ant pipeline scanning
  - Replaces previous placeholder implementation
  - `epub.font.files` parameter passed from Ant to XSLT
  - `epub:get-font-media-type()` function for font MIME types

### Changed
- `add-font-items` template now produces actual OPF `<item>` entries from scanned font files
- Ant pipeline now includes `epub3.scan.fonts`, `epub3.obfuscate.fonts`, and `epub3.optimize.images` targets

### Parameters Added
- `epub.optimize.images` (enum: yes/no, default: no)
- `epub.image.jpeg.quality` (string, default: 0.8)
- `epub.image.max.width` (string, default: 0)
- `epub.font.files` (internal, passed from Ant pipeline)

## [1.1.0] - 2026-02-20

### Added
- Back-of-book index generation from `<indexterm>` elements
- Consolidated glossary from `<glossentry>` topics
- EPUB 3.3 Structural Semantics Vocabulary compliance
- Three test datasets with 0 EPUBCheck errors

## [1.0.0] - 2025-12-01

### Initial Release
- EPUB3 transformation support
- DITA-OT 4.4 compatibility
- Gradle build integration
- Accessibility built-in (WCAG 2.1 AA)
- Cover page generation
- Font embedding
- Modern Java 17 support
- Comprehensive documentation

---

## Release Notes Format

### Added
- New features

### Changed
- Changes to existing functionality

### Deprecated
- Features that will be removed in future releases

### Removed
- Removed features

### Fixed
- Bug fixes

### Security
- Security fixes

---

[Unreleased]: https://github.com/jyjeanne/dita2epub/compare/v1.5.0...HEAD
[1.5.0]: https://github.com/jyjeanne/dita2epub/compare/v1.4.0...v1.5.0
[1.4.0]: https://github.com/jyjeanne/dita2epub/compare/v1.3.0...v1.4.0
[1.3.0]: https://github.com/jyjeanne/dita2epub/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/jyjeanne/dita2epub/compare/v1.1.0...v1.2.0
[1.1.0]: https://github.com/jyjeanne/dita2epub/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/jyjeanne/dita2epub/releases/tag/v1.0.0

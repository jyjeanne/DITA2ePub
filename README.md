# DITA2ePub - Modern EPUB3 Transformation Plugin

<div align="center">

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![DITA-OT](https://img.shields.io/badge/DITA--OT-4.4.1-green.svg)](https://www.dita-ot.org/)
[![EPUB](https://img.shields.io/badge/EPUB-3.3-purple.svg)](https://www.w3.org/publishing/epub3/)
[![Java](https://img.shields.io/badge/Java-17%2B-orange.svg)](https://adoptium.net/)
[![Tests](https://img.shields.io/badge/tests-48%20passing-success.svg)](#testing)

[![CI Build](https://github.com/jyjeanne/dita2epub/actions/workflows/ci.yml/badge.svg)](https://github.com/jyjeanne/dita2epub/actions/workflows/ci.yml)
[![Documentation](https://github.com/jyjeanne/dita2epub/actions/workflows/docs.yml/badge.svg)](https://github.com/jyjeanne/dita2epub/actions/workflows/docs.yml)

**Transform your DITA content into professional, accessible EPUB 3.3 publications**

[Quick Start](#-quick-start) • [Documentation](#-documentation-hub) • [Features](#-key-features) • [Examples](#-usage)

</div>

---

## About

**DITA2ePub** is a production-ready DITA-OT plugin that transforms DITA content into standards-compliant EPUB 3.3 publications. Built for technical writers, documentation teams, and publishers who demand professional-quality e-books with modern features and accessibility compliance.

### Why DITA2ePub?

- **Standards-Compliant**: EPUB 3.3 output validated with EPUBCheck, with EPUB Accessibility 1.1 metadata
- **Professional Output**: Custom cover pages, embedded fonts, optimized images, and typographic features
- **Production-Ready**: 48 automated tests (unit and end-to-end), EPUBCheck validation with zero errors, CI/CD automation
- **Developer-Friendly**: XSLT 3.0 modular architecture, Gradle build system, complete documentation
- **Modern Stack**: Built and tested on DITA-OT 4.4.1, Java 17+, and latest web standards

### What's New in v2.0.0?

- **Theme system** — 5 built-in themes (`default`, `academic`, `fiction`, `technical`, `training`) built on CSS custom properties
- **Platform variants** — Target-specific output for Amazon KDP, Apple Books, Kobo, or generic EPUB
- **Fixed Layout EPUB** — Viewport dimensions, orientation and spread controls, `rendition:*` OPF metadata
- **RTL language support** — Arabic, Hebrew, Farsi, Urdu with CSS logical properties and tuned font stacks
- **Global figure/table numbering** — Sequential numbering across topics
- **DITA-OT 4.4.1** — Built and tested against DITA-OT 4.4.1, with the full integration test suite running end to end
- **Bug fixes** — Font embedding no longer aborts on an invalid Ant copy condition; topics sharing a file name in
  different folders no longer overwrite each other; OPF `<guide>` only emitted for KDP

See [CHANGELOG.md](docs/CHANGELOG.md) for the full list of changes.

### Previous Releases

- **v1.5.0**: Font obfuscation, image optimization, back-of-book index, consolidated glossary, List of Figures/Tables, auto-generated copyright page, drop caps
- **v1.4.0**: ISBN/ASIN identifiers, series metadata, BISAC codes, contributor roles, copyright page, landmarks
- **v1.3.0**: Custom CSS, footnotes with backlinks, figure/table numbering, pull quotes, sidebars
- **v1.2.0**: EPUB 3.3 compliance, NCX generation, EPUBCheck integration, cover pages, WCAG-AA metadata
- **v1.1.0**: Internationalized note labels (eleven languages), locale-aware quotation marks
- **v1.0.0**: Initial release with EPUB 3.3 generation, font embedding, navigation

---

## Key Features

### Core Capabilities
- **EPUB 3.3 Standard**: Full compliance with latest EPUB specification and Structural Semantics Vocabulary (SSV)
- **DITA-OT 4.4+ Integration**: Seamless plugin architecture
- **XHTML5 Output**: Modern, semantic HTML content with proper `epub:type` annotations
- **Accessibility Built-in**: EPUB Accessibility 1.1 metadata that reflects the actual content, skip-navigation links, alt text checks
- **Navigation**: Automatic TOC, landmarks, and NCX generation

### Advanced Features
- **Theme System**: 5 built-in themes (default, academic, fiction, technical, training) via CSS custom properties
- **Platform Variants**: Target-specific output for Amazon KDP, Apple Books, Kobo, or generic EPUB
- **Fixed Layout EPUB**: For children's books, cookbooks, comics with viewport dimensions and rendition controls
- **RTL Language Support**: Arabic, Hebrew, Farsi, Urdu with CSS logical properties and bidirectional text
- **Back-of-Book Index**: Automatic index from `<indexterm>` elements with nested entries, cross-references, and anchor links
- **Consolidated Glossary**: Automatic glossary from `<glossentry>` topics with alphabetical grouping
- **Cover Page Generation**: Automatic HTML cover pages with customizable styles
- **Font Embedding & Obfuscation**: Embed custom fonts (TTF, OTF, WOFF, WOFF2) with IDPF obfuscation
- **Image Optimization**: JPEG quality control, max-width resizing, recursive directory scanning
- **Typography**: Drop caps, zebra-striped tables, figure/table numbering, locale-aware quotation marks
- **EPUBCheck 5.3.0 Integration**: Built-in validation with zero errors
- **Comprehensive Testing**: 47 test methods across 8 test classes

### Developer Experience
- **Gradle Build System**: Modern build configuration with Kotlin DSL
- **Extensible Architecture**: 9 XSLT 3.0 modules with clear separation of concerns
- **Complete Documentation**: Guides, EPUB 3 anatomy reference, and API docs
- **CI/CD Ready**: GitHub Actions workflow templates

---

## Table of Contents

- [About](#about) - Why DITA2ePub? What's new?
- [Key Features](#key-features) - Core capabilities and advanced features
- [Requirements](#requirements) - System requirements
- [Quick Start](#-quick-start) - Installation and first EPUB
- [Usage](#-usage) - Examples and use cases
  - [Basic Transformation](#basic-transformation)
  - [Cover Page Generation](#cover-page-generation)
  - [Font Embedding](#font-embedding)
  - [Advanced Configuration](#advanced-configuration)
- [Configuration Parameters](#-configuration-parameters) - Complete reference
- [Project Structure](#-project-structure) - Codebase organization
- [Testing](#-testing) - Test suite and coverage
- [Documentation Hub](#-documentation-hub) - All documentation links
- [Use Cases](#-use-cases) - Real-world examples
- [Contributing](#-contributing) - How to contribute
- [License](#-license) - Apache 2.0

---

## Requirements

| Component | Version | Notes |
|-----------|---------|-------|
| **DITA-OT** | 4.4+ | [Download](https://www.dita-ot.org/download) |
| **Java** | 17+ | [Adoptium OpenJDK](https://adoptium.net/) recommended |
| **Gradle** | 8.x+ | Wrapper included in project |

### Optional Tools
- **EPUBCheck** 5.3.0+ for validation ([Download](https://github.com/w3c/epubcheck/releases))
- **Calibre** for EPUB viewing and testing

---

## Quick Start

### 1. Installation

```bash
# Clone the repository
git clone https://github.com/jyjeanne/dita2epub.git
cd dita2epub

# Build the plugin package (build/plugin/io.github.jyjeanne.dita2epub.zip)
./gradlew packagePlugin

# Install it into your DITA-OT
$DITA_HOME/bin/dita install build/plugin/io.github.jyjeanne.dita2epub.zip
```

### 2. Verify Installation

```bash
# List installed plugins
dita plugins | grep epub

# Expected output:
# io.github.jyjeanne.dita2epub@2.0.0
```

### 3. Generate Your First EPUB

```bash
dita --input=mybook.ditamap --format=epub3 --output=output
```

**Done!** Your EPUB will be in `output/mybook.epub`

### Build Commands Reference

```bash
# Build and test
./gradlew build                  # Compile + tests
./gradlew test                   # Unit tests; integration tests also run when DITA_HOME is set (see Testing)

# EPUB generation (downloads DITA-OT 4.4.1 on first run)
./gradlew buildSampleEpub        # Build + validate sample EPUB
./gradlew buildAllEpubs          # Build all test datasets

# Validation
./gradlew validateEpub           # EPUBCheck on sample EPUB
./gradlew validateAllEpubs       # EPUBCheck on all outputs

# Full CI pipeline
./gradlew ciCheck                # Compile, test, build EPUBs, EPUBCheck
```

> **Windows:** the Gradle EPUB tasks (`buildSampleEpub`, `buildAllEpubs`, `ciCheck`, …) currently fail because the
> generated `dita.bat` command line exceeds the 8191-character `cmd.exe` limit. Run `dita` directly or use Linux/macOS;
> see [Known Limitations](docs/SPECIFICATION.md#known-limitations).

---

## Usage

### Basic Transformation

Transform a DITA bookmap to EPUB3:

```bash
dita --input=mybook.ditamap \
     --format=epub3 \
     --output=output
```

**Result**: Creates `output/mybook.epub` with default settings.

### Cover Page Generation

#### Automatic Cover Page with Full-Page Style

```bash
dita --input=mybook.ditamap \
     --format=epub3 \
     --output=output \
     --epub.cover.image=images/cover.jpg \
     --epub.generate.cover.page=yes \
     --epub.cover.page.style=full-page
```

#### Centered Cover Style

```bash
dita --input=mybook.ditamap \
     --format=epub3 \
     --output=output \
     --epub.cover.image=images/cover.jpg \
     --epub.cover.page.style=centered
```

**Available Styles**:
- `full-page` (default) - Cover fills entire viewport
- `centered` - Cover centered with padding
- `custom` - Use your own CSS

### Font Embedding

Embed custom fonts in your EPUB:

```bash
dita --input=mybook.ditamap \
     --format=epub3 \
     --output=output \
     --epub.embed.fonts=/path/to/fonts/
```

**Supported Formats**: TTF, OTF, WOFF, WOFF2

**Font Directory Structure**:
```
fonts/
├── MyFont-Regular.woff2
├── MyFont-Bold.woff2
├── MyFont-Italic.woff2
└── MyFont-BoldItalic.woff2
```

**Configure Font CSS** (in `epub-fonts.css`):
```css
@font-face {
  font-family: 'MyFont';
  src: url('../fonts/MyFont-Regular.woff2') format('woff2');
  font-weight: 400;
  font-style: normal;
}
```

### Back-of-Book Index

Generate an index from `<indexterm>` elements in your DITA topics:

```bash
dita --input=mybook.ditamap \
     --format=epub3 \
     --output=output \
     --epub.generate.index=yes
```

The index generator supports:
- Simple and nested index entries
- `<index-see>` ("See") cross-references
- `<index-see-also>` ("See also") cross-references
- `<index-sort-as>` for custom sort ordering
- Alphabetical grouping with chapter.section locators
- Precise anchor links to the exact location in the content

When set to `auto` (default), the index is generated automatically when a `<indexlist/>` element is present in the bookmap.

### Consolidated Glossary

Generate a consolidated glossary page from DITA `<glossentry>` topics:

```bash
dita --input=mybook.ditamap \
     --format=epub3 \
     --output=output \
     --epub.generate.glossary=auto
```

The glossary generator:
- Collects all `<glossentry>` topics referenced from a `<glossarylist>` in the bookmap
- Extracts `<glossterm>` and `<glossdef>` from each entry
- Groups entries alphabetically by first letter
- Produces a consolidated `glossary.xhtml` with EPUB 3.3 `<dl epub:type="glossary">` semantic markup
- Adds the glossary to the TOC, landmarks navigation, OPF manifest, and spine
- Individual glossentry XHTML files are suppressed in favor of the consolidated page

When set to `auto` (default), the glossary is generated automatically when a `<glossarylist>` with topicrefs is present in the bookmap backmatter.

**Bookmap structure**:
```xml
<backmatter>
  <booklists>
    <glossarylist>
      <topicref href="glossary/term-epub.dita" keys="gl-epub"/>
      <topicref href="glossary/term-dita.dita" keys="gl-dita"/>
    </glossarylist>
  </booklists>
</backmatter>
```

**Glossentry topic format**:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE glossentry PUBLIC "-//OASIS//DTD DITA Glossary Entry//EN" "glossentry.dtd">
<glossentry id="epub">
  <glossterm>EPUB</glossterm>
  <glossdef>Electronic Publication — an open standard for digital books.</glossdef>
</glossentry>
```

### Advanced Configuration

Complete example with all major features:

```bash
dita --input=mybook.ditamap \
     --format=epub3 \
     --output=output \
     --epub.version=3.3 \
     --epub.cover.image=images/cover.svg \
     --epub.generate.cover.page=yes \
     --epub.cover.page.style=full-page \
     --epub.embed.fonts=fonts/ \
     --epub.generate.index=auto \
     --epub.generate.glossary=auto \
     --epub.toc.depth=4 \
     --epub.nav.depth=4 \
     --epub.accessibility=wcag-aa \
     --epub.validate=yes
```

---

## Configuration Parameters

### Core Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.version` | string | `3.3` | EPUB specification version (3.3, 3.0, 2.0.1) |
| `epub.accessibility` | enum | `wcag-aa` | No effect on the output, kept so existing build scripts keep working (wcag-a, wcag-aa, wcag-aaa); accessibility metadata is derived from the content, see [Accessibility Metadata](#accessibility-metadata) |
| `epub.toc.depth` | integer | `5` | Maximum table of contents depth |
| `epub.nav.depth` | integer | `5` | Maximum navigation document depth |
| `epub.aria.landmarks` | enum | `yes` | Generate ARIA landmarks |
| `epub.generate.ncx` | enum | `no` | Generate an EPUB 2 NCX file (always generated for `epub.platform=kdp`) |

### Cover Page Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.cover.image` | path | `(none)` | Path to cover image file (JPG, PNG, SVG) |
| `epub.generate.cover.page` | boolean | `yes` | Generate HTML cover page from image |
| `epub.cover.page.style` | enum | `full-page` | Cover page style (full-page, centered, custom) |

### Index Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.generate.index` | enum | `auto` | Generate back-of-book index: `auto` (detect from bookmap), `yes`, `no` |

When set to `auto`, index generation triggers automatically when a `<indexlist/>` element is present in the bookmap. The index collects all `<indexterm>` elements from topics, groups them alphabetically, and generates an `index.xhtml` file with EPUB 3.3 Structural Semantics Vocabulary markup.

### Glossary Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.generate.glossary` | enum | `auto` | Generate consolidated glossary: `auto` (detect from bookmap), `yes`, `no` |

When set to `auto`, glossary generation triggers automatically when a `<glossarylist>` element with topicrefs is present in the bookmap. The glossary collects `<glossterm>` and `<glossdef>` from all referenced `<glossentry>` topics, groups them alphabetically, and generates a `glossary.xhtml` file with EPUB 3.3 `<dl epub:type="glossary">` markup.

### List of Figures / Tables Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.generate.lof` | enum | `no` | Generate List of Figures: `auto` (detect `<figurelist/>` in bookmap), `yes`, `no` |
| `epub.generate.lot` | enum | `no` | Generate List of Tables: `auto` (detect `<tablelist/>` in bookmap), `yes`, `no` |

### Font Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.embed.fonts` | path | `(none)` | Directory containing fonts to embed |
| `epub.obfuscate.fonts` | boolean | `no` | Enable IDPF font obfuscation |

### Image Optimization Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.optimize.images` | boolean | `no` | Optimize images for EPUB (reduce file size) |
| `epub.image.jpeg.quality` | float | `0.8` | JPEG compression quality (0.0-1.0) |
| `epub.image.max.width` | integer | `0` | Max image width in pixels (0 = no limit) |

### Directory Structure

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.topics.dir` | string | `content` | Directory for topic XHTML files |
| `epub.images.dir` | string | `images` | Directory for images |
| `epub.fonts.dir` | string | `fonts` | Directory for embedded fonts |
| `epub.css.dir` | string | `styles` | Directory for CSS files |

### Metadata & Retail Distribution Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.isbn` | string | `(none)` | ISBN override (extracts from bookmap if empty) |
| `epub.series.name` | string | `(none)` | Series/collection name |
| `epub.series.position` | string | `(none)` | Volume position in series |
| `epub.bisac.codes` | string | `(none)` | Comma-separated BISAC subject codes |
| `epub.copyright.page` | enum | `auto` | Generate copyright page: `auto`, `yes`, `no` |

### Typography & Styling Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.custom.css` | path | `(none)` | Path to custom CSS file to include |
| `epub.generate.font.css` | enum | `yes` | Auto-generate `@font-face` CSS from fonts |
| `epub.figure.numbering` | enum | `global` | Figure numbering: `global`, `none` |
| `epub.table.numbering` | enum | `global` | Table numbering: `global`, `none` |
| `epub.table.zebra` | enum | `yes` | Zebra striping on table rows |
| `epub.code.line.numbers` | enum | `no` | Line numbers in code blocks |
| `epub.code.syntax.classes` | enum | `yes` | Language CSS class on code blocks |
| `epub.drop.caps` | enum | `no` | Drop caps on chapter first paragraphs |
| `epub.hyphenation` | enum | `auto` | CSS hyphenation mode: `auto`, `yes`, `no` |
| `epub.locale.quotes` | enum | `no` | Locale-aware quotation marks |

### Theme Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.theme` | enum | `default` | Visual theme: `default`, `academic`, `fiction`, `technical`, `training` |

### Platform Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.platform` | enum | `generic` | Target platform: `generic`, `kdp`, `apple`, `kobo` |

### Fixed Layout Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.layout` | enum | `reflowable` | Layout type: `reflowable`, `fixed` |
| `epub.fxl.width` | integer | `1024` | Viewport width in pixels |
| `epub.fxl.height` | integer | `768` | Viewport height in pixels |
| `epub.fxl.orientation` | enum | `auto` | Orientation: `auto`, `portrait`, `landscape` |
| `epub.fxl.spread` | enum | `auto` | Spread: `auto`, `both`, `landscape`, `none` |

### Validation

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.validate` | boolean | `yes` | Run EPUBCheck validation (if available) |

### Accessibility Metadata

The package document gets [EPUB Accessibility 1.1](https://www.w3.org/TR/epub-a11y-11/) discovery metadata
that describes the generated content: access modes (`visual` only when there are images), sufficient access
modes, features (`structuralNavigation`, `tableOfContents`, `readingOrder`, `ARIA`, plus `index` and
`alternativeText` when they apply), hazards, and a summary that reports images without a text alternative.

The plugin does not claim WCAG conformance by itself, since that requires an evaluation. After evaluating the
publication, declare the claim and the evaluator in the bookmap:

```xml
<bookmeta>
  <data name="accessibility-conformance" value="EPUB Accessibility 1.1 - WCAG 2.2 Level AA"/>
  <data name="accessibility-certifier" value="Example Accessibility Services"/>
  <!-- Optional: replaces the generated summary -->
  <data name="accessibility-summary" value="..."/>
</bookmeta>
```

These become `dcterms:conformsTo` and `a11y:certifiedBy`. A conformance value without a certifier is ignored
with a warning, because EPUB Accessibility 1.1 requires both.

**Complete Reference**: See [SPECIFICATION.md](docs/SPECIFICATION.md) for all parameters

---

## Project Structure

```
dita2epub/
├── src/
│   ├── main/
│   │   ├── java/               # Java utilities (packaging, font obfuscation, image optimization)
│   │   ├── xsl/                # XSLT 3.0 transformation modules (9 modules)
│   │   │   ├── map2epub3.xsl          # Main entry point
│   │   │   ├── epub3-params.xsl       # Parameter definitions
│   │   │   ├── epub3-common.xsl       # Common functions
│   │   │   ├── epub3-metadata.xsl     # Metadata extraction
│   │   │   ├── epub3-content.xsl      # Content generation
│   │   │   ├── epub3-impl.xsl         # OPF/navigation
│   │   │   ├── epub3-index.xsl        # Back-of-book index generation
│   │   │   ├── epub3-glossary.xsl     # Consolidated glossary generation
│   │   │   └── epub3-platform.xsl     # Platform-specific logic
│   │   └── resources/
│   │       ├── css/            # Stylesheets (8 files)
│   │       │   ├── epub-default.css         # Default styles (CSS custom properties)
│   │       │   ├── epub-theme-*.css         # Theme overrides (4 themes)
│   │       │   ├── epub-platform-kdp.css    # KDP-safe CSS
│   │       │   ├── epub-fxl.css             # Fixed Layout CSS overlay
│   │       │   └── epub-fonts.css           # Font declarations
│   │       └── fonts/          # Font directory (empty template)
│   └── test/
│       ├── java/               # Test classes (47 test methods)
│       └── resources/
│           ├── dita/               # Complete English bookmap (18 topics, 10 glossary entries)
│           ├── dita-kdp/           # Amazon KDP commercial novel
│           ├── dita-comprehensive/ # Feature-coverage map
│           ├── dita-edge-cases/    # EPUB 3.3 conformance edge cases
│           └── epub/               # Reference EPUB for validation
├── plugin.xml                  # DITA-OT plugin descriptor
├── build-epub3.xml             # Ant build integration
├── build.gradle.kts            # Gradle build configuration
└── docs/                       # Documentation
    ├── ANATOMY_EPUB_THREE.md   # EPUB 3 file structure reference
    ├── CHANGELOG.md            # Version changelog
    ├── CONTRIBUTING.md         # Contribution guidelines
    ├── EPUB33_CONFORMANCE.md   # EPUB 3.3 conformance review and open findings
    ├── GITHUB_CHECKLIST.md     # GitHub procedures
    ├── PROJECT_STATUS.md       # Project status and metrics
    ├── QUICKSTART.md           # Quick start guide
    ├── REGISTRY.md             # Publishing to the DITA-OT plugin registry
    ├── RELEASE_NOTES.md        # Version history
    ├── ROADMAP.md              # Planned milestones and improvements
    ├── SPECIFICATION.md        # Complete technical specification
    ├── TEST_COVERAGE.md        # Test documentation
    └── TEST_SUMMARY.md         # Executive test summary
```

---

## Testing

### Test Suite Overview

- **47 test methods** (48 test runs) across 8 test classes, all passing against DITA-OT 4.4.1
- **4 test datasets**: complete English bookmap, Amazon KDP novel, a comprehensive feature map, and EPUB 3.3 edge cases
- **0 EPUBCheck errors** on generated EPUBs

### Running Tests

```bash
# Unit tests only (no DITA-OT required; integration tests are skipped)
./gradlew test

# Full suite including integration tests (about 10 minutes)
./gradlew installLocalPlugin                            # downloads DITA-OT 4.4.1 and installs the plugin
export DITA_HOME=$PWD/build/dita-ot/dita-ot-4.4.1       # Windows: set DITA_HOME=%CD%\build\dita-ot\dita-ot-4.4.1
./gradlew test

# Single test class
./gradlew test --tests EpubValidatorTest

# View test report
open build/reports/tests/test/index.html
```

Integration tests run the plugin installed in `DITA_HOME` (`bin/dita`, or `bin\dita.bat` on Windows). Re-run
`./gradlew installLocalPlugin` after changing XSLT, Ant, or CSS files.

### Test Dataset

The sample dataset at `src/test/resources/dita/` is a complete bookmap exercising every plugin feature:

| Element | Count | Description |
|---------|-------|-------------|
| Topics | 18 | Frontmatter, chapters, appendices, backmatter |
| Glossary entries | 10 | Alphabetically grouped |
| Index terms | 100+ | Two-level with cross-references |
| Figures | 4 | SVG diagrams with alt text |
| Tables | 6 | With zebra striping and captions |
| Footnotes | 8 | With backlinks |
| Note types | 6 | Default, tip, important, warning, caution, danger |
| Bookmap features | All | Cover, title page, copyright, TOC, LOF, LOT, glossary, index |

Three more datasets are used by the build and integration tests: `src/test/resources/dita-kdp/` (commercial novel
built with the KDP platform profile), `src/test/resources/dita-comprehensive/` (feature-coverage map, including topics
that share a file name across folders), and `src/test/resources/dita-edge-cases/` (inputs behind the
[EPUB 3.3 conformance review](docs/EPUB33_CONFORMANCE.md): file names that differ only in case, a file name with a
space, a remote image, a TOC heading cut by `epub.toc.depth`), whose EPUB must pass EPUBCheck with no errors or warnings.

### Test Coverage

| Feature | Tests | Status |
|---------|-------|--------|
| Cover Page Generation | 6 | Complete |
| Font Embedding | 6 | Complete |
| OPF Manifest | 8 | Complete |
| EPUB Structure | 10 | Complete |
| Validation | 8 | Complete (0 EPUBCheck errors) |
| Integration | 4 | Complete |

**Detailed Report**: See [TEST_COVERAGE.md](docs/TEST_COVERAGE.md)

---

## Documentation Hub

### Getting Started

| Document | Description | For |
|----------|-------------|-----|
| **[QUICKSTART.md](docs/QUICKSTART.md)** | 5-minute setup and first EPUB | New users |
| **[SPECIFICATION.md](docs/SPECIFICATION.md)** | Complete technical specification | All users |
| **[ANATOMY_EPUB_THREE.md](docs/ANATOMY_EPUB_THREE.md)** | EPUB 3 file structure and SSV reference | Developers |
| **[PROJECT_STATUS.md](docs/PROJECT_STATUS.md)** | Current status and metrics | Project overview |
| **[ROADMAP.md](docs/ROADMAP.md)** | Planned milestones and improvements | Next releases |

### User Documentation

| Document | Description | Details |
|----------|-------------|---------|
| **[Font Embedding Guide](src/main/resources/fonts/README.md)** | Font setup and configuration | 200+ lines with examples |
| **[CHANGELOG.md](docs/CHANGELOG.md)** | Version changelog | All releases up to v2.0.0 |
| **[RELEASE_NOTES.md](docs/RELEASE_NOTES.md)** | Early release notes | v1.0.1 release details |

### Testing & Quality

| Document | Description | Coverage |
|----------|-------------|----------|
| **[TEST_COVERAGE.md](docs/TEST_COVERAGE.md)** | Detailed test documentation | 47 test methods across 8 classes |
| **[EPUB33_CONFORMANCE.md](docs/EPUB33_CONFORMANCE.md)** | EPUB 3.3 conformance review | Fixed and open findings |
| **[TEST_SUMMARY.md](docs/TEST_SUMMARY.md)** | Executive test summary | 100% unit test pass rate |

### Development & CI/CD

| Document | Description | Content |
|----------|-------------|---------|
| **[CONTRIBUTING.md](docs/CONTRIBUTING.md)** | Contribution guidelines | 500+ lines with code examples |
| **[.github/ACTIONS_SETUP.md](.github/ACTIONS_SETUP.md)** | CI/CD setup summary | Workflow descriptions |
| **[REGISTRY.md](docs/REGISTRY.md)** | Publishing to the DITA-OT plugin registry | Release and checksum steps |

### External Resources

- **[GitHub Repository](https://github.com/jyjeanne/dita2epub)** - Source code and releases
- **[GitHub Issues](https://github.com/jyjeanne/dita2epub/issues)** - Bug reports and feature requests
- **[GitHub Discussions](https://github.com/jyjeanne/dita2epub/discussions)** - Community discussions
- **[DITA-OT Documentation](https://www.dita-ot.org/)** - DITA Open Toolkit docs
- **[EPUB 3.3 Specification](https://www.w3.org/publishing/epub3/)** - W3C EPUB standard

---

## Use Cases

### Technical Documentation
```bash
dita --input=user-guide.ditamap \
     --format=epub3 \
     --epub.theme=technical \
     --epub.toc.depth=6 \
     --epub.accessibility=wcag-aa
```

### E-Books with Custom Branding
```bash
dita --input=novel.ditamap \
     --format=epub3 \
     --epub.theme=fiction \
     --epub.cover.image=cover.jpg \
     --epub.embed.fonts=fonts/ \
     --epub.cover.page.style=full-page
```

### Amazon KDP Publishing
```bash
dita --input=novel.ditamap \
     --format=epub3 \
     --epub.platform=kdp \
     --epub.cover.image=cover.jpg \
     --epub.isbn=978-0-13-468599-1
```

### Apple Books Publishing
```bash
dita --input=textbook.ditamap \
     --format=epub3 \
     --epub.platform=apple \
     --epub.embed.fonts=fonts/ \
     --epub.theme=academic
```

### Fixed Layout (Children's Books, Cookbooks)
```bash
dita --input=cookbook.ditamap \
     --format=epub3 \
     --epub.layout=fixed \
     --epub.fxl.width=1024 \
     --epub.fxl.height=768 \
     --epub.fxl.orientation=portrait
```

### Training Materials
```bash
dita --input=training.ditamap \
     --format=epub3 \
     --epub.theme=training \
     --epub.generate.cover.page=yes \
     --epub.accessibility=wcag-aaa
```

---

## Current Status

### Completed Features (v2.0)
- **All v1.5 features** plus:
- Theme system: 5 built-in themes via CSS custom properties
- Platform variants: Amazon KDP, Apple Books, Kobo profiles
- Fixed Layout EPUB with viewport dimensions and rendition controls
- RTL language support: Arabic, Hebrew, Farsi, Urdu with CSS logical properties
- Global figure/table numbering via `xsl:iterate` offset pre-computation
- 0 EPUBCheck errors across all configurations (reflowable, fixed, KDP, Apple, generic)
- Built and tested against DITA-OT 4.4.1, with the full integration test suite running end to end

### Implemented — v2.0 Phases

**Phase 1 — CSS Foundation** ✅
- Refactor stylesheet to CSS custom properties for theme overridability
- Extract inline styles from cover, title, and copyright pages into CSS

**Phase 2 — RTL Language Completion** ✅
- OPF `page-progression-direction` for RTL content
- CSS logical properties (`border-inline-start`, `padding-inline-start`, `text-align: start`)
- Arabic, Hebrew, Farsi, and Urdu font stacks with tuned line-height
- Mixed-direction `dir` attributes via `emit-lang-dir` template
- Disabled drop caps and hyphenation for RTL scripts
- Removed all physical `[dir="rtl"]` CSS overrides (replaced by logical properties)

**Phase 3 — Theme System** ✅
- `epub.theme` parameter: `default`, `academic`, `fiction`, `technical`, `training`
- CSS-only themes via `:root` variable overrides (no duplication of base rules)
- Cascade: `epub-default.css` → `epub-theme-*.css` → `epub-fonts.css` → custom CSS
- Theme CSS automatically added to OPF manifest and all XHTML pages
- DITA-OT Ant pipeline copies theme CSS from plugin resources

**Phase 4 — Platform Variants** ✅
- `epub.platform` parameter: `generic`, `kdp`, `apple`, `kobo`
- **Amazon KDP profile**: forced NCX generation, expanded `<guide>` element with all references (cover, title-page, toc, text, copyright-page, glossary, index, loi, lot), KDP-safe CSS (`epub-platform-kdp.css` — no `position:absolute`, explicit page breaks, no float sidebars, Kindle-safe drop caps), cover image and SVG validation warnings, font embedding warnings
- **Apple Books profile**: `ibooks:specified-fonts` and `ibooks:version` metadata, `prefix` attribute on OPF `<package>` element for ibooks vocabulary
- **Kobo profile**: standard EPUB3 with recommended metadata and cover validation
- New `epub3-platform.xsl` module for platform-specific logic (detection functions, validation warnings, guide generation, platform CSS, Apple metadata)
- Parameter validation with fallback to `generic` for unrecognized values
- CSS cascade: `epub-default.css` → `epub-theme-*.css` → `epub-platform-*.css` → `epub-fonts.css` → custom CSS
- NCX generation now conditional (forced for KDP, optional via `epub.generate.ncx` otherwise)

**Phase 5 — Fixed Layout EPUB** ✅
- `epub.layout` parameter: `reflowable` (default), `fixed`
- Viewport dimensions: `epub.fxl.width` (1024), `epub.fxl.height` (768)
- Orientation control: `epub.fxl.orientation` (`auto`, `portrait`, `landscape`)
- Spread control: `epub.fxl.spread` (`auto`, `both`, `landscape`, `none`)
- OPF rendition metadata: `rendition:layout` (pre-paginated), `rendition:orientation`, `rendition:spread`
- Fixed-layout CSS overlay (`epub-fxl.css`): viewport-filling pages, disabled reflow features (hyphens, drop caps, float sidebars), overflow protection, full-bleed image support
- `<meta name="viewport">` with exact pixel dimensions on all XHTML pages
- Parameter validation with fallback to `reflowable`
- CSS cascade: `epub-default.css` → theme → platform → fonts → custom → `epub-fxl.css`

See [ROADMAP.md](docs/ROADMAP.md) for the planned milestones and improvements.

---

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](docs/CONTRIBUTING.md) for:
- Code of conduct
- Development setup
- Coding standards
- Pull request process
- Testing requirements

### Quick Contribution Guide

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests for new features
5. Run tests (`./gradlew test`)
6. Commit changes (`git commit -m 'Add amazing feature'`)
7. Push to branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

---

## License

This project is licensed under the **Apache License 2.0** - see the [LICENSE](LICENSE) file for details.

```
Copyright 2025 J. Jeanne

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0
```

---

## Acknowledgments

### Built With
- [DITA Open Toolkit 4.4.1](https://www.dita-ot.org/)
- [Saxon-HE 12.7](https://www.saxonica.com/html/documentation12/about/) (XSLT 3.0)
- [EPUBCheck 5.3.0](https://github.com/w3c/epubcheck)
- [Gradle 9.x](https://gradle.org/) with [dita-ot-gradle 2.8.5](https://github.com/jyjeanne/dita-ot-gradle)
- [JUnit 5](https://junit.org/junit5/) + [XMLUnit](https://github.com/xmlunit/xmlunit) + [AssertJ](https://assertj.github.io/doc/)

### Inspired By
- [DITA4Publishers](https://github.com/dita4publishers/dita4publishers) by Eliot Kimber
- DITA-OT community contributions
- [EPUB 3.3 Specification](https://www.w3.org/publishing/epub3/) by W3C

---

## Support & Contact

- **Issues**: [GitHub Issues](https://github.com/jyjeanne/dita2epub/issues)
- **Discussions**: [GitHub Discussions](https://github.com/jyjeanne/dita2epub/discussions)
- **Author**: J. Jeanne

---

## Project Status

![Version](https://img.shields.io/badge/version-2.0.0-blue)
![Build](https://img.shields.io/badge/build-passing-success)
![Coverage](https://img.shields.io/badge/coverage-70%25-green)
![Maintained](https://img.shields.io/badge/maintained-yes-brightgreen)

**Last Updated**: October 27, 2026
**Version**: 2.0.0
**Status**: Production Ready

---

<div align="center">

**[Back to Top](#dita2epub---modern-epub3-transformation-plugin)**

Made with care for the DITA community

</div>

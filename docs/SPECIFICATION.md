# DITA2ePub - Technical Specification

## Project Overview

**Project Name:** DITA2ePub
**Plugin ID:** io.github.jyjeanne.dita2epub
**Version:** 2.0.0
**Target DITA-OT Version:** 4.4+
**License:** Apache License 2.0
**Author:** J. Jeanne
**Repository:** https://github.com/jyjeanne/dita2epub

### Description

DITA2ePub is a transformation plugin for the DITA Open Toolkit (DITA-OT) 4.4 that converts DITA XML content and maps into publication-ready EPUB 3.3 publications. It extends the DITA-OT HTML5 base transformation with 9 XSLT 3.0 modules for OPF, navigation, metadata, content generation, back-of-book index, consolidated glossary, and platform-specific logic, backed by Java utilities for EPUB-compliant ZIP packaging, font obfuscation, image optimization, and validation. The plugin produces EPUB 3.3 output with full Structural Semantics Vocabulary (SSV) compliance, professional typography features, and retail distribution metadata (ISBN, series, BISAC, MARC relator codes) suitable for Amazon KDP, Apple Books, and Kobo ingestion.

### Key Differentiators

- **Modern DITA-OT 4.4+** — Built and tested against DITA-OT 4.4.1, the latest release
- **Gradle Build System** — Kotlin DSL with `dita-ot-gradle` 2.8.5 plugin
- **Java 17+** — Leverages modern Java features
- **EPUB 3.3 + SSV Compliance** — Full Structural Semantics Vocabulary with dynamic `epub:type` annotations
- **Back-of-Book Index** — Automatic index generation from `<indexterm>` elements with precise anchor links
- **Consolidated Glossary** — Automatic glossary from `<glossentry>` topics
- **Cover Page Generation** — Automatic HTML cover pages with customizable styles
- **Font Embedding** — TTF, OTF, WOFF, WOFF2 with auto `@font-face` CSS and obfuscation
- **Image Optimization** — JPEG quality, PNG metadata stripping, resize
- **Professional Typography** — Footnotes, figure/table numbering, drop caps, pull quotes, sidebars
- **Retail Distribution Metadata** — ISBN/ASIN identifiers, series metadata, MARC relator codes, BISAC subjects
- **Book Structure** — Copyright page, dedication, colophon, acknowledgments, extended landmarks
- **10-Language i18n** — en, fr, de, es, it, pt, nl, ja, zh + fallback
- **Comprehensive Testing** — 6 test classes, 3 test datasets, 0 EPUBCheck errors

---

## Technical Stack

### Core Technologies

| Technology | Version | Purpose |
|------------|---------|---------|
| DITA-OT | 4.4.1 (minimum 4.4) | Document processing framework |
| Java | 17+ (LTS) | Runtime environment |
| Gradle | 8.x / 9.x | Build system (Kotlin DSL) |
| dita-ot-gradle | 2.8.5 | Gradle plugin for DITA-OT tasks |
| XSLT | 3.0 (Saxon 12.7) | Primary transformation language |
| EPUB | 3.3 (primary) / 2.0.1 (legacy) | Target output format |
| XHTML | 5.0 | Content markup |
| CSS | 3 | Styling |

### XSLT 3.0 Features Used

- Text value templates (`expand-text`)
- Multiple output documents (`xsl:result-document`)
- Tunnel parameters for context passing
- Processing modes for template specialization
- Strong typing (`xs:string`, `xs:boolean`, `xs:integer`)
- Higher-order functions (`epub:is-true()`, `epub:get-boolean()`)
- Grouping (`xsl:for-each-group`) for index alphabetical grouping and deduplication
- `document()` function for cross-topic indexterm collection

### Dependencies

```kotlin
dependencies {
    // EPUB validation
    implementation("org.w3c:epubcheck:5.3.0")

    // Utilities
    implementation("commons-io:commons-io:2.15.1")

    // Logging
    implementation("org.slf4j:slf4j-api:2.0.9")
    implementation("ch.qos.logback:logback-classic:1.4.14")

    // Testing
    testImplementation("org.junit.jupiter:junit-jupiter:5.10.0")
    testImplementation("org.xmlunit:xmlunit-core:2.9.1")
    testImplementation("org.assertj:assertj-core:3.24.2")
}
```

---

## Architecture

### Multi-Pass Transformation Pipeline

```
┌─────────────────────────────────────────────────────────────┐
│                    Gradle Build Task                         │
│              (dita-ot-gradle plugin 2.8.5)                  │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                  DITA-OT 4.4 Framework                      │
│              (Preprocessing Pipeline)                       │
│  • Topic resolution • Keyref resolution                     │
│  • Conref resolution • Filtering • Chunking                 │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              DITA2ePub Plugin Entry Point                    │
│        (plugin.xml → build-epub3.xml → XSLT)                │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
              ┌────────────────────┐
              │   map2epub3.xsl    │
              │   (entry point)    │
              │   imports HTML5    │
              │   base + modules   │
              └────────┬───────────┘
                       │
        ┌──────────┼──────────┬──────────┬──────────┐
        │          │          │          │          │
        ▼          ▼          ▼          ▼          ▼
┌────────────┐ ┌────────┐ ┌─────────┐ ┌────────┐ ┌────────────┐
│epub3-      │ │epub3-  │ │epub3-   │ │epub3-  │ │epub3-      │
│content     │ │impl    │ │metadata │ │common  │ │index       │
│• XHTML5    │ │• OPF   │ │• Dublin │ │• UUID  │ │• Indexterm  │
│• Topics    │ │• Nav   │ │  Core   │ │• Utils │ │  collection│
│• Anchors   │ │• NCX   │ │• Rights │ │• Lang  │ │• Grouping  │
│            │ │• Spine │ │         │ │        │ │• Locators  │
└─────┬──────┘ └───┬────┘ └────┬────┘ └────────┘ └─────┬──────┘
      │            │           │                        │
      └────────────┴───────────┴────────────────────────┘
                      │
                      ▼
         ┌─────────────────────────┐
         │   build-epub3.xml       │
         │   (Ant pipeline)        │
         │   • Copy CSS/images     │
         │   • Copy fonts/cover    │
         │   • Create mimetype     │
         └────────────┬────────────┘
                      │
                      ▼
         ┌─────────────────────────┐
         │   EpubPackager.java     │
         │   • mimetype first      │
         │   • STORED compression  │
         │   • EPUB-compliant ZIP  │
         └────────────┬────────────┘
                      │
                      ▼
         ┌─────────────────────────┐
         │   EpubValidator.java    │
         │   (EPUBCheck 5.3.0)     │
         └────────────┬────────────┘
                      │
                      ▼
         ┌─────────────────────────┐
         │   Final EPUB 3.3        │
         │   (.epub file)          │
         └─────────────────────────┘
```

### Plugin Integration

The plugin hooks into DITA-OT via `plugin.xml`:
- **Transtype:** `epub3`
- **Extension point:** `depend.preprocess.post` → `epub3.init`
- **Dependencies:** `org.dita.base`, `org.dita.html5`
- **Ant pipeline:** `build-epub3.xml` orchestrates XSLT, file copying, packaging, and validation

### Namespace Management

| Namespace | URI | Usage |
|-----------|-----|-------|
| XHTML5 | `http://www.w3.org/1999/xhtml` | Content output |
| EPUB OPS | `http://www.idpf.org/2007/ops` | EPUB operations, `epub:type` |
| OPF | `http://www.idpf.org/2007/opf` | Package document |
| Dublin Core | `http://purl.org/dc/elements/1.1/` | Metadata |
| DITA | `http://dita-ot.sourceforge.net` | DITA-OT integration |

---

## Directory Structure

```
dita2epub/
├── plugin.xml                          # DITA-OT plugin descriptor (transtype epub3)
├── plugin-info.xml                     # Plugin metadata and compatibility
├── build-epub3.xml                     # Ant pipeline (XSLT, copy, package, validate)
├── build.gradle.kts                    # Gradle build (Kotlin DSL, dita-ot-gradle 2.8.5)
├── settings.gradle.kts                 # Gradle settings
├── gradle.properties                   # Gradle JVM and cache settings
├── README.md                           # Project documentation
├── LICENSE                             # Apache License 2.0
│
├── src/
│   ├── main/
│   │   ├── java/io/github/jyjeanne/dita2epub/
│   │   │   ├── EpubPackager.java       # EPUB-compliant ZIP creation
│   │   │   ├── EpubValidator.java      # EPUBCheck validation wrapper
│   │   │   ├── FontObfuscator.java     # Adobe/IDPF font obfuscation
│   │   │   └── ImageOptimizer.java     # JPEG/PNG image optimization
│   │   │
│   │   ├── xsl/                        # XSLT 3.0 transformation modules
│   │   │   ├── map2epub3.xsl           # Main entry point (imports HTML5 base)
│   │   │   ├── epub3-params.xsl        # All XSLT parameters with defaults
│   │   │   ├── epub3-common.xsl        # Utility functions (UUID, title, language)
│   │   │   ├── epub3-metadata.xsl      # Dublin Core metadata extraction
│   │   │   ├── epub3-content.xsl       # DITA topic → XHTML5 generation
│   │   │   ├── epub3-impl.xsl          # OPF, navigation, NCX, font CSS generation
│   │   │   ├── epub3-index.xsl         # Back-of-book index generation
│   │   │   ├── epub3-glossary.xsl      # Consolidated glossary generation
│   │   │   └── epub3-platform.xsl      # Platform-specific logic (KDP, Apple, Kobo)
│   │   │
│   │   └── resources/
│   │       ├── css/
│   │       │   ├── epub-default.css          # Default EPUB styles (CSS custom properties)
│   │       │   ├── epub-theme-academic.css   # Academic theme overrides
│   │       │   ├── epub-theme-fiction.css    # Fiction theme overrides
│   │       │   ├── epub-theme-technical.css  # Technical theme overrides
│   │       │   ├── epub-theme-training.css   # Training theme overrides
│   │       │   ├── epub-platform-kdp.css     # Amazon KDP CSS overrides
│   │       │   ├── epub-fxl.css              # Fixed Layout CSS overlay
│   │       │   └── epub-fonts.css            # @font-face declaration templates
│   │       └── fonts/                        # Font directory template
│   │           └── README.md                 # Font embedding guide
│   │
│   └── test/
│       ├── java/io/github/jyjeanne/dita2epub/
│       │   ├── CoverPageGenerationTest.java
│       │   ├── EpubStructureTest.java
│       │   ├── EpubValidatorTest.java
│       │   ├── FontEmbeddingTest.java
│       │   ├── OPFManifestTest.java
│       │   └── EpubGenerationIntegrationTest.java
│       │
│       └── resources/
│           ├── dita/                   # English sample bookmap
│           │   ├── sample-bookmap.ditamap
│           │   ├── cover.svg
│           │   └── topics/
│           ├── dita-kdp/               # Amazon KDP commercial novel
│           │   ├── kdp-commercial-bookmap.ditamap
│           │   ├── cover-kdp.svg
│           │   └── topics/
│           ├── dita-comprehensive/     # Feature-coverage map (integration tests)
│           │   ├── comprehensive-test.ditamap
│           │   └── topics/
│           └── epub/                   # Reference EPUB for validation
│
├── strings/                            # Internationalization
│   ├── strings.xml                     # String registry
│   └── strings-en.xml                  # English strings
│
├── docs/                               # Documentation
│   ├── SPECIFICATION.md                # This file
│   ├── ANATOMY_EPUB_THREE.md          # EPUB 3 file structure and SSV reference
│   ├── QUICKSTART.md                   # 5-minute setup guide
│   ├── CONTRIBUTING.md                 # Contribution guidelines
│   ├── CHANGELOG.md                    # Version history
│   ├── RELEASE_NOTES.md               # Release details
│   ├── PROJECT_STATUS.md              # Status and roadmap
│   ├── TEST_COVERAGE.md               # Test documentation
│   ├── TEST_SUMMARY.md                # Executive test summary
│   └── GITHUB_CHECKLIST.md            # GitHub procedures
│
└── .github/
    └── workflows/
        ├── ci.yml                      # CI build and test (multi-platform)
        ├── build.yml                   # Simple build workflow
        ├── release.yml                 # Automated releases
        └── docs.yml                    # Documentation validation
```

---

## Core Components

### 1. map2epub3.xsl — Main Entry Point

**File:** `src/main/xsl/map2epub3.xsl`

Imports the DITA-OT HTML5 base transformation and includes all 8 plugin modules. The root template triggers `epub3-generate` mode which orchestrates:

1. OPF package document generation
2. EPUB3 navigation document
3. NCX table of contents (backward compatibility)
4. Cover page generation
5. Title page
6. Content files (XHTML per topic, with index anchors and footnotes)
7. Consolidated glossary (when enabled)
8. Back-of-book index (when enabled)
9. `@font-face` CSS generation (when fonts are embedded)
10. container.xml

### 2. epub3-params.xsl — Configuration Parameters

**File:** `src/main/xsl/epub3-params.xsl`

Defines all XSLT parameters with typed defaults. Also provides utility functions:
- `epub:is-true($value)` — checks if a string is `yes`, `true`, or `1`
- `epub:get-boolean($param, $default)` — safe boolean parameter resolution

### 3. epub3-common.xsl — Utility Functions

**File:** `src/main/xsl/epub3-common.xsl`

- `epub:generate-uuid()` — UUID derived from the title, language and root map file name, so the identifier stays the same across builds of the same publication
- `epub:get-identifier()` — Extract publication identifier (ISBN from param/bookmap, fallback to UUID)
- `epub:marc-relator()` — MARC relator code lookup (author→aut, editor→edt, translator→trl, etc.)
- `epub:get-title()` — Extract map title with fallbacks
- `epub:get-language()` — Detect language from map metadata
- `epub:get-media-type()` / `epub:get-font-media-type()` — MIME type detection
- `epub:get-font-family()` — Font family name from filename (e.g., `Roboto-BoldItalic.woff2` → `Roboto`)
- `epub:get-font-weight()` — Font weight detection (100-900)
- `epub:get-font-style()` — Font style detection (normal, italic, oblique)
- `epub:get-font-format()` — CSS font format from extension (woff2, truetype, etc.)

### 4. epub3-metadata.xsl — Metadata Extraction

**File:** `src/main/xsl/epub3-metadata.xsl`

Extracts Dublin Core and EPUB3 metadata from DITA bookmaps:
- Publication identifier with ISBN/ASIN detection and ONIX codelist5 refinement
- Titles, subtitles
- Authors, contributors with MARC relator codes (editor, translator, illustrator, etc.)
- Series metadata (`belongs-to-collection` with `collection-type` and `group-position`)
- BISAC/ONIX subject classifications from parameter and bookmap `<data>` elements
- Publisher, publication date, last modified date (required by EPUB3)
- Rights/copyright, description/abstract

### 5. epub3-content.xsl — Content Generation

**File:** `src/main/xsl/epub3-content.xsl`

Transforms DITA topics to XHTML5 content files. Processes topicrefs from the map and generates separate XHTML files per topic with EPUB naming conventions. Key features:
- Dynamic `epub:type` assignment based on bookmap context (chapter, appendix, foreword, preface, glossary, dedication, colophon, copyright-page, errata, acknowledgments, halftitlepage, introduction, epilogue)
- `@type` attribute override on topicrefs for explicit epub:type mapping
- Index anchor injection: `<span id="ixa-{topic-id}-{pos}"/>` elements at each `<indexterm>` location for precise index linking
- Footnotes with EPUB 3 `epub:type="footnote"` / `noteref` semantics and backlinks
- Figure auto-numbering with i18n labels and `<figure>` / `<figcaption>` markup
- Table enhancements: colspan, rowspan, alignment from colspec, zebra striping
- Code block language class from `@outputclass` and optional line numbers
- Drop caps on first paragraph of chapter topics
- Pull quotes (`<lq>` → `<blockquote class="pull-quote">`) with attribution
- Sidebars (`<section outputclass="sidebar">` → `<aside class="sidebar">`)
- Language-aware note labels (tip, warning, important, caution, danger) across 10 languages
- Skip navigation links for accessibility
- Proper XHTML5 semantic structure with `<article>`, `<section>`, `<main>`

### 6. epub3-impl.xsl — OPF and Navigation

**File:** `src/main/xsl/epub3-impl.xsl`

Generates the core EPUB structure:
- **OPF package document** (content.opf) — manifest, spine, metadata (with conditional index/glossary entries, font CSS, custom CSS)
- **EPUB3 navigation document** (nav.xhtml) — TOC, landmarks (with index/glossary/preface/dedication/appendix/colophon/copyright-page landmarks when generated)
- **NCX table of contents** — backward compatibility with EPUB2 readers
- **Cover page** — HTML cover with configurable styles
- **Title page** — with author, copyright, translator, license (i18n)
- **Copyright page** — auto-generated from bookmap metadata (title, copyright notice, publisher, license, ISBN)
- **`@font-face` CSS generation** — auto-generates `epub-fonts.css` from embedded font files
- **container.xml** — OCF container
- **Bookmap navigation flattening** — promotes frontmatter/backmatter children to top level with localized labels

### 7. epub3-index.xsl — Back-of-Book Index Generation

**File:** `src/main/xsl/epub3-index.xsl`

Generates a back-of-book `index.xhtml` file with EPUB 3.3 Structural Semantics Vocabulary markup. Triggered when `epub.generate.index` is `yes` or when set to `auto` and a `<indexlist/>` element exists in the bookmap.

**Index generation pipeline:**
1. Collects all `<indexterm>` elements from all topic files via `document()` calls
2. Computes deterministic anchor IDs matching the anchors injected by `epub3-content.xsl`
3. Groups entries by uppercase first letter of sort key → alphabetical sections
4. Within each letter group, merges duplicate entries → multiple locators
5. Within each primary entry, groups sub-entries by sub-term
6. Generates XHTML with full SSV markup: `epub:type="index"`, `"index-group"`, `"index-entry"`, `"index-entry-list"`, `"index-term"`, `"index-locator"`, `"index-locator-list"`, `"index-xref-preferred"`, `"index-xref-related"`

**Supported DITA index features:**
- Simple entries: `<indexterm>Term</indexterm>`
- Nested entries: `<indexterm>Primary<indexterm>Secondary</indexterm></indexterm>`
- See references: `<indexterm>Term<index-see>Target</index-see></indexterm>`
- See also references: `<indexterm>Term<index-see-also>Target</index-see-also></indexterm>`
- Sort keys: `<indexterm>Term<index-sort-as>SortKey</index-sort-as></indexterm>`

**Locator format:** Chapter.section numbering (e.g., "6.2" = chapter 6, section 2), with appendices as letters ("B.3").

### 7. EpubPackager.java — EPUB ZIP Creation

**File:** `src/main/java/.../EpubPackager.java`

Creates EPUB-compliant ZIP archives enforcing:
- `mimetype` as first entry (STORED, not DEFLATED)
- Correct CRC32 for uncompressed mimetype
- DEFLATED compression for all other files
- Recursive directory processing with ZIP path normalization

### 8. EpubValidator.java — EPUB Validation

**File:** `src/main/java/.../EpubValidator.java`

Wraps EPUBCheck 5.3.0 to validate generated EPUB files. Returns `ValidationResult` with validity status, errors, warnings, and EPUB version. Performs:
- File existence and type checking
- File size validation (warns if >100MB)
- EPUB extension verification

### 9. build-epub3.xml — Ant Pipeline

**File:** `build-epub3.xml`

Ant build file that integrates with the DITA-OT pipeline. Targets:
- `epub3.init` — create output directories, set parameter defaults
- `epub3.transform` — run XSLT transformation
- `epub3.copy.css` — copy default and custom CSS
- `epub3.copy.images` — copy images and cover image from source
- `epub3.copy.fonts` — copy embedded fonts (directory or file list)
- `epub3.create.mimetype` — write `application/epub+zip`
- `epub3.package` — invoke `EpubPackager.java`
- `epub3.validate` — invoke EPUBCheck if available

---

## Gradle Build Configuration

### Plugin and Shared Properties

```kotlin
plugins {
    id("io.github.jyjeanne.dita-ot-gradle") version "2.8.5"
    id("java")
}

val ditaOtVersion = "4.4.1"
val ditaOtHome = layout.buildDirectory.dir("dita-ot/dita-ot-$ditaOtVersion")

val sharedEpubProperties = mapOf(
    "epub.version" to "3.3",
    "epub.topics.dir" to "content",
    "epub.images.dir" to "images",
    "epub.fonts.dir" to "fonts",
    "epub.css.dir" to "styles",
    "epub.accessibility" to "wcag-aa",
    "epub.aria.landmarks" to "yes",
    "args.css" to "epub-default.css",
    "args.copycss" to "yes",
)
```

### Gradle Tasks

| Task | Type | Description |
|------|------|-------------|
| `downloadDitaOt` | DitaOtDownloadTask | Download DITA-OT 4.4.1 from GitHub releases |
| `epubPackagerJar` | Jar | Build epub-packager.jar |
| `packagePlugin` | Zip | Package plugin as ZIP for DITA-OT |
| `installLocalPlugin` | DitaOtInstallPluginTask | Install plugin into DITA-OT |
| `dita` | DitaOtTask | Build sample EPUB (English bookmap) |
| `buildCalibreGuide` | DitaOtTask | Build Calibre Guide EPUB (French) |
| `buildIndexingGuide` | DitaOtTask | Build Indexing Guide EPUB (with back-of-book index) |
| `buildSampleEpub` | Task | Build + validate sample EPUB |
| `buildAllEpubs` | Task | Build all 3 test datasets |
| `validateEpub` | JavaExec | EPUBCheck on sample EPUB |
| `validateCalibreEpub` | JavaExec | EPUBCheck on Calibre Guide |
| `validateIndexingEpub` | JavaExec | EPUBCheck on Indexing Guide |
| `validateAllEpubs` | Task | Validate all generated EPUBs |
| `testAllEpubs` | Task | Build and validate all datasets |
| `integrationTest` | Task | Full integration tests + unit tests |
| `ciCheck` | Task | Full CI: compile, test, build, validate |
| `cleanEpub` | Task | Clean EPUB output directories |
| `listTestDatasets` | Task | List available test DITA datasets |
| `test` | Test | JUnit 5 unit tests |

### DitaOtTask Configuration

Tasks use `ditaProperties` map (configuration-cache compatible):

```kotlin
tasks.named<com.github.jyjeanne.DitaOtTask>("dita") {
    dependsOn("installLocalPlugin")
    ditaOt(ditaOtHome)
    input(file("src/test/resources/dita/sample-bookmap.ditamap"))
    output("build/epub")
    transtype("epub3")

    ditaProperties.putAll(sharedEpubProperties)
    ditaProperties.putAll(mapOf(
        "epub.cover.image" to file("src/test/resources/dita/cover.svg").absolutePath,
        "epub.toc.depth" to "5",
        // ... additional per-dataset properties
    ))
}
```

---

## Complete Parameter Reference

Parameters are declared in `plugin.xml` and defined with defaults in `epub3-params.xsl`. They can be set via:

1. **Gradle `ditaProperties`** (recommended)
2. **DITA-OT command line** (`dita --epub.cover.image=cover.jpg`)
3. **Ant properties** (via `build-epub3.xml`)

### Core Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.version` | enum | `3.3` | EPUB version: `3.3`, `3.0`, `2.0.1` |

### Cover Page Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.cover.image` | path | `(none)` | Path to cover image (JPG, PNG, SVG) |
| `epub.generate.cover.page` | enum | `yes` | Generate HTML cover page: `yes`, `no` |
| `epub.cover.page.style` | enum | `full-page` | Cover style: `full-page`, `centered`, `custom` |

**Cover page styles:**
- **full-page** — image fills viewport (`width: 100%`, `height: 100vh`, `object-fit: contain`)
- **centered** — image centered with flexbox, 2em padding, `max-width: 100%`
- **custom** — no inline styles, use your own CSS via `args.css`

### Navigation Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.toc.depth` | integer | `5` | Maximum table of contents depth |
| `epub.nav.depth` | integer | `5` | Maximum navigation document depth |
| `epub.generate.lof` | enum | `no` | Generate list of figures: `yes`, `no` |
| `epub.generate.lot` | enum | `no` | Generate list of tables: `yes`, `no` |
| `epub.include.toc.page` | enum | `no` | Include standalone TOC page |
| `epub.generate.ncx` | enum | `no` | Generate NCX for EPUB2 readers |

### Index Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.generate.index` | enum | `auto` | Generate back-of-book index from indexterm elements: `auto`, `yes`, `no` |

**Values:**
- `auto` — detect from bookmap: generates index when `<indexlist/>` is present
- `yes` — always generate index from all `<indexterm>` elements in topics
- `no` — disable index generation

### Directory Structure Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.topics.dir` | string | `content` | Directory for topic XHTML files |
| `epub.images.dir` | string | `images` | Directory for images |
| `epub.fonts.dir` | string | `fonts` | Directory for embedded fonts |
| `epub.css.dir` | string | `styles` | Directory for CSS files |
| `epub.js.dir` | string | `scripts` | Directory for JavaScript |

### Accessibility Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.accessibility` | enum | `wcag-aa` | No effect on the output, kept so existing build scripts keep working (`wcag-a`, `wcag-aa`, `wcag-aaa`). Accessibility metadata is derived from the content; declare a conformance claim with bookmap `<data name="accessibility-conformance">` and `<data name="accessibility-certifier">` |
| `epub.aria.landmarks` | enum | `yes` | Generate ARIA landmarks: `yes`, `no` |
| `epub.skip.nav` | enum | `yes` | Include skip navigation links: `yes`, `no` |

### Font Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.embed.fonts` | path | `(none)` | Directory or comma-separated font files to embed |
| `epub.embedded.fonts` | path | `(none)` | Alias for `epub.embed.fonts` |
| `epub.obfuscate.fonts` | enum | `no` | Adobe/IDPF font obfuscation with `encryption.xml` |
| `epub.generate.font.css` | enum | `yes` | Auto-generate `@font-face` CSS from embedded fonts |

**Supported font formats:** TTF, OTF, WOFF, WOFF2

### Metadata Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.publisher` | string | `(from DITA)` | Publisher name (overrides DITA source) |
| `epub.rights` | string | `(from DITA)` | Copyright statement |
| `epub.identifier.scheme` | enum | `UUID` | Identifier scheme: `UUID`, `DOI`, `ISBN`, `URI` |
| `epub.language` | string | `en` | Primary language code |
| `epub.isbn` | string | `(none)` | ISBN override (extracts from bookmap `<bookid><isbn>` if empty) |
| `epub.series.name` | string | `(none)` | Series/collection name (`belongs-to-collection`) |
| `epub.series.position` | string | `(none)` | Volume position in series (`group-position`) |
| `epub.bisac.codes` | string | `(none)` | Comma-separated BISAC subject codes |
| `epub.copyright.page` | enum | `auto` | Generate copyright page: `auto`, `yes`, `no` |

### Styling Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `args.css` | string | `epub-default.css` | Main CSS filename |
| `args.csspath` | path | `styles` | Path to CSS directory |
| `args.copycss` | enum | `yes` | Copy CSS to output: `yes`, `no` |
| `args.output.base.name` | string | `output` | Output file base name |

### Typography & Content Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.custom.css` | path | `(none)` | Path to custom CSS file to include in EPUB |
| `epub.figure.numbering` | enum | `global` | Figure numbering mode: `global` (sequential), `none` |
| `epub.table.numbering` | enum | `global` | Table numbering mode: `global` (sequential), `none` |
| `epub.table.zebra` | enum | `yes` | Zebra striping on table body rows: `yes`, `no` |
| `epub.code.line.numbers` | enum | `no` | Line numbers in code blocks: `yes`, `no` |
| `epub.code.syntax.classes` | enum | `yes` | Add `language-{outputclass}` CSS class to code blocks: `yes`, `no` |
| `epub.drop.caps` | enum | `no` | Drop caps on first paragraph of chapter topics: `yes`, `no` |

### Image Optimization Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.optimize.images` | enum | `no` | Optimize images for EPUB: `yes`, `no` |
| `epub.image.jpeg.quality` | string | `0.8` | JPEG compression quality (0.0-1.0) |
| `epub.image.max.width` | string | `0` | Max image width in pixels (0 = no limit) |

### Glossary Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.generate.glossary` | enum | `auto` | Generate consolidated glossary: `auto`, `yes`, `no` |

### Validation Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.validate` | enum | `yes` | Run EPUBCheck after build: `yes`, `no` |
| `epub.validation.level` | enum | `error` | Validation reporting level |

### Theme Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.theme` | enum | `default` | Visual theme: `default`, `academic`, `fiction`, `technical`, `training` |

### Platform Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.platform` | enum | `generic` | Target platform: `generic`, `kdp`, `apple`, `kobo` |

Platform-specific behavior:
- **`kdp`** — Forces NCX generation, expanded `<guide>` element, KDP-safe CSS overlay, cover/SVG/font warnings
- **`apple`** — Adds `ibooks:specified-fonts` and `ibooks:version` OPF metadata
- **`kobo`** — Standard EPUB3 with cover validation warnings

### Fixed Layout Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.layout` | enum | `reflowable` | Layout type: `reflowable`, `fixed` |
| `epub.fxl.width` | integer | `1024` | Viewport width in pixels (fixed layout only) |
| `epub.fxl.height` | integer | `768` | Viewport height in pixels (fixed layout only) |
| `epub.fxl.orientation` | enum | `auto` | Orientation: `auto`, `portrait`, `landscape` |
| `epub.fxl.spread` | enum | `auto` | Spread behavior: `auto`, `both`, `landscape`, `none` |

When `epub.layout=fixed`:
- OPF metadata includes `rendition:layout` (pre-paginated), `rendition:orientation`, `rendition:spread`
- All XHTML pages include `<meta name="viewport" content="width=..., height=..."/>`
- Fixed-layout CSS overlay (`epub-fxl.css`) is applied after all other stylesheets
- Drop caps, floating sidebars, and hyphenation are disabled
- All values are validated with fallback to defaults for invalid input

### Debug Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `debug` | enum | `no` | Enable debug output: `yes`, `no` |

---

## Testing

### Test Suite

6 test classes using JUnit 5 + XMLUnit + AssertJ:

| Test Class | Tests | Coverage |
|------------|-------|----------|
| `EpubStructureTest` | 10 | mimetype, container.xml, directories, navigation, file naming |
| `OPFManifestTest` | 8 | package structure, Dublin Core, manifest items, spine |
| `CoverPageGenerationTest` | 6 | cover styles, OPF integration, spine ordering |
| `FontEmbeddingTest` | 6 | font formats, directory embedding, CSS templates |
| `EpubValidatorTest` | 8 | validator behavior, null/missing files, size warnings |
| `EpubGenerationIntegrationTest` | 4 | end-to-end EPUB generation from the test datasets |

All classes except `EpubValidatorTest` (and the two font template checks) generate EPUBs with DITA-OT and are skipped
when no DITA-OT installation is found.

### Test Datasets

| Dataset | Language | Map | Output | Features |
|---------|----------|-----|--------|----------|
| sample | English | `src/test/resources/dita/sample-bookmap.ditamap` | `build/epub` | Cover, frontmatter/backmatter |
| kdp-commercial | English (US) | `src/test/resources/dita-kdp/kdp-commercial-bookmap.ditamap` | `build/epub-kdp` | KDP platform profile, fiction theme, series and BISAC metadata |
| comprehensive | English | `src/test/resources/dita-comprehensive/comprehensive-test.ditamap` | (integration tests) | Lists, tables, code, notes; topics sharing a file name across folders |

### Running Tests

Integration tests resolve the DITA-OT launcher from `DITA_HOME` (`bin/dita`, or `bin\dita.bat` on Windows) and fall
back to `dita` on `PATH`. They run the plugin installed in that DITA-OT, so reinstall it after changing plugin files.

```bash
./gradlew installLocalPlugin                    # Download DITA-OT 4.4.1 and install the plugin
export DITA_HOME=$PWD/build/dita-ot/dita-ot-4.4.1
./gradlew test                                  # Unit + integration tests (unit only when DITA_HOME is unset)
./gradlew test --tests EpubValidatorTest        # Single class
./gradlew test --tests "*.FontEmbeddingTest.testFontCSSTemplateExists"  # Single method
./gradlew buildSampleEpub                       # Build + validate sample EPUB
./gradlew buildAllEpubs                         # Build all datasets
./gradlew ciCheck                               # Full CI pipeline
```

---

## Internationalization

Currently supported:
- English (`strings/strings-en.xml`)

String registry in `strings/strings.xml`. To add a language, create `strings/strings-{lang}.xml` and register it in `strings.xml`.

---

## Technical Decisions

### EPUB3-First
EPUB 3.3 is the modern standard with HTML5, accessibility, and rich media. EPUB 2.0.1 backward compatibility via optional NCX generation.

### Gradle over Ant
The project uses Gradle for build management while retaining Ant (`build-epub3.xml`) for DITA-OT pipeline integration, as DITA-OT's plugin system is Ant-based. The `dita-ot-gradle` plugin bridges the two.

### Java 17+ Requirement
Aligned with DITA-OT 4.4 minimum requirements. LTS support until 2029.

### Modular XSLT Design
Seven focused modules rather than a monolithic stylesheet. Each module handles a single concern (params, common, metadata, content, impl, index) plus the orchestrating entry point.

### EPUB ZIP Compliance
The `EpubPackager.java` class exists because standard ZIP utilities don't guarantee `mimetype` as the first uncompressed entry — a hard requirement of the EPUB/OCF specification.

---

## Known Limitations

- Column alignment fallback does not account for rowspan from previous rows
- Cover page limited to 3 styles (full-page, centered, custom)
- Fixed Layout EPUB does not support per-spine-item layout overrides (mixed reflowable/fixed)
- `float: inline-start/inline-end` not supported in EPUB readers (physical float with RTL override used instead)
- On Windows, the Gradle EPUB tasks (`dita`, `ditaKdp` and the aggregate tasks depending on them) fail: `dita-ot-gradle` passes every property on the `dita.bat` command line, which together with the plugin classpath set by DITA-OT's `env.bat` exceeds the 8191-character `cmd.exe` limit. Running `dita` directly (e.g. with `--propertyfile`) works.
- Cross-references between topics in different folders (`../other/topic.dita`) are not remapped to the flattened `content/` file names

---

## Roadmap

### v1.0.0 (Released 2025-12-01)
- [x] EPUB3 transformation support with DITA-OT 4.4
- [x] Accessibility built-in (WCAG 2.1 AA)
- [x] Gradle build integration
- [x] Modern Java 17 support

### v1.1.0 (Released 2026-02-20)
- [x] Cover page generation with multiple styles
- [x] Font embedding (TTF, OTF, WOFF, WOFF2)
- [x] Back-of-book index generation with EPUB 3.3 SSV markup
- [x] Full EPUB 3.3 Structural Semantics Vocabulary compliance
- [x] Dynamic `epub:type` per bookmap context (chapter, appendix, foreword, preface, glossary)
- [x] Bookmap navigation flattening (frontmatter/backmatter)
- [x] Three test datasets with 0 EPUBCheck errors
- [x] GitHub Actions CI/CD
- [x] Windows path handling

### v1.2.0 (Released 2026-03-05)
- [x] Font obfuscation (Adobe/IDPF algorithm with encryption.xml)
- [x] Font manifest generation from actual font files (replaces placeholder)
- [x] Image optimization (JPEG quality, PNG metadata stripping, resize)
- [x] Additional language support (it, pt, nl, ja, zh) across all navigation labels
- [x] DITA-OT plugin registry support

### v1.3.0 (Released 2026-03-05)
*Goal: Close the visual gap between DITA2ePub output and commercial publishers.*

- [x] **Auto `@font-face` CSS generation** from embedded font files with font family/weight/style detection
- [x] **Custom CSS injection** — `epub.custom.css` parameter for publisher-specific stylesheets
- [x] **Footnotes/endnotes** with EPUB 3 `epub:type="footnote"` / `noteref` and backlinks
- [x] **Figure auto-numbering** with i18n labels (10 languages) and `<figure>` / `<figcaption>` markup
- [x] **Table auto-numbering** with i18n labels and `<caption>` markup
- [x] **Table enhancements** — colspan (`@namest`/`@nameend`), rowspan (`@morerows`), alignment from colspec, zebra striping
- [x] **Code block enhancements** — language CSS class from `@outputclass`, optional line numbers
- [x] **Drop caps** (`::first-letter` styling) for chapter opening paragraphs
- [x] **Pull quotes** — `<lq>` → `<blockquote class="pull-quote">` with attribution
- [x] **Sidebars** — `<section outputclass="sidebar">` → `<aside class="sidebar">`
- [x] **i18n note labels** — language-aware labels for tip, warning, important, caution, danger, note

### v1.4.0 (Released 2026-03-05)
*Goal: Produce EPUBs that pass Amazon KDP, Apple Books, and Kobo ingestion validation.*

- [x] **ISBN/ASIN identifier support** — Extract from bookmap `<bookid><isbn>` or override via `epub.isbn` parameter; ONIX codelist5 identifier-type refinement (ISBN-13, ISBN-10, ASIN)
- [x] **Series metadata** — `belongs-to-collection` with `collection-type` and `group-position`; from parameters or bookmap `<data name="series">`
- [x] **Multiple contributor roles** — `epub:marc-relator()` function maps 10 roles to MARC codes; extracts translators and editors from bookmeta `<data>` elements
- [x] **BISAC/ONIX subject classifications** — Comma-separated BISAC codes via `epub.bisac.codes` parameter and bookmap `<data name="bisac">`
- [x] **Frontmatter/backmatter epub:type expansion** — dedication, colophon, copyright-page, errata, acknowledgments, halftitlepage, introduction, epilogue; `@type` attribute override on topicrefs
- [x] **Extended landmarks navigation** — Conditional entries for preface, dedication, appendix, colophon, copyright page; all labels i18n-aware (10 languages)
- [x] **Auto-generated copyright page** — `copyright.xhtml` from bookmap metadata with title, copyright notice, "All rights reserved" (i18n), publisher, license, ISBN

### v2.0.0 — Theme System, Platform Variants & Fixed Layout (Current)
*Goal: Enable publishers to produce branded, series-consistent output across multiple retail channels.*

- [x] **CSS Foundation** — Refactored to CSS custom properties for theme overridability, extracted inline styles
- [x] **RTL Language Completion** — OPF `page-progression-direction`, CSS logical properties, Arabic/Hebrew/Farsi/Urdu font stacks, `emit-lang-dir` template, disabled drop caps/hyphenation for RTL
- [x] **Theme system** — 5 built-in themes (`default`, `academic`, `fiction`, `technical`, `training`) with CSS custom properties and cascade inheritance
- [x] **Platform variants** — `epub.platform` parameter (`generic`, `kdp`, `apple`, `kobo`) with platform-specific OPF, CSS, metadata, and validation warnings
- [x] **Fixed Layout EPUB** — `epub.layout` parameter (`reflowable`, `fixed`) with viewport dimensions, orientation/spread controls, rendition metadata, and fixed-layout CSS overlay
- [x] **Global figure/table numbering** — Cross-topic sequential numbering via `xsl:iterate` offset pre-computation
- [x] **List of Figures / List of Tables** — Auto-generated from bookmap `<figurelist/>` and `<tablelist/>`
- [x] **DITA-OT 4.4.1** — Build, CI and release workflows updated to the latest DITA-OT release; logged DITA-OT version now read from the running toolkit
- [x] **End-to-end integration tests** — Launcher resolved from `DITA_HOME` (including `dita.bat` on Windows), CI installs the packaged plugin, 43 tests passing
- [x] **Fix: font embedding** — Builds using `epub.embed.fonts` no longer abort on an invalid Ant `<copy>` condition
- [x] **Fix: same-named topics** — Topics sharing a file name in different folders get unique output files instead of colliding

### Future
- [ ] **Windows support for Gradle EPUB tasks** — Pass DITA properties via `--propertyfile` in `dita-ot-gradle` to stay under the `cmd.exe` line limit
- [ ] **Cross-folder xref resolution** — Map cross-references to the flattened output file names
- [ ] **DITA 2.0 support** — full compatibility with DITA 2.0 specializations and processing
- [ ] **MathML / equation rendering** — for STEM publishing with proper fallback images
- [ ] **Per-spine-item layout overrides** — mixed reflowable/fixed content within a single EPUB
- [ ] **Extended image descriptions** — long descriptions beyond `alt` text (WCAG AAA)

---

## License

Apache License 2.0 — Copyright 2025 J. Jeanne

---

**Document Version:** 2.0.0
**Last Updated:** 2026-10-12
**Status:** Current Release

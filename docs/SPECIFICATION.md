# Dita2epub - Technical Specification

## Project Overview

**Project Name:** Dita2epub
**Plugin ID:** io.github.jyjeanne.dita2epub
**Version:** 1.0.1
**Target DITA-OT Version:** 4.4+
**License:** Apache License 2.0
**Author:** J. Jeanne
**Repository:** https://github.com/jyjeanne/dita2epub

### Description

Dita2epub is a transformation plugin for the DITA Open Toolkit (DITA-OT) 4.4 that converts DITA XML content and maps into publication-ready EPUB 3.3 publications. It extends the DITA-OT HTML5 base transformation with XSLT 3.0 modules for OPF, navigation, metadata, and content generation, backed by Java utilities for EPUB-compliant ZIP packaging and validation.

### Key Differentiators

- **Modern DITA-OT 4.4** — Built for the latest DITA-OT release
- **Gradle Build System** — Kotlin DSL with `dita-ot-gradle` 2.8.4 plugin
- **Java 17+** — Leverages modern Java features
- **EPUB3-First** — Prioritizes EPUB 3.3 specification
- **Cover Page Generation** — Automatic HTML cover pages with customizable styles (v1.0.1)
- **Font Embedding** — TTF, OTF, WOFF, WOFF2 font formats (v1.0.1)
- **Comprehensive Testing** — 6 test classes with JUnit 5 + XMLUnit + AssertJ

---

## Technical Stack

### Core Technologies

| Technology | Version | Purpose |
|------------|---------|---------|
| DITA-OT | 4.4 | Document processing framework |
| Java | 17+ (LTS) | Runtime environment |
| Gradle | 8.x / 9.x | Build system (Kotlin DSL) |
| dita-ot-gradle | 2.8.4 | Gradle plugin for DITA-OT tasks |
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

### Dependencies

```kotlin
dependencies {
    // EPUB validation
    implementation("org.w3c:epubcheck:5.1.0")

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
│              (dita-ot-gradle plugin 2.8.4)                  │
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
│              Dita2epub Plugin Entry Point                    │
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
        ┌──────────────┼──────────────┬──────────────┐
        │              │              │              │
        ▼              ▼              ▼              ▼
┌──────────────┐ ┌──────────┐ ┌───────────┐ ┌──────────────┐
│epub3-content │ │epub3-impl│ │epub3-meta │ │epub3-common  │
│• XHTML5 gen  │ │• OPF gen │ │• Dublin   │ │• UUID gen    │
│• Topic files │ │• Nav doc │ │  Core     │ │• Utilities   │
│              │ │• NCX     │ │• Authors  │ │• Title/lang  │
│              │ │• Spine   │ │• Rights   │ │  extraction  │
└──────┬───────┘ └────┬─────┘ └─────┬─────┘ └──────────────┘
       │              │              │
       └──────────────┴──────────────┘
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
         │   (EPUBCheck 5.1.0)     │
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
├── build.gradle.kts                    # Gradle build (Kotlin DSL, dita-ot-gradle 2.8.4)
├── settings.gradle.kts                 # Gradle settings
├── gradle.properties                   # Gradle JVM and cache settings
├── README.md                           # Project documentation
├── CLAUDE.md                           # Claude Code guidance
├── LICENSE                             # Apache License 2.0
│
├── src/
│   ├── main/
│   │   ├── java/io/github/jyjeanne/dita2epub/
│   │   │   ├── EpubPackager.java       # EPUB-compliant ZIP creation
│   │   │   └── EpubValidator.java      # EPUBCheck validation wrapper
│   │   │
│   │   ├── xsl/                        # XSLT 3.0 transformation modules
│   │   │   ├── map2epub3.xsl           # Main entry point (imports HTML5 base)
│   │   │   ├── epub3-params.xsl        # All XSLT parameters with defaults
│   │   │   ├── epub3-common.xsl        # Utility functions (UUID, title, language)
│   │   │   ├── epub3-metadata.xsl      # Dublin Core metadata extraction
│   │   │   ├── epub3-content.xsl       # DITA topic → XHTML5 generation
│   │   │   └── epub3-impl.xsl          # OPF, navigation, NCX generation
│   │   │
│   │   └── resources/
│   │       ├── css/
│   │       │   ├── epub-default.css    # Default EPUB styles
│   │       │   └── epub-fonts.css      # @font-face declaration templates
│   │       └── fonts/                  # Font directory template
│   │           └── README.md           # Font embedding guide
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
│           └── dita-calibre/           # French Calibre Guide
│               ├── calibre-guide.ditamap
│               └── cover.jpg
│
├── strings/                            # Internationalization
│   ├── strings.xml                     # String registry
│   └── strings-en.xml                  # English strings
│
├── docs/                               # Documentation
│   ├── SPECIFICATION.md                # This file
│   ├── QUICKSTART.md                   # 5-minute setup guide
│   ├── CONTRIBUTING.md                 # Contribution guidelines
│   ├── CHANGELOG.md                    # Version history
│   ├── RELEASE_NOTES.md               # Release details
│   ├── PROJECT_STATUS.md              # Status and roadmap
│   ├── TEST_COVERAGE.md               # Test documentation
│   ├── TEST_SUMMARY.md                # Executive test summary
│   ├── GITHUB_CHECKLIST.md            # GitHub procedures
│   └── PLUGIN_INSTALL_TASK_FIX.md     # Bug fix spec for dita-ot-gradle
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

Imports the DITA-OT HTML5 base transformation and includes all plugin modules. The root template triggers `epub3-generate` mode which orchestrates:

1. OPF package document generation
2. EPUB3 navigation document
3. NCX table of contents (backward compatibility)
4. Cover page generation
5. Title page
6. Content files (XHTML per topic)
7. container.xml

### 2. epub3-params.xsl — Configuration Parameters

**File:** `src/main/xsl/epub3-params.xsl`

Defines all XSLT parameters with typed defaults. Also provides utility functions:
- `epub:is-true($value)` — checks if a string is `yes`, `true`, or `1`
- `epub:get-boolean($param, $default)` — safe boolean parameter resolution

### 3. epub3-common.xsl — Utility Functions

**File:** `src/main/xsl/epub3-common.xsl`

- `epub:generate-uuid()` — UUID generation for EPUB identifiers
- `epub:get-identifier()` — Extract publication identifier
- `epub:get-title()` — Extract map title with fallbacks
- `epub:get-language()` — Detect language from map metadata

### 4. epub3-metadata.xsl — Metadata Extraction

**File:** `src/main/xsl/epub3-metadata.xsl`

Extracts Dublin Core metadata from DITA bookmaps:
- Publication identifier, titles, subtitles
- Authors, contributors, publisher
- Publication date, last modified date (required by EPUB3)
- Rights/copyright, description/abstract

### 5. epub3-content.xsl — Content Generation

**File:** `src/main/xsl/epub3-content.xsl`

Transforms DITA topics to XHTML5 content files. Processes topicrefs from the map and generates separate XHTML files per topic with EPUB naming conventions.

### 6. epub3-impl.xsl — OPF and Navigation

**File:** `src/main/xsl/epub3-impl.xsl`

Generates the core EPUB structure:
- **OPF package document** (content.opf) — manifest, spine, metadata
- **EPUB3 navigation document** (nav.xhtml) — TOC, landmarks
- **NCX table of contents** — backward compatibility with EPUB2 readers
- **Cover page** — HTML cover with configurable styles
- **container.xml** — OCF container

### 7. EpubPackager.java — EPUB ZIP Creation

**File:** `src/main/java/.../EpubPackager.java`

Creates EPUB-compliant ZIP archives enforcing:
- `mimetype` as first entry (STORED, not DEFLATED)
- Correct CRC32 for uncompressed mimetype
- DEFLATED compression for all other files
- Recursive directory processing with ZIP path normalization

### 8. EpubValidator.java — EPUB Validation

**File:** `src/main/java/.../EpubValidator.java`

Wraps EPUBCheck 5.1.0 to validate generated EPUB files. Returns `ValidationResult` with validity status, errors, warnings, and EPUB version. Performs:
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
    id("io.github.jyjeanne.dita-ot-gradle") version "2.8.4"
    id("java")
}

val ditaOtVersion = "4.4"
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
| `downloadDitaOt` | DitaOtDownloadTask | Download DITA-OT 4.4 from GitHub releases |
| `epubPackagerJar` | Jar | Build epub-packager.jar |
| `packagePlugin` | Zip | Package plugin as ZIP for DITA-OT |
| `installLocalPlugin` | Exec | Install plugin into DITA-OT (uses `dita install <file> --force`) |
| `dita` | DitaOtTask | Build sample EPUB (English bookmap) |
| `buildCalibreGuide` | DitaOtTask | Build Calibre Guide EPUB (French) |
| `buildSampleEpub` | Task | Build + validate sample EPUB |
| `buildAllEpubs` | Task | Build all test datasets |
| `validateEpub` | JavaExec | EPUBCheck on sample EPUB |
| `validateCalibreEpub` | JavaExec | EPUBCheck on Calibre Guide |
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
| `epub.accessibility` | enum | `wcag-aa` | WCAG level: `wcag-a`, `wcag-aa`, `wcag-aaa` |
| `epub.aria.landmarks` | enum | `yes` | Generate ARIA landmarks: `yes`, `no` |
| `epub.skip.nav` | enum | `yes` | Include skip navigation links: `yes`, `no` |

### Font Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.embed.fonts` | path | `(none)` | Directory or comma-separated font files to embed |
| `epub.embedded.fonts` | path | `(none)` | Alias for `epub.embed.fonts` |
| `epub.obfuscate.fonts` | enum | `no` | Font obfuscation (not yet implemented) |

**Supported font formats:** TTF, OTF, WOFF, WOFF2

### Metadata Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.publisher` | string | `(from DITA)` | Publisher name (overrides DITA source) |
| `epub.rights` | string | `(from DITA)` | Copyright statement |
| `epub.identifier.scheme` | enum | `UUID` | Identifier scheme: `UUID`, `DOI`, `ISBN`, `URI` |
| `epub.language` | string | `en` | Primary language code |

### Styling Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `args.css` | string | `epub-default.css` | Main CSS filename |
| `args.csspath` | path | `styles` | Path to CSS directory |
| `args.copycss` | enum | `yes` | Copy CSS to output: `yes`, `no` |
| `args.output.base.name` | string | `output` | Output file base name |

### Validation Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.validate` | enum | `yes` | Run EPUBCheck after build: `yes`, `no` |
| `epub.validation.level` | enum | `error` | Validation reporting level |

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
| `EpubStructureTest` | mimetype, container.xml, directories, navigation, file naming |
| `OPFManifestTest` | package structure, Dublin Core, manifest items, spine |
| `CoverPageGenerationTest` | cover styles, OPF integration, spine ordering |
| `FontEmbeddingTest` | font formats, directory embedding, CSS templates |
| `EpubValidatorTest` | validator behavior, null/missing files, size warnings |
| `EpubGenerationIntegrationTest` | end-to-end EPUB generation (requires DITA-OT) |

### Test Datasets

| Dataset | Language | Map | Output | TOC Depth |
|---------|----------|-----|--------|-----------|
| sample | English | `src/test/resources/dita/sample-bookmap.ditamap` | `build/epub` | 5 |
| calibre-guide | French | `src/test/resources/dita-calibre/calibre-guide.ditamap` | `build/epub-calibre` | 3 |

### Running Tests

```bash
./gradlew test                                  # All unit tests
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
Six focused modules rather than a monolithic stylesheet. Each module handles a single concern (params, common, metadata, content, impl) plus the orchestrating entry point.

### EPUB ZIP Compliance
The `EpubPackager.java` class exists because standard ZIP utilities don't guarantee `mimetype` as the first uncompressed entry — a hard requirement of the EPUB/OCF specification.

---

## Known Limitations

- Font obfuscation not yet implemented (font copying works)
- Automatic font manifest generation requires manual CSS `@font-face` declarations
- Cover page limited to 3 styles (full-page, centered, custom)
- Single language (English) in strings — additional locales require manual addition

---

## Roadmap

### v1.0.1 (Current)
- [x] Cover page generation with multiple styles
- [x] Font embedding (TTF, OTF, WOFF, WOFF2)
- [x] Comprehensive test suite
- [x] GitHub Actions CI/CD
- [x] Windows path handling

### v1.1 (Planned)
- [ ] Font obfuscation (Adobe algorithm)
- [ ] Image optimization
- [ ] Additional language support (fr, de, ja)
- [ ] Dark mode CSS support

### v2.0 (Future)
- [ ] DITA 2.0 full support
- [ ] EPUB3 Fixed Layout
- [ ] Custom theme system

---

## License

Apache License 2.0 — Copyright 2025 J. Jeanne

---

**Document Version:** 1.0.1
**Last Updated:** 2026-02-19
**Status:** Current Release

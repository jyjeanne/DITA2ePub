# Dita2epub - Modern EPUB Transformation Plugin - Technical Specification

## Project Overview

**Project Name:** Dita2epub
**Plugin ID:** io.github.jyjeanne.dita2epub
**Version:** 1.0.1 (Current Release)
**Target DITA-OT Version:** 4.3.5+
**License:** Apache License 2.0
**Author:** J. Jeanne
**Repository:** https://github.com/jyjeanne/dita2epub

### Description

Dita2epub is a modern transformation plugin for the DITA Open Toolkit (DITA-OT) 4.3.5 that converts DITA (Darwin Information Typing Architecture) XML content and maps into publication-ready EPUB (Electronic Publication) formats. This plugin is built from the ground up to leverage the latest DITA-OT 4.x architecture, modern build tools, and contemporary Java features.

The plugin enables technical writers and content publishers to transform structured DITA documentation into ebooks compatible with EPUB3 format, with optional EPUB2 backward compatibility support.

### Key Differentiators

- **Modern DITA-OT 4.3.5** - Built for the latest DITA-OT release
- **Gradle Build System** - Modern, declarative build configuration
- **Java 17+** - Leverages modern Java features and performance
- **EPUB3-First** - Prioritizes modern EPUB3 specification
- **Cover Page Generation** - Automatic HTML cover pages with customizable styles (v1.0.1)
- **Font Embedding** - Support for TTF, OTF, WOFF, WOFF2 font formats (v1.0.1)
- **Comprehensive Testing** - 44 test methods across 6 test classes
- **Continuous Integration** - CI/CD ready with automated testing
- **Active Development** - Regular updates and maintenance

---

## Technical Stack

### Core Technologies

| Technology | Version/Specification | Purpose |
|------------|----------------------|---------|
| DITA-OT | 4.3.5 | Document processing framework |
| Java | 17+ (LTS) | Runtime environment |
| Gradle | 8.x | Build system and dependency management |
| XSLT | 3.0 (Saxon 12.7) | Primary transformation language |
| XML | 1.0/1.1 | Configuration and content files |
| EPUB | 3.3 (primary) / 2.0.1 (legacy) | Target output format |
| XHTML | 5.0 | Content markup |
| CSS | 3 | Styling |
| JavaScript | ES6+ | Interactive enhancements |
| Kotlin DSL | 1.9+ (optional) | Gradle build scripts |

### DITA-OT 4.3.5 Bundled Components

DITA-OT 4.3.5 includes:
- **Apache Ant** 1.10.15 - Internal build orchestration
- **Saxon-HE** 12.7 - XSLT 3.0 processor
- **ICU for Java** 77.1 - Internationalization support
- **FOP** 2.10 - XSL-FO processor (for PDF pipelines)

### XSLT 3.0 Features Used

- Text value templates (`expand-text`)
- Multiple output documents (`xsl:result-document`)
- Tunnel parameters for context passing
- Processing modes for template specialization
- Strong typing (`xs:string`, `xs:boolean`, `xs:integer`)
- Sequence operations and advanced XPath 3.1
- Regular expression processing
- Map and array support (XPath 3.1)
- Higher-order functions

### Build System: Gradle

**Gradle 8.x** with Kotlin DSL (recommended) or Groovy DSL
- Modern dependency management
- Declarative plugin configuration
- Task-based build orchestration
- Parallel execution support
- Incremental builds
- Build caching
- Composite builds for multi-project setups

#### Gradle Plugin Configuration

```kotlin
// build.gradle.kts
plugins {
    id("io.github.jyjeanne.dita-ot-gradle") version "2.2.0"
}

repositories {
    mavenCentral()
    gradlePluginPortal()
}

dita {
    ditaOtVersion.set("4.3.5")

    transtype.set("epub3")

    input.set(file("src/dita/bookmap.ditamap"))
    output.set(file("build/epub"))

    properties.set(mapOf(
        "args.csspath" to "css",
        "epub.cover.graphic" to "images/cover.png",
        "args.gen.task.lbl" to "YES"
    ))
}

dependencies {
    // DITA-OT plugins
    ditaPlugin("org.dita.html5:4.3.5")

    // Additional dependencies
    testImplementation("org.junit.jupiter:junit-jupiter:5.10.0")
    testImplementation("org.xmlunit:xmlunit-core:2.9.1")
}
```

#### Key Gradle Tasks

- `gradle ditaBuild` - Execute DITA transformation
- `gradle ditaInstallPlugin` - Install custom DITA-OT plugins
- `gradle validateEpub` - Validate generated EPUB files
- `gradle test` - Run unit and integration tests
- `gradle clean` - Clean build artifacts
- `gradle publishPlugin` - Publish plugin to repository

---

## Dependencies and Libraries

### Required DITA-OT 4.3.5 Plugins

| Plugin ID | Version | Purpose |
|-----------|---------|---------|
| org.dita.html5 | 4.3.5 | Base HTML5 transformation support |
| org.dita.base | 4.3.5 | Core DITA processing |

**Note:** DITA-OT 4.x has simplified plugin dependencies. Many community plugins from the 2.x era are no longer required as their functionality has been integrated into the core.

### External Java Libraries

| Library | Version | Purpose |
|---------|---------|---------|
| Saxon-HE | 12.7 | XSLT 3.0 processor (bundled with DITA-OT) |
| EPUBCheck | 5.1.0 | EPUB validation |
| Apache Commons IO | 2.15.1 | File handling utilities |
| SLF4J | 2.0.9 | Logging facade |

### Gradle Dependencies

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

### Architectural Patterns

#### 1. Modern Plugin Architecture
- Extends DITA-OT 4.x through `plugin.xml` descriptor
- Uses DITA-OT 4.x extension points
- Leverages Gradle for build management
- Supports template-based customization
- Modular design for maintainability

#### 2. Mode-Based XSLT Processing

Specialized processing modes:
- `generate-content` - Topic transformation to HTML5
- `generate-opf` - OPF manifest generation (EPUB3)
- `generate-nav` - EPUB3 navigation document
- `generate-toc-ncx` - EPUB2 NCX (legacy support)
- `html2xhtml` - HTML5 to XHTML5 conversion
- `collect-resources` - Resource collection and mapping
- `metadata-extraction` - Dublin Core metadata extraction

#### 3. Modular XSLT Design

- **Core Module:** Main transformation orchestrator
- **Content Module:** Topic-to-HTML transformation
- **Navigation Module:** TOC and nav document generation
- **Packaging Module:** OPF and container generation
- **Resource Module:** Asset management (images, fonts, CSS, JS)
- **Metadata Module:** Dublin Core and EPUB metadata
- **Utility Module:** Common templates and functions

#### 4. Map-Driven Processing (DITA-OT 4.x)

- Leverages DITA-OT 4.x preprocessing pipeline
- Utilizes modern keyref resolution
- Processes branch filtering efficiently
- Handles chunking and topic nesting
- Supports DITA 1.3 and 2.0 features

#### 5. Multi-Pass Transformation Pipeline

```
┌─────────────────────────────────────────────────────────────┐
│                    Gradle Build Task                        │
│                  (dita-ot-gradle plugin)                    │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                  DITA-OT 4.3.5 Framework                    │
│              (Preprocessing Pipeline)                       │
│  • Topic resolution • Keyref resolution                     │
│  • Conref resolution • Filtering • Chunking                 │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              Dita2epub Plugin Entry Point                   │
│                 (plugin.xml + XSLT)                         │
└──────────────────────┬──────────────────────────────────────┘
                       │
          ┌────────────┴────────────┐
          │                         │
          ▼                         ▼
┌──────────────────────┐  ┌──────────────────────┐
│  Data Collection     │  │  Resource Collection │
│  • Metadata extract  │  │  • Graphics mapping  │
│  • Element enum      │  │  • Font discovery    │
│  • Navigation struct │  │  • CSS/JS collection │
└──────────┬───────────┘  └──────────┬───────────┘
           │                         │
           └─────────┬───────────────┘
                     ▼
           ┌─────────────────────┐
           │  Main XSLT Engine   │
           │  (map2epub3.xsl)    │
           └─────────┬───────────┘
                     │
        ┌────────────┼────────────┬──────────────┐
        │            │            │              │
        ▼            ▼            ▼              ▼
┌──────────────┐ ┌────────┐ ┌────────────┐ ┌──────────┐
│ Content Gen  │ │OPF Gen │ │Nav Gen     │ │Packaging │
│• HTML5 gen   │ │• Mani- │ │• EPUB3 nav │ │• META-INF│
│• XHTML5      │ │  fest  │ │• Landmarks │ │• mimetype│
│• Topic files │ │• Spine │ │• Optional  │ │• ZIP     │
│              │ │• Meta  │ │  NCX       │ │  creation│
└──────┬───────┘ └────┬───┘ └─────┬──────┘ └────┬─────┘
       │              │            │             │
       └──────────────┴────────────┴─────────────┘
                      │
                      ▼
            ┌──────────────────┐
            │ Post-Processing  │
            │ • EPUB validation│
            │ • Accessibility  │
            │ • Quality checks │
            └─────────┬────────┘
                      │
                      ▼
            ┌──────────────────┐
            │  Final EPUB3     │
            │  (.epub file)    │
            └──────────────────┘
```

#### 6. Configuration via Parameters

Extensive parameterization through Gradle:
- Output directory structure
- EPUB version selection (3 primary, 2 legacy)
- Feature toggles (index, glossary, TOC)
- CSS and font management
- Metadata customization
- Accessibility options

#### 7. Namespace Management

Modern XML namespace handling:
- XHTML5: `http://www.w3.org/1999/xhtml`
- EPUB OPS 3.0: `http://www.idpf.org/2007/ops`
- OPF 3.0: `http://www.idpf.org/2007/opf`
- Dublin Core: `http://purl.org/dc/elements/1.1/`
- DCMI Terms: `http://purl.org/dc/terms/`
- NCX (legacy): `http://www.daisy.org/z3986/2005/ncx/`

---

## Directory Structure

```
Dita2epub/
├── .github/                             # GitHub Actions CI/CD
│   └── workflows/
│       ├── build.yml                    # Build and test workflow
│       └── publish.yml                  # Plugin publishing workflow
│
├── .gitignore                           # Git ignore configuration
├── LICENSE                              # Apache License 2.0
├── README.md                            # Project documentation
├── SPECIFICATION.md                     # This file
├── CONTRIBUTING.md                      # Contribution guidelines
├── CHANGELOG.md                         # Version history
│
├── build.gradle.kts                     # Gradle build configuration (Kotlin DSL)
├── settings.gradle.kts                  # Gradle settings
├── gradle.properties                    # Gradle properties
├── gradlew                              # Gradle wrapper (Unix)
├── gradlew.bat                          # Gradle wrapper (Windows)
├── gradle/                              # Gradle wrapper files
│   └── wrapper/
│       ├── gradle-wrapper.jar
│       └── gradle-wrapper.properties
│
├── plugin.xml                           # DITA-OT plugin descriptor
│
├── src/                                 # Source files
│   ├── main/
│   │   ├── java/                        # Java source (optional extensions)
│   │   │   └── io/github/jyjeanne/
│   │   │       └── dita2epub/
│   │   │           ├── EpubValidator.java
│   │   │           └── FontObfuscator.java
│   │   │
│   │   ├── resources/                   # Static resources
│   │   │   ├── css/
│   │   │   │   ├── epub-default.css    # Default EPUB styles
│   │   │   │   └── epub-accessible.css # Accessibility-focused styles
│   │   │   │
│   │   │   ├── missing-graphic/        # Placeholder graphics
│   │   │   │   ├── missing.png
│   │   │   │   └── missing.svg
│   │   │   │
│   │   │   └── templates/              # Document templates
│   │   │       └── container.xml.template
│   │   │
│   │   └── xsl/                         # XSLT transformations
│   │       ├── map2epub3.xsl           # Main entry point
│   │       ├── map2epub3-impl.xsl      # Core implementation
│   │       ├── epub3-opf.xsl           # OPF generation
│   │       ├── epub3-nav.xsl           # Navigation document
│   │       ├── epub3-content.xsl       # Content transformation
│   │       ├── epub3-metadata.xsl      # Metadata extraction
│   │       ├── epub3-resources.xsl     # Resource management
│   │       ├── epub3-packaging.xsl     # EPUB packaging
│   │       ├── epub2-ncx.xsl           # Legacy NCX (optional)
│   │       ├── html2xhtml5.xsl         # HTML5 to XHTML5
│   │       └── epub-common.xsl         # Common utilities
│   │
│   └── test/                            # Test files
│       ├── java/                        # Java tests
│       │   └── io/github/jyjeanne/
│       │       └── dita2epub/
│       │           └── EpubValidatorTest.java
│       │
│       └── resources/                   # Test resources
│           ├── dita/                    # Sample DITA content
│           │   ├── sample-bookmap.ditamap
│           │   └── topics/
│           │       └── sample-topic.dita
│           │
│           └── expected/                # Expected outputs
│               └── sample-epub/
│
├── strings/                             # Internationalization
│   ├── strings.xml                     # String registry
│   ├── strings-en.xml                  # English
│   ├── strings-fr.xml                  # French
│   ├── strings-de.xml                  # German
│   └── strings-ja.xml                  # Japanese
│
└── docs/                                # Documentation
    ├── user-guide.md
    ├── developer-guide.md
    ├── customization.md
    └── api/                             # Generated API docs
```

---

## Core Components

### 1. Core Transformation Engine
**File:** `src/main/xsl/map2epub3-impl.xsl`

**Purpose:** Root transformation orchestrator for EPUB3 generation

**Key Responsibilities:**
- Manages overall EPUB3 generation workflow
- Coordinates OPF, navigation, and content generation
- Handles DITA-OT 4.x parameters and context
- Processes resolved DITA maps with modern preprocessing
- Supports DITA 1.3 and 2.0 features

**Key Parameters:**
```kotlin
dita {
    properties.set(mapOf(
        "epub.version" to "3.3",              // EPUB version
        "epub.cover.image" to "cover.png",    // Cover graphic
        "epub.toc.depth" to "5",              // TOC depth
        "epub.nav.depth" to "5",              // Navigation depth
        "epub.topics.dir" to "content",       // Topics directory
        "epub.images.dir" to "images",        // Images directory
        "epub.fonts.dir" to "fonts",          // Fonts directory
        "epub.css.dir" to "styles",           // CSS directory
        "epub.js.dir" to "scripts",           // JavaScript directory
        "epub.accessibility" to "wcag-aa"     // Accessibility level
    ))
}
```

### 2. OPF Generation (EPUB3)
**File:** `src/main/xsl/epub3-opf.xsl`

**Purpose:** Generate EPUB3 package document (content.opf)

**Features:**
- EPUB 3.3 compliant package document
- Dublin Core and DCMI Terms metadata
- Spine with reading order and progression direction
- Manifest with proper media types
- EPUB3 collections (series, indexes)
- Accessibility metadata (schema.org)
- Refines metadata (EPUB3 meta elements)

### 3. Navigation Generation (EPUB3)
**File:** `src/main/xsl/epub3-nav.xsl`

**Purpose:** Generate EPUB3 navigation document

**Features:**
- XHTML5 nav document per EPUB3 spec
- Multiple navigation types:
  - `toc` - Table of contents
  - `landmarks` - Document landmarks
  - `page-list` - Page list (optional)
  - `lot` - List of tables
  - `lof` - List of figures
  - `loi` - List of illustrations
- Semantic navigation with `epub:type`
- Accessible navigation with ARIA
- Hidden navigation (hidden attribute)

### 4. Content Generation
**File:** `src/main/xsl/epub3-content.xsl`

**Purpose:** Transform DITA topics to XHTML5

**Features:**
- XHTML5 output (HTML5 in XML serialization)
- Semantic HTML5 elements
- EPUB3 structural semantics (`epub:type`)
- Accessible markup (ARIA attributes)
- Responsive design support
- Math support (MathML)
- SVG support
- Multimedia embedding (audio, video)

### 5. HTML5 to XHTML5 Conversion
**File:** `src/main/xsl/html2xhtml5.xsl`

**Purpose:** Convert HTML5 to XHTML5 for EPUB3

**Features:**
- Proper XHTML5 serialization
- XML namespace management
- Well-formed XML output
- DOCTYPE removal (not needed in EPUB3)
- CSS path rewriting
- Meta tag cleanup

### 6. Resource Management
**File:** `src/main/xsl/epub3-resources.xsl`

**Purpose:** Manage all EPUB resources

**Features:**
- Graphic discovery and mapping
- Font embedding (WOFF, WOFF2, TTF, OTF)
- CSS collection and optimization
- JavaScript bundling
- Multimedia resource handling
- Remote resource detection
- Resource deduplication
- Manifest generation

### 7. Metadata Extraction
**File:** `src/main/xsl/epub3-metadata.xsl`

**Purpose:** Extract and format metadata for EPUB3

**Features:**
- Dublin Core metadata from DITA bookmeta
- DCMI Terms for modern metadata
- Unique identifier generation (UUID or DOI)
- Multiple authors and contributors
- Publication date handling
- Language and localization
- Rights and licensing
- Custom metadata preservation

### 8. EPUB Packaging
**File:** `src/main/xsl/epub3-packaging.xsl`

**Purpose:** Create EPUB container structure

**Features:**
- META-INF/container.xml generation
- mimetype file (uncompressed)
- ZIP packaging per OCF specification
- Encryption.xml (for font obfuscation)
- Signatures.xml (for digital signatures)

### 9. Java Extensions (Optional)
**File:** `src/main/java/io/github/jyjeanne/dita2epub/`

**Purpose:** Java-based processing for performance

**Components:**
- `EpubValidator.java` - EPUBCheck integration
- `FontObfuscator.java` - EPUB3 font obfuscation
- `ZipPackager.java` - Efficient ZIP creation
- `ResourceOptimizer.java` - Image and resource optimization

---

## Use Cases

### Primary Use Cases

#### 1. Technical Documentation Publishing
**Scenario:** Convert DITA-based technical documentation to EPUB3

**Benefits:**
- Modern, accessible ebooks
- Semantic navigation
- Mobile-first design
- Offline reading on all devices
- Automated generation from CI/CD pipeline

**Example:** SaaS company publishes product documentation as EPUBs with automated builds on every documentation update

#### 2. Multi-Format Publishing
**Scenario:** Single-source authoring with automated multi-format output

**Benefits:**
- Author once in DITA 1.3/2.0
- Publish to HTML5, PDF, and EPUB3
- Automated CI/CD publishing pipeline
- Version control and content reuse
- Reduced time-to-publish

**Example:** Technical writing team uses Gradle multi-project build to generate web, PDF, and EPUB from single source

#### 3. Accessible Educational Content
**Scenario:** Create WCAG-compliant educational materials

**Benefits:**
- WCAG 2.1 AA/AAA compliance
- Screen reader optimization
- Semantic HTML5 structure
- MathML for equations
- Multimedia with captions and transcripts

**Example:** Educational publisher creates accessible EPUB3 textbooks meeting legal accessibility requirements

#### 4. Agile Documentation Workflow
**Scenario:** Continuous documentation delivery

**Benefits:**
- Gradle-based automation
- GitHub Actions CI/CD integration
- Automated testing and validation
- Version-tagged releases
- Preview deployments

**Example:** Development team auto-publishes documentation EPUBs on every merge to main branch

#### 5. Enterprise Knowledge Management
**Scenario:** Corporate documentation distribution

**Benefits:**
- Self-service documentation portal
- Mobile and offline access
- Full-text search capabilities
- Multilingual support
- Usage analytics integration

**Example:** Global enterprise distributes compliance documentation in 15 languages as EPUBs

### Key Features

#### 1. EPUB3-First Design
- EPUB 3.3 specification compliance
- Modern HTML5 semantic markup
- CSS Grid and Flexbox support
- JavaScript API access
- Accessibility built-in

#### 2. Advanced Typography
- Modern font formats (WOFF2, WOFF, TTF, OTF)
- Variable fonts support
- Font subsetting (optional)
- OpenType features
- Font obfuscation (EPUB3 method)

#### 3. Rich Media Support
- **Images:** PNG, JPG, GIF, SVG, WEBP
- **Audio:** MP3, M4A, OGG
- **Video:** MP4, WEBM
- **Interactive:** JavaScript ES6+
- **Math:** MathML 3.0
- **Fonts:** WOFF2, WOFF, TTF, OTF

#### 4. Accessibility Features
- WCAG 2.1 AA/AAA support
- ARIA landmarks and roles
- Semantic HTML5 structure
- Keyboard navigation
- Screen reader optimization
- High contrast modes
- Accessibility metadata

#### 5. Modern Development
- Gradle-based builds
- GitHub Actions CI/CD
- Automated testing (JUnit, XMLUnit)
- EPUBCheck validation
- Code quality tools (SpotBugs, PMD)
- Documentation generation

#### 6. Customization Options
- CSS customization via Gradle
- Custom XSLT templates
- Plugin extension points
- Gradle task customization
- Parameter configuration
- Theme support

---

## Configuration Parameters

### Gradle Configuration

```kotlin
// build.gradle.kts
dita {
    // DITA-OT Configuration
    ditaOtVersion.set("4.3.5")
    ditaHome.set(file("dita-ot-4.3.5"))

    // Transformation Configuration
    transtype.set("epub3")
    input.set(file("src/dita/bookmap.ditamap"))
    output.set(file("build/epub"))

    // Temporary Directory
    temp.set(file("build/tmp/dita"))

    // EPUB Configuration
    properties.set(mapOf(
        // Core Parameters
        "epub.version" to "3.3",
        "epub.cover.image" to "images/cover.png",
        "epub.embedded.fonts" to "fonts/OpenSans.woff2,fonts/SourceCode.woff2",

        // Directory Structure
        "epub.topics.dir" to "content",
        "epub.images.dir" to "images",
        "epub.fonts.dir" to "fonts",
        "epub.css.dir" to "styles",
        "epub.js.dir" to "scripts",

        // Navigation
        "epub.toc.depth" to "5",
        "epub.nav.depth" to "5",
        "epub.generate.lof" to "yes",
        "epub.generate.lot" to "yes",

        // Accessibility
        "epub.accessibility" to "wcag-aa",
        "epub.aria.landmarks" to "yes",
        "epub.skip.nav" to "yes",

        // CSS and Styling
        "args.csspath" to "styles",
        "args.css" to "custom.css",
        "args.copycss" to "yes",

        // Metadata
        "epub.publisher" to "Your Publisher Name",
        "epub.rights" to "Copyright 2025 All Rights Reserved",
        "epub.identifier.scheme" to "UUID",

        // Optional Features
        "epub.include.toc.page" to "no",
        "epub.obfuscate.fonts" to "yes",
        "epub.validate" to "yes",

        // Legacy Support
        "epub.generate.ncx" to "no"  // Set to 'yes' for EPUB2 readers
    ))
}

tasks {
    // Custom validation task
    register("validateEpub") {
        dependsOn("ditaBuild")
        doLast {
            val epubFile = file("build/epub/output.epub")
            exec {
                commandLine("java", "-jar", "epubcheck.jar", epubFile)
            }
        }
    }

    // Automated testing
    test {
        useJUnitPlatform()
        testLogging {
            events("passed", "skipped", "failed")
        }
    }
}
```

### Parameter Reference

#### Core Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.version` | string | '3.3' | EPUB specification version |
| `epub.cover.image` | path | (none) | Cover image file path |
| `epub.toc.depth` | integer | 5 | Maximum TOC depth |
| `epub.nav.depth` | integer | 5 | Maximum navigation depth |
| `epub.topics.dir` | string | 'content' | Content directory name |
| `epub.images.dir` | string | 'images' | Images directory name |
| `epub.fonts.dir` | string | 'fonts' | Fonts directory name |
| `epub.css.dir` | string | 'styles' | CSS directory name |
| `epub.js.dir` | string | 'scripts' | JavaScript directory name |

#### Accessibility Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.accessibility` | enum | 'wcag-a' | Accessibility level: wcag-a, wcag-aa, wcag-aaa |
| `epub.aria.landmarks` | boolean | true | Generate ARIA landmarks |
| `epub.skip.nav` | boolean | true | Include skip navigation links |
| `epub.page.list` | boolean | false | Generate page list |

#### Font Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.embedded.fonts` | list | (none) | Comma-separated font file paths |
| `epub.obfuscate.fonts` | boolean | false | Enable font obfuscation |
| `epub.font.subsetting` | boolean | false | Enable font subsetting |

#### Metadata Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.publisher` | string | (from DITA) | Publisher name |
| `epub.rights` | string | (from DITA) | Copyright statement |
| `epub.identifier.scheme` | enum | 'UUID' | Identifier scheme: UUID, DOI, ISBN |
| `epub.language` | string | 'en' | Primary language code |

#### Validation Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.validate` | boolean | true | Run EPUBCheck after build |
| `epub.validation.level` | enum | 'error' | Validation level: error, warning, info |

---

## Complete Parameter Reference (v1.0.1)

This section provides comprehensive documentation for all transformation parameters supported by Dita2epub v1.0.1.

### How to Use Parameters

Parameters can be specified in three ways:

**1. Command Line (DITA-OT)**
```bash
dita --input=mybook.ditamap \
     --format=epub3 \
     --output=output \
     --epub.cover.image=images/cover.jpg \
     --epub.generate.cover.page=yes
```

**2. Gradle Configuration**
```kotlin
dita {
    properties.set(mapOf(
        "epub.cover.image" to "images/cover.jpg",
        "epub.generate.cover.page" to "yes"
    ))
}
```

**3. DITA-OT Configuration File**
```properties
# dita.properties or .properties file
epub.cover.image=images/cover.jpg
epub.generate.cover.page=yes
```

### Parameter Categories

- [Core Parameters](#core-parameters-reference)
- [Cover Page and Branding](#cover-page-and-branding-parameters)
- [Font Management](#font-management-parameters)
- [Directory Structure](#directory-structure-parameters)
- [Navigation](#navigation-parameters)
- [Accessibility](#accessibility-parameters-reference)
- [Metadata](#metadata-parameters-reference)
- [Validation](#validation-parameters-reference)
- [Styling](#styling-parameters)

---

### Core Parameters Reference

#### epub.version
**Type:** `string` (enum)
**Default:** `3.3`
**Values:** `3.3`, `3.0`, `2.0.1`
**Since:** v1.0.0

Specifies the EPUB specification version for the output.

**Usage:**
```bash
--epub.version=3.3
```

**Notes:**
- `3.3` - Latest EPUB 3.3 specification (recommended)
- `3.0` - EPUB 3.0 for broader compatibility
- `2.0.1` - Legacy EPUB 2.0.1 (limited features)

---

### Cover Page and Branding Parameters

#### epub.cover.image
**Type:** `path`
**Default:** `(none)`
**Since:** v1.0.0

Path to the cover image file. The image will be copied to the EPUB and referenced in the OPF manifest.

**Supported Formats:** JPG, PNG, SVG, GIF

**Usage:**
```bash
--epub.cover.image=images/mycover.jpg
--epub.cover.image=/absolute/path/to/cover.svg
```

**Notes:**
- Relative paths are resolved from the input directory
- Absolute paths are supported
- SVG format recommended for scalability
- Image will be copied to `epub.images.dir`
- Automatically marked with `cover-image` property in manifest

**Example:**
```bash
dita --input=book.ditamap \
     --format=epub3 \
     --output=output \
     --epub.cover.image=images/cover.jpg
```

#### epub.generate.cover.page
**Type:** `boolean` (enum)
**Default:** `yes`
**Values:** `yes`, `no`
**Since:** v1.0.1

Automatically generate an HTML cover page from the cover image.

**Usage:**
```bash
--epub.generate.cover.page=yes
--epub.generate.cover.page=no
```

**Notes:**
- Requires `epub.cover.image` to be set
- Generates `cover.xhtml` in content directory
- Cover page is automatically placed first in spine
- Includes embedded CSS based on `epub.cover.page.style`
- Proper XHTML5 structure with semantic markup

**Example:**
```bash
dita --input=book.ditamap \
     --format=epub3 \
     --output=output \
     --epub.cover.image=images/cover.png \
     --epub.generate.cover.page=yes
```

#### epub.cover.page.style
**Type:** `string` (enum)
**Default:** `full-page`
**Values:** `full-page`, `centered`, `custom`
**Since:** v1.0.1

Style for the generated cover page.

**Usage:**
```bash
--epub.cover.page.style=full-page
--epub.cover.page.style=centered
--epub.cover.page.style=custom
```

**Style Descriptions:**

**full-page** (default)
- Cover image fills entire viewport
- Uses `width: 100%` and `height: 100vh`
- `object-fit: contain` to maintain aspect ratio
- No margins or padding
- Best for full-bleed cover designs

**centered**
- Cover image centered on page
- Uses flexbox for centering
- 2em padding around image
- `max-width: 100%` and `max-height: 90vh`
- Best for covers with transparent backgrounds

**custom**
- No inline styles applied
- Use custom CSS via `args.css`
- Full control over layout and styling

**Example:**
```bash
# Full-page style
dita --input=book.ditamap \
     --format=epub3 \
     --output=output \
     --epub.cover.image=cover.jpg \
     --epub.cover.page.style=full-page

# Centered style
dita --input=book.ditamap \
     --format=epub3 \
     --output=output \
     --epub.cover.image=cover.svg \
     --epub.cover.page.style=centered

# Custom style (provide your own CSS)
dita --input=book.ditamap \
     --format=epub3 \
     --output=output \
     --epub.cover.image=cover.png \
     --epub.cover.page.style=custom \
     --args.css=mycustom.css
```

---

### Font Management Parameters

#### epub.embed.fonts
**Type:** `path`
**Default:** `(none)`
**Since:** v1.0.1

Directory path or comma-separated list of font files to embed in the EPUB.

**Supported Formats:** TTF, OTF, WOFF, WOFF2

**Usage:**
```bash
# Directory-based (recommended)
--epub.embed.fonts=/path/to/fonts/

# Individual files
--epub.embed.fonts=fonts/OpenSans-Regular.woff2,fonts/OpenSans-Bold.woff2
```

**Directory Structure Example:**
```
fonts/
├── OpenSans-Regular.woff2
├── OpenSans-Bold.woff2
├── OpenSans-Italic.woff2
└── SourceCodePro-Regular.ttf
```

**Notes:**
- All fonts are copied to `epub.fonts.dir` in the EPUB
- Directory-based copying includes all TTF, OTF, WOFF, WOFF2 files
- You must create `@font-face` declarations in your CSS
- See `src/main/resources/css/epub-fonts.css` for examples
- Font files are added to OPF manifest automatically

**Complete Example:**
```bash
# 1. Place fonts in directory
mkdir -p fonts
cp MyFont-*.woff2 fonts/

# 2. Create font CSS (src/main/resources/css/epub-fonts.css)
cat > epub-fonts.css << 'EOF'
@font-face {
  font-family: 'MyFont';
  src: url('../fonts/MyFont-Regular.woff2') format('woff2');
  font-weight: 400;
  font-style: normal;
}
@font-face {
  font-family: 'MyFont';
  src: url('../fonts/MyFont-Bold.woff2') format('woff2');
  font-weight: 700;
  font-style: normal;
}
EOF

# 3. Generate EPUB
dita --input=book.ditamap \
     --format=epub3 \
     --output=output \
     --epub.embed.fonts=fonts/
```

#### epub.embedded.fonts
**Type:** `path` (alias)
**Default:** `(none)`
**Since:** v1.0.1

Alias for `epub.embed.fonts`. Use either parameter name.

**Usage:**
```bash
--epub.embedded.fonts=/path/to/fonts/
```

#### epub.obfuscate.fonts
**Type:** `boolean` (enum)
**Default:** `no`
**Values:** `yes`, `no`
**Since:** v1.0.1 (planned)

Enable font obfuscation using Adobe algorithm.

**Status:** ⚠️ Not yet implemented in v1.0.1. Font copying works without obfuscation.

**Usage:**
```bash
--epub.obfuscate.fonts=yes
```

**Notes:**
- Font obfuscation planned for v1.1+
- Currently fonts are embedded without obfuscation
- Obfuscation provides basic DRM protection
- Not a security measure, but helps with licensing

---

### Directory Structure Parameters

#### epub.topics.dir
**Type:** `string`
**Default:** `content`
**Since:** v1.0.0

Name of the directory within the EPUB for topic XHTML files.

**Usage:**
```bash
--epub.topics.dir=content
--epub.topics.dir=chapters
```

**Notes:**
- Directory created in EPUB root
- Contains all transformed DITA topic files
- Also contains navigation document (`nav.xhtml`)
- Also contains cover page (`cover.xhtml`) if generated

#### epub.images.dir
**Type:** `string`
**Default:** `images`
**Since:** v1.0.0

Name of the directory within the EPUB for image files.

**Usage:**
```bash
--epub.images.dir=images
--epub.images.dir=graphics
```

**Notes:**
- All referenced images are copied here
- Cover image is placed here
- Supports JPG, PNG, GIF, SVG, WEBP

#### epub.fonts.dir
**Type:** `string`
**Default:** `fonts`
**Since:** v1.0.1

Name of the directory within the EPUB for embedded fonts.

**Usage:**
```bash
--epub.fonts.dir=fonts
--epub.fonts.dir=typefaces
```

**Notes:**
- Only created if `epub.embed.fonts` is specified
- Contains all embedded font files
- Referenced in CSS via relative paths

#### epub.css.dir
**Type:** `string`
**Default:** `styles`
**Since:** v1.0.0

Name of the directory within the EPUB for CSS files.

**Usage:**
```bash
--epub.css.dir=styles
--epub.css.dir=css
```

**Notes:**
- Default CSS file is copied here
- Custom CSS files are copied here
- Font CSS (`epub-fonts.css`) is copied here

---

### Navigation Parameters

#### epub.toc.depth
**Type:** `integer`
**Default:** `5`
**Since:** v1.0.0

Maximum depth level for the table of contents.

**Usage:**
```bash
--epub.toc.depth=5
--epub.toc.depth=3  # Limit to 3 levels
```

**Notes:**
- Controls TOC navigation structure
- Affects `nav.xhtml` TOC section
- Affects NCX TOC (if generated)
- Deeper levels are still in EPUB, just not in TOC

#### epub.nav.depth
**Type:** `integer`
**Default:** `5`
**Since:** v1.0.0

Maximum depth level for the EPUB3 navigation document.

**Usage:**
```bash
--epub.nav.depth=5
--epub.nav.depth=4
```

**Notes:**
- Controls depth of `nav.xhtml` structure
- Separate from `epub.toc.depth`
- Affects all navigation types (TOC, landmarks, etc.)

---

### Accessibility Parameters Reference

#### epub.accessibility
**Type:** `string` (enum)
**Default:** `wcag-aa`
**Values:** `wcag-a`, `wcag-aa`, `wcag-aaa`, `none`
**Since:** v1.0.0

Accessibility compliance level for the EPUB.

**Usage:**
```bash
--epub.accessibility=wcag-aa
--epub.accessibility=wcag-aaa
```

**Level Descriptions:**

**wcag-a** (minimum)
- Alternative text for images
- Keyboard navigation
- Semantic HTML structure
- Proper heading hierarchy

**wcag-aa** (recommended)
- All Level A requirements
- 4.5:1 contrast ratios
- Resizable text
- Focus indicators
- Consistent navigation
- ARIA landmarks

**wcag-aaa** (enhanced)
- All Level AA requirements
- 7:1 contrast ratios
- Extended descriptions
- Sign language support
- Reading level support

**none**
- No specific accessibility features
- Basic semantic HTML only

**Notes:**
- Generates appropriate schema.org metadata
- Affects CSS styling (contrast, focus)
- Recommended: `wcag-aa` for most publications

#### epub.aria.landmarks
**Type:** `boolean` (enum)
**Default:** `yes`
**Values:** `yes`, `no`
**Since:** v1.0.0

Generate ARIA landmarks in navigation document.

**Usage:**
```bash
--epub.aria.landmarks=yes
```

**Notes:**
- Creates landmarks navigation section
- Includes: cover, bodymatter, backmatter, toc, etc.
- Improves screen reader navigation

---

### Metadata Parameters Reference

#### epub.publisher
**Type:** `string`
**Default:** `(from DITA bookmeta)`
**Since:** v1.0.0

Publisher name for the EPUB metadata.

**Usage:**
```bash
--epub.publisher="My Publishing Company"
```

**Notes:**
- Overrides publisher from DITA source
- Appears in OPF metadata as `dc:publisher`
- Used by ebook readers and catalogs

#### epub.rights
**Type:** `string`
**Default:** `(from DITA bookmeta)`
**Since:** v1.0.0

Copyright and rights statement.

**Usage:**
```bash
--epub.rights="Copyright 2025 All Rights Reserved"
```

**Notes:**
- Overrides rights from DITA source
- Appears in OPF metadata as `dc:rights`

#### epub.identifier.scheme
**Type:** `string` (enum)
**Default:** `UUID`
**Values:** `UUID`, `DOI`, `ISBN`, `URI`
**Since:** v1.0.0

Identifier scheme for the unique identifier.

**Usage:**
```bash
--epub.identifier.scheme=ISBN
--epub.identifier.scheme=UUID
```

**Notes:**
- UUID: Automatically generated unique identifier
- ISBN: Use for published books with ISBN
- DOI: Use for academic publications
- URI: Use custom URI

---

### Validation Parameters Reference

#### epub.validate
**Type:** `boolean` (enum)
**Default:** `yes`
**Values:** `yes`, `no`
**Since:** v1.0.1

Run EPUBCheck validation after EPUB generation.

**Usage:**
```bash
--epub.validate=yes
--epub.validate=no
```

**Notes:**
- Requires EPUBCheck in `lib/` directory
- Validation results printed to console
- Build fails if validation errors found
- Can be disabled for faster builds

---

### Styling Parameters

#### args.css
**Type:** `path`
**Default:** `epub-default.css`
**Since:** v1.0.0

Name of the main CSS file to use.

**Usage:**
```bash
--args.css=mycustom.css
```

**Notes:**
- File should be in `args.csspath` directory
- Default CSS is in `src/main/resources/css/`
- Multiple CSS files not supported (use @import)

#### args.csspath
**Type:** `path`
**Default:** `(plugin resource path)`
**Since:** v1.0.0

Path to directory containing CSS files.

**Usage:**
```bash
--args.csspath=my-styles/
```

**Notes:**
- Relative to input directory
- All CSS files copied to `epub.css.dir`

#### args.copycss
**Type:** `boolean` (enum)
**Default:** `yes`
**Values:** `yes`, `no`
**Since:** v1.0.0

Copy CSS files to EPUB output.

**Usage:**
```bash
--args.copycss=yes
```

---

### Parameter Precedence

When parameters are specified in multiple locations, the precedence order is:

1. **Command-line arguments** (highest priority)
   ```bash
   dita --epub.cover.image=cover.jpg
   ```

2. **Gradle configuration**
   ```kotlin
   dita {
       properties["epub.cover.image"] = "cover.jpg"
   }
   ```

3. **DITA-OT configuration file** (.properties)
   ```properties
   epub.cover.image=cover.jpg
   ```

4. **Plugin defaults** (lowest priority)
   - Defined in `plugin.xml`

---

### Parameter Validation

Parameters are validated during transformation:

**Type Validation:**
- Boolean parameters must be `yes` or `no`
- Integer parameters must be valid numbers
- Enum parameters must match allowed values

**Path Validation:**
- Paths are checked for existence
- Missing files generate warnings
- Invalid paths may cause transformation failure

**Value Validation:**
- Depth parameters must be positive integers
- Version parameters must be supported versions

**Warning Messages:**
```
[WARN] Cover image not found: images/cover.jpg
[WARN] Font directory not found: /path/to/fonts
[ERROR] Invalid epub.version: 4.0
```

---

### Complete Example

Comprehensive example using all major v1.0.1 features:

```bash
dita \
  --input=mybook.ditamap \
  --format=epub3 \
  --output=output \
  \
  # Core settings
  --epub.version=3.3 \
  \
  # Cover page (NEW in v1.0.1)
  --epub.cover.image=images/cover.jpg \
  --epub.generate.cover.page=yes \
  --epub.cover.page.style=full-page \
  \
  # Font embedding (NEW in v1.0.1)
  --epub.embed.fonts=fonts/ \
  \
  # Navigation
  --epub.toc.depth=4 \
  --epub.nav.depth=4 \
  \
  # Accessibility
  --epub.accessibility=wcag-aa \
  --epub.aria.landmarks=yes \
  \
  # Metadata
  --epub.publisher="My Publisher" \
  --epub.rights="Copyright 2025" \
  \
  # Validation
  --epub.validate=yes
```

Gradle equivalent:
```kotlin
dita {
    transtype.set("epub3")
    input.set(file("mybook.ditamap"))
    output.set(file("output"))

    properties.set(mapOf(
        // Core
        "epub.version" to "3.3",

        // Cover page (NEW in v1.0.1)
        "epub.cover.image" to "images/cover.jpg",
        "epub.generate.cover.page" to "yes",
        "epub.cover.page.style" to "full-page",

        // Fonts (NEW in v1.0.1)
        "epub.embed.fonts" to "fonts/",

        // Navigation
        "epub.toc.depth" to "4",
        "epub.nav.depth" to "4",

        // Accessibility
        "epub.accessibility" to "wcag-aa",
        "epub.aria.landmarks" to "yes",

        // Metadata
        "epub.publisher" to "My Publisher",
        "epub.rights" to "Copyright 2025",

        // Validation
        "epub.validate" to "yes"
    ))
}
```

---

### Troubleshooting Parameters

**Cover page not generated:**
- Check `epub.cover.image` path exists
- Verify `epub.generate.cover.page=yes`
- Check console for error messages

**Fonts not embedded:**
- Verify `epub.embed.fonts` directory exists
- Check font files have correct extensions
- Ensure `@font-face` declarations in CSS

**Validation errors:**
- Run with `--epub.validate=yes` for details
- Check EPUBCheck output in console
- Verify all referenced files exist

**Path issues on Windows:**
- Use forward slashes: `images/cover.jpg`
- Or use double backslashes: `images\\cover.jpg`
- Absolute paths work: `C:/path/to/file`

---

## Internationalization

### Supported Languages (Initial Release)
- English (en, en-US, en-GB, en-CA)
- French (fr, fr-FR, fr-CA)
- German (de, de-DE, de-AT, de-CH)
- Spanish (es, es-ES, es-MX)
- Japanese (ja, ja-JP)

### Localizable Strings

All UI strings are externalized in `strings/` directory:
- Navigation labels (TOC, LOF, LOT, etc.)
- Landmarks
- Accessibility labels
- Error messages
- Copyright and legal notices

### Adding New Languages

```kotlin
// 1. Create strings file: strings/strings-{lang}.xml
<?xml version="1.0" encoding="UTF-8"?>
<strings xml:lang="pt-BR">
    <str name="Table of Contents">Índice</str>
    <str name="List of Figures">Lista de Figuras</str>
    <!-- ... more strings ... -->
</strings>

// 2. Register in strings/strings.xml
<stringfile locale="pt-BR" filename="strings-pt-BR.xml"/>

// 3. Build will automatically include new language
```

---

## Development and Testing

### Local Development Setup

```bash
# Clone repository
git clone https://github.com/jyjeanne/dita2epub.git
cd dita2epub

# Build project
./gradlew build

# Run tests
./gradlew test

# Install plugin locally
./gradlew ditaInstallPlugin

# Build sample EPUB
./gradlew ditaBuild --args="--input=samples/bookmap.ditamap --output=build/sample.epub"
```

### Testing Strategy

#### Unit Tests
```kotlin
// src/test/java/io/github/jyjeanne/dita2epub/EpubValidatorTest.java
@Test
fun testEpubStructureValidation() {
    val epubFile = File("build/test/sample.epub")
    val validator = EpubValidator()
    val result = validator.validate(epubFile)

    assertTrue(result.isValid)
    assertEquals(0, result.errors.size)
}
```

#### Integration Tests
- Full DITA-to-EPUB transformation tests
- Multi-topic document tests
- Cross-reference resolution tests
- Media embedding tests

#### Validation Tests
- EPUBCheck integration
- WCAG compliance testing
- Link validation
- Image validation

### Continuous Integration

```yaml
# .github/workflows/build.yml
name: Build and Test

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v4

    - name: Set up JDK 17
      uses: actions/setup-java@v4
      with:
        java-version: '17'
        distribution: 'temurin'

    - name: Setup Gradle
      uses: gradle/gradle-build-action@v3

    - name: Build with Gradle
      run: ./gradlew build

    - name: Run Tests
      run: ./gradlew test

    - name: Validate EPUBs
      run: ./gradlew validateEpub

    - name: Publish Test Results
      uses: EnricoMi/publish-unit-test-result-action@v2
      if: always()
      with:
        files: build/test-results/**/*.xml
```

---

## Technical Decisions and Rationale

### Key Design Decisions

#### 1. EPUB3-First Approach
**Decision:** Prioritize EPUB3 with optional EPUB2 support

**Rationale:**
- EPUB3 is the modern standard (since 2011)
- Better accessibility support
- HTML5 semantic markup
- Modern CSS and JavaScript
- Most readers support EPUB3 (2025)

#### 2. Gradle Build System
**Decision:** Use Gradle instead of Ant

**Rationale:**
- Modern, declarative configuration
- Better dependency management
- Incremental builds and caching
- Active community and ecosystem
- CI/CD integration
- Multi-project support

#### 3. Java 17+ Requirement
**Decision:** Require Java 17 LTS (aligned with DITA-OT 4.3.5)

**Rationale:**
- DITA-OT 4.3.5 requires Java 17+
- Long-term support until 2029
- Modern Java features (records, pattern matching, text blocks)
- Better performance and memory management

#### 4. Simplified Dependencies
**Decision:** Minimize external plugin dependencies

**Rationale:**
- DITA-OT 4.x has integrated many features
- Reduced maintenance burden
- Faster builds
- Fewer version conflicts
- Better reliability

#### 5. Semantic HTML5
**Decision:** Generate semantic HTML5 markup

**Rationale:**
- Better accessibility
- SEO benefits (for web-based readers)
- Future-proof content
- Easier styling and scripting
- Standards compliant

#### 6. Accessibility by Default
**Decision:** Build accessibility into core, not as addon

**Rationale:**
- Legal requirements in many jurisdictions
- Better user experience for all
- Easier to maintain
- Market differentiation

### Constraints

- **DITA-OT Version:** Requires DITA-OT 4.3.5 or compatible 4.x version
- **Java Version:** Java 17 or later (LTS versions recommended)
- **Gradle Version:** Gradle 8.x or later
- **XSLT Processor:** Saxon 12.7+ (bundled with DITA-OT)
- **Input Format:** Valid DITA 1.3 or DITA 2.0 content

---

## Performance Considerations

### Build Performance

- **Incremental Builds:** Gradle caches unchanged transformations
- **Parallel Execution:** DITA-OT 4.x parallel topic processing
- **Build Cache:** Share cache across team and CI
- **Dependency Resolution:** Gradle dependency caching
- **Resource Optimization:** Optional image compression and font subsetting

### Optimization Tips

```kotlin
// build.gradle.kts
dita {
    // Enable parallel processing
    properties["parallel"] = "true"
    properties["max.threads"] = "4"

    // Optimize images
    properties["epub.optimize.images"] = "yes"
    properties["epub.image.quality"] = "85"

    // Font subsetting
    properties["epub.font.subsetting"] = "yes"
}

// Enable Gradle build cache
buildCache {
    local {
        isEnabled = true
    }
}
```

---

## Accessibility Compliance

### WCAG 2.1 Support

#### Level A (Minimum)
- Semantic HTML5 structure
- Alternative text for images
- Keyboard navigation
- Skip navigation links
- Proper heading hierarchy

#### Level AA (Recommended)
- Contrast ratios (4.5:1 for text)
- Resizable text
- Focus indicators
- Consistent navigation
- Error identification

#### Level AAA (Enhanced)
- Sign language interpretation
- Extended audio descriptions
- Contrast ratios (7:1 for text)
- Reading level support

### Accessibility Metadata

```xml
<!-- Automatically generated in OPF -->
<meta property="schema:accessMode">textual</meta>
<meta property="schema:accessMode">visual</meta>
<meta property="schema:accessibilityFeature">alternativeText</meta>
<meta property="schema:accessibilityFeature">structuralNavigation</meta>
<meta property="schema:accessibilityFeature">tableOfContents</meta>
<meta property="schema:accessibilityHazard">none</meta>
<meta property="schema:accessibilitySummary">
    This publication meets WCAG 2.1 Level AA.
</meta>
```

---

## Security Considerations

### Font Security
- Font obfuscation using EPUB3 method (not IDPF algorithm)
- Optional font subsetting to reduce file size
- License compliance checking

### JavaScript Security
- Content Security Policy (CSP) headers
- Sandboxed execution (reader-dependent)
- No external resource loading by default
- Input validation for user-provided scripts

### Build Security
- Dependency verification (Gradle)
- Checksum validation
- Signed commits (GitHub)
- Security scanning (GitHub Dependabot)

---

## Validation and Quality Assurance

### EPUBCheck Integration

```kotlin
// Automatic validation after build
dita {
    properties["epub.validate"] = "yes"
    properties["epub.validation.level"] = "error"
}

// Manual validation
gradle validateEpub
```

### Quality Checks
- EPUB structure validation
- Manifest completeness
- Link validation
- Image reference validation
- CSS validation
- Accessibility validation (Ace by DAISY)

### Validation Reports

```
build/
└── reports/
    ├── epubcheck/
    │   └── validation-report.json
    ├── accessibility/
    │   └── ace-report.html
    └── links/
        └── link-check.xml
```

---

## Migration from Legacy Plugins

### Migrating from DITA4Publishers

#### Key Differences

| Aspect | DITA4Publishers (OT 2.5.4) | Dita2epub (OT 4.3.5) |
|--------|---------------------------|----------------------|
| Build System | Apache Ant | Gradle |
| Java Version | Java 8 | Java 17+ |
| EPUB Focus | Dual EPUB2/3 | EPUB3-first |
| Dependencies | 5+ D4P plugins | Core DITA-OT only |
| XSLT | Saxon 9.x | Saxon 12.7 |
| Accessibility | Optional | Built-in |

#### Migration Steps

```bash
# 1. Update DITA-OT
# Download DITA-OT 4.3.5

# 2. Update Java
# Install Java 17 LTS

# 3. Create Gradle project
gradle init --type basic --dsl kotlin

# 4. Add dita-ot-gradle plugin
# Edit build.gradle.kts (see configuration section)

# 5. Migrate Ant parameters to Gradle
# Convert build properties to Gradle DSL

# 6. Test transformation
./gradlew ditaBuild

# 7. Update CI/CD
# Update to use Gradle instead of Ant
```

---

## Support and Resources

### Documentation
- **User Guide:** `docs/user-guide.md`
- **Developer Guide:** `docs/developer-guide.md`
- **API Documentation:** `docs/api/`
- **DITA-OT Docs:** https://www.dita-ot.org/4.3/

### Community
- **Repository:** https://github.com/jyjeanne/dita2epub
- **Issues:** https://github.com/jyjeanne/dita2epub/issues
- **Discussions:** https://github.com/jyjeanne/dita2epub/discussions
- **License:** Apache License 2.0

### Related Standards
- **DITA 2.0:** https://www.oasis-open.org/committees/dita/
- **EPUB 3.3:** https://www.w3.org/TR/epub-33/
- **WCAG 2.1:** https://www.w3.org/TR/WCAG21/
- **Schema.org Accessibility:** https://www.w3.org/wiki/WebSchemas/Accessibility

---

## Roadmap

### Version 1.0.0 (Initial Release)
- [x] EPUB3 basic transformation
- [x] Gradle build integration
- [x] DITA-OT 4.3.5 compatibility
- [x] EPUBCheck validation
- [x] WCAG AA accessibility
- [x] CI/CD pipeline
- [x] Documentation

### Version 1.0.1 (Current Release)
- [x] Cover page generation with multiple styles
- [x] Font embedding (TTF, OTF, WOFF, WOFF2)
- [x] Comprehensive test suite (44 tests)
- [x] Enhanced documentation
- [x] Parameter validation
- [x] Windows path handling

### Version 1.1 (Planned)
- [ ] Font obfuscation (Adobe algorithm)
- [ ] Font subsetting support
- [ ] Image optimization
- [ ] Advanced CSS Grid layouts
- [ ] Dark mode support
- [ ] Performance optimizations
- [ ] Additional language support

### Version 1.2 (Future)
- [ ] EPUB3 Fixed Layout support
- [ ] Interactive elements library
- [ ] Advanced multimedia support
- [ ] Custom theme system
- [ ] Visual editor integration

### Version 2.0 (Long-term)
- [ ] DITA 2.0 full support
- [ ] AI-powered accessibility enhancements
- [ ] Real-time preview server
- [ ] Cloud build service
- [ ] Analytics integration

---

## License

Apache License 2.0

Copyright 2025 J. Jeanne

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

---

## Acknowledgments

This project is inspired by and builds upon the excellent work of:
- **DITA4Publishers** by Eliot Kimber and contributors
- **DITA Open Toolkit** community
- **EPUBCheck** by DAISY Consortium

---

**Document Version:** 1.0.1
**Created:** 2025-10-29
**Last Updated:** 2025-10-29
**Status:** Current Release
**Target Audience:** Developers, Technical Writers, Publishers
**Changelog:** Added comprehensive parameter reference for v1.0.1 features (cover page generation, font embedding)

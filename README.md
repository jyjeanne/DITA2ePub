# Dita2epub - Modern EPUB3 Transformation Plugin

<div align="center">

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![DITA-OT](https://img.shields.io/badge/DITA--OT-4.4-green.svg)](https://www.dita-ot.org/)
[![EPUB](https://img.shields.io/badge/EPUB-3.3-purple.svg)](https://www.w3.org/publishing/epub3/)
[![Java](https://img.shields.io/badge/Java-17%2B-orange.svg)](https://adoptium.net/)
[![Tests](https://img.shields.io/badge/tests-41%20passing-success.svg)](#testing)

[![CI Build](https://github.com/jyjeanne/dita2epub/actions/workflows/ci.yml/badge.svg)](https://github.com/jyjeanne/dita2epub/actions/workflows/ci.yml)
[![Nightly Tests](https://github.com/jyjeanne/dita2epub/actions/workflows/nightly-tests.yml/badge.svg)](https://github.com/jyjeanne/dita2epub/actions/workflows/nightly-tests.yml)
[![Documentation](https://github.com/jyjeanne/dita2epub/actions/workflows/docs.yml/badge.svg)](https://github.com/jyjeanne/dita2epub/actions/workflows/docs.yml)

**Transform your DITA content into professional, accessible EPUB 3.3 publications**

[Quick Start](#-quick-start) • [Documentation](#-documentation-hub) • [Features](#-key-features) • [Examples](#-usage)

</div>

---

## 📖 About

**Dita2epub** is a production-ready DITA-OT plugin that transforms DITA content into standards-compliant EPUB 3.3 publications. Built for technical writers, documentation teams, and publishers who demand professional-quality e-books with modern features and accessibility compliance.

### Why Dita2epub?

- **📚 Standards-Compliant**: Full EPUB 3.3 specification compliance with WCAG 2.1 accessibility
- **🎨 Professional Output**: Custom cover pages, embedded fonts, and optimized images
- **⚡ Production-Ready**: 41 comprehensive tests, CI/CD automation, and multi-platform support
- **🔧 Developer-Friendly**: XSLT 3.0 modular architecture, Gradle build system, complete documentation
- **🚀 Modern Stack**: Built on DITA-OT 4.4, Java 17+, and latest web standards

### What's New in v1.1.0?

- **Back-of-Book Index** - Automatic index generation from DITA `<indexterm>` elements with precise anchor links
- **EPUB 3.3 SSV Compliance** - Full Structural Semantics Vocabulary: `epub:type` for chapters, appendices, forewords, glossaries, index markup
- **Three Test Datasets** - English sample, French Calibre Guide, and Indexing Guide with back-of-book index
- **Zero EPUBCheck Errors** - All 3 test EPUBs pass EPUBCheck 5.3.0 with 0 errors and 0 warnings
- **DITA-OT 4.4** - Built for the latest DITA Open Toolkit
- **Cover Page Generation** - Automatic HTML cover pages with 3 customizable styles
- **Font Embedding** - Embed custom fonts (TTF, OTF, WOFF, WOFF2) with proper manifest generation
- **Comprehensive Testing** - 41 tests across 6 test classes with 100% unit test pass rate
- **GitHub Actions CI/CD** - Automated testing, releases, and documentation validation

---

## 🌟 Key Features

### Core Capabilities
- **EPUB 3.3 Standard**: Full compliance with latest EPUB specification and Structural Semantics Vocabulary (SSV)
- **DITA-OT 4.4 Integration**: Seamless plugin architecture
- **XHTML5 Output**: Modern, semantic HTML content with proper `epub:type` annotations
- **Accessibility Built-in**: WCAG 2.1 AA/AAA metadata and ARIA support
- **Navigation**: Automatic TOC, landmarks, and NCX generation

### Advanced Features
- **Back-of-Book Index**: Automatic index generation from `<indexterm>` elements with alphabetical grouping, nested entries, cross-references (`See`/`See also`), and precise anchor links
- **Cover Page Generation**: Automatic HTML cover pages with customizable styles
- **Font Embedding**: Embed custom fonts (TTF, OTF, WOFF, WOFF2)
- **Image Support**: Automatic image copying and manifest generation
- **EPUBCheck 5.3.0 Integration**: Built-in validation with zero errors on all test EPUBs
- **Comprehensive Testing**: 41 tests across 6 test classes

### Developer Experience
- **Gradle Build System**: Modern build configuration with Kotlin DSL
- **Extensible Architecture**: 7 XSLT 3.0 modules with clear separation of concerns
- **Complete Documentation**: Guides, EPUB 3 anatomy reference, and API docs
- **CI/CD Ready**: GitHub Actions workflow templates

---

## 📋 Table of Contents

- [About](#-about) - Why Dita2epub? What's new?
- [Key Features](#-key-features) - Core capabilities and advanced features
- [Requirements](#-requirements) - System requirements
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

## 📦 Requirements

| Component | Version | Notes |
|-----------|---------|-------|
| **DITA-OT** | 4.4+ | [Download](https://www.dita-ot.org/download) |
| **Java** | 17+ | [Adoptium OpenJDK](https://adoptium.net/) recommended |
| **Gradle** | 8.x+ | Wrapper included in project |

### Optional Tools
- **EPUBCheck** 5.3.0+ for validation ([Download](https://github.com/w3c/epubcheck/releases))
- **Calibre** for EPUB viewing and testing

---

## 🚀 Quick Start

### 1. Installation

```bash
# Clone the repository
git clone https://github.com/jyjeanne/dita2epub.git
cd dita2epub

# Build the project
./gradlew build

# Install plugin to DITA-OT
./gradlew installPlugin

# Integrate with DITA-OT
cd $DITA_HOME
bin/dita install
```

### 2. Verify Installation

```bash
# List installed plugins
dita --plugins | grep epub

# Expected output:
# io.github.jyjeanne.dita2epub@1.1.0
```

### 3. Generate Your First EPUB

```bash
dita --input=mybook.ditamap --format=epub3 --output=output
```

✅ **Done!** Your EPUB will be in `output/mybook.epub`

### Build Commands Reference

```bash
# Build and test
./gradlew build                  # Compile + unit tests
./gradlew test                   # Unit tests only (no DITA-OT needed)

# EPUB generation (downloads DITA-OT 4.4 on first run)
./gradlew buildSampleEpub        # Build + validate sample EPUB (English)
./gradlew buildCalibreGuide      # Build Calibre Guide EPUB (French)
./gradlew buildIndexingGuide     # Build Indexing Guide EPUB (with back-of-book index)
./gradlew buildAllEpubs          # Build all 3 test datasets

# Validation
./gradlew validateEpub           # EPUBCheck on sample
./gradlew validateCalibreEpub    # EPUBCheck on Calibre guide
./gradlew validateIndexingEpub   # EPUBCheck on Indexing guide
./gradlew validateAllEpubs       # EPUBCheck on all outputs

# Full CI pipeline
./gradlew ciCheck                # Compile, test, build EPUBs, EPUBCheck
```

---

## 💡 Usage

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
     --epub.toc.depth=4 \
     --epub.nav.depth=4 \
     --epub.accessibility=wcag-aa \
     --epub.validate=yes
```

---

## ⚙️ Configuration Parameters

### Core Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.version` | string | `3.3` | EPUB specification version (3.3, 3.0, 2.0.1) |
| `epub.accessibility` | enum | `wcag-aa` | Accessibility level (wcag-a, wcag-aa, wcag-aaa) |
| `epub.toc.depth` | integer | `5` | Maximum table of contents depth |
| `epub.nav.depth` | integer | `5` | Maximum navigation document depth |

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

### Font Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.embed.fonts` | path | `(none)` | Directory containing fonts to embed |
| `epub.obfuscate.fonts` | boolean | `no` | Enable font obfuscation (planned) |

### Directory Structure

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.topics.dir` | string | `content` | Directory for topic XHTML files |
| `epub.images.dir` | string | `images` | Directory for images |
| `epub.fonts.dir` | string | `fonts` | Directory for embedded fonts |
| `epub.css.dir` | string | `styles` | Directory for CSS files |

### Validation

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.validate` | boolean | `yes` | Run EPUBCheck validation (if available) |

**📘 Complete Reference**: See [SPECIFICATION.md](docs/SPECIFICATION.md) for all parameters

---

## 📁 Project Structure

```
dita2epub/
├── src/
│   ├── main/
│   │   ├── java/               # Java utilities (packaging, validation)
│   │   ├── xsl/                # XSLT 3.0 transformation modules
│   │   │   ├── map2epub3.xsl          # Main entry point
│   │   │   ├── epub3-params.xsl       # Parameter definitions
│   │   │   ├── epub3-common.xsl       # Common functions
│   │   │   ├── epub3-metadata.xsl     # Metadata extraction
│   │   │   ├── epub3-content.xsl      # Content generation
│   │   │   ├── epub3-impl.xsl         # OPF/navigation
│   │   │   └── epub3-index.xsl        # Back-of-book index generation
│   │   └── resources/
│   │       ├── css/            # Stylesheets
│   │       │   ├── epub-default.css   # Default styles
│   │       │   └── epub-fonts.css     # Font declarations
│   │       └── fonts/          # Font directory (empty template)
│   └── test/
│       ├── java/               # Test classes (41 tests)
│       └── resources/
│           ├── dita/           # English sample bookmap
│           ├── dita-calibre/   # French Calibre Guide
│           ├── dita-indexing/  # Indexing Guide (with back-of-book index)
│           └── epub/           # Reference EPUB for validation
├── plugin.xml                  # DITA-OT plugin descriptor
├── build-epub3.xml             # Ant build integration
├── build.gradle.kts            # Gradle build configuration
└── docs/                       # Documentation
    ├── ANATOMY_EPUB_THREE.md   # EPUB 3 file structure reference
    ├── CHANGELOG.md            # Version changelog
    ├── CONTRIBUTING.md         # Contribution guidelines
    ├── GITHUB_CHECKLIST.md     # GitHub procedures
    ├── PROJECT_STATUS.md       # Project status and metrics
    ├── QUICKSTART.md           # Quick start guide
    ├── RELEASE_NOTES.md        # Version history
    ├── SPECIFICATION.md        # Complete technical specification
    ├── TEST_COVERAGE.md        # Test documentation
    └── TEST_SUMMARY.md         # Executive test summary
```

---

## 🧪 Testing

### Test Suite Overview

- **41 test methods** across 6 test classes
- **100% unit test pass rate**
- **3 test datasets**: English sample, French Calibre Guide, Indexing Guide
- **0 EPUBCheck errors** on all 3 generated EPUBs

### Running Tests

```bash
# Run all tests
./gradlew test

# Run unit tests only (no DITA-OT required)
./gradlew test --tests EpubValidatorTest

# View test report
open build/reports/tests/test/index.html
```

### Test Coverage

| Feature | Tests | Status |
|---------|-------|--------|
| Cover Page Generation | 5 | Complete |
| Font Embedding | 6 | Complete |
| OPF Manifest | 8 | Complete |
| EPUB Structure | 10 | Complete |
| Validation | 8 | Complete (0 EPUBCheck errors) |
| Integration | 4 | Complete |

**📊 Detailed Report**: See [TEST_COVERAGE.md](docs/TEST_COVERAGE.md)

---

## 📚 Documentation Hub

### 🚀 Getting Started

| Document | Description | For |
|----------|-------------|-----|
| **[QUICKSTART.md](docs/QUICKSTART.md)** | 5-minute setup and first EPUB | New users |
| **[SPECIFICATION.md](docs/SPECIFICATION.md)** | Complete technical specification | All users |
| **[ANATOMY_EPUB_THREE.md](docs/ANATOMY_EPUB_THREE.md)** | EPUB 3 file structure and SSV reference | Developers |
| **[PROJECT_STATUS.md](docs/PROJECT_STATUS.md)** | Current status, roadmap, and metrics | Project overview |

### 📖 User Documentation

| Document | Description | Details |
|----------|-------------|---------|
| **[Font Embedding Guide](src/main/resources/fonts/README.md)** | Font setup and configuration | 200+ lines with examples |
| **[RELEASE_NOTES.md](docs/RELEASE_NOTES.md)** | Version history and changelog | v1.0.1 release details |

### 🧪 Testing & Quality

| Document | Description | Coverage |
|----------|-------------|----------|
| **[TEST_COVERAGE.md](docs/TEST_COVERAGE.md)** | Detailed test documentation | 41 tests across 6 classes |
| **[TEST_SUMMARY.md](docs/TEST_SUMMARY.md)** | Executive test summary | 100% unit test pass rate |

### 🔧 Development & CI/CD

| Document | Description | Content |
|----------|-------------|---------|
| **[CONTRIBUTING.md](docs/CONTRIBUTING.md)** | Contribution guidelines | 500+ lines with code examples |
| **[.github/README.md](.github/README.md)** | CI/CD documentation | Complete GitHub Actions guide |
| **[.github/ACTIONS_SETUP.md](.github/ACTIONS_SETUP.md)** | CI/CD setup summary | Workflow descriptions |

### 🔗 External Resources

- **[GitHub Repository](https://github.com/jyjeanne/dita2epub)** - Source code and releases
- **[GitHub Issues](https://github.com/jyjeanne/dita2epub/issues)** - Bug reports and feature requests
- **[GitHub Discussions](https://github.com/jyjeanne/dita2epub/discussions)** - Community discussions
- **[GitHub Actions](https://github.com/jyjeanne/dita2epub/actions)** - CI/CD workflow runs
- **[DITA-OT Documentation](https://www.dita-ot.org/)** - DITA Open Toolkit docs
- **[EPUB 3.3 Specification](https://www.w3.org/publishing/epub3/)** - W3C EPUB standard

### 📊 Quick Links

- [Installation Guide](#1-installation)
- [Configuration Parameters](#-configuration-parameters)
- [Test Reports](#-testing)
- [Project Structure](#-project-structure)

---

## 🎯 Use Cases

### Technical Documentation
```bash
dita --input=user-guide.ditamap \
     --format=epub3 \
     --epub.toc.depth=6 \
     --epub.accessibility=wcag-aa
```

### E-Books with Custom Branding
```bash
dita --input=novel.ditamap \
     --format=epub3 \
     --epub.cover.image=cover.jpg \
     --epub.embed.fonts=fonts/ \
     --epub.cover.page.style=full-page
```

### Training Materials
```bash
dita --input=training.ditamap \
     --format=epub3 \
     --epub.generate.cover.page=yes \
     --epub.accessibility=wcag-aaa
```

---

## 🔄 Current Status

### Completed Features (v1.1.0)
- EPUB 3.3 generation from DITA bookmaps — **0 EPUBCheck errors** on all 3 test EPUBs
- Full EPUB 3.3 Structural Semantics Vocabulary (SSV) compliance
- Back-of-book index generation from `<indexterm>` elements with precise anchor links
- Dynamic `epub:type` annotations (chapter, appendix, foreword, preface, glossary, index)
- DITA-OT 4.4 integration with dita-ot-gradle 2.8.5 build system
- Complete XHTML5 content generation with proper namespace handling
- OPF package document, NCX TOC, and EPUB3 navigation document
- Dublin Core metadata extraction from DITA maps/bookmaps
- WCAG AA accessibility metadata and ARIA landmarks
- Cover page generation with customizable styles (full-page, centered, custom)
- Title page with author, copyright, translator, and license info
- Font embedding (TTF, OTF, WOFF, WOFF2)
- Image copying and manifest generation
- EPUBCheck 5.3.0 validation integration
- Three test datasets: English sample, French Calibre Guide, Indexing Guide
- Comprehensive test suite (41 tests across 6 classes)

### Known Limitations
- Font obfuscation not yet implemented (copying works)
- Automatic font manifest generation (manual configuration available)

### Planned Features
- Font obfuscation (Adobe algorithm)
- DITA 2.0 full support
- Fixed Layout EPUB
- Additional language support (de, ja)
- Custom theme system

---

## 🤝 Contributing

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

## 📝 License

This project is licensed under the **Apache License 2.0** - see the [LICENSE](LICENSE) file for details.

```
Copyright 2025 J. Jeanne

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0
```

---

## 🙏 Acknowledgments

### Built With
- [DITA Open Toolkit 4.4](https://www.dita-ot.org/)
- [Saxon-HE 12.7](https://www.saxonica.com/html/documentation12/about/) (XSLT 3.0)
- [EPUBCheck 5.3.0](https://github.com/w3c/epubcheck)
- [Gradle 9.x](https://gradle.org/) with [dita-ot-gradle 2.8.5](https://github.com/jyjeanne/dita-ot-gradle)
- [JUnit 5](https://junit.org/junit5/) + [XMLUnit](https://github.com/xmlunit/xmlunit) + [AssertJ](https://assertj.github.io/doc/)

### Inspired By
- [DITA4Publishers](https://github.com/dita4publishers/dita4publishers) by Eliot Kimber
- DITA-OT community contributions
- [EPUB 3.3 Specification](https://www.w3.org/publishing/epub3/) by W3C

---

## 📞 Support & Contact

- **Issues**: [GitHub Issues](https://github.com/jyjeanne/dita2epub/issues)
- **Discussions**: [GitHub Discussions](https://github.com/jyjeanne/dita2epub/discussions)
- **Author**: J. Jeanne

---

## 🎖️ Project Status

![Version](https://img.shields.io/badge/version-1.1.0-blue)
![Build](https://img.shields.io/badge/build-passing-success)
![Coverage](https://img.shields.io/badge/coverage-70%25-green)
![Maintained](https://img.shields.io/badge/maintained-yes-brightgreen)

**Last Updated**: February 23, 2026
**Version**: 1.1.0
**Status**: ✅ Production Ready

---

<div align="center">

**[⬆ Back to Top](#dita2epub---modern-epub3-transformation-plugin)**

Made with ❤️ for the DITA community

</div>

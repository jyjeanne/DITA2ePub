# Dita2epub - Modern EPUB3 Transformation Plugin

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![DITA-OT](https://img.shields.io/badge/DITA--OT-4.3.5-green.svg)](https://www.dita-ot.org/)
[![EPUB](https://img.shields.io/badge/EPUB-3.3-purple.svg)](https://www.w3.org/publishing/epub3/)
[![Java](https://img.shields.io/badge/Java-17%2B-orange.svg)](https://adoptium.net/)
[![Tests](https://img.shields.io/badge/tests-44%20passing-success.svg)](#testing)

[![CI Build](https://github.com/jyjeanne/dita2epub/actions/workflows/ci.yml/badge.svg)](https://github.com/jyjeanne/dita2epub/actions/workflows/ci.yml)
[![Nightly Tests](https://github.com/jyjeanne/dita2epub/actions/workflows/nightly-tests.yml/badge.svg)](https://github.com/jyjeanne/dita2epub/actions/workflows/nightly-tests.yml)
[![Documentation](https://github.com/jyjeanne/dita2epub/actions/workflows/docs.yml/badge.svg)](https://github.com/jyjeanne/dita2epub/actions/workflows/docs.yml)

A professional-grade DITA-OT plugin for transforming DITA content into standards-compliant EPUB 3.3 publications with built-in accessibility, custom fonts, and cover page generation.

---

## 🌟 Key Features

### Core Capabilities
- ✅ **EPUB 3.3 Standard**: Full compliance with latest EPUB specification
- ✅ **DITA-OT 4.3.5 Integration**: Seamless plugin architecture
- ✅ **XHTML5 Output**: Modern, semantic HTML content
- ✅ **Accessibility Built-in**: WCAG 2.1 AA/AAA metadata and ARIA support
- ✅ **Navigation**: Automatic TOC and landmarks generation

### Advanced Features ⭐ NEW in v1.0.1
- 🎨 **Cover Page Generation**: Automatic HTML cover pages with customizable styles
- 🔤 **Font Embedding**: Embed custom fonts (TTF, OTF, WOFF, WOFF2)
- 🖼️ **Image Support**: Automatic image copying and manifest generation
- ✅ **EPUBCheck Integration**: Built-in validation support
- 🧪 **Comprehensive Testing**: 44 tests across 6 test classes

### Developer Experience
- 🏗️ **Gradle Build System**: Modern build configuration with Kotlin DSL
- 🔧 **Extensible Architecture**: XSLT 3.0 modular design
- 📚 **Complete Documentation**: Guides, examples, and API docs
- 🚀 **CI/CD Ready**: GitHub Actions workflow templates

---

## 📋 Table of Contents

- [Requirements](#requirements)
- [Quick Start](#quick-start)
- [Usage](#usage)
  - [Basic Transformation](#basic-transformation)
  - [Cover Page Generation](#cover-page-generation)
  - [Font Embedding](#font-embedding)
  - [Advanced Configuration](#advanced-configuration)
- [Configuration Parameters](#configuration-parameters)
- [Project Structure](#project-structure)
- [Testing](#testing)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [License](#license)

---

## 📦 Requirements

| Component | Version | Notes |
|-----------|---------|-------|
| **DITA-OT** | 4.3.5+ | [Download](https://www.dita-ot.org/download) |
| **Java** | 17+ | [Adoptium OpenJDK](https://adoptium.net/) recommended |
| **Gradle** | 8.x+ | Wrapper included in project |

### Optional Tools
- **EPUBCheck** 5.1.0+ for validation ([Download](https://github.com/w3c/epubcheck/releases))
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
# io.github.jyjeanne.dita2epub@1.0.1
```

### 3. Generate Your First EPUB

```bash
dita --input=mybook.ditamap --format=epub3 --output=output
```

✅ **Done!** Your EPUB will be in `output/mybook.epub`

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

### Cover Page Parameters ⭐ NEW

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `epub.cover.image` | path | `(none)` | Path to cover image file (JPG, PNG, SVG) |
| `epub.generate.cover.page` | boolean | `yes` | Generate HTML cover page from image |
| `epub.cover.page.style` | enum | `full-page` | Cover page style (full-page, centered, custom) |

### Font Parameters ⭐ NEW

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

**📘 Complete Reference**: See [SPECIFICATION.md](SPECIFICATION.md) for all parameters

---

## 📁 Project Structure

```
dita2epub/
├── src/
│   ├── main/
│   │   ├── java/               # Java validation code
│   │   ├── xsl/                # XSLT transformation modules
│   │   │   ├── map2epub3.xsl          # Main entry point
│   │   │   ├── epub3-params.xsl       # Parameter definitions
│   │   │   ├── epub3-common.xsl       # Common functions
│   │   │   ├── epub3-metadata.xsl     # Metadata extraction
│   │   │   ├── epub3-content.xsl      # Content generation
│   │   │   └── epub3-impl.xsl         # OPF/navigation
│   │   └── resources/
│   │       ├── css/            # Stylesheets
│   │       │   ├── epub-default.css   # Default styles
│   │       │   └── epub-fonts.css     # Font declarations
│   │       └── fonts/          # Font directory (empty template)
│   └── test/
│       ├── java/               # Test classes (44 tests)
│       └── resources/          # Test DITA content
├── lib/                        # EPUBCheck library
├── plugin.xml                  # DITA-OT plugin descriptor
├── build-epub3.xml             # Ant build integration
├── build.gradle.kts            # Gradle build configuration
└── docs/                       # Additional documentation
    ├── QUICKSTART.md           # Quick start guide
    ├── SPECIFICATION.md        # Complete parameter reference
    ├── RELEASE_NOTES.md        # Version history
    ├── TEST_COVERAGE.md        # Test documentation
    └── CONTRIBUTING.md         # Contribution guidelines
```

---

## 🧪 Testing

### Test Suite Overview

- **44 test methods** across 6 test classes
- **100% unit test pass rate**
- Comprehensive coverage of all features

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
| Cover Page Generation | 8 | ✅ Complete |
| Font Embedding | 7 | ✅ Complete |
| OPF Manifest | 8 | ✅ Complete |
| EPUB Structure | 11 | ✅ Complete |
| Validation | 8 | ✅ Complete |
| Integration | 3 | ✅ Complete |

**📊 Detailed Report**: See [TEST_COVERAGE.md](TEST_COVERAGE.md)

---

## 📚 Documentation

### User Guides
- **[QUICKSTART.md](QUICKSTART.md)** - 5-minute setup guide
- **[SPECIFICATION.md](SPECIFICATION.md)** - Complete parameter reference
- **[EXAMPLES.md](docs/EXAMPLES.md)** - Real-world examples and recipes

### Technical Documentation
- **[RELEASE_NOTES.md](RELEASE_NOTES.md)** - Version history and changelog
- **[TEST_COVERAGE.md](TEST_COVERAGE.md)** - Test suite documentation
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Contribution guidelines

### Resources
- **[Font Embedding Guide](src/main/resources/fonts/README.md)** - Font setup instructions
- **[EPUBCheck Setup](lib/README.md)** - Validation configuration

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

### ✅ Completed Features (v1.0.1)
- EPUB 3.3 generation from DITA bookmaps
- Complete XHTML content generation
- Navigation and metadata extraction
- WCAG AA accessibility metadata
- Cover page generation with styles
- Font embedding (TTF, OTF, WOFF, WOFF2)
- Image copying and manifest generation
- EPUBCheck integration
- Comprehensive test suite (44 tests)

### ⚠️ Known Limitations
- Font obfuscation not yet implemented (copying works)
- Automatic font manifest generation (manual configuration available)
- Limited to basic cover page styles (advanced customization planned)

### 🔮 Planned Features (v1.1+)
- Font obfuscation (Adobe algorithm)
- Multiple output format support (MOBI, KF8)
- Advanced cover page templates
- Automatic image optimization
- CSS preprocessor support
- Custom JavaScript inclusion

---

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for:
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
- [DITA Open Toolkit 4.3.5](https://www.dita-ot.org/)
- [Saxon-HE 12.7](https://www.saxonica.com/html/documentation12/about/)
- [Gradle 9.1](https://gradle.org/)
- [JUnit 5](https://junit.org/junit5/)

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

![Version](https://img.shields.io/badge/version-1.0.1-blue)
![Build](https://img.shields.io/badge/build-passing-success)
![Coverage](https://img.shields.io/badge/coverage-70%25-green)
![Maintained](https://img.shields.io/badge/maintained-yes-brightgreen)

**Last Updated**: October 29, 2025
**Version**: 1.0.1
**Status**: ✅ Production Ready

---

<div align="center">

**[⬆ Back to Top](#dita2epub---modern-epub3-transformation-plugin)**

Made with ❤️ for the DITA community

</div>

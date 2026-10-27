# Release Notes

## Version 1.0.1

**Release Date:** October 29, 2025

This release adds major new features for professional EPUB generation, including cover page generation, font embedding, and comprehensive testing.

### ⭐ New Features

#### Cover Page Generation
- **HTML Cover Pages**: Automatic generation of `cover.xhtml` from cover images
- **Multiple Styles**: Choose from `full-page`, `centered`, or `custom` styles
- **Smart Layout**: Full-page style fills viewport with `object-fit: contain`
- **Centered Option**: Flexbox-based centered layout with padding
- **OPF Integration**: Cover page automatically added to manifest and placed first in spine
- **XHTML5 Compliant**: Proper semantic markup and structure
- **Path Handling**: Cross-platform support for Windows and Unix paths

**Usage:**
```bash
dita --input=book.ditamap --format=epub3 --output=output \
     --epub.cover.image=images/cover.jpg \
     --epub.generate.cover.page=yes \
     --epub.cover.page.style=full-page
```

#### Font Embedding
- **Directory-Based**: Specify a fonts directory to embed all fonts
- **Multiple Formats**: Full support for TTF, OTF, WOFF, WOFF2
- **Automatic Copying**: Fonts copied to `epub.fonts.dir` in EPUB structure
- **Manifest Integration**: Font files automatically added to OPF manifest
- **CSS Templates**: Example `@font-face` declarations provided
- **Documentation**: Comprehensive font embedding guide in `src/main/resources/fonts/README.md`

**Usage:**
```bash
dita --input=book.ditamap --format=epub3 --output=output \
     --epub.embed.fonts=fonts/
```

#### Comprehensive Test Suite
- **44 Test Methods**: Across 6 test classes
- **100% Unit Test Pass Rate**: All unit tests passing
- **Integration Tests**: Conditional execution with DITA-OT availability
- **Feature Coverage**:
  - Cover page generation (8 tests)
  - Font embedding (7 tests)
  - OPF manifest validation (8 tests)
  - EPUB structure (11 tests)
  - Validation logic (8 tests)
  - Integration tests (3 tests)

**Test Classes:**
- `CoverPageGenerationTest`
- `FontEmbeddingTest`
- `OPFManifestTest`
- `EpubStructureTest`
- `EpubValidatorTest`
- `EpubGenerationIntegrationTest`

### 🔧 Improvements

#### Build System
- **Parameter Passing**: Fixed parameter propagation from Ant to XSLT
- **Default Values**: Added sensible defaults for all parameters
- **Conditional Targets**: Improved conditional execution for optional features
- **Path Normalization**: Fixed Windows backslash handling in paths

#### Documentation
- **README.md**: Complete rewrite with badges, table of contents, comprehensive examples
- **SPECIFICATION.md**: Added complete parameter reference for all v1.0.1 features
- **QUICKSTART.md**: Enhanced with v1.0.1 feature examples and workflows
- **TEST_COVERAGE.md**: Detailed test documentation with 350+ lines
- **TEST_SUMMARY.md**: Executive summary of test suite (450+ lines)

#### XSLT Improvements
- **Cover Page Template**: New `generate-cover-page` template with style support
- **Font Manifest**: New `add-font-items` template for font file manifest entries
- **Path Handling**: Cross-platform path separator normalization
- **Parameter Validation**: Better handling of optional parameters

### 🐛 Bug Fixes

- **Windows Path Separators**: Fixed cover image paths showing full Windows paths in OPF
- **Parameter Passing**: Fixed parameters not being passed from Ant to XSLT
- **Cover Image Manifest**: Fixed cover image `href` showing incorrect paths
- **Font Directory Detection**: Fixed conditional logic for font directory checking

### 📚 Documentation Updates

- **Parameter Reference**: Complete documentation for all 40+ parameters
- **Usage Examples**: Real-world examples for technical manuals, e-books, training materials
- **Troubleshooting Guide**: Common issues and solutions
- **Quick Reference Card**: Fast lookup for common commands
- **Font Embedding Guide**: Step-by-step font setup instructions

### ✅ Completed Items

Items completed in v1.0.1 that were planned for future versions:

- ~~Image and resource handling~~ ✅ **Completed**
- ~~Cover image processing~~ ✅ **Completed**
- ~~EPUBCheck validation~~ ✅ **Completed**
- ~~Font embedding~~ ✅ **Completed**
- ~~Cover page generation~~ ✅ **Completed**
- ~~Comprehensive testing~~ ✅ **Completed**

### ⚠️ Known Limitations

- **Font Obfuscation**: Not yet implemented (copying works without obfuscation)
- **Automatic Font Manifest**: Manual `@font-face` declarations required in CSS
- **Custom Cover Templates**: Limited to 3 built-in styles

### 📦 Generated EPUB Structure (v1.0.1)

```
book.epub
├── mimetype
├── META-INF/
│   └── container.xml
├── content/
│   ├── content.opf (package document)
│   ├── nav.xhtml (navigation)
│   ├── cover.xhtml (NEW - cover page)
│   └── *.xhtml (topic files)
├── images/
│   ├── cover.jpg (NEW - cover image)
│   └── *.{jpg,png,svg} (content images)
├── fonts/ (NEW)
│   └── *.{ttf,otf,woff,woff2}
└── styles/
    ├── epub-default.css
    └── epub-fonts.css (NEW - font declarations)
```

### 🎯 Migration from v1.0.0

**Breaking Changes:** None

**New Parameters:**
- `epub.generate.cover.page` (default: `yes`)
- `epub.cover.page.style` (default: `full-page`)
- `epub.embed.fonts` (no default)
- `epub.obfuscate.fonts` (default: `no`, not yet functional)

**Upgrade Steps:**
1. No changes required for existing transformations
2. Optionally add cover page generation
3. Optionally add font embedding
4. Update documentation references

---

## Version 1.0.0 (Initial Release)

**Release Date:** October 2025

Initial release of DITA2ePub - A modern EPUB3 transformation plugin for DITA-OT 4.3.5.

## Features

### Core Functionality
- ✅ **EPUB3 3.3 Generation**: Full EPUB3 package creation from DITA bookmaps
- ✅ **XHTML Content**: Clean XHTML5 content files generated from DITA topics
- ✅ **Navigation**: Complete TOC and landmarks navigation
- ✅ **Metadata**: Automatic extraction of metadata from DITA sources
- ✅ **Accessibility**: WCAG AA accessibility metadata included
- ✅ **CSS Styling**: Default stylesheet with customization support

### Technical Implementation
- ✅ **DITA-OT 4.3.5 Plugin**: Full integration with DITA-OT plugin system
- ✅ **XSLT 3.0**: Modern XSLT transformations using Saxon-HE
- ✅ **URI Resolution**: Proper plugin: URI scheme handling
- ✅ **Unique Filenames**: Smart filename generation from source DITA files
- ✅ **Gradle Integration**: Build automation with Kotlin DSL

### Generated EPUB Structure
```
sample-bookmap.epub
├── mimetype
├── META-INF/
│   └── container.xml
└── content/
    ├── content.opf (package document)
    ├── nav.xhtml (navigation)
    ├── *.xhtml (topic files)
    └── styles/
        └── epub-default.css
```

## Installation

### Prerequisites
- DITA-OT 4.3.5
- Java 17+
- Gradle 8.x (wrapper included)

### Quick Install
```bash
git clone https://github.com/jyjeanne/dita2epub.git
cd dita2epub
./gradlew installPlugin
cd $DITA_HOME
bin/dita install
```

## Usage

### Basic Transformation
```bash
dita --input=mybook.ditamap --format=epub3 --output=output
```

### With Parameters
```bash
dita --input=mybook.ditamap \
     --format=epub3 \
     --output=output \
     --epub.version=3.3 \
     --epub.accessibility=wcag-aa
```

### v1.0.0 Core Functionality
- ✅ **EPUB3 3.3 Generation**: Full EPUB3 package creation from DITA bookmaps
- ✅ **XHTML Content**: Clean XHTML5 content files generated from DITA topics
- ✅ **Navigation**: Complete TOC and landmarks navigation
- ✅ **Metadata**: Automatic extraction of metadata from DITA sources
- ✅ **Accessibility**: WCAG AA accessibility metadata included
- ✅ **CSS Styling**: Default stylesheet with customization support

### v1.0.0 Technical Implementation
- ✅ **DITA-OT 4.3.5 Plugin**: Full integration with DITA-OT plugin system
- ✅ **XSLT 3.0**: Modern XSLT transformations using Saxon-HE
- ✅ **URI Resolution**: Proper plugin: URI scheme handling
- ✅ **Unique Filenames**: Smart filename generation from source DITA files
- ✅ **Gradle Integration**: Build automation with Kotlin DSL

## Technical Details

### XSLT Modules
1. `map2epub3.xsl` - Main transformation entry point
2. `epub3-params.xsl` - Parameter definitions
3. `epub3-common.xsl` - Common functions and utilities
4. `epub3-metadata.xsl` - Metadata extraction
5. `epub3-content.xsl` - XHTML content generation
6. `epub3-impl.xsl` - OPF and navigation generation

### Key Fixes in This Release
- Fixed circular XSLT imports
- Implemented consistent filename generation
- Resolved duplicate topic processing
- Fixed XML namespace issues
- Added proper URI resolver configuration

## Roadmap

### Version 1.1 (Planned)
- **Font Obfuscation**: Adobe algorithm implementation for font DRM
- **Font Subsetting**: Reduce font file sizes by including only used glyphs
- **Advanced Cover Templates**: More customizable cover page layouts
- **Image Optimization**: Automatic image compression and format conversion
- **Performance Improvements**: Faster transformation for large documents
- **Additional Language Support**: More internationalization strings

### Version 1.2 (Future)
- **EPUB3 Fixed Layout**: Support for fixed-layout publications
- **Interactive Elements**: Enhanced multimedia and interactive content
- **Advanced CSS Grid Layouts**: Modern responsive designs
- **Dark Mode Support**: Built-in dark mode stylesheets
- **Multiple Output Formats**: MOBI, KF8, PDF support
- **Cloud Build Service**: Optional cloud-based transformation service

## Acknowledgments

Built with:
- DITA Open Toolkit 4.3.5
- Saxon-HE 12.7
- Gradle 9.1
- Java 17

Inspired by:
- DITA4Publishers by Eliot Kimber
- DITA-OT community
- EPUB specifications by W3C/IDPF

## License

Apache License 2.0

Copyright 2025 J. Jeanne

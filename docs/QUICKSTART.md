# Quick Start Guide

## Installation (5 minutes)

### Step 1: Clone the Repository
```bash
git clone https://github.com/jyjeanne/dita2epub.git
cd dita2epub
```

### Step 2: Install the Plugin to DITA-OT

#### Option A: Using Gradle (Recommended)
```bash
# Edit build.gradle.kts and set your DITA-OT path:
# ditaOt(file("C:\\dita-ot\\dita-ot-4.3.5"))  # Windows
# ditaOt(file("/usr/local/dita-ot-4.3.5"))    # Linux/Mac

./gradlew installPlugin
```

#### Option B: Manual Installation
```bash
# Copy plugin files to DITA-OT plugins directory
cp -r . $DITA_HOME/plugins/io.github.jyjeanne.dita2epub

# Integrate the plugin
cd $DITA_HOME
bin/dita install
```

### Step 3: Verify Installation
```bash
dita --plugins | grep epub
# Should show: io.github.jyjeanne.dita2epub@1.0.1
```

## First EPUB Generation (2 minutes)

### Using the Sample Content
```bash
# From the dita2epub directory
./gradlew dita

# EPUB will be created at: build/epub/sample-bookmap.epub
```

### Using Your Own DITA Content
```bash
dita --input=mybook.ditamap \
     --format=epub3 \
     --output=output
```

### With Custom Parameters
```bash
dita --input=mybook.ditamap \
     --format=epub3 \
     --output=output \
     --epub.version=3.3 \
     --epub.toc.depth=4 \
     --epub.accessibility=wcag-aa \
     --args.css=mystyles.css
```

## New in v1.0.1: Cover Pages & Fonts (2 minutes)

### Adding a Cover Page

Generate a professional HTML cover page automatically:

```bash
dita --input=mybook.ditamap \
     --format=epub3 \
     --output=output \
     --epub.cover.image=images/cover.jpg \
     --epub.generate.cover.page=yes \
     --epub.cover.page.style=full-page
```

**Cover Page Styles:**

**Full-page (default)** - Cover fills entire viewport:
```bash
--epub.cover.page.style=full-page
```

**Centered** - Cover centered with padding:
```bash
--epub.cover.page.style=centered
```

**Example with SVG cover:**
```bash
dita --input=mybook.ditamap \
     --format=epub3 \
     --output=output \
     --epub.cover.image=images/cover.svg \
     --epub.generate.cover.page=yes \
     --epub.cover.page.style=full-page
```

### Embedding Custom Fonts

Add your own fonts to the EPUB (supports TTF, OTF, WOFF, WOFF2):

**Step 1: Prepare fonts directory**
```bash
mkdir fonts
cp MyFont-Regular.woff2 fonts/
cp MyFont-Bold.woff2 fonts/
```

**Step 2: Create font CSS** (`fonts/fonts.css`):
```css
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

body {
  font-family: 'MyFont', sans-serif;
}
```

**Step 3: Generate EPUB with embedded fonts**
```bash
dita --input=mybook.ditamap \
     --format=epub3 \
     --output=output \
     --epub.embed.fonts=fonts/ \
     --args.css=fonts/fonts.css
```

**Quick Test** - Use included sample fonts:
```bash
# The plugin includes a fonts directory template
dita --input=mybook.ditamap \
     --format=epub3 \
     --output=output \
     --epub.embed.fonts=/path/to/your/fonts/
```

### Complete Example: Cover + Fonts + Accessibility

```bash
dita --input=mybook.ditamap \
     --format=epub3 \
     --output=output \
     \
     # Cover page (NEW)
     --epub.cover.image=images/cover.jpg \
     --epub.generate.cover.page=yes \
     --epub.cover.page.style=full-page \
     \
     # Font embedding (NEW)
     --epub.embed.fonts=fonts/ \
     \
     # Accessibility
     --epub.accessibility=wcag-aa \
     --epub.toc.depth=4 \
     \
     # Custom CSS
     --args.css=mystyles.css
```

## Testing Your EPUB

### View the Generated Files
```bash
# Extract EPUB to see contents
unzip output/yourbook.epub -d epub-contents/

# Check the structure
ls -R epub-contents/
```

### Validate (Optional)

The plugin includes integrated EPUBCheck validation that runs automatically after EPUB generation.

**To enable automatic validation:**
1. Download EPUBCheck from https://github.com/w3c/epubcheck/releases
2. Extract and copy `epubcheck.jar` to the `lib/` directory
3. Run your transformation - validation will happen automatically

**To disable validation:**
```bash
dita --input=mybook.ditamap --format=epub3 --output=output --epub.validate=no
```

**Manual validation:**
```bash
# If you prefer to validate separately
java -jar lib/epubcheck.jar output/yourbook.epub
```

### Open in E-Reader
- **Calibre**: File → Add books → Select your .epub file
- **Apple Books**: Drag and drop the .epub file
- **Adobe Digital Editions**: File → Add to Library

## Common Issues

### "DITA-OT not found"
**Solution**: Set DITA_HOME environment variable:
```bash
export DITA_HOME=/path/to/dita-ot-4.3.5  # Linux/Mac
set DITA_HOME=C:\dita-ot\dita-ot-4.3.5   # Windows
```

### "Plugin not found"
**Solution**: Run `dita install` to integrate the plugin:
```bash
cd $DITA_HOME
bin/dita install
```

### "Java version error"
**Solution**: Ensure Java 17+ is installed:
```bash
java -version  # Should show 17 or higher
```

## Next Steps

- Read the [full README](README.md) for all features
- Check [SPECIFICATION.md](SPECIFICATION.md) for all parameters
- See [RELEASE_NOTES.md](RELEASE_NOTES.md) for what's new
- Visit the [issues page](https://github.com/jyjeanne/dita2epub/issues) for help

## Getting Help

- **Issues**: https://github.com/jyjeanne/dita2epub/issues
- **Discussions**: https://github.com/jyjeanne/dita2epub/discussions
- **Documentation**: See the `docs/` folder

## Example: Complete Workflow

### Basic Workflow (Traditional)
```bash
# 1. Clone and install
git clone https://github.com/jyjeanne/dita2epub.git
cd dita2epub
./gradlew installPlugin
cd $DITA_HOME
bin/dita install

# 2. Test with sample
cd -  # Return to dita2epub directory
./gradlew dita
ls -lh build/epub/sample-bookmap.epub

# 3. Use with your content
dita --input=/path/to/your/book.ditamap \
     --format=epub3 \
     --output=/path/to/output \
     --epub.accessibility=wcag-aa

# 4. Open the result
open /path/to/output/book.epub  # Mac
xdg-open /path/to/output/book.epub  # Linux
start /path/to/output/book.epub  # Windows
```

### Advanced Workflow (v1.0.1 Features)
```bash
# 1. Prepare your assets
mkdir -p myproject/images
mkdir -p myproject/fonts

cp mycover.jpg myproject/images/cover.jpg
cp MyFont-*.woff2 myproject/fonts/

# 2. Create font CSS
cat > myproject/fonts.css << 'EOF'
@font-face {
  font-family: 'MyFont';
  src: url('../fonts/MyFont-Regular.woff2') format('woff2');
  font-weight: 400;
  font-style: normal;
}
body { font-family: 'MyFont', sans-serif; }
EOF

# 3. Generate EPUB with all v1.0.1 features
dita \
  --input=myproject/book.ditamap \
  --format=epub3 \
  --output=myproject/output \
  \
  # Cover page generation
  --epub.cover.image=myproject/images/cover.jpg \
  --epub.generate.cover.page=yes \
  --epub.cover.page.style=full-page \
  \
  # Font embedding
  --epub.embed.fonts=myproject/fonts/ \
  \
  # Styling
  --args.css=myproject/fonts.css \
  \
  # Accessibility
  --epub.accessibility=wcag-aa \
  --epub.toc.depth=4 \
  \
  # Metadata
  --epub.publisher="My Publisher" \
  --epub.rights="Copyright 2025"

# 4. Validate and view
java -jar lib/epubcheck.jar myproject/output/book.epub
open myproject/output/book.epub
```

### Real-World Example: Technical Manual

```bash
# Create a professional technical manual with cover and fonts

# Step 1: Set up project structure
mkdir -p tech-manual/{images,fonts,styles}

# Step 2: Add assets
# - Place cover.png in tech-manual/images/
# - Place font files in tech-manual/fonts/
# - Place custom.css in tech-manual/styles/

# Step 3: Generate with all features
dita \
  --input=tech-manual/manual.ditamap \
  --format=epub3 \
  --output=tech-manual/output \
  --epub.version=3.3 \
  --epub.cover.image=tech-manual/images/cover.png \
  --epub.generate.cover.page=yes \
  --epub.cover.page.style=full-page \
  --epub.embed.fonts=tech-manual/fonts/ \
  --epub.accessibility=wcag-aa \
  --epub.toc.depth=5 \
  --epub.publisher="Tech Documentation Team" \
  --args.css=tech-manual/styles/custom.css

# Step 4: Test on multiple readers
# - Calibre (desktop)
# - Apple Books (iOS/macOS)
# - Google Play Books (Android)
# - Adobe Digital Editions (all platforms)
```

That's it! You now have a working EPUB3 generation system with professional cover pages and custom fonts. 🎉

## Quick Reference Card

### Minimal EPUB
```bash
dita --input=book.ditamap --format=epub3 --output=out
```

### With Cover Page (v1.0.1)
```bash
dita --input=book.ditamap --format=epub3 --output=out \
     --epub.cover.image=cover.jpg \
     --epub.generate.cover.page=yes
```

### With Fonts (v1.0.1)
```bash
dita --input=book.ditamap --format=epub3 --output=out \
     --epub.embed.fonts=fonts/
```

### Professional EPUB (All Features)
```bash
dita --input=book.ditamap --format=epub3 --output=out \
     --epub.cover.image=cover.jpg \
     --epub.generate.cover.page=yes \
     --epub.embed.fonts=fonts/ \
     --epub.accessibility=wcag-aa \
     --args.css=custom.css
```

## What's Next?

Now that you have the basics down, explore these advanced topics:

1. **[SPECIFICATION.md](SPECIFICATION.md)** - Complete parameter reference for all 40+ parameters
2. **[README.md](README.md)** - Full feature documentation and use cases
3. **[TEST_COVERAGE.md](TEST_COVERAGE.md)** - Testing and quality assurance
4. **[Font Embedding Guide](src/main/resources/fonts/README.md)** - Detailed font setup instructions
5. **[RELEASE_NOTES.md](RELEASE_NOTES.md)** - Version history and breaking changes

# Embedded Fonts

This directory is for storing font files that you want to embed in your EPUB publications.

## Supported Font Formats

- **WOFF2** (.woff2) - Recommended, best compression
- **WOFF** (.woff) - Good compression, wide support
- **TrueType** (.ttf) - Universal support
- **OpenType** (.otf) - Advanced typography features

## How to Embed Fonts

### Step 1: Add Font Files

Place your font files in this directory or a custom directory:

```
src/main/resources/fonts/
├── MyFont-Regular.woff2
├── MyFont-Bold.woff2
├── MyFont-Italic.woff2
└── MyFont-BoldItalic.woff2
```

### Step 2: Configure Font Embedding

When running the DITA transformation, specify the fonts directory:

```bash
dita --input=mybook.ditamap \
     --format=epub3 \
     --output=output \
     --epub.embed.fonts=src/main/resources/fonts
```

Or in your build.gradle.kts:

```kotlin
dita {
    properties {
        "epub.embed.fonts" to file("src/main/resources/fonts").absolutePath
    }
}
```

### Step 3: Define @font-face Rules

Edit `src/main/resources/css/epub-fonts.css` to add @font-face declarations:

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
```

### Step 4: Use Your Font

Update `epub-default.css` to use your embedded font:

```css
html {
  font-family: 'MyFont', -apple-system, BlinkMacSystemFont, sans-serif;
}
```

## Font Obfuscation

Some font licenses require obfuscation when embedding in EPUBs. Enable obfuscation:

```bash
dita --input=mybook.ditamap \
     --format=epub3 \
     --epub.embed.fonts=fonts \
     --epub.obfuscate.fonts=yes
```

Note: Font obfuscation is currently planned for a future release.

## Font Licensing

**Important:** Ensure you have proper licensing for embedding fonts in EPUBs.

### Free/Open Source Fonts

Good sources for freely licensed fonts:
- **Google Fonts**: https://fonts.google.com/
- **Adobe Fonts**: https://fonts.adobe.com/ (check license)
- **Font Squirrel**: https://www.fontsquirrel.com/fonts/list/find_fonts?filter%5Blicense%5D%5B0%5D=app

Popular open source fonts:
- Open Sans
- Roboto
- Noto Sans/Serif
- Source Sans Pro
- Lato
- Merriweather

### Converting Fonts

To convert TTF/OTF to WOFF/WOFF2:

**Online tools:**
- https://www.fontsquirrel.com/tools/webfont-generator
- https://cloudconvert.com/ttf-to-woff2

**Command line:**
```bash
# Install woff2 tools
# Ubuntu/Debian: sudo apt-get install woff2
# macOS: brew install woff2

# Convert to WOFF2
woff2_compress MyFont.ttf

# For WOFF, use FontForge or online tools
```

## Best Practices

1. **Use WOFF2 format** for smallest file size
2. **Subset fonts** to include only needed characters
3. **Limit font weights** - typically Regular and Bold are sufficient
4. **Test on multiple readers** - not all e-readers support all formats
5. **Provide fallback fonts** in your CSS font-family stack
6. **Consider file size** - each font adds to EPUB size

## Troubleshooting

### Fonts not displaying
- Check @font-face declarations in CSS
- Verify font paths are correct (relative to CSS file)
- Ensure fonts are in the OPF manifest (check content.opf)
- Test on multiple e-readers (support varies)

### File size too large
- Use WOFF2 format
- Subset fonts to needed characters
- Use fewer font weights
- Consider system fonts instead

## Examples

See the test resources for examples:
- `src/test/resources/fonts/` - Example font files (if available)
- `src/test/resources/css/` - Example font CSS

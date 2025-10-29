# EPUBCheck Library

This directory should contain the EPUBCheck JAR file for EPUB validation.

## Installation

1. Download EPUBCheck from the official W3C repository:
   https://github.com/w3c/epubcheck/releases

2. Download the latest version (e.g., `epubcheck-5.1.0.zip`)

3. Extract the ZIP file and copy `epubcheck.jar` to this `lib/` directory

4. The file should be located at: `lib/epubcheck.jar`

## Usage

Once installed, EPUBCheck validation will automatically run after EPUB generation if:
- The `epub.validate` parameter is set to `yes` (default)
- The `epubcheck.jar` file exists in this directory

To disable validation, set `--epub.validate=no` when running the DITA transformation.

## Example

```bash
# With validation (requires epubcheck.jar)
dita --input=mybook.ditamap --format=epub3 --output=output

# Without validation
dita --input=mybook.ditamap --format=epub3 --output=output --epub.validate=no
```

## Version Compatibility

This plugin has been tested with EPUBCheck 5.1.0 but should work with version 4.x and later.

## Alternative Validation

If you prefer not to use automated validation, you can validate your EPUB manually:

```bash
java -jar epubcheck.jar path/to/your/output.epub
```

## More Information

- EPUBCheck GitHub: https://github.com/w3c/epubcheck
- EPUB Specifications: https://www.w3.org/publishing/epub3/

# Contributing to DITA2ePub

Thank you for your interest in contributing to DITA2ePub! This document provides guidelines for contributing to the project.

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for all contributors.

## How to Contribute

### Reporting Issues

- Use the GitHub issue tracker to report bugs
- Check if the issue already exists before creating a new one
- Provide detailed information:
  - DITA-OT version
  - Java version
  - Operating system
  - Steps to reproduce
  - Expected vs actual behavior
  - Error messages or logs

### Suggesting Features

- Use GitHub issues with the "enhancement" label
- Describe the use case and benefit
- Provide examples if possible

### Pull Requests

1. **Fork the repository** and create a new branch from `develop`:
   ```bash
   git checkout -b feature/my-new-feature develop
   ```

2. **Make your changes** following the code style guidelines

3. **Write tests** for new functionality

4. **Update documentation** as needed

5. **Ensure all tests pass**:
   ```bash
   ./gradlew test
   ```

6. **Commit your changes** with clear commit messages:
   ```bash
   git commit -m "Add feature: description of feature"
   ```

7. **Push to your fork** and create a pull request to the `develop` branch

## Development Setup

### Prerequisites

- **Java**: 17 or later (LTS recommended)
- **Gradle**: 8.x (wrapper included in project)
- **DITA-OT**: 4.3.5 or later ([Download](https://www.dita-ot.org/download))
- **Git**: 2.x or later
- **Optional**: EPUBCheck 5.1.0+ for validation testing

### Local Setup

```bash
# 1. Clone the repository
git clone https://github.com/jyjeanne/dita2epub.git
cd dita2epub

# 2. Set DITA_HOME environment variable
export DITA_HOME=/path/to/dita-ot-4.3.5   # Linux/Mac
set DITA_HOME=C:\dita-ot\dita-ot-4.3.5    # Windows

# 3. Build the project
./gradlew build

# 4. Run unit tests (no DITA-OT required)
./gradlew test --tests EpubValidatorTest
./gradlew test --tests FontEmbeddingTest.testFontCSSTemplateExists

# 5. Install plugin for integration testing
./gradlew installPlugin
cd $DITA_HOME
bin/dita install

# 6. Run integration tests (requires DITA-OT)
cd -  # Return to dita2epub directory
./gradlew test

# 7. Test with sample content
dita --input=src/test/resources/dita/sample-bookmap.ditamap \
     --format=epub3 \
     --output=build/test-output
```

### Project Structure

Understanding the codebase structure:

```
dita2epub/
├── src/main/
│   ├── java/                # Java extensions (EPUBCheck, validation)
│   ├── xsl/                 # XSLT transformation modules
│   │   ├── map2epub3.xsl           # Main entry point
│   │   ├── epub3-params.xsl        # Parameter definitions
│   │   ├── epub3-common.xsl        # Utility functions
│   │   ├── epub3-metadata.xsl      # Metadata extraction
│   │   ├── epub3-content.xsl       # Content transformation
│   │   └── epub3-impl.xsl          # OPF/navigation generation
│   └── resources/
│       ├── css/             # Default stylesheets
│       └── fonts/           # Font directory template
├── src/test/
│   ├── java/                # Test classes (44 tests)
│   └── resources/
│       └── dita/            # Test DITA content
├── plugin.xml               # DITA-OT plugin descriptor
└── build-epub3.xml          # Ant build integration
```

## Code Style Guidelines

### Java

- Follow standard Java conventions
- Use meaningful variable and method names
- Add Javadoc comments for public APIs
- Keep methods focused and short

### XSLT

- Use XSLT 3.0 features appropriately
- Add XML comments to explain complex logic
- Use meaningful template names and modes
- Follow consistent indentation (2 spaces)

### Kotlin (Gradle scripts)

- Follow Kotlin coding conventions
- Use descriptive names for tasks and properties

## Testing

### Test Requirements

- **Write unit tests** for all new functionality
- **Write integration tests** for XSLT transformations (when applicable)
- **Ensure tests are deterministic** and independent
- **Use meaningful test names** that describe what is being tested
- **Follow existing patterns** in test classes

### Test Structure (v1.0.1)

The project has **44 test methods** across **6 test classes**:

1. **EpubValidatorTest** (8 tests) - Validation logic, no DITA-OT required
2. **FontEmbeddingTest** (7 tests) - Font embedding functionality
   - Unit tests: `testFontCSSTemplateExists`, `testFontDocumentationExists`
   - Integration tests: Require DITA-OT
3. **CoverPageGenerationTest** (8 tests) - Cover page generation
4. **OPFManifestTest** (8 tests) - OPF manifest validation
5. **EpubStructureTest** (11 tests) - EPUB file structure
6. **EpubGenerationIntegrationTest** (3 tests) - End-to-end generation

### Running Tests

```bash
# Run all tests
./gradlew test

# Run unit tests only (no DITA-OT required)
./gradlew test --tests EpubValidatorTest
./gradlew test --tests FontEmbeddingTest.testFontCSSTemplateExists

# Run specific test class
./gradlew test --tests CoverPageGenerationTest
./gradlew test --tests FontEmbeddingTest

# Run specific test method
./gradlew test --tests "OPFManifestTest.testOPFStructure"

# Run with detailed output
./gradlew test --info

# View test report
# Open: build/reports/tests/test/index.html
```

### Writing Tests

**Example: Unit Test**
```java
@Test
void testCoverPageStyleParameter() {
    // Arrange
    String style = "full-page";

    // Act
    CoverPageGenerator generator = new CoverPageGenerator(style);

    // Assert
    assertEquals("full-page", generator.getStyle());
}
```

**Example: Integration Test**
```java
@Test
@EnabledIf("isDitaOtAvailable")
void testEPUBGenerationWithCoverPage(@TempDir Path tempDir) throws Exception {
    // Generate EPUB with cover page
    File epubFile = generateEpubWithCover(tempDir, "full-page");

    // Verify cover page exists
    try (ZipFile zipFile = new ZipFile(epubFile)) {
        ZipEntry coverEntry = zipFile.getEntry("content/cover.xhtml");
        assertNotNull(coverEntry, "Cover page should exist");
    }
}
```

### Test Coverage

See [TEST_COVERAGE.md](TEST_COVERAGE.md) for detailed coverage information.

## Documentation

### Documentation Requirements

- **README.md**: Update for user-facing changes and new features
- **SPECIFICATION.md**: Update for new parameters and technical changes
- **QUICKSTART.md**: Add examples for new features
- **RELEASE_NOTES.md**: Document all changes in current version section
- **Code Comments**: Add for complex logic in XSLT and Java
- **plugin.xml**: Update parameter documentation for new/changed parameters
- **Test Documentation**: Update TEST_COVERAGE.md for new test classes

### Documentation Structure

- **README.md** - User-focused documentation with examples
- **SPECIFICATION.md** - Complete technical reference (2000+ lines)
- **QUICKSTART.md** - 5-minute setup guide with quick examples
- **RELEASE_NOTES.md** - Version-based changelog
- **CONTRIBUTING.md** - This file, contribution guidelines
- **TEST_COVERAGE.md** - Test suite documentation
- **TEST_SUMMARY.md** - Executive test summary

## Common Contribution Scenarios

### Adding a New Parameter

**Example: Adding `epub.custom.layout` parameter**

1. **Define in plugin.xml:**
```xml
<param name="epub.custom.layout"
       desc="Custom layout style for content pages"
       type="enum">
  <val>standard</val>
  <val>wide</val>
  <val default="true">responsive</val>
</param>
```

2. **Add to epub3-params.xsl:**
```xsl
<xsl:param name="epub.custom.layout" as="xs:string" select="'responsive'"/>
```

3. **Add to build-epub3.xml (Ant integration):**
```xml
<!-- In epub3.init target -->
<property name="epub.custom.layout" value="responsive"/>

<!-- In epub3.compile target -->
<param name="epub.custom.layout" expression="${epub.custom.layout}"/>
```

4. **Use in XSLT:**
```xsl
<xsl:template name="generate-layout">
  <xsl:choose>
    <xsl:when test="$epub.custom.layout = 'wide'">
      <!-- Wide layout logic -->
    </xsl:when>
    <xsl:when test="$epub.custom.layout = 'responsive'">
      <!-- Responsive layout logic -->
    </xsl:when>
  </xsl:choose>
</xsl:template>
```

5. **Write tests:**
```java
@Test
@EnabledIf("isDitaOtAvailable")
void testCustomLayoutParameter(@TempDir Path tempDir) {
    File epubFile = generateEpub(tempDir, "epub.custom.layout", "wide");
    // Verify layout applied correctly
}
```

6. **Document in SPECIFICATION.md:**
```markdown
#### epub.custom.layout
**Type:** `string` (enum)
**Default:** `responsive`
**Values:** `standard`, `wide`, `responsive`
**Since:** v1.1.0

Custom layout style for content pages.
```

### Adding a New XSLT Feature

**Example: Adding table of figures generation**

1. **Create new template in epub3-impl.xsl:**
```xsl
<xsl:template name="generate-lof">
  <xsl:param name="map" as="element()"/>

  <!-- Generate list of figures -->
  <xsl:result-document href="{concat($epub.topics.dir, '/lof.xhtml')}">
    <html xmlns="http://www.w3.org/1999/xhtml">
      <head><title>List of Figures</title></head>
      <body>
        <nav epub:type="lof">
          <h1>List of Figures</h1>
          <!-- TOC logic here -->
        </nav>
      </body>
    </html>
  </xsl:result-document>
</xsl:template>
```

2. **Call from map2epub3.xsl:**
```xsl
<xsl:if test="epub:is-true($epub.generate.lof)">
  <xsl:call-template name="generate-lof">
    <xsl:with-param name="map" select="$map"/>
  </xsl:call-template>
</xsl:if>
```

3. **Add to OPF manifest:**
```xsl
<xsl:if test="epub:is-true($epub.generate.lof)">
  <item id="lof" href="{concat($epub.topics.dir, '/lof.xhtml')}"
        media-type="application/xhtml+xml" properties="nav"/>
</xsl:if>
```

4. **Write tests:**
```java
@Test
@EnabledIf("isDitaOtAvailable")
void testListOfFiguresGeneration(@TempDir Path tempDir) {
    File epubFile = generateEpub(tempDir, "epub.generate.lof", "yes");

    try (ZipFile zipFile = new ZipFile(epubFile)) {
        ZipEntry lofEntry = zipFile.getEntry("content/lof.xhtml");
        assertNotNull(lofEntry, "List of figures should exist");
    }
}
```

### Fixing a Bug

**Example: Fixing incorrect image path handling**

1. **Create issue** with reproduction steps

2. **Write failing test first:**
```java
@Test
void testImagePathNormalization() {
    String windowsPath = "images\\cover.jpg";
    String normalized = PathUtils.normalize(windowsPath);
    assertEquals("images/cover.jpg", normalized);
}
```

3. **Fix the code:**
```xsl
<xsl:variable name="normalized-path"
              select="replace($image-path, '\\', '/')"/>
```

4. **Verify test passes**

5. **Add to RELEASE_NOTES.md:**
```markdown
### Bug Fixes
- **Image Path Handling**: Fixed Windows backslash normalization
```

6. **Create pull request** with clear description

### Adding Documentation

**Example: Adding usage example**

1. **Add to appropriate doc file** (README.md, QUICKSTART.md, etc.)

2. **Test the example** to ensure it works

3. **Use real-world scenarios** that users will encounter

4. **Include expected output** when helpful

### Performance Optimization

**Guidelines:**
- Profile before optimizing
- Document performance improvements with benchmarks
- Don't sacrifice readability for minor gains
- Test with large documents (100+ topics)
- Consider memory usage for large transformations

## Commit Messages

Follow this format:

```
<type>: <subject>

<body>

<footer>
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

Example:
```
feat: Add dark mode CSS support

- Add dark-mode.css stylesheet
- Update parameter documentation
- Add tests for CSS generation

Closes #123
```

## Branch Strategy

- `main`: Stable releases
- `develop`: Development branch
- `feature/*`: Feature branches
- `bugfix/*`: Bug fix branches
- `hotfix/*`: Urgent fixes for main

## Release Process

1. Update version in `build.gradle.kts`
2. Update CHANGELOG.md
3. Create release branch from `develop`
4. Test thoroughly
5. Merge to `main` and tag release
6. Merge back to `develop`

## Continuous Integration

The project uses GitHub Actions for automated testing and builds:

### CI Workflows

1. **CI - Build and Test** (`ci.yml`)
   - Runs on every push and pull request
   - Tests on Ubuntu, Windows, macOS
   - Tests with Java 17 and 21
   - Separates unit tests (fast) from integration tests (requires DITA-OT)

2. **Nightly Tests** (`nightly-tests.yml`)
   - Comprehensive testing daily at 2 AM UTC
   - Tests all platforms and Java versions
   - Generates coverage reports

3. **Release** (`release.yml`)
   - Triggered by version tags (e.g., `v1.0.1`)
   - Validates, builds, and creates GitHub releases
   - Generates plugin ZIP with checksums

4. **Documentation** (`docs.yml`)
   - Validates markdown links
   - Checks spelling
   - Verifies documentation structure

### CI Expectations

- **All tests must pass** before merge
- **Unit tests** should complete in < 5 minutes
- **Integration tests** should complete in < 20 minutes
- **Code quality checks** must pass
- **Documentation** must validate successfully

### Viewing CI Results

1. Go to the Actions tab on GitHub
2. Click on the workflow run
3. View job details and test reports
4. Download artifacts for detailed analysis

See [.github/ACTIONS_SETUP.md](../.github/ACTIONS_SETUP.md) for complete CI/CD documentation.

---

## Questions?

If you have questions:
- Open a GitHub discussion
- Check existing issues and documentation
- Review [.github/ACTIONS_SETUP.md](../.github/ACTIONS_SETUP.md) for CI/CD help
- Contact the maintainers

## License

By contributing, you agree that your contributions will be licensed under the Apache License 2.0.

Thank you for contributing to DITA2ePub!

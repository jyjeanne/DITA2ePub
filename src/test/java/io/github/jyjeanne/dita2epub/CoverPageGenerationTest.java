package io.github.jyjeanne.dita2epub;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.junit.jupiter.api.condition.EnabledIf;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.URI;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Tests for cover page generation functionality.
 * Tests various cover page styles and configurations.
 *
 * @author J. Jeanne
 * @version 1.0.1
 */
class CoverPageGenerationTest {

    static boolean isDitaOtAvailable() {
        return EpubGenerationIntegrationTest.isDitaOtAvailable();
    }

    @Test
    @EnabledIf("isDitaOtAvailable")
    void testCoverPageGenerationWithDefaultStyle(@TempDir Path tempDir) throws IOException, InterruptedException {
        File outputDir = generateEpubWithCoverPage(tempDir, "full-page");

        // Verify EPUB was created
        File epubFile = findEpubFile(outputDir);
        assertNotNull(epubFile, "EPUB file should be generated");

        // Verify cover page exists in EPUB
        try (ZipFile zipFile = new ZipFile(epubFile)) {
            ZipEntry coverEntry = zipFile.getEntry("content/cover.xhtml");
            assertNotNull(coverEntry, "Cover page (cover.xhtml) should exist in EPUB");

            // Read and verify cover page content
            String coverContent = new String(zipFile.getInputStream(coverEntry).readAllBytes());
            assertTrue(coverContent.contains("cover"), "Cover page should have cover class");
            assertTrue(coverContent.contains("cover-image"), "Cover page should reference cover image");
            assertFullPageCoverStyle(zipFile, coverContent);
        }
    }

    @ParameterizedTest
    @ValueSource(strings = {"full-page", "centered"})
    @EnabledIf("isDitaOtAvailable")
    void testCoverPageGenerationWithDifferentStyles(String style, @TempDir Path tempDir)
            throws IOException, InterruptedException {
        File outputDir = generateEpubWithCoverPage(tempDir, style);

        File epubFile = findEpubFile(outputDir);
        assertNotNull(epubFile, "EPUB file should be generated for style: " + style);

        try (ZipFile zipFile = new ZipFile(epubFile)) {
            ZipEntry coverEntry = zipFile.getEntry("content/cover.xhtml");
            assertNotNull(coverEntry, "Cover page should exist for style: " + style);

            String coverContent = new String(zipFile.getInputStream(coverEntry).readAllBytes());

            if ("full-page".equals(style)) {
                assertFullPageCoverStyle(zipFile, coverContent);
            } else if ("centered".equals(style)) {
                assertTrue(coverContent.contains("class=\"cover-page-centered\""),
                    "Centered style should set the cover-page-centered class");
                String rule = extractCssRule(readLinkedStylesheet(zipFile, coverContent),
                    ".cover-page-centered body");
                assertTrue(rule.contains("display: flex"), "Centered style should use flex layout");
            }
        }
    }

    @Test
    @EnabledIf("isDitaOtAvailable")
    void testCoverPageInManifest(@TempDir Path tempDir) throws IOException, InterruptedException {
        File outputDir = generateEpubWithCoverPage(tempDir, "full-page");
        File epubFile = findEpubFile(outputDir);

        try (ZipFile zipFile = new ZipFile(epubFile)) {
            // Check content.opf
            ZipEntry opfEntry = zipFile.getEntry("content/content.opf");
            assertNotNull(opfEntry, "content.opf should exist");

            String opfContent = new String(zipFile.getInputStream(opfEntry).readAllBytes());

            // Verify cover page is in manifest
            assertTrue(opfContent.contains("id=\"cover\""),
                "Cover page should be in manifest with id='cover'");
            assertTrue(opfContent.contains("href=\"cover.xhtml\""),
                "Cover page manifest entry should reference cover.xhtml");

            // Verify cover page is in spine
            assertTrue(opfContent.contains("<itemref idref=\"cover\""),
                "Cover page should be in spine");

            // Verify cover image is in manifest with cover-image property
            assertTrue(opfContent.contains("id=\"cover-image\""),
                "Cover image should be in manifest");
            assertTrue(opfContent.contains("properties=\"cover-image\""),
                "Cover image should have cover-image property");
        }
    }

    @Test
    @EnabledIf("isDitaOtAvailable")
    void testCoverPageIsFirstInSpine(@TempDir Path tempDir) throws IOException, InterruptedException {
        File outputDir = generateEpubWithCoverPage(tempDir, "full-page");
        File epubFile = findEpubFile(outputDir);

        try (ZipFile zipFile = new ZipFile(epubFile)) {
            ZipEntry opfEntry = zipFile.getEntry("content/content.opf");
            String opfContent = new String(zipFile.getInputStream(opfEntry).readAllBytes());

            // Extract spine section (the spine element carries attributes such as page-progression-direction)
            int spineStart = opfContent.indexOf("<spine");
            int spineEnd = opfContent.indexOf("</spine>");
            assertTrue(spineStart > 0 && spineEnd > spineStart, "Spine section should exist");

            String spineContent = opfContent.substring(spineStart, spineEnd);

            // Find first itemref
            int firstItemrefStart = spineContent.indexOf("<itemref");
            int firstItemrefEnd = spineContent.indexOf("/>", firstItemrefStart);
            String firstItemref = spineContent.substring(firstItemrefStart, firstItemrefEnd + 2);

            assertTrue(firstItemref.contains("idref=\"cover\""),
                "First itemref in spine should be the cover page");
        }
    }

    @Test
    @EnabledIf("isDitaOtAvailable")
    void testNoCoverPageWhenDisabled(@TempDir Path tempDir) throws IOException, InterruptedException {
        File outputDir = generateEpubWithCoverPage(tempDir, "full-page", false);
        File epubFile = findEpubFile(outputDir);

        try (ZipFile zipFile = new ZipFile(epubFile)) {
            ZipEntry coverEntry = zipFile.getEntry("content/cover.xhtml");
            assertNull(coverEntry, "Cover page should not exist when generation is disabled");
        }
    }

    @Test
    @EnabledIf("isDitaOtAvailable")
    void testCoverImageCopiedToEpub(@TempDir Path tempDir) throws IOException, InterruptedException {
        File outputDir = generateEpubWithCoverPage(tempDir, "full-page");
        File epubFile = findEpubFile(outputDir);

        try (ZipFile zipFile = new ZipFile(epubFile)) {
            ZipEntry coverImageEntry = zipFile.getEntry("images/cover.svg");
            assertNotNull(coverImageEntry, "Cover image should be copied to images directory");

            // Verify it's not empty
            assertTrue(coverImageEntry.getSize() > 0, "Cover image should have content");
        }
    }

    // Helper methods

    private File generateEpubWithCoverPage(Path tempDir, String style)
            throws IOException, InterruptedException {
        return generateEpubWithCoverPage(tempDir, style, true);
    }

    private File generateEpubWithCoverPage(Path tempDir, String style, boolean generateCoverPage)
            throws IOException, InterruptedException {
        Path testResourcesPath = Paths.get("src/test/resources/dita");
        File ditamapFile = testResourcesPath.resolve("sample-bookmap.ditamap").toFile();
        File coverImageFile = testResourcesPath.resolve("cover.svg").toFile();

        assertTrue(ditamapFile.exists(), "Sample bookmap should exist");
        assertTrue(coverImageFile.exists(), "Cover image should exist");

        File outputDir = tempDir.resolve("epub-cover-test-" + style).toFile();
        outputDir.mkdirs();

        List<String> command = new ArrayList<>();
        command.add(EpubGenerationIntegrationTest.ditaCommand());
        command.add("--input=" + ditamapFile.getAbsolutePath());
        command.add("--format=epub3");
        command.add("--output=" + outputDir.getAbsolutePath());
        command.add("-Depub.cover.image=" + coverImageFile.getAbsolutePath());
        command.add("-Depub.cover.page.style=" + style);

        if (!generateCoverPage) {
            command.add("-Depub.generate.cover.page=no");
        }

        ProcessBuilder processBuilder = new ProcessBuilder(command);
        processBuilder.redirectErrorStream(true);
        Process process = processBuilder.start();

        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(process.getInputStream()))) {
            String line;
            while ((line = reader.readLine()) != null) {
                System.out.println(line);
            }
        }

        int exitCode = process.waitFor();
        assertEquals(0, exitCode, "DITA-OT transformation should succeed");

        return outputDir;
    }

    private File findEpubFile(File directory) {
        File[] epubFiles = directory.listFiles((dir, name) -> name.endsWith(".epub"));
        return (epubFiles != null && epubFiles.length > 0) ? epubFiles[0] : null;
    }

    /**
     * Cover styles live in the shared stylesheet, selected by a class on the cover page's html element.
     */
    private void assertFullPageCoverStyle(ZipFile zipFile, String coverContent) throws IOException {
        assertTrue(coverContent.contains("class=\"cover-page-full\""),
            "Full-page style should set the cover-page-full class");
        String rule = extractCssRule(readLinkedStylesheet(zipFile, coverContent), ".cover-page-full .cover-image");
        assertTrue(rule.contains("width: 100%"), "Full-page style should set width to 100%");
        assertTrue(rule.contains("height: 100vh"), "Full-page style should set height to 100vh");
    }

    private String readLinkedStylesheet(ZipFile zipFile, String coverContent) throws IOException {
        Matcher matcher = Pattern.compile("<link[^>]+href=\"([^\"]+\\.css)\"").matcher(coverContent);
        assertTrue(matcher.find(), "Cover page should link a stylesheet");
        String cssPath = URI.create("content/cover.xhtml").resolve(matcher.group(1)).getPath();
        ZipEntry cssEntry = zipFile.getEntry(cssPath);
        assertNotNull(cssEntry, "Linked stylesheet should exist in EPUB: " + cssPath);
        return new String(zipFile.getInputStream(cssEntry).readAllBytes());
    }

    private String extractCssRule(String css, String selector) {
        int start = css.indexOf(selector + " {");
        assertTrue(start >= 0, "Stylesheet should define rule: " + selector);
        return css.substring(start, css.indexOf('}', start));
    }
}

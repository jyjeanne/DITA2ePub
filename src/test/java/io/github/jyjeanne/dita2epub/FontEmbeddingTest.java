package io.github.jyjeanne.dita2epub;

import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.junit.jupiter.api.condition.EnabledIf;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.List;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Tests for font embedding functionality.
 * Tests font copying, manifest entries, and font configuration.
 *
 * @author J. Jeanne
 * @version 1.0.1
 */
class FontEmbeddingTest {

    static boolean isDitaOtAvailable() {
        return EpubGenerationIntegrationTest.isDitaOtAvailable();
    }

    @Test
    @EnabledIf("isDitaOtAvailable")
    void testFontEmbeddingWithDirectory(@TempDir Path tempDir) throws IOException, InterruptedException {
        // Create test fonts directory with dummy font files
        Path fontsDir = tempDir.resolve("fonts");
        Files.createDirectories(fontsDir);

        createDummyFontFile(fontsDir.resolve("TestFont-Regular.ttf").toFile());
        createDummyFontFile(fontsDir.resolve("TestFont-Bold.ttf").toFile());
        createDummyFontFile(fontsDir.resolve("TestFont.woff2").toFile());

        File outputDir = generateEpubWithFonts(tempDir, fontsDir.toString());
        File epubFile = findEpubFile(outputDir);
        assertNotNull(epubFile, "EPUB file should be generated");

        try (ZipFile zipFile = new ZipFile(epubFile)) {
            // Verify fonts directory exists in EPUB
            boolean hasFontsDir = false;
            Enumeration<? extends ZipEntry> entries = zipFile.entries();
            while (entries.hasMoreElements()) {
                ZipEntry entry = entries.nextElement();
                if (entry.getName().startsWith("fonts/")) {
                    hasFontsDir = true;
                }
            }
            assertTrue(hasFontsDir, "EPUB should contain fonts directory");

            // Verify individual font files
            assertFontExists(zipFile, "fonts/TestFont-Regular.ttf");
            assertFontExists(zipFile, "fonts/TestFont-Bold.ttf");
            assertFontExists(zipFile, "fonts/TestFont.woff2");
        }
    }

    @Test
    @EnabledIf("isDitaOtAvailable")
    void testEpubStructureWithFonts(@TempDir Path tempDir) throws IOException, InterruptedException {
        Path fontsDir = tempDir.resolve("fonts");
        Files.createDirectories(fontsDir);
        createDummyFontFile(fontsDir.resolve("CustomFont.ttf").toFile());

        File outputDir = generateEpubWithFonts(tempDir, fontsDir.toString());
        File epubFile = findEpubFile(outputDir);

        try (ZipFile zipFile = new ZipFile(epubFile)) {
            // Verify all required EPUB structure elements exist
            assertNotNull(zipFile.getEntry("mimetype"), "mimetype should exist");
            assertNotNull(zipFile.getEntry("META-INF/container.xml"), "container.xml should exist");
            assertNotNull(zipFile.getEntry("content/content.opf"), "content.opf should exist");
            assertNotNull(zipFile.getEntry("content/nav.xhtml"), "nav.xhtml should exist");
        }
    }

    @Test
    @EnabledIf("isDitaOtAvailable")
    void testFontTypesSupport(@TempDir Path tempDir) throws IOException, InterruptedException {
        Path fontsDir = tempDir.resolve("fonts");
        Files.createDirectories(fontsDir);

        // Create dummy font files of different types
        createDummyFontFile(fontsDir.resolve("Font.ttf").toFile());
        createDummyFontFile(fontsDir.resolve("Font.otf").toFile());
        createDummyFontFile(fontsDir.resolve("Font.woff").toFile());
        createDummyFontFile(fontsDir.resolve("Font.woff2").toFile());

        File outputDir = generateEpubWithFonts(tempDir, fontsDir.toString());
        File epubFile = findEpubFile(outputDir);

        try (ZipFile zipFile = new ZipFile(epubFile)) {
            // All font types should be copied
            List<String> fontEntries = new ArrayList<>();
            Enumeration<? extends ZipEntry> entries = zipFile.entries();
            while (entries.hasMoreElements()) {
                ZipEntry entry = entries.nextElement();
                if (entry.getName().startsWith("fonts/") && !entry.isDirectory()) {
                    fontEntries.add(entry.getName());
                }
            }

            assertTrue(fontEntries.stream().anyMatch(name -> name.endsWith(".ttf")),
                "TTF font should be present");
            assertTrue(fontEntries.stream().anyMatch(name -> name.endsWith(".otf")),
                "OTF font should be present");
            assertTrue(fontEntries.stream().anyMatch(name -> name.endsWith(".woff")),
                "WOFF font should be present");
            assertTrue(fontEntries.stream().anyMatch(name -> name.endsWith(".woff2")),
                "WOFF2 font should be present");
        }
    }

    @Test
    @EnabledIf("isDitaOtAvailable")
    void testNoFontsWhenNotSpecified(@TempDir Path tempDir) throws IOException, InterruptedException {
        // Generate EPUB without font parameter
        Path testResourcesPath = Paths.get("src/test/resources/dita");
        File ditamapFile = testResourcesPath.resolve("sample-bookmap.ditamap").toFile();
        File outputDir = tempDir.resolve("epub-no-fonts").toFile();
        outputDir.mkdirs();

        List<String> command = new ArrayList<>();
        command.add("dita");
        command.add("--input=" + ditamapFile.getAbsolutePath());
        command.add("--format=epub3");
        command.add("--output=" + outputDir.getAbsolutePath());

        ProcessBuilder processBuilder = new ProcessBuilder(command);
        processBuilder.redirectErrorStream(true);
        Process process = processBuilder.start();

        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(process.getInputStream()))) {
            reader.lines().forEach(System.out::println);
        }

        assertEquals(0, process.waitFor(), "DITA-OT should succeed without fonts");

        File epubFile = findEpubFile(outputDir);
        try (ZipFile zipFile = new ZipFile(epubFile)) {
            // Fonts directory should be empty or not contain custom fonts
            long customFontCount = zipFile.stream()
                .filter(entry -> entry.getName().startsWith("fonts/"))
                .filter(entry -> !entry.isDirectory())
                .count();

            assertEquals(0, customFontCount,
                "EPUB should not contain custom fonts when not specified");
        }
    }

    @Test
    void testFontCSSTemplateExists() {
        Path cssFile = Paths.get("src/main/resources/css/epub-fonts.css");
        assertTrue(Files.exists(cssFile), "Font CSS template should exist");

        // Verify it contains @font-face declarations
        try {
            String content = Files.readString(cssFile);
            assertTrue(content.contains("@font-face"),
                "CSS should contain @font-face declarations");
            assertTrue(content.contains("font-family"),
                "CSS should reference font-family");
        } catch (IOException e) {
            fail("Should be able to read font CSS template: " + e.getMessage());
        }
    }

    @Test
    void testFontDocumentationExists() {
        Path fontReadme = Paths.get("src/main/resources/fonts/README.md");
        assertTrue(Files.exists(fontReadme), "Font documentation should exist");

        try {
            String content = Files.readString(fontReadme);
            assertTrue(content.contains("embed"), "Documentation should mention embedding");
            assertTrue(content.contains("@font-face"), "Documentation should explain @font-face");
            assertTrue(content.contains("woff2") || content.contains("WOFF2"),
                "Documentation should mention WOFF2 format");
        } catch (IOException e) {
            fail("Should be able to read font documentation: " + e.getMessage());
        }
    }

    // Helper methods

    private void createDummyFontFile(File file) throws IOException {
        // Create a dummy font file with some content
        try (FileWriter writer = new FileWriter(file)) {
            writer.write("Dummy font file for testing: " + file.getName());
        }
    }

    private File generateEpubWithFonts(Path tempDir, String fontsPath)
            throws IOException, InterruptedException {
        Path testResourcesPath = Paths.get("src/test/resources/dita");
        File ditamapFile = testResourcesPath.resolve("sample-bookmap.ditamap").toFile();

        File outputDir = tempDir.resolve("epub-fonts-test").toFile();
        outputDir.mkdirs();

        List<String> command = new ArrayList<>();
        command.add("dita");
        command.add("--input=" + ditamapFile.getAbsolutePath());
        command.add("--format=epub3");
        command.add("--output=" + outputDir.getAbsolutePath());
        command.add("-Depub.embed.fonts=" + fontsPath);

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

    private void assertFontExists(ZipFile zipFile, String fontPath) {
        ZipEntry entry = zipFile.getEntry(fontPath);
        assertNotNull(entry, "Font file should exist: " + fontPath);
        assertTrue(entry.getSize() > 0, "Font file should have content: " + fontPath);
    }
}

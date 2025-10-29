package io.github.jyjeanne.dita2epub;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.junit.jupiter.api.condition.EnabledIf;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Enumeration;
import java.util.List;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Tests for EPUB file structure and organization.
 * Validates the overall EPUB package structure and required files.
 *
 * @author J. Jeanne
 * @version 1.0.1
 */
class EpubStructureTest {

    static boolean isDitaOtAvailable() {
        return EpubGenerationIntegrationTest.isDitaOtAvailable();
    }

    @Test
    @EnabledIf("isDitaOtAvailable")
    void testMimetypeFile(@TempDir Path tempDir) throws IOException, InterruptedException {
        File epubFile = generateEpub(tempDir);

        try (ZipFile zipFile = new ZipFile(epubFile)) {
            ZipEntry mimetype = zipFile.getEntry("mimetype");
            assertNotNull(mimetype, "mimetype file must exist");

            // mimetype must be first entry and uncompressed
            Enumeration<? extends ZipEntry> entries = zipFile.entries();
            assertTrue(entries.hasMoreElements());
            ZipEntry firstEntry = entries.nextElement();
            assertEquals("mimetype", firstEntry.getName(), "mimetype must be first entry");

            // Verify content
            String mimetypeContent = new String(zipFile.getInputStream(mimetype).readAllBytes()).trim();
            assertEquals("application/epub+zip", mimetypeContent,
                "mimetype content should be 'application/epub+zip'");

            // Verify size (should be exactly 20 bytes)
            assertEquals(20, mimetypeContent.length(), "mimetype should be 20 bytes");
        }
    }

    @Test
    @EnabledIf("isDitaOtAvailable")
    void testContainerXML(@TempDir Path tempDir) throws IOException, InterruptedException {
        File epubFile = generateEpub(tempDir);

        try (ZipFile zipFile = new ZipFile(epubFile)) {
            ZipEntry container = zipFile.getEntry("META-INF/container.xml");
            assertNotNull(container, "META-INF/container.xml must exist");

            String containerContent = new String(zipFile.getInputStream(container).readAllBytes());

            // Verify XML structure
            assertTrue(containerContent.contains("<?xml"), "Should be XML");
            assertTrue(containerContent.contains("<container"), "Should have container element");
            assertTrue(containerContent.contains("<rootfiles"), "Should have rootfiles element");
            assertTrue(containerContent.contains("<rootfile"), "Should have rootfile element");
            assertTrue(containerContent.contains("content.opf"), "Should reference content.opf");
            assertTrue(containerContent.contains("application/oebps-package+xml"),
                "Should have correct media type");
        }
    }

    @Test
    @EnabledIf("isDitaOtAvailable")
    void testRequiredDirectories(@TempDir Path tempDir) throws IOException, InterruptedException {
        File epubFile = generateEpub(tempDir);

        try (ZipFile zipFile = new ZipFile(epubFile)) {
            // Check for required directories
            assertTrue(hasDirectory(zipFile, "META-INF/"), "META-INF/ directory should exist");
            assertTrue(hasDirectory(zipFile, "content/"), "content/ directory should exist");
            assertTrue(hasDirectory(zipFile, "images/"), "images/ directory should exist");
            assertTrue(hasDirectory(zipFile, "styles/"), "styles/ directory should exist");
            assertTrue(hasDirectory(zipFile, "fonts/"), "fonts/ directory should exist");
        }
    }

    @Test
    @EnabledIf("isDitaOtAvailable")
    void testNavigationDocument(@TempDir Path tempDir) throws IOException, InterruptedException {
        File epubFile = generateEpub(tempDir);

        try (ZipFile zipFile = new ZipFile(epubFile)) {
            ZipEntry nav = zipFile.getEntry("content/nav.xhtml");
            assertNotNull(nav, "Navigation document should exist");

            String navContent = new String(zipFile.getInputStream(nav).readAllBytes());

            // Verify structure
            assertTrue(navContent.contains("<html"), "Should be HTML");
            assertTrue(navContent.contains("<nav"), "Should have nav element");
            assertTrue(navContent.contains("epub:type=\"toc\""), "Should have TOC nav");
            assertTrue(navContent.contains("Table of Contents"), "Should have TOC heading");

            // Verify ARIA landmarks
            assertTrue(navContent.contains("epub:type=\"landmarks\"") ||
                      navContent.contains("role=\"doc-toc\""),
                "Should have landmarks or ARIA roles");
        }
    }

    @Test
    @EnabledIf("isDitaOtAvailable")
    void testContentFiles(@TempDir Path tempDir) throws IOException, InterruptedException {
        File epubFile = generateEpub(tempDir);

        try (ZipFile zipFile = new ZipFile(epubFile)) {
            // Count XHTML content files
            long xhtmlCount = zipFile.stream()
                .filter(entry -> entry.getName().endsWith(".xhtml"))
                .filter(entry -> !entry.isDirectory())
                .filter(entry -> !entry.getName().equals("content/nav.xhtml"))
                .count();

            assertTrue(xhtmlCount >= 9,
                "Should have at least 9 content XHTML files (from sample bookmap)");

            // Verify each XHTML file is valid
            zipFile.stream()
                .filter(entry -> entry.getName().endsWith(".xhtml"))
                .filter(entry -> !entry.isDirectory())
                .forEach(entry -> {
                    try {
                        String content = new String(zipFile.getInputStream(entry).readAllBytes());
                        assertTrue(content.contains("<html"), "XHTML should have html element");
                        assertTrue(content.contains("<head"), "XHTML should have head element");
                        assertTrue(content.contains("<body"), "XHTML should have body element");
                    } catch (IOException e) {
                        fail("Failed to read XHTML file: " + entry.getName());
                    }
                });
        }
    }

    @Test
    @EnabledIf("isDitaOtAvailable")
    void testCSSFile(@TempDir Path tempDir) throws IOException, InterruptedException {
        File epubFile = generateEpub(tempDir);

        try (ZipFile zipFile = new ZipFile(epubFile)) {
            ZipEntry css = zipFile.getEntry("styles/epub-default.css");
            assertNotNull(css, "CSS file should exist");

            String cssContent = new String(zipFile.getInputStream(css).readAllBytes());

            // Verify it contains CSS rules
            assertTrue(cssContent.contains("{") && cssContent.contains("}"),
                "CSS should contain style rules");
            assertTrue(cssContent.contains("font-family") || cssContent.contains("color"),
                "CSS should contain style properties");
        }
    }

    @Test
    @EnabledIf("isDitaOtAvailable")
    void testEpubFileSize(@TempDir Path tempDir) throws IOException, InterruptedException {
        File epubFile = generateEpub(tempDir);

        // Verify file exists and has reasonable size
        assertTrue(epubFile.exists(), "EPUB file should exist");
        assertTrue(epubFile.length() > 1000, "EPUB should be at least 1KB");
        assertTrue(epubFile.length() < 50 * 1024 * 1024, "EPUB should be less than 50MB");

        System.out.println("Generated EPUB size: " + epubFile.length() + " bytes");
    }

    @Test
    @EnabledIf("isDitaOtAvailable")
    void testNoEmptyFiles(@TempDir Path tempDir) throws IOException, InterruptedException {
        File epubFile = generateEpub(tempDir);

        try (ZipFile zipFile = new ZipFile(epubFile)) {
            zipFile.stream()
                .filter(entry -> !entry.isDirectory())
                .forEach(entry -> {
                    assertTrue(entry.getSize() > 0,
                        "File should not be empty: " + entry.getName());
                });
        }
    }

    @Test
    @EnabledIf("isDitaOtAvailable")
    void testFileNamingConventions(@TempDir Path tempDir) throws IOException, InterruptedException {
        File epubFile = generateEpub(tempDir);

        try (ZipFile zipFile = new ZipFile(epubFile)) {
            zipFile.stream()
                .filter(entry -> !entry.isDirectory())
                .forEach(entry -> {
                    String name = entry.getName();

                    // No spaces in filenames
                    assertFalse(name.contains(" "),
                        "Filenames should not contain spaces: " + name);

                    // No special characters except . / - _
                    assertTrue(name.matches("[a-zA-Z0-9./_-]+"),
                        "Filename should only contain allowed characters: " + name);
                });
        }
    }

    @Test
    @EnabledIf("isDitaOtAvailable")
    void testAllFilesHaveExtensions(@TempDir Path tempDir) throws IOException, InterruptedException {
        File epubFile = generateEpub(tempDir);

        try (ZipFile zipFile = new ZipFile(epubFile)) {
            zipFile.stream()
                .filter(entry -> !entry.isDirectory())
                .filter(entry -> !entry.getName().equals("mimetype"))
                .forEach(entry -> {
                    String name = entry.getName();
                    assertTrue(name.contains("."),
                        "File should have extension: " + name);
                });
        }
    }

    // Helper methods

    private File generateEpub(Path tempDir) throws IOException, InterruptedException {
        Path testResourcesPath = Paths.get("src/test/resources/dita");
        File ditamapFile = testResourcesPath.resolve("sample-bookmap.ditamap").toFile();

        File outputDir = tempDir.resolve("epub-structure-test").toFile();
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

        assertEquals(0, process.waitFor(), "DITA-OT should succeed");

        File[] epubFiles = outputDir.listFiles((dir, name) -> name.endsWith(".epub"));
        assertNotNull(epubFiles);
        assertTrue(epubFiles.length > 0);
        return epubFiles[0];
    }

    private boolean hasDirectory(ZipFile zipFile, String dirPath) {
        Enumeration<? extends ZipEntry> entries = zipFile.entries();
        while (entries.hasMoreElements()) {
            ZipEntry entry = entries.nextElement();
            if (entry.getName().startsWith(dirPath)) {
                return true;
            }
        }
        return false;
    }
}

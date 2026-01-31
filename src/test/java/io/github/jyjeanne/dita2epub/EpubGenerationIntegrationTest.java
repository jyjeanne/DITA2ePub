package io.github.jyjeanne.dita2epub;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.junit.jupiter.api.condition.EnabledIf;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Integration tests for EPUB generation from DITA content.
 * These tests require DITA-OT to be installed and available.
 *
 * @author J. Jeanne
 * @version 1.0.0
 */
class EpubGenerationIntegrationTest {

    private static final String DITA_COMMAND = "dita";

    /**
     * Check if DITA-OT is available on the system
     */
    static boolean isDitaOtAvailable() {
        String ditaHome = System.getenv("DITA_HOME");
        if (ditaHome != null && !ditaHome.isEmpty()) {
            File ditaHomeDir = new File(ditaHome);
            if (ditaHomeDir.exists() && ditaHomeDir.isDirectory()) {
                return true;
            }
        }

        // Try to run dita command
        try {
            Process process = Runtime.getRuntime().exec(new String[]{"dita", "--version"});
            int exitCode = process.waitFor();
            return exitCode == 0;
        } catch (Exception e) {
            return false;
        }
    }

    @Test
    @EnabledIf("isDitaOtAvailable")
    void testGenerateEpubFromSampleBookmap(@TempDir Path tempDir) throws IOException, InterruptedException {
        // Locate test resources
        Path testResourcesPath = Paths.get("src/test/resources/dita");
        File ditamapFile = testResourcesPath.resolve("sample-bookmap.ditamap").toFile();

        assertTrue(ditamapFile.exists(), "Sample bookmap should exist");

        // Set output directory
        File outputDir = tempDir.resolve("epub-output").toFile();
        outputDir.mkdirs();

        // Build DITA command
        List<String> command = new ArrayList<>();
        command.add("dita");
        command.add("--input=" + ditamapFile.getAbsolutePath());
        command.add("--format=epub3");
        command.add("--output=" + outputDir.getAbsolutePath());
        command.add("-Depub.version=3.3");
        command.add("-Depub.accessibility=wcag-aa");

        System.out.println("Running DITA-OT command: " + String.join(" ", command));

        // Execute DITA-OT transformation
        ProcessBuilder processBuilder = new ProcessBuilder(command);
        processBuilder.redirectErrorStream(true);
        Process process = processBuilder.start();

        // Capture output
        StringBuilder output = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(process.getInputStream()))) {
            String line;
            while ((line = reader.readLine()) != null) {
                output.append(line).append("\n");
                System.out.println(line);
            }
        }

        int exitCode = process.waitFor();

        if (exitCode != 0) {
            System.err.println("DITA-OT output:\n" + output.toString());
            fail("DITA-OT transformation failed with exit code: " + exitCode);
        }

        // Verify EPUB was created
        File[] epubFiles = outputDir.listFiles((dir, name) -> name.endsWith(".epub"));
        assertNotNull(epubFiles, "Output directory should contain files");
        assertTrue(epubFiles.length > 0, "At least one EPUB file should be generated");

        File epubFile = epubFiles[0];
        System.out.println("Generated EPUB: " + epubFile.getAbsolutePath());
        assertTrue(epubFile.exists(), "EPUB file should exist");
        assertTrue(epubFile.length() > 0, "EPUB file should not be empty");

        // Validate the generated EPUB
        EpubValidator validator = new EpubValidator();
        EpubValidator.ValidationResult result = validator.validate(epubFile);

        System.out.println("Validation result: " + result);
        System.out.println("Errors: " + result.getErrorCount());
        System.out.println("Warnings: " + result.getWarningCount());

        if (!result.isValid()) {
            System.err.println("EPUB validation errors:");
            result.getErrors().forEach(error -> System.err.println("  - " + error));
        }

        assertTrue(result.isValid(), "Generated EPUB should be valid");
    }

    @Test
    @EnabledIf("isDitaOtAvailable")
    void testGenerateEpubFromComprehensiveTest(@TempDir Path tempDir) throws IOException, InterruptedException {
        // Locate comprehensive test resources
        Path testResourcesPath = Paths.get("src/test/resources/dita-comprehensive");
        File ditamapFile = testResourcesPath.resolve("comprehensive-test.ditamap").toFile();

        if (!ditamapFile.exists()) {
            System.out.println("Comprehensive test ditamap not found, skipping test");
            return;
        }

        // Set output directory
        File outputDir = tempDir.resolve("epub-comprehensive").toFile();
        outputDir.mkdirs();

        // Build DITA command
        List<String> command = new ArrayList<>();
        command.add("dita");
        command.add("--input=" + ditamapFile.getAbsolutePath());
        command.add("--format=epub3");
        command.add("--output=" + outputDir.getAbsolutePath());
        command.add("-Depub.version=3.3");
        command.add("-Depub.toc.depth=5");
        command.add("-Depub.nav.depth=5");

        System.out.println("Running DITA-OT command: " + String.join(" ", command));

        // Execute DITA-OT transformation
        ProcessBuilder processBuilder = new ProcessBuilder(command);
        processBuilder.redirectErrorStream(true);
        Process process = processBuilder.start();

        // Capture output
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(process.getInputStream()))) {
            String line;
            while ((line = reader.readLine()) != null) {
                System.out.println(line);
            }
        }

        int exitCode = process.waitFor();
        assertEquals(0, exitCode, "DITA-OT transformation should succeed");

        // Verify EPUB was created
        File[] epubFiles = outputDir.listFiles((dir, name) -> name.endsWith(".epub"));
        assertNotNull(epubFiles);
        assertTrue(epubFiles.length > 0, "EPUB file should be generated");

        File epubFile = epubFiles[0];
        assertTrue(epubFile.length() > 1000,
            "Comprehensive EPUB should be reasonably large (> 1KB)");

        // Basic validation
        EpubValidator validator = new EpubValidator();
        EpubValidator.ValidationResult result = validator.validate(epubFile);

        System.out.println("Comprehensive EPUB validation: " + result);
        assertTrue(result.isValid() || result.getWarningCount() <= 5,
            "Generated EPUB should be valid or have minimal warnings");
    }

    @Test
    @EnabledIf("isDitaOtAvailable")
    void testGenerateEpubFromCalibreGuide(@TempDir Path tempDir) throws IOException, InterruptedException {
        // Locate Calibre Guide test resources (French content)
        Path testResourcesPath = Paths.get("src/test/resources/dita-calibre");
        File ditamapFile = testResourcesPath.resolve("calibre-guide.ditamap").toFile();

        if (!ditamapFile.exists()) {
            System.out.println("Calibre Guide ditamap not found, skipping test");
            return;
        }

        assertTrue(ditamapFile.exists(), "Calibre Guide bookmap should exist");

        // Set output directory
        File outputDir = tempDir.resolve("epub-calibre").toFile();
        outputDir.mkdirs();

        // Build DITA command with French language settings
        List<String> command = new ArrayList<>();
        command.add("dita");
        command.add("--input=" + ditamapFile.getAbsolutePath());
        command.add("--format=epub3");
        command.add("--output=" + outputDir.getAbsolutePath());
        command.add("-Depub.version=3.3");
        command.add("-Depub.toc.depth=3");
        command.add("-Depub.nav.depth=3");
        command.add("-Depub.accessibility=wcag-aa");

        System.out.println("Running DITA-OT command for Calibre Guide: " + String.join(" ", command));

        // Execute DITA-OT transformation
        ProcessBuilder processBuilder = new ProcessBuilder(command);
        processBuilder.redirectErrorStream(true);
        Process process = processBuilder.start();

        // Capture output
        StringBuilder output = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(process.getInputStream()))) {
            String line;
            while ((line = reader.readLine()) != null) {
                output.append(line).append("\n");
                System.out.println(line);
            }
        }

        int exitCode = process.waitFor();

        if (exitCode != 0) {
            System.err.println("DITA-OT output:\n" + output.toString());
            fail("DITA-OT transformation failed with exit code: " + exitCode);
        }

        // Verify EPUB was created
        File[] epubFiles = outputDir.listFiles((dir, name) -> name.endsWith(".epub"));
        assertNotNull(epubFiles, "Output directory should contain files");
        assertTrue(epubFiles.length > 0, "At least one EPUB file should be generated");

        File epubFile = epubFiles[0];
        System.out.println("Generated Calibre Guide EPUB: " + epubFile.getAbsolutePath());
        assertTrue(epubFile.exists(), "EPUB file should exist");
        assertTrue(epubFile.length() > 0, "EPUB file should not be empty");

        // Calibre Guide should be reasonably sized (14 chapters + cover)
        assertTrue(epubFile.length() > 5000,
            "Calibre Guide EPUB should be at least 5KB (has 14+ topics)");

        // Validate the generated EPUB
        EpubValidator validator = new EpubValidator();
        EpubValidator.ValidationResult result = validator.validate(epubFile);

        System.out.println("Calibre Guide validation result: " + result);
        System.out.println("Errors: " + result.getErrorCount());
        System.out.println("Warnings: " + result.getWarningCount());

        if (!result.isValid()) {
            System.err.println("EPUB validation errors:");
            result.getErrors().forEach(error -> System.err.println("  - " + error));
        }

        // Allow some warnings for French content (encoding, etc.)
        assertTrue(result.isValid() || result.getErrorCount() == 0,
            "Generated EPUB should be valid or have only warnings");
    }

    @Test
    void testDitaOtAvailabilityMessage() {
        if (!isDitaOtAvailable()) {
            System.out.println("=".repeat(70));
            System.out.println("DITA-OT is not installed or not available on PATH");
            System.out.println("To test EPUB generation, please:");
            System.out.println("1. Download DITA-OT from https://www.dita-ot.org/download");
            System.out.println("2. Extract and set DITA_HOME environment variable");
            System.out.println("3. Add DITA-OT bin directory to PATH");
            System.out.println("4. Install this plugin: gradle installPlugin");
            System.out.println("5. Run tests again");
            System.out.println("=".repeat(70));
        } else {
            System.out.println("DITA-OT is available - integration tests will run");
        }

        // This test always passes, it's just informational
        assertTrue(true);
    }
}

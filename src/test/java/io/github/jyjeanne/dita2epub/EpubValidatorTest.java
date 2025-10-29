package io.github.jyjeanne.dita2epub;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for EpubValidator
 *
 * @author J. Jeanne
 * @version 1.0.0
 */
class EpubValidatorTest {

    @Test
    void testValidatorCreation() {
        EpubValidator validator = new EpubValidator();
        assertNotNull(validator, "Validator should be created successfully");
    }

    @Test
    void testValidateNullFile() {
        EpubValidator validator = new EpubValidator();
        assertThrows(IllegalArgumentException.class, () -> {
            validator.validate(null);
        }, "Should throw IllegalArgumentException for null file");
    }

    @Test
    void testValidateNonExistentFile() {
        EpubValidator validator = new EpubValidator();
        File nonExistent = new File("/nonexistent/file.epub");

        assertThrows(IOException.class, () -> {
            validator.validate(nonExistent);
        }, "Should throw IOException for non-existent file");
    }

    @Test
    void testValidateNonEpubExtension(@TempDir Path tempDir) throws IOException {
        EpubValidator validator = new EpubValidator();
        File textFile = tempDir.resolve("test.txt").toFile();

        // Create a test file
        try (FileWriter writer = new FileWriter(textFile)) {
            writer.write("test content");
        }

        assertThrows(IllegalArgumentException.class, () -> {
            validator.validate(textFile);
        }, "Should throw IllegalArgumentException for non-EPUB file");
    }

    @Test
    void testValidateEmptyEpubFile(@TempDir Path tempDir) throws IOException {
        EpubValidator validator = new EpubValidator();
        File emptyEpub = tempDir.resolve("empty.epub").toFile();

        // Create empty file
        emptyEpub.createNewFile();

        EpubValidator.ValidationResult result = validator.validate(emptyEpub);

        assertFalse(result.isValid(), "Empty EPUB should be invalid");
        assertTrue(result.getErrorCount() > 0, "Should have at least one error");
    }

    @Test
    void testValidateSmallEpubFile(@TempDir Path tempDir) throws IOException {
        EpubValidator validator = new EpubValidator();
        File smallEpub = tempDir.resolve("small.epub").toFile();

        // Create small file with some content
        try (FileWriter writer = new FileWriter(smallEpub)) {
            writer.write("minimal content");
        }

        EpubValidator.ValidationResult result = validator.validate(smallEpub);

        // Should have warnings about small size
        assertTrue(result.getWarningCount() > 0, "Should have warnings about small file size");
    }

    @Test
    void testValidationResultProperties() {
        EpubValidator.ValidationResult result = new EpubValidator.ValidationResult(
                true,
                null,
                null,
                "3.3"
        );

        assertTrue(result.isValid(), "Result should be valid");
        assertEquals("3.3", result.getEpubVersion(), "Version should be 3.3");
        assertEquals(0, result.getErrorCount(), "Should have no errors");
        assertEquals(0, result.getWarningCount(), "Should have no warnings");
        assertNotNull(result.toString(), "toString should not be null");
    }

    @Test
    void testValidationResultWithErrorsAndWarnings() {
        java.util.List<String> errors = java.util.Arrays.asList("Error 1", "Error 2");
        java.util.List<String> warnings = java.util.Arrays.asList("Warning 1");

        EpubValidator.ValidationResult result = new EpubValidator.ValidationResult(
                false,
                errors,
                warnings,
                "3.0"
        );

        assertFalse(result.isValid(), "Result should be invalid");
        assertEquals(2, result.getErrorCount(), "Should have 2 errors");
        assertEquals(1, result.getWarningCount(), "Should have 1 warning");
        assertEquals(errors, result.getErrors(), "Errors should match");
        assertEquals(warnings, result.getWarnings(), "Warnings should match");
    }
}

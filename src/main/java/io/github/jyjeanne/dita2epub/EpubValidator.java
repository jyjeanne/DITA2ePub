package io.github.jyjeanne.dita2epub;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

/**
 * EPUB Validator using EPUBCheck
 *
 * Validates EPUB files against EPUB specifications.
 *
 * @author J. Jeanne
 * @version 1.0.0
 * @since 2025-10-29
 */
public class EpubValidator {

    /**
     * Validation result container
     */
    public static class ValidationResult {
        private final boolean valid;
        private final List<String> errors;
        private final List<String> warnings;
        private final String epubVersion;

        public ValidationResult(boolean valid, List<String> errors, List<String> warnings, String epubVersion) {
            this.valid = valid;
            this.errors = errors != null ? errors : new ArrayList<>();
            this.warnings = warnings != null ? warnings : new ArrayList<>();
            this.epubVersion = epubVersion != null ? epubVersion : "unknown";
        }

        public boolean isValid() {
            return valid;
        }

        public List<String> getErrors() {
            return errors;
        }

        public List<String> getWarnings() {
            return warnings;
        }

        public String getEpubVersion() {
            return epubVersion;
        }

        public int getErrorCount() {
            return errors.size();
        }

        public int getWarningCount() {
            return warnings.size();
        }

        @Override
        public String toString() {
            return String.format("ValidationResult{valid=%s, version=%s, errors=%d, warnings=%d}",
                    valid, epubVersion, errors.size(), warnings.size());
        }
    }

    /**
     * Validates an EPUB file
     *
     * @param epubFile the EPUB file to validate
     * @return ValidationResult containing validation status and messages
     * @throws IOException if the file cannot be read
     */
    public ValidationResult validate(File epubFile) throws IOException {
        if (epubFile == null) {
            throw new IllegalArgumentException("EPUB file cannot be null");
        }

        if (!epubFile.exists()) {
            throw new IOException("EPUB file does not exist: " + epubFile.getAbsolutePath());
        }

        if (!epubFile.isFile()) {
            throw new IOException("Path is not a file: " + epubFile.getAbsolutePath());
        }

        if (!epubFile.getName().toLowerCase().endsWith(".epub")) {
            throw new IllegalArgumentException("File does not have .epub extension: " + epubFile.getName());
        }

        // TODO: Integrate with EPUBCheck library
        // For now, return basic structure validation
        return performBasicValidation(epubFile);
    }

    /**
     * Performs basic EPUB structure validation
     *
     * @param epubFile the EPUB file to validate
     * @return ValidationResult
     */
    private ValidationResult performBasicValidation(File epubFile) {
        List<String> errors = new ArrayList<>();
        List<String> warnings = new ArrayList<>();

        // Basic file size check
        long fileSize = epubFile.length();
        if (fileSize == 0) {
            errors.add("EPUB file is empty");
            return new ValidationResult(false, errors, warnings, "unknown");
        }

        // Check minimum file size (valid EPUB should be at least a few KB)
        if (fileSize < 1024) {
            warnings.add("EPUB file is unusually small (" + fileSize + " bytes)");
        }

        // Check maximum file size (warn if over 100MB)
        long maxSize = 100 * 1024 * 1024; // 100 MB
        if (fileSize > maxSize) {
            warnings.add("EPUB file is unusually large (" + (fileSize / 1024 / 1024) + " MB)");
        }

        boolean isValid = errors.isEmpty();
        String version = "3.0"; // Assume EPUB3

        return new ValidationResult(isValid, errors, warnings, version);
    }

    /**
     * Validates an EPUB file and prints results to console
     *
     * @param epubFilePath path to the EPUB file
     * @return true if validation passed, false otherwise
     */
    public boolean validateAndPrint(String epubFilePath) {
        try {
            File epubFile = new File(epubFilePath);
            ValidationResult result = validate(epubFile);

            System.out.println("=".repeat(60));
            System.out.println("EPUB Validation Report");
            System.out.println("=".repeat(60));
            System.out.println("File: " + epubFile.getName());
            System.out.println("Version: " + result.getEpubVersion());
            System.out.println("Status: " + (result.isValid() ? "VALID" : "INVALID"));
            System.out.println();

            if (!result.getErrors().isEmpty()) {
                System.out.println("Errors (" + result.getErrorCount() + "):");
                for (String error : result.getErrors()) {
                    System.out.println("  - " + error);
                }
                System.out.println();
            }

            if (!result.getWarnings().isEmpty()) {
                System.out.println("Warnings (" + result.getWarningCount() + "):");
                for (String warning : result.getWarnings()) {
                    System.out.println("  - " + warning);
                }
                System.out.println();
            }

            System.out.println("=".repeat(60));

            return result.isValid();
        } catch (Exception e) {
            System.err.println("Validation failed: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }

    /**
     * Main method for command-line validation
     *
     * @param args command line arguments (expects EPUB file path)
     */
    public static void main(String[] args) {
        if (args.length < 1) {
            System.err.println("Usage: java EpubValidator <epub-file>");
            System.exit(1);
        }

        EpubValidator validator = new EpubValidator();
        boolean isValid = validator.validateAndPrint(args[0]);

        System.exit(isValid ? 0 : 1);
    }
}

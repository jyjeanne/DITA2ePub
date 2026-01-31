package io.github.jyjeanne.dita2epub;

import java.io.*;
import java.nio.file.*;
import java.util.zip.*;

/**
 * Creates EPUB-compliant ZIP archives.
 *
 * EPUB requires:
 * 1. mimetype must be FIRST file in archive
 * 2. mimetype must be STORED (uncompressed)
 * 3. mimetype must have no extra field in ZIP header
 */
public class EpubPackager {

    private static final int BUFFER_SIZE = 8192;
    private static boolean verbose = false;

    public static void main(String[] args) {
        try {
            run(args);
        } catch (IllegalArgumentException e) {
            System.err.println("Error: " + e.getMessage());
            printUsage();
            System.exit(1);
        } catch (IOException e) {
            System.err.println("I/O Error: " + e.getMessage());
            System.exit(2);
        } catch (Exception e) {
            System.err.println("Unexpected error: " + e.getMessage());
            e.printStackTrace();
            System.exit(3);
        }
    }

    private static void printUsage() {
        System.err.println("Usage: EpubPackager <outputDir> <epubFilename> <topicsDir> <imagesDir> <cssDir> <fontsDir> [--verbose]");
    }

    private static void run(String[] args) throws IOException {
        // Validate arguments
        if (args.length < 6) {
            throw new IllegalArgumentException("Not enough arguments. Expected at least 6, got " + args.length);
        }

        String outputDir = args[0];
        String epubFilename = args[1];
        String topicsDir = args[2];
        String imagesDir = args[3];
        String cssDir = args[4];
        String fontsDir = args[5];

        // Check for verbose flag
        if (args.length > 6 && "--verbose".equals(args[6])) {
            verbose = true;
        }

        // Validate output directory exists
        File outputDirFile = new File(outputDir);
        if (!outputDirFile.exists()) {
            throw new IllegalArgumentException("Output directory does not exist: " + outputDir);
        }
        if (!outputDirFile.isDirectory()) {
            throw new IllegalArgumentException("Output path is not a directory: " + outputDir);
        }

        // Validate mimetype file exists (required for EPUB)
        File mimetypeFile = new File(outputDir, "mimetype");
        if (!mimetypeFile.exists()) {
            throw new IllegalArgumentException("Required mimetype file not found in: " + outputDir);
        }

        File epubFile = new File(outputDir, epubFilename);
        log("Creating EPUB: " + epubFile.getAbsolutePath());

        try (FileOutputStream fos = new FileOutputStream(epubFile);
             ZipOutputStream zos = new ZipOutputStream(fos)) {

            // 1. Add mimetype FIRST (STORED, no extra field) - CRITICAL for EPUB compliance
            addStoredFile(zos, outputDir, "mimetype");

            // 2. Add META-INF
            addDirectory(zos, outputDir, "META-INF");

            // 3. Add toc.ncx at root level (for backwards compatibility with older readers)
            File tocNcx = new File(outputDir, "toc.ncx");
            if (tocNcx.exists()) {
                addCompressedFile(zos, outputDir, "toc.ncx");
            }

            // 4. Add content directories
            addDirectory(zos, outputDir, topicsDir);
            addDirectory(zos, outputDir, imagesDir);
            addDirectory(zos, outputDir, cssDir);

            // 5. Add fonts only if directory exists and has content
            File fontsPath = new File(outputDir, fontsDir);
            if (fontsPath.exists() && fontsPath.isDirectory()) {
                String[] fontFiles = fontsPath.list();
                if (fontFiles != null && fontFiles.length > 0) {
                    addDirectory(zos, outputDir, fontsDir);
                } else {
                    log("Skipping empty fonts directory: " + fontsDir);
                }
            }
        }

        System.out.println("EPUB created: " + epubFile.getAbsolutePath());
    }

    /**
     * Add a file with STORED compression (uncompressed) and no extra field.
     * Required for the mimetype file in EPUB.
     *
     * Per EPUB OCF specification:
     * - The mimetype file MUST be the first file in the ZIP archive
     * - It MUST be uncompressed (STORED method)
     * - It MUST NOT have an extra field in its ZIP header
     * - The CRC32 checksum must be calculated manually for STORED entries
     */
    private static void addStoredFile(ZipOutputStream zos, String baseDir, String relativePath) throws IOException {
        File file = new File(baseDir, relativePath);
        if (!file.exists()) {
            log("Warning: File not found, skipping: " + relativePath);
            return;
        }

        byte[] content = Files.readAllBytes(file.toPath());
        String normalizedPath = normalizePath(relativePath);

        ZipEntry entry = new ZipEntry(normalizedPath);
        entry.setMethod(ZipEntry.STORED);
        entry.setSize(content.length);
        entry.setCompressedSize(content.length);

        // Calculate CRC32 checksum (required for STORED entries)
        CRC32 crc = new CRC32();
        crc.update(content);
        entry.setCrc(crc.getValue());

        // Critical: no extra field for EPUB compliance (must be null, not empty array)
        entry.setExtra(null);

        zos.putNextEntry(entry);
        zos.write(content);
        zos.closeEntry();

        log("Added (STORED): " + normalizedPath + " (" + content.length + " bytes, CRC=" + Long.toHexString(crc.getValue()) + ")");
    }

    /**
     * Add a file with DEFLATED compression.
     */
    private static void addCompressedFile(ZipOutputStream zos, String baseDir, String relativePath) throws IOException {
        File file = new File(baseDir, relativePath);
        if (!file.exists()) {
            log("Warning: File not found, skipping: " + relativePath);
            return;
        }

        String normalizedPath = normalizePath(relativePath);
        ZipEntry entry = new ZipEntry(normalizedPath);
        entry.setMethod(ZipEntry.DEFLATED);

        zos.putNextEntry(entry);

        long bytesWritten = 0;
        try (FileInputStream fis = new FileInputStream(file)) {
            byte[] buffer = new byte[BUFFER_SIZE];
            int len;
            while ((len = fis.read(buffer)) > 0) {
                zos.write(buffer, 0, len);
                bytesWritten += len;
            }
        }

        zos.closeEntry();
        log("Added (DEFLATED): " + normalizedPath + " (" + bytesWritten + " bytes)");
    }

    /**
     * Add a directory recursively with DEFLATED compression.
     */
    private static void addDirectory(ZipOutputStream zos, String baseDir, String dirPath) throws IOException {
        File dir = new File(baseDir, dirPath);
        if (!dir.exists()) {
            log("Warning: Directory not found, skipping: " + dirPath);
            return;
        }
        if (!dir.isDirectory()) {
            log("Warning: Path is not a directory, skipping: " + dirPath);
            return;
        }

        File[] files = dir.listFiles();
        if (files == null) {
            // This can happen if we don't have permission to read the directory
            System.err.println("Warning: Cannot list directory contents (permission denied?): " + dirPath);
            return;
        }

        if (files.length == 0) {
            log("Skipping empty directory: " + dirPath);
            return;
        }

        for (File f : files) {
            String relativePath = normalizePath(dirPath + "/" + f.getName());
            if (f.isDirectory()) {
                addDirectory(zos, baseDir, relativePath);
            } else {
                addCompressedFile(zos, baseDir, relativePath);
            }
        }
    }

    /**
     * Normalize path separators to forward slashes (required for ZIP format).
     */
    private static String normalizePath(String path) {
        return path.replace("\\", "/").replaceAll("/+", "/");
    }

    /**
     * Log a message if verbose mode is enabled.
     */
    private static void log(String message) {
        if (verbose) {
            System.out.println("[EpubPackager] " + message);
        }
    }
}

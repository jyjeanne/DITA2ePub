package io.github.jyjeanne.dita2epub;

import java.awt.Graphics2D;
import java.awt.image.BufferedImage;
import java.io.*;
import java.nio.file.*;
import java.util.Iterator;
import javax.imageio.*;
import javax.imageio.stream.ImageOutputStream;

/**
 * Optimizes images for EPUB output.
 *
 * - JPEG: re-encodes at configurable quality (default 0.8)
 * - PNG: re-encodes to strip non-essential metadata
 * - Optional max dimension resize (preserving aspect ratio)
 * - Skips SVG files (already compact)
 * - Only processes files above 50KB threshold to avoid touching small icons
 */
public class ImageOptimizer {

    private static final long MIN_FILE_SIZE = 50 * 1024; // 50KB threshold
    private static boolean verbose = false;

    public static void main(String[] args) {
        try {
            run(args);
        } catch (IllegalArgumentException e) {
            System.err.println("Error: " + e.getMessage());
            printUsage();
            System.exit(1);
        } catch (Exception e) {
            System.err.println("Error: " + e.getMessage());
            e.printStackTrace();
            System.exit(2);
        }
    }

    private static void printUsage() {
        System.err.println("Usage: ImageOptimizer <imagesDir> [--jpeg-quality=0.8] [--max-width=0] [--strip-metadata] [--verbose]");
    }

    private static void run(String[] args) throws Exception {
        if (args.length < 1) {
            throw new IllegalArgumentException("Not enough arguments. Expected at least 1.");
        }

        String imagesDir = args[0];
        float jpegQuality = 0.8f;
        int maxWidth = 0;
        boolean stripMetadata = true;

        // Parse optional arguments
        for (int i = 1; i < args.length; i++) {
            if (args[i].startsWith("--jpeg-quality=")) {
                jpegQuality = Float.parseFloat(args[i].substring("--jpeg-quality=".length()));
            } else if (args[i].startsWith("--max-width=")) {
                maxWidth = Integer.parseInt(args[i].substring("--max-width=".length()));
            } else if ("--strip-metadata".equals(args[i])) {
                stripMetadata = true;
            } else if ("--verbose".equals(args[i])) {
                verbose = true;
            }
        }

        Path imagesPath = Paths.get(imagesDir);
        if (!Files.isDirectory(imagesPath)) {
            log("No images directory found at: " + imagesPath);
            return;
        }

        int optimizedCount = 0;
        long totalSaved = 0;

        try (DirectoryStream<Path> stream = Files.newDirectoryStream(imagesPath)) {
            for (Path entry : stream) {
                if (Files.isDirectory(entry)) continue;

                String filename = entry.getFileName().toString().toLowerCase();
                long originalSize = Files.size(entry);

                // Skip small files
                if (originalSize < MIN_FILE_SIZE) {
                    log("Skipping (too small): " + entry.getFileName() + " (" + originalSize + " bytes)");
                    continue;
                }

                long newSize = originalSize;
                if (filename.endsWith(".jpg") || filename.endsWith(".jpeg")) {
                    newSize = optimizeJpeg(entry, jpegQuality, maxWidth);
                    optimizedCount++;
                } else if (filename.endsWith(".png")) {
                    newSize = optimizePng(entry, stripMetadata, maxWidth);
                    optimizedCount++;
                } else {
                    log("Skipping (unsupported format): " + entry.getFileName());
                    continue;
                }

                long saved = originalSize - newSize;
                totalSaved += Math.max(0, saved);
                log(String.format("Optimized: %s (%d -> %d bytes, saved %d bytes)",
                        entry.getFileName(), originalSize, newSize, saved));
            }
        }

        System.out.println(String.format("Image optimization complete: %d image(s) processed, %d bytes saved.",
                optimizedCount, totalSaved));
    }

    /**
     * Re-encode JPEG at specified quality, optionally resizing.
     */
    private static long optimizeJpeg(Path file, float quality, int maxWidth) throws IOException {
        BufferedImage image = ImageIO.read(file.toFile());
        if (image == null) {
            log("Warning: Could not read image: " + file.getFileName());
            return Files.size(file);
        }

        image = resizeIfNeeded(image, maxWidth);

        // Write JPEG with specified quality
        Iterator<ImageWriter> writers = ImageIO.getImageWritersByFormatName("jpeg");
        if (!writers.hasNext()) {
            log("Warning: No JPEG writer available");
            return Files.size(file);
        }

        ImageWriter writer = writers.next();
        Path tempFile = file.resolveSibling(file.getFileName() + ".tmp");
        try {
            ImageWriteParam param = writer.getDefaultWriteParam();
            param.setCompressionMode(ImageWriteParam.MODE_EXPLICIT);
            param.setCompressionQuality(quality);

            try (ImageOutputStream ios = ImageIO.createImageOutputStream(tempFile.toFile())) {
                writer.setOutput(ios);
                writer.write(null, new IIOImage(image, null, null), param);
            }

            long newSize = Files.size(tempFile);
            long originalSize = Files.size(file);

            if (newSize < originalSize) {
                Files.move(tempFile, file, StandardCopyOption.REPLACE_EXISTING);
                return newSize;
            } else {
                Files.deleteIfExists(tempFile);
                return originalSize;
            }
        } catch (IOException e) {
            Files.deleteIfExists(tempFile);
            throw e;
        } finally {
            writer.dispose();
        }
    }

    /**
     * Re-encode PNG to strip metadata, optionally resizing.
     */
    private static long optimizePng(Path file, boolean stripMetadata, int maxWidth) throws IOException {
        BufferedImage image = ImageIO.read(file.toFile());
        if (image == null) {
            log("Warning: Could not read image: " + file.getFileName());
            return Files.size(file);
        }

        image = resizeIfNeeded(image, maxWidth);

        // Re-encode PNG (ImageIO strips non-essential metadata by default)
        Path tempFile = file.resolveSibling(file.getFileName() + ".tmp");
        try {
            ImageIO.write(image, "png", tempFile.toFile());

            long newSize = Files.size(tempFile);
            long originalSize = Files.size(file);

            if (newSize < originalSize) {
                Files.move(tempFile, file, StandardCopyOption.REPLACE_EXISTING);
                return newSize;
            } else {
                Files.deleteIfExists(tempFile);
                return originalSize;
            }
        } catch (IOException e) {
            Files.deleteIfExists(tempFile);
            throw e;
        }
    }

    /**
     * Resize image if it exceeds maxWidth, preserving aspect ratio.
     */
    private static BufferedImage resizeIfNeeded(BufferedImage image, int maxWidth) {
        if (maxWidth <= 0 || image.getWidth() <= maxWidth) {
            return image;
        }

        double scale = (double) maxWidth / image.getWidth();
        int newWidth = maxWidth;
        int newHeight = (int) Math.round(image.getHeight() * scale);

        BufferedImage resized = new BufferedImage(newWidth, newHeight, image.getType() != 0 ? image.getType() : BufferedImage.TYPE_INT_ARGB);
        Graphics2D g = resized.createGraphics();
        g.setRenderingHint(java.awt.RenderingHints.KEY_INTERPOLATION, java.awt.RenderingHints.VALUE_INTERPOLATION_BICUBIC);
        g.setRenderingHint(java.awt.RenderingHints.KEY_RENDERING, java.awt.RenderingHints.VALUE_RENDER_QUALITY);
        g.drawImage(image, 0, 0, newWidth, newHeight, null);
        g.dispose();

        return resized;
    }

    private static void log(String message) {
        if (verbose) {
            System.out.println("[ImageOptimizer] " + message);
        }
    }
}

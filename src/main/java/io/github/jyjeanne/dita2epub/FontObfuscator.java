package io.github.jyjeanne.dita2epub;

import java.io.*;
import java.nio.file.*;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;
import java.util.List;

/**
 * EPUB font obfuscation using the Adobe/IDPF algorithm.
 *
 * Per EPUB OCF 3.3 Section 4.2:
 * 1. Derive a 20-byte key from SHA-1 hash of the unique identifier (stripped of whitespace only)
 * 2. XOR the first 1040 bytes of each font file with the key (cycling every 20 bytes)
 * 3. Record obfuscated fonts in META-INF/encryption.xml
 */
public class FontObfuscator {

    private static final int KEY_SIZE = 20;
    private static final int OBFUSCATION_LENGTH = 1040;
    private static final String OBFUSCATION_ALGORITHM = "http://www.idpf.org/2008/embedding";
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
        System.err.println("Usage: FontObfuscator <outputDir> <fontsDir> <uniqueIdentifier> [--verbose]");
    }

    private static void run(String[] args) throws Exception {
        if (args.length < 3) {
            throw new IllegalArgumentException("Not enough arguments. Expected at least 3, got " + args.length);
        }

        String outputDir = args[0];
        String fontsDir = args[1];
        String uniqueIdentifier = args[2];

        if (args.length > 3 && "--verbose".equals(args[3])) {
            verbose = true;
        }

        Path outputPath = Paths.get(outputDir);
        Path fontsPath = outputPath.resolve(fontsDir);

        if (!Files.isDirectory(fontsPath)) {
            log("No fonts directory found at: " + fontsPath);
            return;
        }

        // Find all font files
        List<Path> fontFiles = new ArrayList<>();
        try (DirectoryStream<Path> stream = Files.newDirectoryStream(fontsPath, "*.{ttf,otf,woff,woff2}")) {
            for (Path entry : stream) {
                fontFiles.add(entry);
            }
        }

        if (fontFiles.isEmpty()) {
            log("No font files found in: " + fontsPath);
            return;
        }

        // Derive the obfuscation key
        byte[] key = deriveKey(uniqueIdentifier);
        log("Derived obfuscation key from identifier: " + uniqueIdentifier);

        // Obfuscate each font file in-place
        List<String> relativeFontPaths = new ArrayList<>();
        for (Path fontFile : fontFiles) {
            obfuscateFont(fontFile, key);
            String relativePath = fontsDir + "/" + fontFile.getFileName().toString();
            relativeFontPaths.add(relativePath);
            log("Obfuscated: " + relativePath);
        }

        // Generate encryption.xml
        Path metaInfDir = outputPath.resolve("META-INF");
        Files.createDirectories(metaInfDir);
        generateEncryptionXml(metaInfDir, relativeFontPaths);

        System.out.println("Font obfuscation complete: " + fontFiles.size() + " font(s) processed.");
    }

    /**
     * Derive a 20-byte obfuscation key from the unique identifier.
     * Per EPUB 3.3 section 4.4.3: remove all whitespace, then SHA-1 hash.
     */
    static byte[] deriveKey(String identifier) throws NoSuchAlgorithmException {
        // Only the XML whitespace code points U+0020, U+0009, U+000D and U+000A are removed.
        // Hyphens and every other character stay: removing them would give reading systems a
        // different key, and they would de-obfuscate the fonts into garbage.
        // The full identifier (including any urn:uuid: scheme) is used.
        String cleaned = identifier.replaceAll("[\\u0020\\u0009\\u000D\\u000A]", "");

        MessageDigest sha1 = MessageDigest.getInstance("SHA-1");
        byte[] hash = sha1.digest(cleaned.getBytes(java.nio.charset.StandardCharsets.UTF_8));

        // SHA-1 produces exactly 20 bytes
        return hash;
    }

    /**
     * Obfuscate a font file in-place by XORing the first 1040 bytes with the key.
     */
    static void obfuscateFont(Path fontFile, byte[] key) throws IOException {
        byte[] data = Files.readAllBytes(fontFile);

        int limit = Math.min(OBFUSCATION_LENGTH, data.length);
        for (int i = 0; i < limit; i++) {
            data[i] ^= key[i % KEY_SIZE];
        }

        Files.write(fontFile, data);
    }

    /**
     * Generate META-INF/encryption.xml listing all obfuscated fonts.
     */
    static void generateEncryptionXml(Path metaInfDir, List<String> fontPaths) throws IOException {
        StringBuilder xml = new StringBuilder();
        xml.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
        xml.append("<encryption xmlns=\"urn:oasis:names:tc:opendocument:xmlns:container\"\n");
        xml.append("            xmlns:enc=\"http://www.w3.org/2001/04/xmlenc#\">\n");

        for (String fontPath : fontPaths) {
            xml.append("  <enc:EncryptedData>\n");
            xml.append("    <enc:EncryptionMethod Algorithm=\"").append(OBFUSCATION_ALGORITHM).append("\"/>\n");
            xml.append("    <enc:CipherData>\n");
            xml.append("      <enc:CipherReference URI=\"").append(escapeXml(fontPath)).append("\"/>\n");
            xml.append("    </enc:CipherData>\n");
            xml.append("  </enc:EncryptedData>\n");
        }

        xml.append("</encryption>\n");

        Path encryptionFile = metaInfDir.resolve("encryption.xml");
        Files.write(encryptionFile, xml.toString().getBytes(java.nio.charset.StandardCharsets.UTF_8));
        log("Generated: " + encryptionFile);
    }

    private static String escapeXml(String value) {
        return value.replace("&", "&amp;").replace("\"", "&quot;").replace("<", "&lt;").replace(">", "&gt;");
    }

    private static void log(String message) {
        if (verbose) {
            System.out.println("[FontObfuscator] " + message);
        }
    }
}

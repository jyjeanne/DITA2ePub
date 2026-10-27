package io.github.jyjeanne.dita2epub;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Unit tests for FontObfuscator, against EPUB 3.3 section 4.4 (font obfuscation).
 * A wrong key is invisible to EPUBCheck but makes reading systems de-obfuscate fonts into garbage.
 *
 * @author J. Jeanne
 */
class FontObfuscatorTest {

    private static byte[] sha1(String value) throws Exception {
        return MessageDigest.getInstance("SHA-1").digest(value.getBytes(StandardCharsets.UTF_8));
    }

    @Test
    void testKeyKeepsHyphens() throws Exception {
        // Unique identifiers are almost always hyphenated (UUIDs, ISBNs): only whitespace is removed
        String uuid = "urn:uuid:bea2311a-1730-8bdd-b46e-a9e2f5638b5b";
        assertArrayEquals(sha1(uuid), FontObfuscator.deriveKey(uuid), "Hyphens must be part of the key");

        String isbn = "978-0-13-468599-1";
        assertArrayEquals(sha1(isbn), FontObfuscator.deriveKey(isbn), "Hyphens must be part of the key");
    }

    @Test
    void testKeyRemovesXmlWhitespace() throws Exception {
        // U+0020, U+0009, U+000D and U+000A, wherever they occur
        assertArrayEquals(sha1("urn:isbn:9780134685991"),
                FontObfuscator.deriveKey(" urn:isbn:\t978013 4685991\r\n"),
                "Space, tab, carriage return and line feed must be removed");
    }

    @Test
    void testObfuscationXorsFirst1040BytesOnly(@TempDir Path tempDir) throws Exception {
        byte[] original = new byte[2000];
        for (int i = 0; i < original.length; i++) {
            original[i] = (byte) (i % 251);
        }
        Path font = tempDir.resolve("test.ttf");
        Files.write(font, original);
        byte[] key = FontObfuscator.deriveKey("urn:uuid:bea2311a-1730-8bdd-b46e-a9e2f5638b5b");

        FontObfuscator.obfuscateFont(font, key);
        byte[] obfuscated = Files.readAllBytes(font);
        for (int i = 0; i < 1040; i++) {
            assertEquals((byte) (original[i] ^ key[i % 20]), obfuscated[i], "Byte " + i + " should be XORed with the key");
        }
        for (int i = 1040; i < original.length; i++) {
            assertEquals(original[i], obfuscated[i], "Byte " + i + " should be unchanged");
        }

        // The algorithm is its own inverse: applying it again restores the font
        FontObfuscator.obfuscateFont(font, key);
        assertArrayEquals(original, Files.readAllBytes(font), "Obfuscating twice should restore the font");
    }

    @Test
    void testEncryptionXmlDeclaresObfuscatedFonts(@TempDir Path tempDir) throws Exception {
        FontObfuscator.generateEncryptionXml(tempDir, List.of("fonts/Body-Regular.ttf"));
        String xml = Files.readString(tempDir.resolve("encryption.xml"));

        assertTrue(xml.contains("Algorithm=\"http://www.idpf.org/2008/embedding\""), "Should use the IDPF obfuscation algorithm");
        assertTrue(xml.contains("URI=\"fonts/Body-Regular.ttf\""), "Should reference the font path within the container");
        assertFalse(xml.contains("KeyInfo"), "The key must not be stored in encryption.xml");
    }
}

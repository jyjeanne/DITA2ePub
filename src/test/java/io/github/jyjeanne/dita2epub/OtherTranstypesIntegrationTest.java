package io.github.jyjeanne.dita2epub;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIf;
import org.junit.jupiter.api.io.TempDir;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

/**
 * The plugin must leave the other transformation types alone. Its epub3.init target used to be
 * hooked into every preprocessing (depend.preprocess.post), so an HTML5 build installed next to
 * the plugin ran it, and got empty META-INF, content, fonts, images and styles folders.
 * Requires DITA-OT with the plugin installed (DITA_HOME), like the other integration tests.
 */
class OtherTranstypesIntegrationTest {

    @Test
    @EnabledIf("io.github.jyjeanne.dita2epub.EpubGenerationIntegrationTest#isDitaOtAvailable")
    void testHtml5BuildDoesNotRunTheEpubInitialization(@TempDir Path tempDir) throws IOException, InterruptedException {
        File ditamapFile = Paths.get("src/test/resources/dita/sample-bookmap.ditamap").toFile();
        assertTrue(ditamapFile.exists(), "Sample bookmap should exist");
        File outputDir = tempDir.resolve("html5-output").toFile();

        List<String> command = List.of(
            EpubGenerationIntegrationTest.ditaCommand(),
            "--input=" + ditamapFile.getAbsolutePath(),
            "--format=html5",
            "--output=" + outputDir.getAbsolutePath());
        Process process = new ProcessBuilder(command).redirectErrorStream(true).start();

        StringBuilder output = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(process.getInputStream(), StandardCharsets.UTF_8))) {
            String line;
            while ((line = reader.readLine()) != null) {
                output.append(line).append('\n');
            }
        }
        int exitCode = process.waitFor();
        assertEquals(0, exitCode, () -> "The HTML5 build should succeed:\n" + output);

        assertTrue(new File(outputDir, "index.html").isFile(), "The HTML5 build should write index.html");
        assertFalse(output.toString().contains("Initializing EPUB3 transformation"),
            "An HTML5 build must not run epub3.init");
        for (String folder : List.of("META-INF", "content", "fonts", "styles")) {
            assertFalse(new File(outputDir, folder).exists(),
                "An HTML5 build must not create the EPUB folder " + folder);
        }
    }
}

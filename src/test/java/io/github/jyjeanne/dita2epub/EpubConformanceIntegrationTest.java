package io.github.jyjeanne.dita2epub;

import com.adobe.epubcheck.api.EpubCheck;
import com.adobe.epubcheck.util.DefaultReportImpl;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIf;
import org.junit.jupiter.api.io.TempDir;

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

import static org.junit.jupiter.api.Assertions.*;

/**
 * EPUB 3.3 conformance on inputs the other datasets never exercise (src/test/resources/dita-edge-cases):
 * topic file names that differ only in case, a file name with a space, a remote image, and a topichead
 * cut by the TOC depth. The EPUB is checked with EPUBCheck itself, plus the OCF file name rules.
 * Requires DITA-OT (see EpubGenerationIntegrationTest).
 *
 * @author J. Jeanne
 */
class EpubConformanceIntegrationTest {

    @Test
    @EnabledIf("io.github.jyjeanne.dita2epub.EpubGenerationIntegrationTest#isDitaOtAvailable")
    void testEdgeCasesPassEpubCheck(@TempDir Path tempDir) throws IOException, InterruptedException {
        File ditamapFile = Paths.get("src/test/resources/dita-edge-cases/edge-cases.ditamap").toFile();
        assertTrue(ditamapFile.exists(), "Edge-case map should exist");

        File outputDir = tempDir.resolve("epub-edge-cases").toFile();
        outputDir.mkdirs();

        List<String> command = new ArrayList<>();
        command.add(EpubGenerationIntegrationTest.ditaCommand());
        command.add("--input=" + ditamapFile.getAbsolutePath());
        command.add("--format=epub3");
        command.add("--output=" + outputDir.getAbsolutePath());
        command.add("-Depub.toc.depth=1");
        command.add("-Depub.generate.index=yes");

        System.out.println("Running DITA-OT command: " + String.join(" ", command));
        Process process = new ProcessBuilder(command).redirectErrorStream(true).start();
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
            String line;
            while ((line = reader.readLine()) != null) {
                System.out.println(line);
            }
        }
        assertEquals(0, process.waitFor(), "DITA-OT transformation should succeed");

        File[] epubFiles = outputDir.listFiles((dir, name) -> name.endsWith(".epub"));
        assertNotNull(epubFiles, "Output directory should contain files");
        assertEquals(1, epubFiles.length, "One EPUB file should be generated");
        File epubFile = epubFiles[0];

        // EPUBCheck: invalid manifest ids, a nav heading without its list or a missing
        // (remote) image would all be reported as errors
        DefaultReportImpl report = new DefaultReportImpl(epubFile.getName());
        new EpubCheck(epubFile, report).doValidate();
        assertEquals(0, report.getFatalErrorCount(), "EPUBCheck fatal errors");
        assertEquals(0, report.getErrorCount(), "EPUBCheck errors");
        assertEquals(0, report.getWarningCount(), "EPUBCheck warnings");

        try (ZipFile zip = new ZipFile(epubFile)) {
            List<String> names = zip.stream().map(ZipEntry::getName).toList();

            // File names must be unique after case folding, and should not contain spaces (EPUB 3.3, 4.2.3)
            assertEquals(names.size(), names.stream().map(name -> name.toLowerCase(Locale.ROOT)).distinct().count(),
                    "File names should be unique after case folding: " + names);
            assertTrue(names.stream().noneMatch(name -> name.contains(" ")), "File names should not contain spaces: " + names);
            assertTrue(names.contains("content/index.xhtml"), "The generated index should keep its name");

            // The remote image becomes a link, not a reference to a missing local file (EPUB 3.3, 3.6)
            String topic = readEntry(zip, "content/My-Topic.xhtml");
            assertTrue(topic.contains("href=\"https://www.w3.org/assets/logos/w3c-2025/svg/w3c.svg\""),
                    "The remote image should be linked");
            assertFalse(topic.contains("<img"), "The remote image should not be embedded");
        }
    }

    private static String readEntry(ZipFile zip, String name) throws IOException {
        ZipEntry entry = zip.getEntry(name);
        assertNotNull(entry, name + " should exist");
        try (InputStream in = zip.getInputStream(entry)) {
            return new String(in.readAllBytes(), StandardCharsets.UTF_8);
        }
    }
}

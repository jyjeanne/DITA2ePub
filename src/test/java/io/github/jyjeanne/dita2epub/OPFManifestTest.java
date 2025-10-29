package io.github.jyjeanne.dita2epub;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.junit.jupiter.api.condition.EnabledIf;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;
import org.xml.sax.SAXException;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;

import static org.junit.jupiter.api.Assertions.*;

/**
 * Tests for OPF manifest generation.
 * Validates the content.opf file structure and entries.
 *
 * @author J. Jeanne
 * @version 1.0.1
 */
class OPFManifestTest {

    static boolean isDitaOtAvailable() {
        return EpubGenerationIntegrationTest.isDitaOtAvailable();
    }

    @Test
    @EnabledIf("isDitaOtAvailable")
    void testOPFStructure(@TempDir Path tempDir) throws Exception {
        File epubFile = generateBasicEpub(tempDir);
        Document opfDoc = getOPFDocument(epubFile);

        // Verify root element
        Element packageElement = opfDoc.getDocumentElement();
        assertEquals("package", packageElement.getLocalName());
        assertEquals("http://www.idpf.org/2007/opf", packageElement.getNamespaceURI());

        // Verify required attributes
        assertTrue(packageElement.hasAttribute("version"));
        assertTrue(packageElement.hasAttribute("unique-identifier"));

        // Verify required sections
        assertNotNull(getFirstElementByTagName(opfDoc, "metadata"));
        assertNotNull(getFirstElementByTagName(opfDoc, "manifest"));
        assertNotNull(getFirstElementByTagName(opfDoc, "spine"));
    }

    @Test
    @EnabledIf("isDitaOtAvailable")
    void testMetadataSection(@TempDir Path tempDir) throws Exception {
        File epubFile = generateBasicEpub(tempDir);
        Document opfDoc = getOPFDocument(epubFile);

        Element metadata = getFirstElementByTagName(opfDoc, "metadata");
        assertNotNull(metadata);

        // Verify required Dublin Core metadata
        assertHasElement(metadata, "dc:title");
        assertHasElement(metadata, "dc:language");
        assertHasElement(metadata, "dc:identifier");
        assertHasElement(metadata, "dc:date");

        // Verify accessibility metadata
        assertTrue(containsMetaProperty(metadata, "schema:accessMode"));
        assertTrue(containsMetaProperty(metadata, "schema:accessibilityFeature"));
    }

    @Test
    @EnabledIf("isDitaOtAvailable")
    void testManifestContainsRequiredItems(@TempDir Path tempDir) throws Exception {
        File epubFile = generateBasicEpub(tempDir);
        Document opfDoc = getOPFDocument(epubFile);

        Element manifest = getFirstElementByTagName(opfDoc, "manifest");
        assertNotNull(manifest);

        NodeList items = manifest.getElementsByTagName("item");
        assertTrue(items.getLength() > 0, "Manifest should contain items");

        // Verify required items
        assertTrue(hasManifestItem(manifest, "nav"), "Manifest should have navigation document");
        assertTrue(hasManifestItemWithProperties(manifest, "nav"), "Nav item should have nav property");

        // Verify CSS item
        assertTrue(hasManifestItem(manifest, "css-main"), "Manifest should have CSS file");
    }

    @Test
    @EnabledIf("isDitaOtAvailable")
    void testSpineStructure(@TempDir Path tempDir) throws Exception {
        File epubFile = generateBasicEpub(tempDir);
        Document opfDoc = getOPFDocument(epubFile);

        Element spine = getFirstElementByTagName(opfDoc, "spine");
        assertNotNull(spine);

        NodeList itemrefs = spine.getElementsByTagName("itemref");
        assertTrue(itemrefs.getLength() > 0, "Spine should contain itemrefs");

        // Verify all itemrefs have idref attribute
        for (int i = 0; i < itemrefs.getLength(); i++) {
            Element itemref = (Element) itemrefs.item(i);
            assertTrue(itemref.hasAttribute("idref"),
                "Itemref should have idref attribute");
        }
    }

    @Test
    @EnabledIf("isDitaOtAvailable")
    void testManifestAndSpineConsistency(@TempDir Path tempDir) throws Exception {
        File epubFile = generateBasicEpub(tempDir);
        Document opfDoc = getOPFDocument(epubFile);

        Element manifest = getFirstElementByTagName(opfDoc, "manifest");
        Element spine = getFirstElementByTagName(opfDoc, "spine");

        NodeList manifestItems = manifest.getElementsByTagName("item");
        NodeList spineItemrefs = spine.getElementsByTagName("itemref");

        // Get all manifest IDs
        List<String> manifestIds = new ArrayList<>();
        for (int i = 0; i < manifestItems.getLength(); i++) {
            Element item = (Element) manifestItems.item(i);
            manifestIds.add(item.getAttribute("id"));
        }

        // Verify all spine itemrefs reference valid manifest items
        for (int i = 0; i < spineItemrefs.getLength(); i++) {
            Element itemref = (Element) spineItemrefs.item(i);
            String idref = itemref.getAttribute("idref");
            assertTrue(manifestIds.contains(idref),
                "Spine itemref '" + idref + "' should reference a manifest item");
        }
    }

    @Test
    @EnabledIf("isDitaOtAvailable")
    void testCoverImageInManifest(@TempDir Path tempDir) throws Exception {
        File epubFile = generateEpubWithCover(tempDir);
        Document opfDoc = getOPFDocument(epubFile);

        Element manifest = getFirstElementByTagName(opfDoc, "manifest");

        // Verify cover image item
        assertTrue(hasManifestItem(manifest, "cover-image"),
            "Manifest should have cover-image item");

        Element coverImage = getManifestItem(manifest, "cover-image");
        assertNotNull(coverImage);

        String properties = coverImage.getAttribute("properties");
        assertEquals("cover-image", properties,
            "Cover image should have 'cover-image' property");

        String mediaType = coverImage.getAttribute("media-type");
        assertTrue(mediaType.startsWith("image/"),
            "Cover image should have image media type");
    }

    @Test
    @EnabledIf("isDitaOtAvailable")
    void testAllManifestItemsHaveRequiredAttributes(@TempDir Path tempDir) throws Exception {
        File epubFile = generateBasicEpub(tempDir);
        Document opfDoc = getOPFDocument(epubFile);

        Element manifest = getFirstElementByTagName(opfDoc, "manifest");
        NodeList items = manifest.getElementsByTagName("item");

        for (int i = 0; i < items.getLength(); i++) {
            Element item = (Element) items.item(i);

            assertTrue(item.hasAttribute("id"), "Item should have id attribute");
            assertTrue(item.hasAttribute("href"), "Item should have href attribute");
            assertTrue(item.hasAttribute("media-type"), "Item should have media-type attribute");

            // Verify id is not empty
            assertFalse(item.getAttribute("id").trim().isEmpty(),
                "Item id should not be empty");
            // Verify href is not empty
            assertFalse(item.getAttribute("href").trim().isEmpty(),
                "Item href should not be empty");
            // Verify media-type is not empty
            assertFalse(item.getAttribute("media-type").trim().isEmpty(),
                "Item media-type should not be empty");
        }
    }

    @Test
    @EnabledIf("isDitaOtAvailable")
    void testTopicItemsInManifest(@TempDir Path tempDir) throws Exception {
        File epubFile = generateBasicEpub(tempDir);
        Document opfDoc = getOPFDocument(epubFile);

        Element manifest = getFirstElementByTagName(opfDoc, "manifest");

        // Sample bookmap has 9 topics
        String[] expectedTopics = {"preface", "chapter1", "chapter2", "appendix", "glossary"};

        for (String topicId : expectedTopics) {
            assertTrue(hasManifestItem(manifest, topicId),
                "Manifest should contain topic: " + topicId);

            Element topic = getManifestItem(manifest, topicId);
            String href = topic.getAttribute("href");
            assertTrue(href.endsWith(".xhtml"),
                "Topic href should end with .xhtml: " + href);

            String mediaType = topic.getAttribute("media-type");
            assertEquals("application/xhtml+xml", mediaType,
                "Topic should have XHTML media type");
        }
    }

    // Helper methods

    private File generateBasicEpub(Path tempDir) throws IOException, InterruptedException {
        return generateEpub(tempDir, false);
    }

    private File generateEpubWithCover(Path tempDir) throws IOException, InterruptedException {
        return generateEpub(tempDir, true);
    }

    private File generateEpub(Path tempDir, boolean withCover)
            throws IOException, InterruptedException {
        Path testResourcesPath = Paths.get("src/test/resources/dita");
        File ditamapFile = testResourcesPath.resolve("sample-bookmap.ditamap").toFile();

        File outputDir = tempDir.resolve("epub-opf-test").toFile();
        outputDir.mkdirs();

        List<String> command = new ArrayList<>();
        command.add("dita");
        command.add("--input=" + ditamapFile.getAbsolutePath());
        command.add("--format=epub3");
        command.add("--output=" + outputDir.getAbsolutePath());

        if (withCover) {
            File coverFile = testResourcesPath.resolve("cover.svg").toFile();
            command.add("-Depub.cover.image=" + coverFile.getAbsolutePath());
        }

        ProcessBuilder processBuilder = new ProcessBuilder(command);
        processBuilder.redirectErrorStream(true);
        Process process = processBuilder.start();

        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(process.getInputStream()))) {
            reader.lines().forEach(System.out::println);
        }

        assertEquals(0, process.waitFor());

        File[] epubFiles = outputDir.listFiles((dir, name) -> name.endsWith(".epub"));
        return (epubFiles != null && epubFiles.length > 0) ? epubFiles[0] : null;
    }

    private Document getOPFDocument(File epubFile)
            throws IOException, ParserConfigurationException, SAXException {
        try (ZipFile zipFile = new ZipFile(epubFile)) {
            ZipEntry opfEntry = zipFile.getEntry("content/content.opf");
            assertNotNull(opfEntry, "content.opf should exist in EPUB");

            byte[] opfBytes = zipFile.getInputStream(opfEntry).readAllBytes();

            DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
            factory.setNamespaceAware(true);
            DocumentBuilder builder = factory.newDocumentBuilder();

            return builder.parse(new ByteArrayInputStream(opfBytes));
        }
    }

    private Element getFirstElementByTagName(Document doc, String tagName) {
        NodeList nodes = doc.getElementsByTagNameNS("*", tagName);
        return nodes.getLength() > 0 ? (Element) nodes.item(0) : null;
    }

    private void assertHasElement(Element parent, String tagName) {
        NodeList nodes = parent.getElementsByTagName(tagName);
        assertTrue(nodes.getLength() > 0, "Should have element: " + tagName);
    }

    private boolean containsMetaProperty(Element metadata, String property) {
        NodeList metas = metadata.getElementsByTagName("meta");
        for (int i = 0; i < metas.getLength(); i++) {
            Element meta = (Element) metas.item(i);
            if (property.equals(meta.getAttribute("property"))) {
                return true;
            }
        }
        return false;
    }

    private boolean hasManifestItem(Element manifest, String id) {
        return getManifestItem(manifest, id) != null;
    }

    private Element getManifestItem(Element manifest, String id) {
        NodeList items = manifest.getElementsByTagName("item");
        for (int i = 0; i < items.getLength(); i++) {
            Element item = (Element) items.item(i);
            if (id.equals(item.getAttribute("id"))) {
                return item;
            }
        }
        return null;
    }

    private boolean hasManifestItemWithProperties(Element manifest, String properties) {
        NodeList items = manifest.getElementsByTagName("item");
        for (int i = 0; i < items.getLength(); i++) {
            Element item = (Element) items.item(i);
            if (properties.equals(item.getAttribute("properties"))) {
                return true;
            }
        }
        return false;
    }
}

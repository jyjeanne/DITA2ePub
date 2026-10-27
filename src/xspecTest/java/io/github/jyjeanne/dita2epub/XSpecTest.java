package io.github.jyjeanne.dita2epub;

import net.sf.saxon.s9api.DocumentBuilder;
import net.sf.saxon.s9api.Processor;
import net.sf.saxon.s9api.QName;
import net.sf.saxon.s9api.SaxonApiException;
import net.sf.saxon.s9api.Serializer;
import net.sf.saxon.s9api.XPathCompiler;
import net.sf.saxon.s9api.XdmAtomicValue;
import net.sf.saxon.s9api.XdmDestination;
import net.sf.saxon.s9api.XdmItem;
import net.sf.saxon.s9api.XdmNode;
import net.sf.saxon.s9api.XdmNodeKind;
import net.sf.saxon.s9api.XsltExecutable;
import net.sf.saxon.s9api.Xslt30Transformer;
import org.junit.jupiter.api.DynamicNode;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestFactory;
import org.opentest4j.AssertionFailedError;
import org.opentest4j.TestAbortedException;

import javax.xml.transform.stream.StreamSource;
import java.io.IOException;
import java.io.StringWriter;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Stream;

import static org.assertj.core.api.Assertions.assertThat;
import static org.junit.jupiter.api.DynamicContainer.dynamicContainer;
import static org.junit.jupiter.api.DynamicTest.dynamicTest;

/**
 * Runs the XSpec tests of the XSLT modules (src/test/xspec/*.xspec) with Saxon-HE, as DITA-OT does.
 * Each XSpec expectation becomes a JUnit test, grouped by XSpec file and scenario, and the XSpec HTML
 * report of each file is written to build/reports/xspec.
 */
class XSpecTest {

    private static final String XSPEC_NS = "http://www.jenitennison.com/xslt/xspec";
    private static final String XSL_NS = "http://www.w3.org/1999/XSL/Transform";

    private static final Path XSPEC_HOME = Path.of(System.getProperty("xspec.home", "build/xspec/src"));
    private static final Path TESTS_DIR = Path.of(System.getProperty("xspec.tests", "src/test/xspec"));
    private static final Path REPORTS_DIR = Path.of(System.getProperty("xspec.reports", "build/reports/xspec"));
    private static final Path WORK_DIR = Path.of(System.getProperty("xspec.work", "build/tmp/xspecTest"));
    private static final Path MAIN_STYLESHEET = Path.of("src/main/xsl/map2epub3.xsl");
    private static final Path TESTED_STYLESHEET = TESTS_DIR.resolve("epub3-modules.xsl");

    private final Processor processor = new Processor(false);

    @TestFactory
    Stream<DynamicNode> xspec() throws IOException, SaxonApiException {
        List<Path> xspecFiles;
        try (Stream<Path> files = Files.list(TESTS_DIR)) {
            xspecFiles = files.filter(file -> file.getFileName().toString().endsWith(".xspec")).sorted().toList();
        }
        assertThat(xspecFiles).as("XSpec files in %s", TESTS_DIR).isNotEmpty();
        Files.createDirectories(REPORTS_DIR);
        Files.createDirectories(WORK_DIR);
        XsltExecutable xspecCompiler = compile(XSPEC_HOME.resolve("compiler/compile-xslt-tests.xsl"));
        XsltExecutable reportFormatter = compile(XSPEC_HOME.resolve("reporter/format-xspec-report.xsl"));
        return xspecFiles.stream().map(file -> run(file, xspecCompiler, reportFormatter));
    }

    /** The tested stylesheet must stay the plugin as map2epub3.xsl assembles it */
    @Test
    void testedStylesheetIncludesTheModulesOfTheMainStylesheet() throws SaxonApiException {
        assertThat(includedModules(TESTED_STYLESHEET)).isNotEmpty().isEqualTo(includedModules(MAIN_STYLESHEET));
    }

    private DynamicNode run(Path xspecFile, XsltExecutable xspecCompiler, XsltExecutable reportFormatter) {
        String name = xspecFile.getFileName().toString();
        String baseName = name.replaceFirst("\\.xspec$", "");
        Path htmlReport = REPORTS_DIR.resolve(baseName + "-result.html");
        try {
            // The XSpec file becomes a stylesheet that runs its scenarios against the tested stylesheet
            Path compiled = WORK_DIR.resolve(baseName + "-compiled.xsl");
            xspecCompiler.load30().transform(new StreamSource(xspecFile.toFile()), serializer(compiled));

            XdmDestination result = new XdmDestination();
            compile(compiled).load30().callTemplate(new QName(XSPEC_NS, "main"), result);
            XdmNode report = result.getXdmNode();
            processor.writeXdmValue(report, serializer(REPORTS_DIR.resolve(baseName + "-result.xml")));

            Xslt30Transformer formatter = reportFormatter.load30();
            formatter.setStylesheetParameters(Map.of(new QName("inline-css"), new XdmAtomicValue("true")));
            formatter.transform(report.asSource(), serializer(htmlReport));

            XdmNode reportElement = report.children().iterator().next();
            return dynamicContainer(name, xspecFile.toUri(), nodes(reportElement, htmlReport).stream());
        } catch (SaxonApiException | RuntimeException e) {
            return dynamicTest(name, xspecFile.toUri(), () -> {
                throw new AssertionFailedError("XSpec run of " + name + " failed: " + e.getMessage(), e);
            });
        }
    }

    /** JUnit containers for the scenarios of a report element, and tests for its expectations */
    private List<DynamicNode> nodes(XdmNode parent, Path htmlReport) {
        List<DynamicNode> nodes = new ArrayList<>();
        for (XdmNode child : parent.children()) {
            if (isXSpec(child, "scenario")) {
                nodes.add(dynamicContainer(label(child), nodes(child, htmlReport).stream()));
            } else if (isXSpec(child, "test")) {
                nodes.add(test(child, parent, htmlReport));
            }
        }
        return nodes;
    }

    private DynamicNode test(XdmNode test, XdmNode scenario, Path htmlReport) {
        String pending = test.getAttributeValue(new QName("pending"));
        boolean successful = "true".equals(test.getAttributeValue(new QName("successful")));
        String details = String.join("\n",
            "Expected:", serialize(firstChild(test, "expect")),
            "Result:", serialize(firstChild(scenario, "result")),
            "Report: " + htmlReport.toUri());
        // Labels are written to read as a sentence: "<scenario> <expectation>"
        String sentence = label(scenario) + " " + label(test);
        return dynamicTest(sentence, () -> {
            if (pending != null) {
                throw new TestAbortedException("Pending: " + pending);
            }
            if (!successful) {
                throw new AssertionFailedError(sentence + "\n" + details);
            }
        });
    }

    private List<String> includedModules(Path stylesheet) throws SaxonApiException {
        DocumentBuilder builder = processor.newDocumentBuilder();
        XPathCompiler xpath = processor.newXPathCompiler();
        xpath.declareNamespace("xsl", XSL_NS);
        return xpath.evaluate("/*/xsl:include/@href ! tokenize(., '/')[last()]",
                builder.build(stylesheet.toFile()))
            .stream().map(XdmItem::getStringValue).toList();
    }

    private XsltExecutable compile(Path stylesheet) throws SaxonApiException {
        return processor.newXsltCompiler().compile(new StreamSource(stylesheet.toFile()));
    }

    private Serializer serializer(Path file) {
        Serializer serializer = processor.newSerializer(file.toFile());
        serializer.setOutputProperty(Serializer.Property.INDENT, "yes");
        return serializer;
    }

    private static boolean isXSpec(XdmNode node, String localName) {
        return node.getNodeKind() == XdmNodeKind.ELEMENT
            && node.getNodeName().getNamespace().equals(XSPEC_NS)
            && node.getNodeName().getLocalName().equals(localName);
    }

    private static XdmNode firstChild(XdmNode parent, String localName) {
        for (XdmNode child : parent.children()) {
            if (isXSpec(child, localName)) {
                return child;
            }
        }
        return null;
    }

    private static String label(XdmNode node) {
        XdmNode label = firstChild(node, "label");
        return label == null ? "(no label)" : label.getStringValue().strip().replaceAll("\\s+", " ");
    }

    private String serialize(XdmNode node) {
        if (node == null) {
            return "(none)";
        }
        StringWriter text = new StringWriter();
        Serializer serializer = processor.newSerializer(text);
        serializer.setOutputProperty(Serializer.Property.OMIT_XML_DECLARATION, "yes");
        serializer.setOutputProperty(Serializer.Property.INDENT, "yes");
        try {
            serializer.serializeNode(node);
        } catch (SaxonApiException e) {
            return "(not serializable: " + e.getMessage() + ")";
        }
        return text.toString();
    }
}

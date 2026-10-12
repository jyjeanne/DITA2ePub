plugins {
    id("io.github.jyjeanne.dita-ot-gradle") version "2.8.5"
    id("java")
}

// DITA-OT version configuration
val ditaOtVersion = "4.4.1"
val ditaOtHome = layout.buildDirectory.dir("dita-ot/dita-ot-$ditaOtVersion")

group = "io.github.jyjeanne"
version = "1.5.0"

// =============================================================================
// Shared EPUB properties (common to all EPUB builds)
// =============================================================================
val sharedEpubProperties = mapOf(
    "epub.version" to "3.3",
    "epub.topics.dir" to "content",
    "epub.images.dir" to "images",
    "epub.fonts.dir" to "fonts",
    "epub.css.dir" to "styles",
    "epub.accessibility" to "wcag-aa",
    "epub.aria.landmarks" to "yes",
    "args.css" to "epub-default.css",
    "args.copycss" to "yes",
)

// =============================================================================
// Test datasets configuration
// =============================================================================
// Each dataset defines a DITA source and its expected EPUB output characteristics
data class TestDataset(
    val name: String,
    val ditamap: String,
    val outputDir: String,
    val coverImage: String?,
    val language: String = "en",
    val tocDepth: Int = 5,
    val description: String = ""
)

val testDatasets = listOf(
    TestDataset(
        name = "sample",
        ditamap = "src/test/resources/dita/sample-bookmap.ditamap",
        outputDir = "build/epub",
        coverImage = "src/test/resources/dita/cover.svg",
        language = "en",
        tocDepth = 5,
        description = "Complete English bookmap with all EPUB features"
    ),
    TestDataset(
        name = "kdp-commercial",
        ditamap = "src/test/resources/dita-kdp/kdp-commercial-bookmap.ditamap",
        outputDir = "build/epub-kdp",
        coverImage = "src/test/resources/dita-kdp/cover-kdp.svg",
        language = "en-US",
        tocDepth = 3,
        description = "Commercial fiction novel for Amazon KDP with full metadata"
    )
)

repositories {
    mavenCentral()
    gradlePluginPortal()
}

java {
    sourceCompatibility = JavaVersion.VERSION_17
    targetCompatibility = JavaVersion.VERSION_17
}

dependencies {
    // EPUB validation
    implementation("org.w3c:epubcheck:5.3.0")

    // Utilities
    implementation("commons-io:commons-io:2.15.1")

    // Logging
    implementation("org.slf4j:slf4j-api:2.0.9")
    implementation("ch.qos.logback:logback-classic:1.4.14")

    // Testing
    testImplementation("org.junit.jupiter:junit-jupiter:5.10.0")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
    testImplementation("org.xmlunit:xmlunit-core:2.9.1")
    testImplementation("org.assertj:assertj-core:3.24.2")
}

tasks.test {
    useJUnitPlatform()
    // Integration tests run the plugin installed in DITA_HOME: track the plugin sources and
    // DITA-OT location so cached results are not reused after XSLT/Ant changes
    inputs.files(fileTree(projectDir) {
        include("plugin.xml", "build-epub3.xml", "src/main/xsl/**", "strings/**")
    }).withPropertyName("pluginSources").withPathSensitivity(PathSensitivity.RELATIVE)
    inputs.property("ditaHome", providers.environmentVariable("DITA_HOME").orElse(""))
    testLogging {
        events("passed", "skipped", "failed")
        showStandardStreams = true
    }
}

tasks.withType<JavaCompile> {
    options.encoding = "UTF-8"
}

// =============================================================================
// DITA-OT download and plugin installation
// =============================================================================

// Download DITA-OT automatically
tasks.register<com.github.jyjeanne.DitaOtDownloadTask>("downloadDitaOt") {
    group = "dita"
    description = "Download DITA-OT from GitHub releases"
    version.set(ditaOtVersion)
    destinationDir.set(layout.buildDirectory.dir("dita-ot"))
    retries.set(3)
}

// Create epub-packager.jar for EPUB-compliant ZIP creation
val epubPackagerJar = tasks.register<Jar>("epubPackagerJar") {
    group = "dita"
    description = "Create epub-packager.jar for EPUB packaging"
    archiveFileName.set("epub-packager.jar")
    destinationDirectory.set(layout.buildDirectory.dir("libs"))
    from(sourceSets.main.get().output) {
        include("io/github/jyjeanne/dita2epub/EpubPackager.class")
        include("io/github/jyjeanne/dita2epub/FontObfuscator.class")
        include("io/github/jyjeanne/dita2epub/ImageOptimizer.class")
    }
    manifest {
        attributes["Main-Class"] = "io.github.jyjeanne.dita2epub.EpubPackager"
    }
    dependsOn("compileJava")
}

// Shared plugin ZIP content configuration
fun Zip.configurePluginContents() {
    dependsOn(epubPackagerJar)
    from(projectDir) {
        include("plugin.xml")
        include("plugin-info.xml")
        include("build-epub3.xml")
        include("src/main/**")
        include("strings/**")
    }
    from(layout.buildDirectory.dir("libs")) {
        include("epub-packager.jar")
        into("lib")
    }
}

// Package the local plugin as a ZIP file for DITA-OT installation
val packagePlugin = tasks.register<Zip>("packagePlugin") {
    group = "dita"
    description = "Package the DITA2ePub plugin as a ZIP file"
    archiveFileName.set("io.github.jyjeanne.dita2epub.zip")
    destinationDirectory.set(layout.buildDirectory.dir("plugin"))
    configurePluginContents()
}

// Package for registry distribution (versioned filename for GitHub Releases)
val distPlugin = tasks.register<Zip>("distPlugin") {
    group = "distribution"
    description = "Package the plugin for DITA-OT registry distribution"
    archiveFileName.set("io.github.jyjeanne.dita2epub-${version}.zip")
    destinationDirectory.set(layout.buildDirectory.dir("dist"))
    configurePluginContents()
}

// Generate SHA-256 checksum for the distribution ZIP
tasks.register("distChecksum") {
    group = "distribution"
    description = "Generate SHA-256 checksum for the distribution ZIP"
    dependsOn(distPlugin)
    doLast {
        val zipFile = layout.buildDirectory.file("dist/io.github.jyjeanne.dita2epub-${version}.zip").get().asFile
        ant.withGroovyBuilder {
            "checksum"("file" to zipFile.absolutePath, "algorithm" to "SHA-256", "forceOverwrite" to "yes")
        }
        val checksumFile = file("${zipFile.absolutePath}.SHA-256")
        if (checksumFile.exists()) {
            val hash = checksumFile.readText().trim()
            println("SHA-256: $hash")
            println("Checksum file: ${checksumFile.absolutePath}")
        }
    }
}

// Install local DITA2ePub plugin to DITA-OT
tasks.register<com.github.jyjeanne.DitaOtInstallPluginTask>("installLocalPlugin") {
    group = "dita"
    description = "Install the local DITA2ePub plugin to DITA-OT"
    dependsOn("downloadDitaOt", packagePlugin)
    ditaOtDir.set(ditaOtHome)
    plugins.set(listOf(layout.buildDirectory.file("plugin/io.github.jyjeanne.dita2epub.zip").get().asFile.absolutePath))
    force.set(true)
}

// =============================================================================
// EPUB build tasks
// =============================================================================

// Build sample EPUB (default dita task)
tasks.named<com.github.jyjeanne.DitaOtTask>("dita") {
    dependsOn("installLocalPlugin")
    ditaOt(ditaOtHome)
    input(file("src/test/resources/dita/sample-bookmap.ditamap"))
    output("build/epub")
    transtype("epub3")

    ditaProperties.putAll(sharedEpubProperties)
    ditaProperties.putAll(mapOf(
        "epub.cover.image" to file("src/test/resources/dita/cover.svg").absolutePath,
        "epub.toc.depth" to "5",
        "epub.nav.depth" to "5",
        "epub.generate.lof" to "auto",
        "epub.generate.lot" to "auto",
        "epub.generate.index" to "auto",
        "epub.generate.glossary" to "auto",
        "epub.copyright.page" to "auto",
        "epub.drop.caps" to "yes",
        "epub.table.zebra" to "yes",
        "epub.figure.numbering" to "global",
        "epub.table.numbering" to "global",
        "epub.skip.nav" to "yes",
        "args.csspath" to "styles",
        "epub.publisher" to "Sample Publisher",
        "epub.rights" to "Copyright 2025-2026 Sample Publisher. All Rights Reserved.",
        "epub.identifier.scheme" to "ISBN",
        "epub.validate" to "yes",
        "args.output.base.name" to "dita-to-epub-handbook",
        "epub.platform" to "generic",
    ))
}

// =============================================================================
// KDP Commercial Book Build (Amazon Kindle Direct Publishing)
// =============================================================================

tasks.register<com.github.jyjeanne.DitaOtTask>("ditaKdp") {
    group = "dita"
    description = "Build KDP-compliant commercial EPUB from fiction novel dataset"
    dependsOn("installLocalPlugin")
    ditaOt(ditaOtHome)
    input(file("src/test/resources/dita-kdp/kdp-commercial-bookmap.ditamap"))
    output("build/epub-kdp")
    transtype("epub3")

    ditaProperties.putAll(sharedEpubProperties)
    ditaProperties.putAll(mapOf(
        "epub.cover.image" to file("src/test/resources/dita-kdp/cover-kdp.svg").absolutePath,
        "epub.toc.depth" to "3",
        "epub.nav.depth" to "3",
        "epub.generate.glossary" to "auto",
        "epub.copyright.page" to "auto",
        "epub.drop.caps" to "yes",
        "epub.table.zebra" to "yes",
        "epub.figure.numbering" to "none",
        "epub.table.numbering" to "none",
        "epub.skip.nav" to "yes",
        "args.csspath" to "styles",
        "epub.publisher" to "Apex Fiction Press",
        "epub.rights" to "Copyright 2026 Sarah Mitchell. All rights reserved.",
        "epub.identifier.scheme" to "ISBN",
        "epub.validate" to "yes",
        "args.output.base.name" to "the-last-algorithm",
        // KDP platform: forces NCX, guide element, emits KDP warnings
        "epub.platform" to "kdp",
        // Fiction theme for novel styling
        "epub.theme" to "fiction",
        // Series metadata
        "epub.series.name" to "Meridian Systems",
        "epub.series.position" to "1",
        // BISAC codes for Amazon category placement
        "epub.bisac.codes" to "FIC028080,FIC031080,FIC028130",
    ))
}

registerEpubValidation("validateEpubKdp", "build/epub-kdp", "ditaKdp")

// =============================================================================
// DITA source validation and link checking
// =============================================================================

// Validate DITA source files before transformation
tasks.register<com.github.jyjeanne.DitaOtValidateTask>("validateDita") {
    group = "verification"
    description = "Validate DITA source files for structural correctness"
    dependsOn("installLocalPlugin")
    ditaOtDir.set(ditaOtHome)
    input("src/test/resources/dita/sample-bookmap.ditamap")
    strictMode.set(true)
}

// Check for broken links in DITA sources
tasks.register<com.github.jyjeanne.DitaLinkCheckTask>("checkLinks") {
    group = "verification"
    description = "Check for broken links in DITA sources"
    input("src/test/resources/dita/sample-bookmap.ditamap")
    failOnBroken.set(true)
    recursive.set(true)
}

// =============================================================================
// EPUB validation (EPUBCheck)
// =============================================================================

fun registerEpubValidation(name: String, epubDir: String, dependsOnTask: String) =
    tasks.register<JavaExec>(name) {
        group = "verification"
        description = "Validate EPUB files in $epubDir using EPUBCheck"
        dependsOn(dependsOnTask)
        mainClass.set("com.adobe.epubcheck.tool.Checker")
        classpath = configurations.runtimeClasspath.get()
        isIgnoreExitValue = true
        doFirst {
            val epubFiles = fileTree(file(epubDir)) { include("**/*.epub") }.files
            if (epubFiles.isEmpty()) throw GradleException("No EPUB files found in $epubDir")
            val epubFile = epubFiles.first()
            println("Validating EPUB: ${epubFile.name}")
            args(epubFile.absolutePath)
        }
    }

registerEpubValidation("validateEpub", "build/epub", "dita")

// =============================================================================
// Workflow tasks
// =============================================================================

tasks.register("buildSampleEpub") {
    group = "dita"
    description = "Build sample EPUB from test DITA content"
    dependsOn("dita")
    finalizedBy("validateEpub")
}

tasks.register("cleanEpub") {
    group = "dita"
    description = "Clean EPUB output directory"
    doLast {
        delete("build/epub")
    }
}

// =============================================================================
// Aggregate tasks
// =============================================================================

tasks.register("buildAllEpubs") {
    group = "dita"
    description = "Build EPUB from all test DITA datasets"
    dependsOn("buildSampleEpub", "ditaKdp")
}

tasks.register("validateAllEpubs") {
    group = "verification"
    description = "Validate all generated EPUB files"
    dependsOn("validateEpub")
}

tasks.register("testAllEpubs") {
    group = "verification"
    description = "Build and validate all test EPUB datasets"
    dependsOn("buildAllEpubs")
    finalizedBy("validateAllEpubs")
}

tasks.register("integrationTest") {
    group = "verification"
    description = "Run integration tests with all DITA datasets"
    dependsOn("testAllEpubs", "test")
}

tasks.register("ciCheck") {
    group = "verification"
    description = "Full CI check: compile, test, build EPUBs, validate"
    dependsOn("compileJava", "compileTestJava", "test", "validateDita", "checkLinks", "testAllEpubs")
}

// List available test datasets
tasks.register("listTestDatasets") {
    group = "help"
    description = "List all available test DITA datasets"
    doLast {
        println("\n" + "=".repeat(70))
        println("Available Test Datasets")
        println("=".repeat(70))
        testDatasets.forEach { dataset ->
            println("\n${dataset.name}:")
            println("  Description: ${dataset.description}")
            println("  DITA Map:    ${dataset.ditamap}")
            println("  Output:      ${dataset.outputDir}")
            println("  Language:    ${dataset.language}")
            println("  TOC Depth:   ${dataset.tocDepth}")
            dataset.coverImage?.let { println("  Cover:       $it") }
        }
        println("\n" + "=".repeat(70))
        println("Run 'gradle buildAllEpubs' to build all datasets")
        println("Run 'gradle testAllEpubs' to build and validate all datasets")
        println("=".repeat(70) + "\n")
    }
}

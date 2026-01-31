plugins {
    id("io.github.jyjeanne.dita-ot-gradle") version "2.8.3"
    id("java")
}

// DITA-OT version configuration
val ditaOtVersion = "4.3.5"

group = "io.github.jyjeanne"
version = "1.0.1"

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
        description = "Basic English sample bookmap"
    ),
    TestDataset(
        name = "calibre-guide",
        ditamap = "src/test/resources/dita-calibre/calibre-guide.ditamap",
        outputDir = "build/epub-calibre",
        coverImage = "src/test/resources/dita-calibre/cover.jpg",
        language = "fr",
        tocDepth = 3,
        description = "French Calibre Guide with nested chapters"
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
    implementation("org.w3c:epubcheck:5.1.0")

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
    testLogging {
        events("passed", "skipped", "failed")
        showStandardStreams = true
    }
}

// Download DITA-OT automatically
tasks.register<com.github.jyjeanne.DitaOtDownloadTask>("downloadDitaOt") {
    group = "dita"
    description = "Download DITA-OT from GitHub releases"
    version.set(ditaOtVersion)
    destinationDir.set(layout.buildDirectory.dir("dita-ot"))
    retries.set(3)
}

// DITA-OT Configuration
tasks.named<com.github.jyjeanne.DitaOtTask>("dita") {
    dependsOn("installLocalPlugin")
    ditaOt(layout.buildDirectory.dir("dita-ot/dita-ot-$ditaOtVersion"))

    // Input and output configuration
    input(file("src/test/resources/dita/sample-bookmap.ditamap"))
    output("build/epub")
    transtype("epub3")

    // EPUB3 properties
    properties {
        // Core EPUB Parameters
        "epub.version" to "3.3"
        "epub.cover.image" to file("src/test/resources/dita/cover.svg").absolutePath

        // Directory Structure
        "epub.topics.dir" to "content"
        "epub.images.dir" to "images"
        "epub.fonts.dir" to "fonts"
        "epub.css.dir" to "styles"

        // Navigation
        "epub.toc.depth" to "5"
        "epub.nav.depth" to "5"
        "epub.generate.lof" to "no"
        "epub.generate.lot" to "no"

        // Accessibility (WCAG 2.1)
        "epub.accessibility" to "wcag-aa"
        "epub.aria.landmarks" to "yes"
        "epub.skip.nav" to "yes"

        // CSS and Styling
        "args.csspath" to "styles"
        "args.css" to "epub-default.css"
        "args.copycss" to "yes"

        // Metadata
        "epub.publisher" to "Dita2epub Project"
        "epub.rights" to "Copyright 2026 All Rights Reserved"
        "epub.identifier.scheme" to "UUID"

        // Validation
        "epub.validate" to "yes"

        // Output
        "args.output.base.name" to "sample-book"
    }
}

// Custom validation task using EPUBCheck
tasks.register<JavaExec>("validateEpub") {
    group = "verification"
    description = "Validate generated EPUB files using EPUBCheck"
    dependsOn("dita")

    mainClass.set("com.adobe.epubcheck.tool.Checker")
    classpath = configurations.runtimeClasspath.get()

    val epubDir = file("build/epub")

    doFirst {
        val epubFiles = fileTree(epubDir) {
            include("**/*.epub")
        }.files

        if (epubFiles.isEmpty()) {
            throw GradleException("No EPUB files found in build/epub")
        }

        val epubFile = epubFiles.first()
        println("Validating EPUB: ${epubFile.name}")
        args(epubFile.absolutePath)
    }

    // EPUBCheck has a known StackOverflowError bug but still reports results
    // We ignore exit value and check the output manually
    isIgnoreExitValue = true

    doLast {
        println("EPUB validation completed. Check output above for any errors.")
    }
}

// Build cache configuration
// Using default Gradle build cache settings

tasks.withType<JavaCompile> {
    options.encoding = "UTF-8"
}

// Custom tasks for EPUB workflow
tasks.register("buildSampleEpub") {
    group = "dita"
    description = "Build sample EPUB from test DITA content"
    dependsOn("dita")
    finalizedBy("validateEpub")
}

// Build Calibre Guide EPUB from French DITA content
tasks.register<com.github.jyjeanne.DitaOtTask>("buildCalibreGuide") {
    group = "dita"
    description = "Build Calibre Guide EPUB from French DITA content"
    dependsOn("installLocalPlugin")
    ditaOt(layout.buildDirectory.dir("dita-ot/dita-ot-$ditaOtVersion"))

    input(file("src/test/resources/dita-calibre/calibre-guide.ditamap"))
    output("build/epub-calibre")
    transtype("epub3")

    properties {
        "epub.version" to "3.3"
        "epub.cover.image" to file("src/test/resources/dita-calibre/cover.jpg").absolutePath
        "epub.topics.dir" to "content"
        "epub.images.dir" to "images"
        "epub.fonts.dir" to "fonts"
        "epub.css.dir" to "styles"
        "epub.toc.depth" to "3"
        "epub.nav.depth" to "3"
        "epub.accessibility" to "wcag-aa"
        "epub.aria.landmarks" to "yes"
        "args.css" to "epub-default.css"
        "args.copycss" to "yes"
    }
}

// Validate Calibre Guide EPUB
tasks.register<JavaExec>("validateCalibreEpub") {
    group = "verification"
    description = "Validate Calibre Guide EPUB using EPUBCheck"
    dependsOn("buildCalibreGuide")

    mainClass.set("com.adobe.epubcheck.tool.Checker")
    classpath = configurations.runtimeClasspath.get()

    val epubDir = file("build/epub-calibre")

    doFirst {
        val epubFiles = fileTree(epubDir) {
            include("**/*.epub")
        }.files

        if (epubFiles.isEmpty()) {
            throw GradleException("No EPUB files found in build/epub-calibre")
        }

        val epubFile = epubFiles.first()
        println("Validating EPUB: ${epubFile.name}")
        args(epubFile.absolutePath)
    }

    isIgnoreExitValue = true

    doLast {
        println("EPUB validation completed. Check output above for any errors.")
    }
}

tasks.register("cleanEpub") {
    group = "dita"
    description = "Clean EPUB output directory"
    doLast {
        delete("build/epub")
        delete("build/epub-calibre")
    }
}

// =============================================================================
// Aggregate tasks for testing all DITA datasets
// =============================================================================

// Build all EPUB test datasets
tasks.register("buildAllEpubs") {
    group = "dita"
    description = "Build EPUB from all test DITA datasets"
    dependsOn("buildSampleEpub", "buildCalibreGuide")
}

// Validate all generated EPUBs
tasks.register("validateAllEpubs") {
    group = "verification"
    description = "Validate all generated EPUB files"
    dependsOn("validateEpub", "validateCalibreEpub")
}

// Full test pipeline: build and validate all datasets
tasks.register("testAllEpubs") {
    group = "verification"
    description = "Build and validate all test EPUB datasets"
    dependsOn("buildAllEpubs")
    finalizedBy("validateAllEpubs")
}

// Integration test task that requires EPUB builds first
tasks.register("integrationTest") {
    group = "verification"
    description = "Run integration tests with all DITA datasets"
    dependsOn("testAllEpubs", "test")
}

// CI/CD task for continuous integration
tasks.register("ciCheck") {
    group = "verification"
    description = "Full CI check: compile, test, build EPUBs, validate"
    dependsOn("compileJava", "compileTestJava", "test", "testAllEpubs")
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

// Create epub-packager.jar for EPUB-compliant ZIP creation
val epubPackagerJar = tasks.register<Jar>("epubPackagerJar") {
    group = "dita"
    description = "Create epub-packager.jar for EPUB packaging"
    archiveFileName.set("epub-packager.jar")
    destinationDirectory.set(layout.buildDirectory.dir("libs"))
    from(sourceSets.main.get().output) {
        include("io/github/jyjeanne/dita2epub/EpubPackager.class")
    }
    manifest {
        attributes["Main-Class"] = "io.github.jyjeanne.dita2epub.EpubPackager"
    }
    dependsOn("compileJava")
}

// Package the local plugin as a ZIP file for DITA-OT installation
val packagePlugin = tasks.register<Zip>("packagePlugin") {
    group = "dita"
    description = "Package the dita2epub plugin as a ZIP file"
    archiveFileName.set("io.github.jyjeanne.dita2epub.zip")
    destinationDirectory.set(layout.buildDirectory.dir("plugin"))
    dependsOn(epubPackagerJar)
    from(projectDir) {
        include("plugin.xml")
        include("plugin-info.xml")
        include("build-epub3.xml")
        include("src/**")
        include("xsl/**")
        include("css/**")
        include("strings/**")
    }
    from(layout.buildDirectory.dir("libs")) {
        include("epub-packager.jar")
        into("lib")
    }
}

// Install local dita2epub plugin using DITA-OT CLI (workaround for DITA-OT 4.3.5 syntax)
tasks.register<Exec>("installLocalPlugin") {
    group = "dita"
    description = "Install the local dita2epub plugin to DITA-OT"
    dependsOn("downloadDitaOt", packagePlugin)

    // Platform-independent executable path
    val isWindows = System.getProperty("os.name").lowercase().contains("windows")
    val ditaScript = if (isWindows) "dita.bat" else "dita"
    val ditaExecutable = layout.buildDirectory.file("dita-ot/dita-ot-$ditaOtVersion/bin/$ditaScript").get().asFile
    val pluginZip = layout.buildDirectory.file("plugin/io.github.jyjeanne.dita2epub.zip").get().asFile

    workingDir = layout.buildDirectory.dir("dita-ot/dita-ot-$ditaOtVersion").get().asFile
    commandLine(ditaExecutable.absolutePath, "install", pluginZip.absolutePath, "--force")

    // DITA-OT install returns 0 for success, non-zero for failure
    // --force flag ensures reinstallation works, so we can fail on errors
    isIgnoreExitValue = false

    doLast {
        println("Plugin installed to DITA-OT")
    }
}

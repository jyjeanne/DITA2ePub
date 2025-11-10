plugins {
    id("io.github.jyjeanne.dita-ot-gradle") version "2.2.0"
    id("java")
}

group = "io.github.jyjeanne"
version = "1.0.1"

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

// DITA-OT Configuration
// Note: Requires DITA-OT to be installed. Set DITA_HOME environment variable or configure ditaOt path below
tasks.named<com.github.jyjeanne.DitaOtTask>("dita") {
    // DITA-OT installation path
    val ditaHome = System.getenv("DITA_HOME") ?: "C:\\dita-ot\\dita-ot-4.3.5"
    ditaOt(file(ditaHome))

    // Input and output configuration
    input(file("src/test/resources/dita/sample-bookmap.ditamap"))
    output("build/epub")
    transtype("epub3")

    // EPUB3 properties
    properties {
        // Core EPUB Parameters
        "epub.version" to "3.3"
        "epub.cover.image" to "images/cover.png"

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
        "epub.rights" to "Copyright 2025 All Rights Reserved"
        "epub.identifier.scheme" to "UUID"

        // Validation
        "epub.validate" to "yes"

        // Output
        "args.output.base.name" to "sample-book"
    }
}

// Custom validation task
tasks.register("validateEpub") {
    group = "verification"
    description = "Validate generated EPUB files using EPUBCheck"

    doLast {
        val epubDir = file("build/epub")
        if (epubDir.exists()) {
            fileTree(epubDir) {
                include("**/*.epub")
            }.forEach { epubFile ->
                println("Validating: ${epubFile.name}")
                // EPUBCheck validation will be implemented in Java class
            }
        } else {
            println("No EPUB files found in build/epub")
        }
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
}

tasks.register("cleanEpub") {
    group = "dita"
    description = "Clean EPUB output directory"
    doLast {
        delete("build/epub")
    }
}

tasks.register("installPlugin") {
    group = "dita"
    description = "Install plugin to local DITA-OT installation"
    doLast {
        val ditaOtHome = System.getenv("DITA_HOME") ?: "C:\\dita-ot\\dita-ot-4.3.5"
        val pluginDir = file("$ditaOtHome/plugins/io.github.jyjeanne.dita2epub")
        println("Installing plugin to: $pluginDir")

        copy {
            from(projectDir) {
                include("plugin.xml")
                include("plugin-info.xml")
                include("build-epub3.xml")
                include("src/**")
                include("strings/**")
            }
            into(pluginDir)
        }

        println("Plugin installed to: $pluginDir")
        println("Next step: Run 'dita install' in the DITA-OT directory to integrate the plugin")
    }
}

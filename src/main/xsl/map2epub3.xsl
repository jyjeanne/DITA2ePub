<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xhtml="http://www.w3.org/1999/xhtml"
                xmlns:epub="http://www.idpf.org/2007/ops"
                xmlns:opf="http://www.idpf.org/2007/opf"
                xmlns:dc="http://purl.org/dc/elements/1.1/"
                xmlns:dita="http://dita-ot.sourceforge.net"
                exclude-result-prefixes="xs xhtml epub opf dc dita"
                version="3.0">

  <!--
    Dita2epub - Modern EPUB3 Transformation Plugin for DITA-OT 4.4

    Main entry point for DITA to EPUB3 transformation

    Copyright 2025 J. Jeanne
    Licensed under Apache License 2.0
  -->

  <!-- Import DITA-OT base HTML5 transformation -->
  <xsl:import href="plugin:org.dita.html5:xsl/dita2html5.xsl"/>

  <!-- Import plugin-specific modules -->
  <xsl:include href="epub3-params.xsl"/>
  <xsl:include href="epub3-common.xsl"/>
  <xsl:include href="epub3-metadata.xsl"/>
  <xsl:include href="epub3-content.xsl"/>
  <xsl:include href="epub3-impl.xsl"/>
  <xsl:include href="epub3-index.xsl"/>
  <xsl:include href="epub3-glossary.xsl"/>
  <xsl:include href="epub3-platform.xsl"/>

  <!-- Output method for XHTML5 (no doctype-system to avoid OPF-073 errors) -->
  <xsl:output method="xhtml"
              encoding="UTF-8"
              indent="yes"
              omit-xml-declaration="no"/>

  <!-- Named output for XML documents (OPF, container.xml) with no DOCTYPE -->
  <xsl:output name="xml-no-doctype"
              method="xml"
              encoding="UTF-8"
              indent="yes"
              omit-xml-declaration="no"/>

  <!-- Root template -->
  <xsl:template match="/">
    <xsl:message>
      <xsl:text>Dita2epub v2.0.0 - Starting EPUB3 transformation</xsl:text>
    </xsl:message>
    <xsl:message>
      <xsl:text>DITA-OT Version: </xsl:text>
      <xsl:value-of select="$dita.ot.version"/>
    </xsl:message>
    <xsl:message>
      <xsl:text>EPUB Version: </xsl:text>
      <xsl:value-of select="$epub.version"/>
    </xsl:message>

    <!-- Process the DITA map -->
    <xsl:apply-templates select="." mode="epub3-generate"/>
  </xsl:template>

  <!-- Main EPUB3 generation mode -->
  <xsl:template match="/" mode="epub3-generate">
    <xsl:variable name="map" select="*[contains(@class, ' map/map ')]"/>

    <xsl:message>Generating EPUB3 components...</xsl:message>
    <xsl:message>Map title: <xsl:value-of select="epub:get-title($map)"/></xsl:message>

    <!-- Emit platform-specific validation warnings -->
    <xsl:call-template name="emit-platform-warnings">
      <xsl:with-param name="map" select="$map"/>
    </xsl:call-template>

    <!-- Generate OPF package document -->
    <xsl:call-template name="generate-opf">
      <xsl:with-param name="map" select="$map"/>
    </xsl:call-template>

    <!-- Generate EPUB3 navigation document -->
    <xsl:call-template name="generate-nav">
      <xsl:with-param name="map" select="$map"/>
    </xsl:call-template>

    <!-- Generate NCX table of contents (forced for KDP, optional otherwise) -->
    <xsl:if test="epub:should-generate-ncx()">
      <xsl:call-template name="generate-ncx">
        <xsl:with-param name="map" select="$map"/>
      </xsl:call-template>
    </xsl:if>

    <!-- Generate cover page if cover image is specified -->
    <xsl:call-template name="generate-cover-page">
      <xsl:with-param name="map" select="$map"/>
    </xsl:call-template>

    <!-- Generate title page -->
    <xsl:call-template name="generate-title-page">
      <xsl:with-param name="map" select="$map"/>
    </xsl:call-template>

    <!-- Generate copyright page -->
    <xsl:call-template name="generate-copyright-page">
      <xsl:with-param name="map" select="$map"/>
    </xsl:call-template>

    <!-- Generate content files -->
    <xsl:call-template name="generate-content">
      <xsl:with-param name="map" select="$map"/>
    </xsl:call-template>

    <!-- Generate consolidated glossary if glossentry topics are present -->
    <xsl:call-template name="generate-glossary">
      <xsl:with-param name="map" select="$map"/>
    </xsl:call-template>

    <!-- Generate List of Figures -->
    <xsl:call-template name="generate-lof">
      <xsl:with-param name="map" select="$map"/>
    </xsl:call-template>

    <!-- Generate List of Tables -->
    <xsl:call-template name="generate-lot">
      <xsl:with-param name="map" select="$map"/>
    </xsl:call-template>

    <!-- Generate back-of-book index if indexterms are present -->
    <xsl:call-template name="generate-index">
      <xsl:with-param name="map" select="$map"/>
    </xsl:call-template>

    <!-- Generate @font-face CSS if fonts are embedded -->
    <xsl:call-template name="generate-font-css"/>

    <!-- Generate container.xml -->
    <xsl:call-template name="generate-container"/>

    <xsl:message>EPUB3 generation complete.</xsl:message>
  </xsl:template>

</xsl:stylesheet>

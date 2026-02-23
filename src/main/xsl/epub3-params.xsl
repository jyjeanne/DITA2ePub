<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:epub="http://www.idpf.org/2007/ops"
                exclude-result-prefixes="xs epub"
                version="3.0">

  <!--
    EPUB3 Parameters

    Defines all configurable parameters for EPUB3 transformation
  -->

  <!-- EPUB Version -->
  <xsl:param name="epub.version" as="xs:string" select="'3.3'"/>

  <!-- Cover Image -->
  <xsl:param name="epub.cover.image" as="xs:string" select="''"/>

  <!-- Cover Page Generation -->
  <xsl:param name="epub.generate.cover.page" as="xs:string" select="'yes'"/>
  <xsl:param name="epub.cover.page.style" as="xs:string" select="'full-page'"/>

  <!-- Navigation Parameters -->
  <xsl:param name="epub.toc.depth" as="xs:integer" select="5"/>
  <xsl:param name="epub.nav.depth" as="xs:integer" select="5"/>

  <!-- Directory Structure -->
  <xsl:param name="epub.topics.dir" as="xs:string" select="'content'"/>
  <xsl:param name="epub.images.dir" as="xs:string" select="'images'"/>
  <xsl:param name="epub.fonts.dir" as="xs:string" select="'fonts'"/>
  <xsl:param name="epub.css.dir" as="xs:string" select="'styles'"/>
  <xsl:param name="epub.js.dir" as="xs:string" select="'scripts'"/>

  <!-- Accessibility -->
  <xsl:param name="epub.accessibility" as="xs:string" select="'wcag-aa'"/>
  <xsl:param name="epub.aria.landmarks" as="xs:string" select="'yes'"/>
  <xsl:param name="epub.skip.nav" as="xs:string" select="'yes'"/>

  <!-- Font Management -->
  <xsl:param name="epub.embed.fonts" as="xs:string" select="''"/>
  <xsl:param name="epub.embedded.fonts" as="xs:string" select="''"/>
  <xsl:param name="epub.obfuscate.fonts" as="xs:string" select="'no'"/>

  <!-- Metadata -->
  <xsl:param name="epub.publisher" as="xs:string" select="''"/>
  <xsl:param name="epub.rights" as="xs:string" select="''"/>
  <xsl:param name="epub.identifier.scheme" as="xs:string" select="'UUID'"/>
  <xsl:param name="epub.language" as="xs:string" select="'en'"/>

  <!-- Optional Features -->
  <xsl:param name="epub.generate.lof" as="xs:string" select="'no'"/>
  <xsl:param name="epub.generate.lot" as="xs:string" select="'no'"/>
  <xsl:param name="epub.include.toc.page" as="xs:string" select="'no'"/>

  <!-- Index Generation -->
  <xsl:param name="epub.generate.index" as="xs:string" select="'auto'"/>

  <!-- Validation -->
  <xsl:param name="epub.validate" as="xs:string" select="'yes'"/>
  <xsl:param name="epub.validation.level" as="xs:string" select="'error'"/>

  <!-- Legacy Support -->
  <xsl:param name="epub.generate.ncx" as="xs:string" select="'no'"/>

  <!-- Output Base Name -->
  <xsl:param name="args.output.base.name" as="xs:string" select="'output'"/>

  <!-- CSS Parameters -->
  <xsl:param name="args.csspath" as="xs:string" select="'styles'"/>
  <xsl:param name="args.css" as="xs:string" select="'epub-default.css'"/>
  <xsl:param name="args.copycss" as="xs:string" select="'yes'"/>

  <!-- Debugging -->
  <xsl:param name="debug" as="xs:string" select="'no'"/>

  <!-- Helper function to check if a parameter is true -->
  <xsl:function name="epub:is-true" as="xs:boolean">
    <xsl:param name="value" as="xs:string"/>
    <xsl:sequence select="lower-case($value) = ('yes', 'true', '1')"/>
  </xsl:function>

  <!-- Helper function to get boolean value -->
  <xsl:function name="epub:get-boolean" as="xs:boolean">
    <xsl:param name="param" as="xs:string"/>
    <xsl:param name="default" as="xs:boolean"/>
    <xsl:choose>
      <xsl:when test="normalize-space($param) != ''">
        <xsl:sequence select="epub:is-true($param)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="$default"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

</xsl:stylesheet>

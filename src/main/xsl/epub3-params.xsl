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
  <xsl:param name="epub.font.files" as="xs:string" select="''"/>

  <!-- Metadata -->
  <xsl:param name="epub.publisher" as="xs:string" select="''"/>
  <xsl:param name="epub.rights" as="xs:string" select="''"/>
  <xsl:param name="epub.identifier.scheme" as="xs:string" select="'UUID'"/>
  <xsl:param name="epub.language" as="xs:string" select="'en'"/>

  <!-- ISBN/ASIN Identifier -->
  <xsl:param name="epub.isbn" as="xs:string" select="''"/>

  <!-- Series Metadata -->
  <xsl:param name="epub.series.name" as="xs:string" select="''"/>
  <xsl:param name="epub.series.position" as="xs:string" select="''"/>

  <!-- BISAC/ONIX Subject Classifications -->
  <xsl:param name="epub.bisac.codes" as="xs:string" select="''"/>

  <!-- Copyright Page Generation -->
  <xsl:param name="epub.copyright.page" as="xs:string" select="'auto'"/>

  <!-- Optional Features -->
  <xsl:param name="epub.generate.lof" as="xs:string" select="'no'"/>
  <xsl:param name="epub.generate.lot" as="xs:string" select="'no'"/>
  <xsl:param name="epub.include.toc.page" as="xs:string" select="'no'"/>

  <!-- Index Generation -->
  <xsl:param name="epub.generate.index" as="xs:string" select="'auto'"/>

  <!-- Glossary Generation -->
  <xsl:param name="epub.generate.glossary" as="xs:string" select="'auto'"/>

  <!-- Image Optimization -->
  <xsl:param name="epub.optimize.images" as="xs:string" select="'no'"/>
  <xsl:param name="epub.image.jpeg.quality" as="xs:string" select="'0.8'"/>
  <xsl:param name="epub.image.max.width" as="xs:string" select="'0'"/>

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

  <!-- Theme (default | academic | fiction | technical | training) -->
  <xsl:param name="epub.theme" as="xs:string" select="'default'"/>

  <!-- Validated theme value: falls back to 'default' for unrecognized values -->
  <xsl:variable name="epub.theme.validated" as="xs:string"
                select="if (lower-case(normalize-space($epub.theme)) = ('default', 'academic', 'fiction', 'technical', 'training'))
                        then lower-case(normalize-space($epub.theme))
                        else 'default'"/>

  <!-- Platform (generic | kdp | apple | kobo) -->
  <xsl:param name="epub.platform" as="xs:string" select="'generic'"/>

  <!-- Validated platform value: falls back to 'generic' for unrecognized values -->
  <xsl:variable name="epub.platform.validated" as="xs:string"
                select="if (lower-case(normalize-space($epub.platform)) = ('generic', 'kdp', 'apple', 'kobo'))
                        then lower-case(normalize-space($epub.platform))
                        else 'generic'"/>

  <!-- Custom CSS -->
  <xsl:param name="epub.custom.css" as="xs:string" select="''"/>

  <!-- Font CSS Generation -->
  <xsl:param name="epub.generate.font.css" as="xs:string" select="'yes'"/>

  <!-- Figure and Table Numbering -->
  <xsl:param name="epub.figure.numbering" as="xs:string" select="'global'"/>
  <xsl:param name="epub.table.numbering" as="xs:string" select="'global'"/>

  <!-- Table Zebra Striping -->
  <xsl:param name="epub.table.zebra" as="xs:string" select="'yes'"/>

  <!-- Code Block Enhancements -->
  <xsl:param name="epub.code.line.numbers" as="xs:string" select="'no'"/>
  <xsl:param name="epub.code.syntax.classes" as="xs:string" select="'yes'"/>

  <!-- Drop Caps -->
  <xsl:param name="epub.drop.caps" as="xs:string" select="'no'"/>

  <!-- CSS Hyphenation -->
  <xsl:param name="epub.hyphenation" as="xs:string" select="'auto'"/>

  <!-- Locale-Aware Quotation Marks -->
  <xsl:param name="epub.locale.quotes" as="xs:string" select="'no'"/>

  <!-- Fixed Layout EPUB -->
  <xsl:param name="epub.layout" as="xs:string" select="'reflowable'"/>
  <xsl:param name="epub.fxl.width" as="xs:string" select="'1024'"/>
  <xsl:param name="epub.fxl.height" as="xs:string" select="'768'"/>
  <xsl:param name="epub.fxl.orientation" as="xs:string" select="'auto'"/>
  <xsl:param name="epub.fxl.spread" as="xs:string" select="'auto'"/>

  <!-- Validated layout value -->
  <xsl:variable name="epub.layout.validated" as="xs:string"
                select="if (lower-case(normalize-space($epub.layout)) = ('reflowable', 'fixed'))
                        then lower-case(normalize-space($epub.layout))
                        else 'reflowable'"/>

  <!-- Validated FXL dimensions: must be positive integers, fallback to defaults -->
  <xsl:variable name="epub.fxl.width.validated" as="xs:string"
                select="if (normalize-space($epub.fxl.width) castable as xs:positiveInteger)
                        then normalize-space($epub.fxl.width) else '1024'"/>
  <xsl:variable name="epub.fxl.height.validated" as="xs:string"
                select="if (normalize-space($epub.fxl.height) castable as xs:positiveInteger)
                        then normalize-space($epub.fxl.height) else '768'"/>

  <!-- Validated FXL orientation and spread (case-insensitive) -->
  <xsl:variable name="epub.fxl.orientation.validated" as="xs:string"
                select="if (lower-case(normalize-space($epub.fxl.orientation)) = ('auto', 'portrait', 'landscape'))
                        then lower-case(normalize-space($epub.fxl.orientation)) else 'auto'"/>
  <xsl:variable name="epub.fxl.spread.validated" as="xs:string"
                select="if (lower-case(normalize-space($epub.fxl.spread)) = ('auto', 'both', 'landscape', 'none'))
                        then lower-case(normalize-space($epub.fxl.spread)) else 'auto'"/>

  <!-- Convenience: is this a fixed-layout publication? -->
  <xsl:variable name="is-fixed-layout" as="xs:boolean"
                select="$epub.layout.validated = 'fixed'"/>

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

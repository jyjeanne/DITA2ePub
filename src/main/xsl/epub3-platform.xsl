<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:epub="http://www.idpf.org/2007/ops"
                xmlns:opf="http://www.idpf.org/2007/opf"
                exclude-result-prefixes="xs epub opf"
                version="3.0">

  <!--
    EPUB3 Platform-Specific Logic

    Adapts EPUB output for specific distribution platforms:
    - generic (default): Standard EPUB 3.3
    - kdp: Amazon Kindle Direct Publishing
    - apple: Apple Books
    - kobo: Rakuten Kobo
  -->

  <!-- ================================================================== -->
  <!-- Platform Detection Functions                                        -->
  <!-- ================================================================== -->

  <!-- Check if current platform is a specific value -->
  <xsl:function name="epub:is-platform" as="xs:boolean">
    <xsl:param name="platform" as="xs:string"/>
    <xsl:sequence select="$epub.platform.validated = $platform"/>
  </xsl:function>

  <!-- Check if NCX should be generated (forced for KDP, optional otherwise) -->
  <xsl:function name="epub:should-generate-ncx" as="xs:boolean">
    <xsl:sequence select="epub:is-platform('kdp') or epub:is-true($epub.generate.ncx)"/>
  </xsl:function>

  <!-- Check if guide element should be generated (forced for KDP, optional otherwise) -->
  <xsl:function name="epub:should-generate-guide" as="xs:boolean">
    <xsl:sequence select="epub:is-platform('kdp')"/>
  </xsl:function>

  <!-- ================================================================== -->
  <!-- Platform Validation Warnings                                        -->
  <!-- ================================================================== -->

  <!-- Emit platform-specific validation warnings at build start -->
  <xsl:template name="emit-platform-warnings">
    <xsl:param name="map" as="element()"/>

    <xsl:if test="$epub.platform.validated != 'generic'">
      <xsl:message>Platform profile: <xsl:value-of select="$epub.platform.validated"/></xsl:message>
    </xsl:if>

    <!-- KDP-specific warnings -->
    <xsl:if test="epub:is-platform('kdp')">
      <!-- Cover image validation -->
      <xsl:if test="normalize-space($epub.cover.image) = ''">
        <xsl:message>[KDP WARNING] No cover image specified. Amazon KDP requires a cover image for publication.</xsl:message>
      </xsl:if>

      <!-- SVG cover warning -->
      <xsl:if test="normalize-space($epub.cover.image) != '' and ends-with(lower-case($epub.cover.image), '.svg')">
        <xsl:message>[KDP WARNING] SVG cover images are not supported by Kindle. Use JPEG or PNG (recommended: 2560x1600px).</xsl:message>
      </xsl:if>

      <!-- Font embedding warning -->
      <xsl:if test="normalize-space($epub.font.files) != ''">
        <xsl:message>[KDP INFO] Kindle may not render embedded fonts. Consider using KDP-supported fonts for consistent display.</xsl:message>
      </xsl:if>

      <!-- NCX forced generation notice -->
      <xsl:message>[KDP] NCX table of contents will be generated (required by Kindle).</xsl:message>

      <!-- Guide element notice -->
      <xsl:message>[KDP] OPF guide element will be generated (required by older Kindle devices).</xsl:message>

      <!-- Check for SVG images in content -->
      <xsl:variable name="all-topicrefs" select="epub:content-topicrefs($map)"/>
      <xsl:variable name="has-svg-images" as="xs:boolean">
        <xsl:variable name="svg-count" as="xs:integer">
          <xsl:sequence select="count(
            for $ref in $all-topicrefs[@href]
            return
              if (doc-available(epub:resolve-href($ref/@href, $ref)))
              then epub:topic-document($ref)//*[contains(@class, ' topic/image ')][ends-with(lower-case(@href), '.svg')]
              else ()
          )"/>
        </xsl:variable>
        <xsl:sequence select="$svg-count > 0"/>
      </xsl:variable>
      <xsl:if test="$has-svg-images">
        <xsl:message>[KDP WARNING] SVG images detected in content. Kindle has limited SVG support — consider providing PNG/JPEG fallbacks.</xsl:message>
      </xsl:if>
    </xsl:if>

    <!-- Apple Books specific warnings -->
    <xsl:if test="epub:is-platform('apple')">
      <xsl:if test="normalize-space($epub.cover.image) = ''">
        <xsl:message>[APPLE WARNING] No cover image specified. Apple Books requires a cover image for publication.</xsl:message>
      </xsl:if>
      <xsl:message>[APPLE] ibooks:specified-fonts metadata will be added for custom font rendering.</xsl:message>
    </xsl:if>

    <!-- Kobo specific warnings -->
    <xsl:if test="epub:is-platform('kobo')">
      <xsl:if test="normalize-space($epub.cover.image) = ''">
        <xsl:message>[KOBO WARNING] No cover image specified. Kobo requires a cover image for publication.</xsl:message>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <!-- ================================================================== -->
  <!-- KDP Guide Element Generation                                        -->
  <!-- ================================================================== -->

  <!-- Generate expanded guide element for KDP (older Kindle compatibility) -->
  <xsl:template name="generate-kdp-guide">
    <xsl:param name="map" as="element()"/>
    <xsl:param name="generate-glossary" as="xs:boolean" select="false()"/>
    <xsl:param name="generate-index" as="xs:boolean" select="false()"/>
    <xsl:param name="generate-lof" as="xs:boolean" select="false()"/>
    <xsl:param name="generate-lot" as="xs:boolean" select="false()"/>

    <guide xmlns="http://www.idpf.org/2007/opf">
      <!-- Cover reference -->
      <xsl:if test="epub:is-true($epub.generate.cover.page) and $epub.cover.image != ''">
        <reference type="cover" title="Cover" href="cover.xhtml"/>
      </xsl:if>

      <!-- Title page -->
      <reference type="title-page" title="Title Page" href="titlepage.xhtml"/>

      <!-- Table of contents -->
      <reference type="toc" title="Table of Contents" href="nav.xhtml"/>

      <!-- Start of content: first body topic -->
      <xsl:variable name="first-body-topic" select="(
        $map//*[contains(@class, ' map/topicref ')][@href]
          [not(@processing-role = 'resource-only')]
          [not(ancestor::*[contains(@class, ' bookmap/frontmatter ')])]
          [not(ancestor::*[contains(@class, ' bookmap/backmatter ')])]
          [not(ancestor::*[contains(@class, ' bookmap/glossarylist ')])]
      )[1]"/>
      <xsl:if test="$first-body-topic">
        <reference type="text" title="Start" href="{epub:get-topic-filename($first-body-topic)}"/>
      </xsl:if>

      <!-- Copyright page -->
      <xsl:if test="epub:is-true($epub.copyright.page) or ($epub.copyright.page = 'auto' and $map//*[contains(@class, ' bookmap/bookrights ')])">
        <reference type="copyright-page" title="Copyright" href="copyright.xhtml"/>
      </xsl:if>

      <!-- Glossary -->
      <xsl:if test="$generate-glossary">
        <reference type="glossary" title="Glossary" href="glossary.xhtml"/>
      </xsl:if>

      <!-- Index -->
      <xsl:if test="$generate-index">
        <reference type="index" title="Index" href="index.xhtml"/>
      </xsl:if>

      <!-- List of Figures -->
      <xsl:if test="$generate-lof">
        <reference type="loi" title="List of Figures" href="lof.xhtml"/>
      </xsl:if>

      <!-- List of Tables -->
      <xsl:if test="$generate-lot">
        <reference type="lot" title="List of Tables" href="lot.xhtml"/>
      </xsl:if>
    </guide>
  </xsl:template>

  <!-- ================================================================== -->
  <!-- Apple Books Metadata                                                -->
  <!-- ================================================================== -->

  <!-- Emit Apple Books specific metadata in OPF -->
  <xsl:template name="emit-apple-metadata">
    <!-- Apple Books requires ibooks:specified-fonts for custom font rendering -->
    <xsl:if test="epub:is-platform('apple')">
      <opf:meta property="ibooks:specified-fonts">true</opf:meta>
      <!-- Apple Books version identifier -->
      <opf:meta property="ibooks:version">1.0</opf:meta>
    </xsl:if>
  </xsl:template>

  <!-- ================================================================== -->
  <!-- Platform CSS Links                                                  -->
  <!-- ================================================================== -->

  <!-- Emit platform-specific CSS link if applicable -->
  <xsl:template name="emit-platform-css-link">
    <xsl:if test="epub:is-platform('kdp')">
      <link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" type="text/css"
            href="{epub:get-relative-path($epub.topics.dir, concat($epub.css.dir, '/epub-platform-kdp.css'))}"/>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>

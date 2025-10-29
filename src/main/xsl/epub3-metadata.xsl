<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:dc="http://purl.org/dc/elements/1.1/"
                xmlns:dcterms="http://purl.org/dc/terms/"
                xmlns:opf="http://www.idpf.org/2007/opf"
                xmlns:epub="http://www.idpf.org/2007/ops"
                exclude-result-prefixes="xs dc dcterms opf epub"
                version="3.0">

  <!--
    EPUB3 Metadata Extraction

    Extracts and formats Dublin Core and EPUB3 metadata from DITA
  -->

  <!-- Extract metadata from bookmap or map -->
  <xsl:template name="extract-metadata">
    <xsl:param name="root" as="element()"/>

    <metadata xmlns:dc="http://purl.org/dc/elements/1.1/"
              xmlns:dcterms="http://purl.org/dc/terms/">

      <!-- Publication Identifier -->
      <dc:identifier id="pub-id">
        <xsl:value-of select="epub:get-identifier($root)"/>
      </dc:identifier>

      <!-- Title -->
      <dc:title id="title">
        <xsl:value-of select="epub:get-title($root)"/>
      </dc:title>

      <!-- Subtitle (if present) -->
      <xsl:if test="$root//*[contains(@class, ' bookmap/booktitle ')]/*[contains(@class, ' bookmap/booktitlealt ')]">
        <dc:title id="subtitle">
          <xsl:value-of select="normalize-space($root//*[contains(@class, ' bookmap/booktitle ')]/*[contains(@class, ' bookmap/booktitlealt ')][1])"/>
        </dc:title>
        <meta refines="#subtitle" property="title-type">subtitle</meta>
      </xsl:if>

      <!-- Language -->
      <dc:language>
        <xsl:value-of select="epub:get-language($root)"/>
      </dc:language>

      <!-- Authors -->
      <xsl:call-template name="extract-authors">
        <xsl:with-param name="root" select="$root"/>
      </xsl:call-template>

      <!-- Contributors -->
      <xsl:call-template name="extract-contributors">
        <xsl:with-param name="root" select="$root"/>
      </xsl:call-template>

      <!-- Publisher -->
      <xsl:call-template name="extract-publisher">
        <xsl:with-param name="root" select="$root"/>
      </xsl:call-template>

      <!-- Publication Date -->
      <dc:date>
        <xsl:call-template name="extract-publication-date">
          <xsl:with-param name="root" select="$root"/>
        </xsl:call-template>
      </dc:date>

      <!-- Last Modified (required by EPUB3) -->
      <meta property="dcterms:modified">
        <xsl:value-of select="format-dateTime(current-dateTime(), '[Y0001]-[M01]-[D01]T[H01]:[m01]:[s01]Z')"/>
      </meta>

      <!-- Rights/Copyright -->
      <xsl:call-template name="extract-rights">
        <xsl:with-param name="root" select="$root"/>
      </xsl:call-template>

      <!-- Description/Abstract -->
      <xsl:call-template name="extract-description">
        <xsl:with-param name="root" select="$root"/>
      </xsl:call-template>

      <!-- Subject/Keywords -->
      <xsl:call-template name="extract-subjects">
        <xsl:with-param name="root" select="$root"/>
      </xsl:call-template>

      <!-- Accessibility Metadata -->
      <xsl:call-template name="generate-accessibility-metadata"/>

      <!-- Cover Image -->
      <xsl:if test="$epub.cover.image != ''">
        <meta name="cover" content="cover-image"/>
      </xsl:if>

    </metadata>
  </xsl:template>

  <!-- Extract authors from bookmeta -->
  <xsl:template name="extract-authors">
    <xsl:param name="root" as="element()"/>

    <xsl:for-each select="$root//*[contains(@class, ' bookmap/bookmeta ')]//*[contains(@class, ' topic/author ')]">
      <xsl:variable name="author-id" select="concat('author-', position())"/>

      <dc:creator id="{$author-id}">
        <xsl:choose>
          <xsl:when test="*[contains(@class, ' topic/data ')][@name='firstname'] or *[contains(@class, ' topic/data ')][@name='lastname']">
            <xsl:value-of select="concat(
              normalize-space(*[contains(@class, ' topic/data ')][@name='firstname']),
              ' ',
              normalize-space(*[contains(@class, ' topic/data ')][@name='lastname'])
            )"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="normalize-space(.)"/>
          </xsl:otherwise>
        </xsl:choose>
      </dc:creator>

      <meta refines="#{$author-id}" property="role" scheme="marc:relators">aut</meta>

      <!-- File-as for sorting -->
      <xsl:if test="*[contains(@class, ' topic/data ')][@name='lastname']">
        <meta refines="#{$author-id}" property="file-as">
          <xsl:value-of select="concat(
            normalize-space(*[contains(@class, ' topic/data ')][@name='lastname']),
            ', ',
            normalize-space(*[contains(@class, ' topic/data ')][@name='firstname'])
          )"/>
        </meta>
      </xsl:if>
    </xsl:for-each>

    <!-- Fallback if no author in bookmeta -->
    <xsl:if test="not($root//*[contains(@class, ' bookmap/bookmeta ')]//*[contains(@class, ' topic/author ')])">
      <dc:creator id="creator">Unknown</dc:creator>
      <meta refines="#creator" property="role" scheme="marc:relators">aut</meta>
    </xsl:if>
  </xsl:template>

  <!-- Extract contributors -->
  <xsl:template name="extract-contributors">
    <xsl:param name="root" as="element()"/>

    <xsl:for-each select="$root//*[contains(@class, ' xnal-d/namedetails ')][@role != 'author']">
      <xsl:variable name="contrib-id" select="concat('contributor-', position())"/>

      <dc:contributor id="{$contrib-id}">
        <xsl:value-of select="normalize-space(.)"/>
      </dc:contributor>

      <xsl:if test="@role">
        <meta refines="#{$contrib-id}" property="role" scheme="marc:relators">
          <xsl:value-of select="@role"/>
        </meta>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

  <!-- Extract publisher -->
  <xsl:template name="extract-publisher">
    <xsl:param name="root" as="element()"/>

    <xsl:variable name="publisher">
      <xsl:choose>
        <xsl:when test="$epub.publisher != ''">
          <xsl:value-of select="$epub.publisher"/>
        </xsl:when>
        <xsl:when test="$root//*[contains(@class, ' bookmap/publisherinformation ')]//*[contains(@class, ' bookmap/organization ')]">
          <xsl:value-of select="normalize-space(($root//*[contains(@class, ' bookmap/publisherinformation ')]//*[contains(@class, ' bookmap/organization ')])[1])"/>
        </xsl:when>
        <xsl:when test="$root//*[contains(@class, ' topic/publisher ')]">
          <xsl:value-of select="normalize-space($root//*[contains(@class, ' topic/publisher ')][1])"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>Unknown Publisher</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <dc:publisher>
      <xsl:value-of select="$publisher"/>
    </dc:publisher>
  </xsl:template>

  <!-- Extract publication date -->
  <xsl:template name="extract-publication-date">
    <xsl:param name="root" as="element()"/>

    <xsl:choose>
      <xsl:when test="$root//*[contains(@class, ' bookmap/published ')]//*[contains(@class, ' bookmap/completed ')]/*[contains(@class, ' topic/year ')]">
        <xsl:variable name="year" select="$root//*[contains(@class, ' bookmap/published ')]//*[contains(@class, ' bookmap/completed ')]/*[contains(@class, ' topic/year ')][1]"/>
        <xsl:variable name="month" select="$root//*[contains(@class, ' bookmap/published ')]//*[contains(@class, ' bookmap/completed ')]/*[contains(@class, ' topic/month ')][1]"/>
        <xsl:variable name="day" select="$root//*[contains(@class, ' bookmap/published ')]//*[contains(@class, ' bookmap/completed ')]/*[contains(@class, ' topic/day ')][1]"/>

        <xsl:value-of select="concat($year,
          if ($month) then concat('-', format-number($month, '00')) else '',
          if ($day) then concat('-', format-number($day, '00')) else ''
        )"/>
      </xsl:when>
      <xsl:when test="$root//*[contains(@class, ' topic/created ')]/@date">
        <xsl:value-of select="$root//*[contains(@class, ' topic/created ')]/@date"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="format-dateTime(current-dateTime(), '[Y0001]-[M01]-[D01]')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Extract rights/copyright -->
  <xsl:template name="extract-rights">
    <xsl:param name="root" as="element()"/>

    <xsl:variable name="rights">
      <xsl:choose>
        <xsl:when test="$epub.rights != ''">
          <xsl:value-of select="$epub.rights"/>
        </xsl:when>
        <xsl:when test="$root//*[contains(@class, ' bookmap/bookrights ')]//*[contains(@class, ' bookmap/copyrfirst ')]">
          <xsl:variable name="year" select="$root//*[contains(@class, ' bookmap/bookrights ')]//*[contains(@class, ' bookmap/copyrfirst ')]/*[contains(@class, ' topic/year ')][1]"/>
          <xsl:variable name="holder" select="$root//*[contains(@class, ' bookmap/bookrights ')]//*[contains(@class, ' bookmap/bookowner ')]/*[contains(@class, ' topic/organization ')][1]"/>
          <xsl:value-of select="concat('Copyright © ', $year, ' ', normalize-space($holder))"/>
        </xsl:when>
        <xsl:when test="$root//*[contains(@class, ' topic/copyright ')]">
          <xsl:value-of select="normalize-space($root//*[contains(@class, ' topic/copyright ')][1])"/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>

    <xsl:if test="normalize-space($rights) != ''">
      <dc:rights>
        <xsl:value-of select="$rights"/>
      </dc:rights>
    </xsl:if>
  </xsl:template>

  <!-- Extract description/abstract -->
  <xsl:template name="extract-description">
    <xsl:param name="root" as="element()"/>

    <xsl:if test="$root//*[contains(@class, ' topic/shortdesc ')][1]">
      <dc:description>
        <xsl:value-of select="normalize-space($root//*[contains(@class, ' topic/shortdesc ')][1])"/>
      </dc:description>
    </xsl:if>
  </xsl:template>

  <!-- Extract subjects/keywords -->
  <xsl:template name="extract-subjects">
    <xsl:param name="root" as="element()"/>

    <xsl:for-each select="$root//*[contains(@class, ' topic/keywords ')]//*[contains(@class, ' topic/keyword ')]">
      <dc:subject>
        <xsl:value-of select="normalize-space(.)"/>
      </dc:subject>
    </xsl:for-each>

    <xsl:for-each select="$root//*[contains(@class, ' bookmap/category ')]">
      <dc:subject>
        <xsl:value-of select="normalize-space(.)"/>
      </dc:subject>
    </xsl:for-each>
  </xsl:template>

  <!-- Generate accessibility metadata -->
  <xsl:template name="generate-accessibility-metadata">
    <xsl:variable name="wcag-level" select="upper-case($epub.accessibility)"/>

    <!-- Access modes -->
    <meta property="schema:accessMode">textual</meta>
    <meta property="schema:accessMode">visual</meta>

    <!-- Accessibility features -->
    <meta property="schema:accessibilityFeature">structuralNavigation</meta>
    <meta property="schema:accessibilityFeature">tableOfContents</meta>
    <meta property="schema:accessibilityFeature">readingOrder</meta>

    <xsl:if test="epub:is-true($epub.aria.landmarks)">
      <meta property="schema:accessibilityFeature">ARIA</meta>
    </xsl:if>

    <!-- Accessibility hazards -->
    <meta property="schema:accessibilityHazard">none</meta>

    <!-- Accessibility summary -->
    <meta property="schema:accessibilitySummary">
      <xsl:text>This publication conforms to </xsl:text>
      <xsl:value-of select="$wcag-level"/>
      <xsl:text> accessibility guidelines.</xsl:text>
    </meta>

    <!-- Accessibility control -->
    <meta property="schema:accessibilityControl">fullKeyboardControl</meta>
    <meta property="schema:accessibilityControl">fullMouseControl</meta>

    <!-- Accessibility API -->
    <meta property="schema:accessibilityAPI">ARIA</meta>
  </xsl:template>

</xsl:stylesheet>

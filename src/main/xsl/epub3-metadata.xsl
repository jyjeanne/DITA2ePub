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

    <metadata xmlns="http://www.idpf.org/2007/opf"
              xmlns:dc="http://purl.org/dc/elements/1.1/"
              xmlns:dcterms="http://purl.org/dc/terms/">

      <!-- Publication Identifier -->
      <xsl:variable name="id-value" select="epub:get-identifier($root)"/>
      <dc:identifier id="pub-id">
        <xsl:value-of select="$id-value"/>
      </dc:identifier>

      <!-- ISBN-13 identifier-type refinement (ONIX codelist5 value 15) -->
      <xsl:if test="matches($id-value, '^\d{3}-?\d{1,5}-?\d{1,7}-?\d{1,6}-?\d$')">
        <opf:meta refines="#pub-id" property="identifier-type" scheme="onix:codelist5">15</opf:meta>
      </xsl:if>
      <!-- ISBN-10 identifier-type refinement (ONIX codelist5 value 02) -->
      <xsl:if test="matches($id-value, '^\d{1,5}-?\d{1,7}-?\d{1,6}-?[\dXx]$') and not(matches($id-value, '^\d{3}-?\d{1,5}-?\d{1,7}-?\d{1,6}-?\d$'))">
        <opf:meta refines="#pub-id" property="identifier-type" scheme="onix:codelist5">02</opf:meta>
      </xsl:if>
      <!-- ASIN identifier-type refinement (ONIX codelist5 value 01 = proprietary) -->
      <xsl:if test="matches($id-value, '^B[A-Z0-9]{9}$')">
        <opf:meta refines="#pub-id" property="identifier-type" scheme="onix:codelist5">01</opf:meta>
      </xsl:if>

      <!-- Title -->
      <dc:title id="title">
        <xsl:value-of select="epub:get-title($root)"/>
      </dc:title>

      <!-- Subtitle (if present) -->
      <xsl:if test="$root//*[contains(@class, ' bookmap/booktitle ')]/*[contains(@class, ' bookmap/booktitlealt ')]">
        <dc:title id="subtitle">
          <xsl:value-of select="normalize-space($root//*[contains(@class, ' bookmap/booktitle ')]/*[contains(@class, ' bookmap/booktitlealt ')][1])"/>
        </dc:title>
        <opf:meta refines="#subtitle" property="title-type">subtitle</opf:meta>
      </xsl:if>

      <!-- Series metadata (belongs-to-collection) -->
      <xsl:variable name="series-name" select="
        if (normalize-space($epub.series.name) != '') then $epub.series.name
        else normalize-space($root//*[contains(@class, ' bookmap/bookmeta ')]//*[contains(@class, ' topic/data ')][@name='series']/@value)
      "/>
      <xsl:if test="normalize-space($series-name) != ''">
        <opf:meta property="belongs-to-collection" id="series-id">
          <xsl:value-of select="$series-name"/>
        </opf:meta>
        <opf:meta refines="#series-id" property="collection-type">series</opf:meta>
        <xsl:variable name="series-pos" select="
          if (normalize-space($epub.series.position) != '') then $epub.series.position
          else normalize-space($root//*[contains(@class, ' bookmap/bookmeta ')]//*[contains(@class, ' topic/data ')][@name='series-position']/@value)
        "/>
        <xsl:if test="normalize-space($series-pos) != ''">
          <opf:meta refines="#series-id" property="group-position">
            <xsl:value-of select="$series-pos"/>
          </opf:meta>
        </xsl:if>
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
      <opf:meta property="dcterms:modified">
        <xsl:value-of select="format-dateTime(current-dateTime(), '[Y0001]-[M01]-[D01]T[H01]:[m01]:[s01]Z')"/>
      </opf:meta>

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
      <xsl:call-template name="generate-accessibility-metadata">
        <xsl:with-param name="root" select="$root"/>
      </xsl:call-template>

      <!-- Cover Image -->
      <xsl:if test="$epub.cover.image != ''">
        <opf:meta name="cover" content="cover-image"/>
      </xsl:if>

      <!-- Platform-specific metadata -->
      <xsl:call-template name="emit-apple-metadata"/>

      <!-- Fixed Layout rendition metadata -->
      <xsl:if test="$is-fixed-layout">
        <opf:meta property="rendition:layout">pre-paginated</opf:meta>
        <opf:meta property="rendition:orientation">
          <xsl:value-of select="$epub.fxl.orientation.validated"/>
        </opf:meta>
        <opf:meta property="rendition:spread">
          <xsl:value-of select="$epub.fxl.spread.validated"/>
        </opf:meta>
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

      <opf:meta refines="#{$author-id}" property="role" scheme="marc:relators">aut</opf:meta>

      <!-- File-as for sorting -->
      <xsl:if test="*[contains(@class, ' topic/data ')][@name='lastname']">
        <opf:meta refines="#{$author-id}" property="file-as">
          <xsl:value-of select="concat(
            normalize-space(*[contains(@class, ' topic/data ')][@name='lastname']),
            ', ',
            normalize-space(*[contains(@class, ' topic/data ')][@name='firstname'])
          )"/>
        </opf:meta>
      </xsl:if>
    </xsl:for-each>

    <!-- Fallback if no author in bookmeta -->
    <xsl:if test="not($root//*[contains(@class, ' bookmap/bookmeta ')]//*[contains(@class, ' topic/author ')])">
      <dc:creator id="creator">Unknown</dc:creator>
      <opf:meta refines="#creator" property="role" scheme="marc:relators">aut</opf:meta>
    </xsl:if>
  </xsl:template>

  <!-- Extract contributors -->
  <xsl:template name="extract-contributors">
    <xsl:param name="root" as="element()"/>

    <!-- Contributors from xnal-d/namedetails with roles -->
    <xsl:for-each select="$root//*[contains(@class, ' xnal-d/namedetails ')][@role != 'author']">
      <xsl:variable name="contrib-id" select="concat('contributor-', position())"/>

      <dc:contributor id="{$contrib-id}">
        <xsl:value-of select="normalize-space(.)"/>
      </dc:contributor>

      <xsl:if test="@role">
        <opf:meta refines="#{$contrib-id}" property="role" scheme="marc:relators">
          <xsl:value-of select="epub:marc-relator(@role)"/>
        </opf:meta>
      </xsl:if>
    </xsl:for-each>

    <!-- Translators from bookmeta data -->
    <xsl:for-each select="$root//*[contains(@class, ' bookmap/bookmeta ')]//*[contains(@class, ' topic/data ')][@name='translator']">
      <xsl:variable name="trl-id" select="concat('translator-', position())"/>
      <xsl:variable name="trl-name" select="normalize-space(if (@value) then @value else .)"/>
      <xsl:if test="string-length($trl-name) > 0">
        <dc:contributor id="{$trl-id}">
          <xsl:value-of select="$trl-name"/>
        </dc:contributor>
        <opf:meta refines="#{$trl-id}" property="role" scheme="marc:relators">trl</opf:meta>
      </xsl:if>
    </xsl:for-each>

    <!-- Editors from bookmeta data -->
    <xsl:for-each select="$root//*[contains(@class, ' bookmap/bookmeta ')]//*[contains(@class, ' topic/data ')][@name='editor']">
      <xsl:variable name="edt-id" select="concat('editor-', position())"/>
      <xsl:variable name="edt-name" select="normalize-space(if (@value) then @value else .)"/>
      <xsl:if test="string-length($edt-name) > 0">
        <dc:contributor id="{$edt-id}">
          <xsl:value-of select="$edt-name"/>
        </dc:contributor>
        <opf:meta refines="#{$edt-id}" property="role" scheme="marc:relators">edt</opf:meta>
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
          if ($month) then concat('-', format-number(number(normalize-space($month)), '00')) else '',
          if ($day) then concat('-', format-number(number(normalize-space($day)), '00')) else ''
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

    <!-- BISAC codes from parameter -->
    <xsl:for-each select="tokenize($epub.bisac.codes, ',')">
      <xsl:variable name="code" select="normalize-space(.)"/>
      <xsl:if test="string-length($code) > 0">
        <dc:subject>
          <xsl:value-of select="$code"/>
        </dc:subject>
      </xsl:if>
    </xsl:for-each>

    <!-- BISAC codes from bookmap bookmeta data elements -->
    <xsl:for-each select="$root//*[contains(@class, ' bookmap/bookmeta ')]//*[contains(@class, ' topic/data ')][@name='bisac']">
      <dc:subject>
        <xsl:value-of select="normalize-space(if (@value) then @value else .)"/>
      </dc:subject>
    </xsl:for-each>
  </xsl:template>

  <!-- Generate accessibility metadata -->
  <xsl:template name="generate-accessibility-metadata">
    <xsl:param name="root" as="element()"/>
    <xsl:variable name="wcag-level" select="upper-case($epub.accessibility)"/>

    <!-- Access modes -->
    <opf:meta property="schema:accessMode">textual</opf:meta>
    <opf:meta property="schema:accessMode">visual</opf:meta>

    <!-- Accessibility features -->
    <opf:meta property="schema:accessibilityFeature">structuralNavigation</opf:meta>
    <opf:meta property="schema:accessibilityFeature">tableOfContents</opf:meta>
    <opf:meta property="schema:accessibilityFeature">readingOrder</opf:meta>

    <xsl:if test="epub:is-true($epub.aria.landmarks)">
      <opf:meta property="schema:accessibilityFeature">ARIA</opf:meta>
    </xsl:if>

    <!-- DPUB-ARIA doc-* roles on structural elements -->
    <xsl:if test="epub:is-true($epub.aria.landmarks)">
      <opf:meta property="schema:accessibilityFeature">dpubAria</opf:meta>
    </xsl:if>

    <!-- List of Illustrations (conditional on LOF generation) -->
    <xsl:variable name="lof-figurelist" select="exists($root//*[contains(@class, ' bookmap/figurelist ')])"/>
    <xsl:if test="epub:is-true($epub.generate.lof) or ($epub.generate.lof = 'auto' and $lof-figurelist)">
      <opf:meta property="schema:accessibilityFeature">listOfIllustrations</opf:meta>
    </xsl:if>

    <!-- List of Tables (conditional on LOT generation) -->
    <xsl:variable name="lot-tablelist" select="exists($root//*[contains(@class, ' bookmap/tablelist ')])"/>
    <xsl:if test="epub:is-true($epub.generate.lot) or ($epub.generate.lot = 'auto' and $lot-tablelist)">
      <opf:meta property="schema:accessibilityFeature">listOfTables</opf:meta>
    </xsl:if>

    <!-- Accessibility hazards -->
    <opf:meta property="schema:accessibilityHazard">none</opf:meta>

    <!-- Accessibility summary -->
    <opf:meta property="schema:accessibilitySummary">
      <xsl:text>This publication conforms to </xsl:text>
      <xsl:value-of select="$wcag-level"/>
      <xsl:text> accessibility guidelines.</xsl:text>
    </opf:meta>

    <!-- Accessibility control -->
    <opf:meta property="schema:accessibilityControl">fullKeyboardControl</opf:meta>
    <opf:meta property="schema:accessibilityControl">fullMouseControl</opf:meta>

    <!-- Accessibility API -->
    <opf:meta property="schema:accessibilityAPI">ARIA</opf:meta>
  </xsl:template>

</xsl:stylesheet>

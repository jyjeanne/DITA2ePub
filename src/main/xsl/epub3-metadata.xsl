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

  <!-- Metadata of the publication itself: the bookmap's bookmeta, or a map's own topicmeta.
       Searching the whole map would also pick up topicref metadata, such as key definitions
       used as text variables (<keydef keys="release"><topicmeta><keywords>...) -->
  <xsl:function name="epub:publication-metadata" as="element()*">
    <xsl:param name="root" as="element()"/>
    <xsl:sequence select="$root/*[contains(@class, ' map/topicmeta ')]"/>
  </xsl:function>

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
          <xsl:value-of select="normalize-space(($root//*[contains(@class, ' bookmap/booktitle ')]/*[contains(@class, ' bookmap/booktitlealt ')])[1])"/>
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

    <xsl:for-each select="epub:publication-metadata($root)//*[contains(@class, ' topic/author ')]">
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
    <!-- No author: dc:creator is optional in EPUB 3, and a placeholder would show up in libraries -->
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
        <xsl:when test="epub:publication-metadata($root)//*[contains(@class, ' topic/publisher ')]">
          <xsl:value-of select="normalize-space((epub:publication-metadata($root)//*[contains(@class, ' topic/publisher ')])[1])"/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>

    <!-- No publisher: dc:publisher is optional, so no placeholder is written -->
    <xsl:if test="normalize-space($publisher) != ''">
      <dc:publisher>
        <xsl:value-of select="$publisher"/>
      </dc:publisher>
    </xsl:if>
  </xsl:template>

  <!-- Extract publication date -->
  <xsl:template name="extract-publication-date">
    <xsl:param name="root" as="element()"/>

    <xsl:choose>
      <xsl:when test="$root//*[contains(@class, ' bookmap/published ')]//*[contains(@class, ' bookmap/completed ')]/*[contains(@class, ' bookmap/year ')]">
        <xsl:variable name="year" select="($root//*[contains(@class, ' bookmap/published ')]//*[contains(@class, ' bookmap/completed ')]/*[contains(@class, ' bookmap/year ')])[1]"/>
        <xsl:variable name="month" select="($root//*[contains(@class, ' bookmap/published ')]//*[contains(@class, ' bookmap/completed ')]/*[contains(@class, ' bookmap/month ')])[1]"/>
        <xsl:variable name="day" select="($root//*[contains(@class, ' bookmap/published ')]//*[contains(@class, ' bookmap/completed ')]/*[contains(@class, ' bookmap/day ')])[1]"/>

        <xsl:value-of select="concat($year,
          if ($month) then concat('-', format-number(number(normalize-space($month)), '00')) else '',
          if ($day) then concat('-', format-number(number(normalize-space($day)), '00')) else ''
        )"/>
      </xsl:when>
      <xsl:when test="epub:publication-metadata($root)//*[contains(@class, ' topic/created ')]/@date">
        <xsl:value-of select="(epub:publication-metadata($root)//*[contains(@class, ' topic/created ')]/@date)[1]"/>
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
          <xsl:variable name="year" select="($root//*[contains(@class, ' bookmap/bookrights ')]//*[contains(@class, ' bookmap/copyrfirst ')]/*[contains(@class, ' bookmap/year ')])[1]"/>
          <xsl:variable name="holder" select="($root//*[contains(@class, ' bookmap/bookrights ')]//*[contains(@class, ' bookmap/bookowner ')]/*[contains(@class, ' bookmap/organization ')])[1]"/>
          <xsl:value-of select="concat('Copyright © ', $year, ' ', normalize-space($holder))"/>
        </xsl:when>
        <xsl:when test="epub:publication-metadata($root)//*[contains(@class, ' topic/copyright ')]">
          <xsl:value-of select="normalize-space((epub:publication-metadata($root)//*[contains(@class, ' topic/copyright ')])[1])"/>
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

    <!-- The map's own short description (a topicref's would describe that topic, not the book) -->
    <xsl:variable name="shortdesc" select="epub:publication-metadata($root)/*[contains(@class, ' topic/shortdesc ')][normalize-space(.) != '']"/>
    <xsl:if test="$shortdesc">
      <dc:description>
        <xsl:value-of select="normalize-space($shortdesc[1])"/>
      </dc:description>
    </xsl:if>
  </xsl:template>

  <!-- Extract subjects/keywords -->
  <xsl:template name="extract-subjects">
    <xsl:param name="root" as="element()"/>

    <xsl:variable name="pub-meta" select="epub:publication-metadata($root)"/>
    <xsl:variable name="subjects" as="xs:string*" select="
      $pub-meta//*[contains(@class, ' topic/keywords ')]//*[contains(@class, ' topic/keyword ')]/normalize-space(.),
      $pub-meta//*[contains(@class, ' topic/category ')]/normalize-space(.),
      (: BISAC codes from the parameter, then from bookmeta data elements :)
      tokenize($epub.bisac.codes, ',')!normalize-space(.),
      $pub-meta//*[contains(@class, ' topic/data ')][@name = 'bisac']/normalize-space(if (@value) then @value else .)"/>

    <!-- Each subject once, in order of first appearance -->
    <xsl:for-each-group select="$subjects[. != '']" group-by=".">
      <dc:subject>
        <xsl:value-of select="current-grouping-key()"/>
      </dc:subject>
    </xsl:for-each-group>
  </xsl:template>

  <!-- Value of a <data name="..."> element of the publication metadata (its @value, or its text) -->
  <xsl:function name="epub:get-publication-data" as="xs:string">
    <xsl:param name="root" as="element()"/>
    <xsl:param name="name" as="xs:string"/>
    <xsl:variable name="data" select="(epub:publication-metadata($root)//*[contains(@class, ' topic/data ')][@name = $name])[1]"/>
    <xsl:sequence select="normalize-space(if ($data/@value) then $data/@value else string($data))"/>
  </xsl:function>

  <!-- Accessibility metadata (EPUB Accessibility 1.1). The discovery metadata describes what the
       generated content actually contains. Conformance is only claimed when the bookmap declares it
       with the party that evaluated it: a converter cannot evaluate WCAG conformance by itself.
         <data name="accessibility-conformance" value="EPUB Accessibility 1.1 - WCAG 2.2 Level AA"/>
         <data name="accessibility-certifier" value="Name of the evaluating organization"/>
         <data name="accessibility-summary" value="Replaces the generated summary"/> -->
  <xsl:template name="generate-accessibility-metadata">
    <xsl:param name="root" as="element()"/>

    <!-- Rendered content: images outside the prolog, related links and unpublished elements -->
    <xsl:variable name="docs" select="epub:content-topicrefs($root)/epub:topic-document(.)"/>
    <xsl:variable name="images" select="$docs//*[contains(@class, ' topic/image ')][not(epub:is-remote-image(.))][not(ancestor::*[
      contains(@class, ' topic/prolog ') or contains(@class, ' topic/related-links ') or contains(@class, ' topic/draft-comment ')
      or contains(@class, ' topic/required-cleanup ') or contains(@class, ' topic/data ') or contains(@class, ' topic/foreign ')])]"/>
    <!-- Decorative images (@alt="" or outputclass="decorative") correctly have no text alternative -->
    <xsl:variable name="images-without-alt" select="$images[not(@outputclass = 'decorative' or exists(@alt)
      or *[contains(@class, ' topic/alt ')][normalize-space(.) != ''])]"/>
    <xsl:variable name="has-visual" select="exists($images) or normalize-space($epub.cover.image) != ''"/>
    <xsl:variable name="has-index" select="epub:is-true($epub.generate.index)
      or ($epub.generate.index = 'auto' and exists($root//*[contains(@class, ' bookmap/indexlist ')]))"/>
    <!-- Animated images and embedded media may flash or play sound: their hazards cannot be determined -->
    <xsl:variable name="has-media" select="exists($images[matches(lower-case(@href), '\.gif$')])
      or exists($docs//*[contains(@class, ' topic/object ') or contains(@class, ' media-d/')])"/>

    <!-- Access modes, and the ones sufficient to read everything -->
    <opf:meta property="schema:accessMode">textual</opf:meta>
    <xsl:if test="$has-visual">
      <opf:meta property="schema:accessMode">visual</opf:meta>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="empty($images-without-alt)">
        <opf:meta property="schema:accessModeSufficient">textual</opf:meta>
      </xsl:when>
      <xsl:otherwise>
        <opf:meta property="schema:accessModeSufficient">textual,visual</opf:meta>
      </xsl:otherwise>
    </xsl:choose>

    <!-- Accessibility features: headings, navigation document, spine order and ARIA roles
         (main, note, doc-toc, doc-noteref...) are always generated -->
    <opf:meta property="schema:accessibilityFeature">structuralNavigation</opf:meta>
    <opf:meta property="schema:accessibilityFeature">tableOfContents</opf:meta>
    <opf:meta property="schema:accessibilityFeature">readingOrder</opf:meta>
    <opf:meta property="schema:accessibilityFeature">ARIA</opf:meta>
    <xsl:if test="$has-index">
      <opf:meta property="schema:accessibilityFeature">index</opf:meta>
    </xsl:if>
    <xsl:if test="exists($images) and empty($images-without-alt)">
      <opf:meta property="schema:accessibilityFeature">alternativeText</opf:meta>
    </xsl:if>

    <!-- Accessibility hazards -->
    <opf:meta property="schema:accessibilityHazard">
      <xsl:value-of select="if ($has-media) then 'unknown' else 'none'"/>
    </opf:meta>

    <!-- Conformance claim, only as declared by the author (EPUB Accessibility 1.1 requires the evaluator) -->
    <xsl:variable name="conformance" select="epub:get-publication-data($root, 'accessibility-conformance')"/>
    <xsl:variable name="certifier" select="epub:get-publication-data($root, 'accessibility-certifier')"/>
    <xsl:variable name="has-claim" select="$conformance != '' and $certifier != ''"/>
    <xsl:if test="$conformance != '' and $certifier = ''">
      <xsl:message>[WARN] Accessibility conformance "<xsl:value-of select="$conformance"/>" is declared without a data element named "accessibility-certifier": EPUB Accessibility 1.1 requires the evaluator, so no conformance claim is written.</xsl:message>
    </xsl:if>
    <xsl:if test="$conformance != '' and not(matches($conformance, '^EPUB Accessibility 1\.[1-9][0-9]* - WCAG 2\.[0-9]+ Level (A|AA|AAA)$'))">
      <xsl:message>[WARN] Accessibility conformance "<xsl:value-of select="$conformance"/>" does not follow the EPUB Accessibility 1.1 form, e.g. "EPUB Accessibility 1.1 - WCAG 2.2 Level AA".</xsl:message>
    </xsl:if>
    <xsl:if test="$has-claim">
      <opf:meta property="dcterms:conformsTo">
        <xsl:value-of select="$conformance"/>
      </opf:meta>
      <opf:meta property="a11y:certifiedBy">
        <xsl:value-of select="$certifier"/>
      </opf:meta>
    </xsl:if>

    <!-- Summary: the author's, or a factual one built from the checks above (in English) -->
    <xsl:variable name="declared-summary" select="epub:get-publication-data($root, 'accessibility-summary')"/>
    <xsl:variable name="image-count" select="count($images)"/>
    <xsl:variable name="missing-count" select="count($images-without-alt)"/>
    <xsl:variable name="generated-summary" select="string-join((
      'Structured headings, a table of contents and a logical reading order support navigation with assistive technologies.',
      if ($has-index) then 'A back-of-book index is included.' else (),
      if ($image-count = 0) then ()
      else if ($missing-count = 0) then concat(if ($image-count = 1) then 'The image has' else 'All images have', ' a text alternative.')
      else concat($missing-count, ' of ', $image-count, ' image', if ($image-count gt 1) then 's' else '',
                  if ($missing-count = 1) then ' has' else ' have', ' no text alternative.'),
      if ($has-claim) then () else 'No conformance to EPUB Accessibility or WCAG is claimed.'), ' ')"/>
    <opf:meta property="schema:accessibilitySummary">
      <xsl:if test="$declared-summary = '' and not(starts-with(lower-case(epub:get-language($root)), 'en'))">
        <xsl:attribute name="xml:lang">en</xsl:attribute>
      </xsl:if>
      <xsl:value-of select="if ($declared-summary != '') then $declared-summary else $generated-summary"/>
    </opf:meta>
  </xsl:template>

</xsl:stylesheet>

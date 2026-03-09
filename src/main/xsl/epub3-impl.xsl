<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xhtml="http://www.w3.org/1999/xhtml"
                xmlns:epub="http://www.idpf.org/2007/ops"
                xmlns:opf="http://www.idpf.org/2007/opf"
                xmlns:dc="http://purl.org/dc/elements/1.1/"
                xmlns:dcterms="http://purl.org/dc/terms/"
                exclude-result-prefixes="xs xhtml epub opf dc dcterms"
                version="3.0">

  <!--
    EPUB3 Core Implementation

    Main implementation for EPUB3 generation
  -->

  <!-- Emit CSS stylesheet links (centralized for all generated XHTML pages).
       Cascade order: epub-default.css → epub-theme-*.css → epub-platform-*.css → epub-fonts.css → custom.css -->
  <xsl:template name="emit-css-links">
    <!-- Default stylesheet -->
    <link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" type="text/css"
          href="{epub:get-relative-path($epub.topics.dir, concat($epub.css.dir, '/', $args.css))}"/>
    <!-- Theme CSS (only when a non-default theme is selected) -->
    <xsl:if test="$epub.theme.validated != 'default' and normalize-space($epub.theme.validated) != ''">
      <link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" type="text/css"
            href="{epub:get-relative-path($epub.topics.dir, concat($epub.css.dir, '/epub-theme-', $epub.theme.validated, '.css'))}"/>
    </xsl:if>
    <!-- Platform CSS (KDP overrides) -->
    <xsl:call-template name="emit-platform-css-link"/>
    <!-- Font CSS -->
    <xsl:if test="normalize-space($epub.font.files) != '' and epub:is-true($epub.generate.font.css)">
      <link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" type="text/css"
            href="{epub:get-relative-path($epub.topics.dir, concat($epub.css.dir, '/epub-fonts.css'))}"/>
    </xsl:if>
    <!-- Custom CSS -->
    <xsl:if test="normalize-space($epub.custom.css) != ''">
      <xsl:variable name="custom-css-filename" select="tokenize(replace($epub.custom.css, '\\', '/'), '/')[last()]"/>
      <link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" type="text/css"
            href="{epub:get-relative-path($epub.topics.dir, concat($epub.css.dir, '/', $custom-css-filename))}"/>
    </xsl:if>
    <!-- Fixed Layout CSS and viewport -->
    <xsl:if test="$is-fixed-layout">
      <link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" type="text/css"
            href="{epub:get-relative-path($epub.topics.dir, concat($epub.css.dir, '/epub-fxl.css'))}"/>
      <meta xmlns="http://www.w3.org/1999/xhtml" name="viewport"
            content="width={$epub.fxl.width.validated}, height={$epub.fxl.height.validated}"/>
    </xsl:if>
  </xsl:template>

  <!-- Generate OPF package document -->
  <xsl:template name="generate-opf">
    <xsl:param name="map" as="element()"/>

    <xsl:message>Generating OPF package document...</xsl:message>

    <!-- Write unique identifier to side-effect file for font obfuscation -->
    <xsl:if test="epub:is-true($epub.obfuscate.fonts)">
      <xsl:result-document href=".epub-identifier" method="text" encoding="UTF-8">
        <xsl:value-of select="epub:get-identifier($map)"/>
      </xsl:result-document>
    </xsl:if>

    <!-- Collect all topicrefs for manifest and spine (exclude glossarylist descendants when glossary is consolidated) -->
    <!-- Exclude glossarylist descendants only when glossary is being consolidated -->
    <xsl:variable name="glossary-topicrefs-exist" select="exists($map//*[contains(@class, ' bookmap/glossarylist ')]//*[contains(@class, ' map/topicref ')][@href][not(@processing-role = 'resource-only')])"/>
    <xsl:variable name="consolidate-glossary" select="
      $glossary-topicrefs-exist and (
        epub:is-true($epub.generate.glossary) or
        $epub.generate.glossary = 'auto'
      )
    "/>
    <xsl:variable name="all-topicrefs" select="$map//*[contains(@class, ' map/topicref ')][@href][not(@processing-role = 'resource-only')][not($consolidate-glossary and ancestor::*[contains(@class, ' bookmap/glossarylist ')])]"/>

    <!-- Determine if index should be generated -->
    <xsl:variable name="has-indexlist" select="exists($map//*[contains(@class, ' bookmap/indexlist ')])"/>
    <xsl:variable name="generate-index" select="
      epub:is-true($epub.generate.index) or
      ($epub.generate.index = 'auto' and $has-indexlist)
    "/>

    <!-- Determine if glossary should be generated -->
    <xsl:variable name="glossary-topicrefs" select="$map//*[contains(@class, ' bookmap/glossarylist ')]//*[contains(@class, ' map/topicref ')][@href][not(@processing-role = 'resource-only')]"/>
    <xsl:variable name="generate-glossary" select="
      count($glossary-topicrefs) > 0 and (
        epub:is-true($epub.generate.glossary) or
        $epub.generate.glossary = 'auto'
      )
    "/>

    <!-- Determine if LOF/LOT should be generated -->
    <xsl:variable name="has-figurelist" select="exists($map//*[contains(@class, ' bookmap/figurelist ')])"/>
    <xsl:variable name="has-tablelist" select="exists($map//*[contains(@class, ' bookmap/tablelist ')])"/>
    <xsl:variable name="generate-lof" select="
      epub:is-true($epub.generate.lof) or
      ($epub.generate.lof = 'auto' and $has-figurelist)
    "/>
    <xsl:variable name="generate-lot" select="
      epub:is-true($epub.generate.lot) or
      ($epub.generate.lot = 'auto' and $has-tablelist)
    "/>

    <xsl:result-document href="{concat($epub.topics.dir, '/content.opf')}"
                         format="xml-no-doctype">
      <package xmlns="http://www.idpf.org/2007/opf"
               version="3.0"
               unique-identifier="pub-id"
               xml:lang="{epub:get-language($map)}">
        <xsl:if test="epub:is-platform('apple')">
          <xsl:attribute name="prefix">ibooks: http://vocabulary.itunes.apple.com/rdf/ibooks/vocabulary-extensions-1.0/</xsl:attribute>
        </xsl:if>

        <!-- Metadata -->
        <xsl:call-template name="extract-metadata">
          <xsl:with-param name="root" select="$map"/>
        </xsl:call-template>

        <!-- Manifest -->
        <manifest>
          <!-- NCX for backwards compatibility (forced for KDP, optional otherwise) -->
          <xsl:if test="epub:should-generate-ncx()">
            <item id="ncx"
                  href="../toc.ncx"
                  media-type="application/x-dtbncx+xml"/>
          </xsl:if>

          <!-- Navigation document -->
          <item id="nav"
                href="nav.xhtml"
                media-type="application/xhtml+xml"
                properties="nav"/>

          <!-- CSS - use relative path from content/ directory -->
          <item id="css-main"
                href="{epub:get-relative-path($epub.topics.dir, concat($epub.css.dir, '/', $args.css))}"
                media-type="text/css"/>

          <!-- Theme CSS (if a non-default theme is selected) -->
          <xsl:if test="$epub.theme.validated != 'default' and normalize-space($epub.theme.validated) != ''">
            <item id="css-theme"
                  href="{epub:get-relative-path($epub.topics.dir, concat($epub.css.dir, '/epub-theme-', $epub.theme.validated, '.css'))}"
                  media-type="text/css"/>
          </xsl:if>

          <!-- Font CSS (if fonts embedded and font CSS generation enabled) -->
          <xsl:if test="normalize-space($epub.font.files) != '' and epub:is-true($epub.generate.font.css)">
            <item id="css-fonts"
                  href="{epub:get-relative-path($epub.topics.dir, concat($epub.css.dir, '/epub-fonts.css'))}"
                  media-type="text/css"/>
          </xsl:if>

          <!-- Custom CSS (if specified) -->
          <xsl:if test="normalize-space($epub.custom.css) != ''">
            <xsl:variable name="custom-css-filename" select="tokenize(replace($epub.custom.css, '\\', '/'), '/')[last()]"/>
            <item id="css-custom"
                  href="{epub:get-relative-path($epub.topics.dir, concat($epub.css.dir, '/', $custom-css-filename))}"
                  media-type="text/css"/>
          </xsl:if>

          <!-- Fixed Layout CSS -->
          <xsl:if test="$is-fixed-layout">
            <item id="css-fxl"
                  href="{epub:get-relative-path($epub.topics.dir, concat($epub.css.dir, '/epub-fxl.css'))}"
                  media-type="text/css"/>
          </xsl:if>

          <!-- Platform CSS (if KDP) -->
          <xsl:if test="epub:is-platform('kdp')">
            <item id="css-platform"
                  href="{epub:get-relative-path($epub.topics.dir, concat($epub.css.dir, '/epub-platform-kdp.css'))}"
                  media-type="text/css"/>
          </xsl:if>

          <!-- Cover image (if specified) - use relative path from content/ directory -->
          <xsl:if test="$epub.cover.image != ''">
            <xsl:variable name="cover-filename" select="tokenize(replace($epub.cover.image, '\\', '/'), '/')[last()]"/>
            <item id="cover-image"
                  href="{epub:get-relative-path($epub.topics.dir, concat($epub.images.dir, '/', $cover-filename))}"
                  media-type="{epub:get-media-type($cover-filename)}"
                  properties="cover-image"/>
          </xsl:if>

          <!-- Cover page (if generated) -->
          <xsl:if test="epub:is-true($epub.generate.cover.page) and $epub.cover.image != ''">
            <item id="cover"
                  href="cover.xhtml"
                  media-type="application/xhtml+xml"/>
          </xsl:if>

          <!-- Title page -->
          <item id="titlepage"
                href="titlepage.xhtml"
                media-type="application/xhtml+xml"/>

          <!-- Copyright page (if generated) -->
          <xsl:if test="$epub.copyright.page = 'yes' or ($epub.copyright.page = 'auto' and $map//*[contains(@class, ' bookmap/bookrights ')])">
            <item id="copyright"
                  href="copyright.xhtml"
                  media-type="application/xhtml+xml"/>
          </xsl:if>

          <!-- Content documents -->
          <xsl:for-each select="$all-topicrefs">
            <xsl:variable name="filename" select="epub:get-topic-filename(.)"/>
            <xsl:variable name="topic-id" select="replace($filename, '\.xhtml$', '')"/>

            <item id="{$topic-id}"
                  href="{$filename}"
                  media-type="application/xhtml+xml"/>
          </xsl:for-each>

          <!-- Glossary page (if generated) -->
          <xsl:if test="$generate-glossary">
            <item id="glossary"
                  href="glossary.xhtml"
                  media-type="application/xhtml+xml"/>
          </xsl:if>

          <!-- List of Figures (if generated) -->
          <xsl:if test="$generate-lof">
            <item id="lof"
                  href="lof.xhtml"
                  media-type="application/xhtml+xml"/>
          </xsl:if>

          <!-- List of Tables (if generated) -->
          <xsl:if test="$generate-lot">
            <item id="lot"
                  href="lot.xhtml"
                  media-type="application/xhtml+xml"/>
          </xsl:if>

          <!-- Index page (if generated) -->
          <xsl:if test="$generate-index">
            <item id="index"
                  href="index.xhtml"
                  media-type="application/xhtml+xml"/>
          </xsl:if>

          <!-- Add images referenced in topics - load each topic document and scan for image elements -->
          <xsl:variable name="all-image-hrefs" as="xs:string*">
            <xsl:for-each select="$all-topicrefs[@href]">
              <xsl:variable name="topic-doc" select="document(@href, .)"/>
              <xsl:if test="$topic-doc">
                <xsl:for-each select="$topic-doc//*[contains(@class, ' topic/image ')]/@href">
                  <xsl:sequence select="string(.)"/>
                </xsl:for-each>
              </xsl:if>
            </xsl:for-each>
          </xsl:variable>
          <xsl:for-each select="distinct-values($all-image-hrefs)">
            <xsl:variable name="image-filename" select="tokenize(., '/')[last()]"/>
            <xsl:variable name="image-id" select="concat('image-', replace($image-filename, '[\.\s]', '-'))"/>
            <xsl:variable name="image-path" select="epub:get-relative-path($epub.topics.dir, concat($epub.images.dir, '/', $image-filename))"/>

            <item id="{$image-id}"
                  href="{$image-path}"
                  media-type="{epub:get-media-type($image-filename)}"/>
          </xsl:for-each>

          <!-- Add embedded fonts if specified -->
          <xsl:if test="normalize-space($epub.embed.fonts) != '' or normalize-space($epub.embedded.fonts) != ''">
            <xsl:call-template name="add-font-items"/>
          </xsl:if>
        </manifest>

        <!-- Spine -->
        <spine page-progression-direction="{if (epub:is-rtl(epub:get-language($map))) then 'rtl' else 'ltr'}">
          <xsl:if test="epub:should-generate-ncx()">
            <xsl:attribute name="toc" select="'ncx'"/>
          </xsl:if>
          <!-- Cover page first if generated -->
          <xsl:if test="epub:is-true($epub.generate.cover.page) and $epub.cover.image != ''">
            <itemref idref="cover" linear="yes"/>
          </xsl:if>

          <!-- Navigation document (non-linear, required for landmark references) -->
          <itemref idref="nav" linear="no"/>

          <!-- Title page -->
          <itemref idref="titlepage"/>

          <!-- Copyright page -->
          <xsl:if test="$epub.copyright.page = 'yes' or ($epub.copyright.page = 'auto' and $map//*[contains(@class, ' bookmap/bookrights ')])">
            <itemref idref="copyright"/>
          </xsl:if>

          <!-- Main content -->
          <xsl:for-each select="$all-topicrefs">
            <xsl:variable name="filename" select="epub:get-topic-filename(.)"/>
            <xsl:variable name="topic-id" select="replace($filename, '\.xhtml$', '')"/>
            <itemref idref="{$topic-id}"/>
          </xsl:for-each>

          <!-- Glossary (if generated) -->
          <xsl:if test="$generate-glossary">
            <itemref idref="glossary"/>
          </xsl:if>

          <!-- List of Figures (if generated) -->
          <xsl:if test="$generate-lof">
            <itemref idref="lof"/>
          </xsl:if>

          <!-- List of Tables (if generated) -->
          <xsl:if test="$generate-lot">
            <itemref idref="lot"/>
          </xsl:if>

          <!-- Index (if generated) -->
          <xsl:if test="$generate-index">
            <itemref idref="index"/>
          </xsl:if>
        </spine>

        <!-- Guide element: only for KDP (deprecated in EPUB 3.0.1, removed in 3.3) -->
        <xsl:if test="epub:should-generate-guide()">
          <xsl:call-template name="generate-kdp-guide">
            <xsl:with-param name="map" select="$map"/>
            <xsl:with-param name="generate-glossary" select="$generate-glossary"/>
            <xsl:with-param name="generate-index" select="$generate-index"/>
            <xsl:with-param name="generate-lof" select="$generate-lof"/>
            <xsl:with-param name="generate-lot" select="$generate-lot"/>
          </xsl:call-template>
        </xsl:if>

      </package>
    </xsl:result-document>

    <xsl:message>OPF package document generated with <xsl:value-of select="count($all-topicrefs)"/> topics.</xsl:message>
  </xsl:template>

  <!-- Generate EPUB3 navigation document -->
  <xsl:template name="generate-nav">
    <xsl:param name="map" as="element()"/>

    <xsl:message>Generating EPUB3 navigation document...</xsl:message>

    <!-- Determine if index should be generated (shared by TOC and landmarks) -->
    <xsl:variable name="nav-has-indexlist" select="exists($map//*[contains(@class, ' bookmap/indexlist ')])"/>
    <xsl:variable name="nav-generate-index" select="
      epub:is-true($epub.generate.index) or
      ($epub.generate.index = 'auto' and $nav-has-indexlist)
    "/>

    <!-- Determine if glossary should be generated (shared by TOC and landmarks) -->
    <xsl:variable name="nav-glossary-topicrefs" select="$map//*[contains(@class, ' bookmap/glossarylist ')]//*[contains(@class, ' map/topicref ')][@href][not(@processing-role = 'resource-only')]"/>
    <xsl:variable name="nav-generate-glossary" select="
      count($nav-glossary-topicrefs) > 0 and (
        epub:is-true($epub.generate.glossary) or
        $epub.generate.glossary = 'auto'
      )
    "/>

    <!-- Determine if LOF/LOT should be generated -->
    <xsl:variable name="nav-has-figurelist" select="exists($map//*[contains(@class, ' bookmap/figurelist ')])"/>
    <xsl:variable name="nav-has-tablelist" select="exists($map//*[contains(@class, ' bookmap/tablelist ')])"/>
    <xsl:variable name="nav-generate-lof" select="
      epub:is-true($epub.generate.lof) or
      ($epub.generate.lof = 'auto' and $nav-has-figurelist)
    "/>
    <xsl:variable name="nav-generate-lot" select="
      epub:is-true($epub.generate.lot) or
      ($epub.generate.lot = 'auto' and $nav-has-tablelist)
    "/>

    <xsl:result-document href="{concat($epub.topics.dir, '/nav.xhtml')}"
                         method="xhtml"
                         encoding="UTF-8"
                         indent="yes">
      <html xmlns="http://www.w3.org/1999/xhtml"
            xml:lang="{epub:get-language($map)}"
            dir="{epub:get-dir(epub:get-language($map))}">
        <!-- Force epub namespace on root html element per EPUB 3.3 Section 7.2 -->
        <xsl:namespace name="epub">http://www.idpf.org/2007/ops</xsl:namespace>
        <head>
          <meta charset="UTF-8"/>
          <title>
            <xsl:text>Navigation - </xsl:text>
            <xsl:value-of select="epub:get-title($map)"/>
          </title>
          <xsl:call-template name="emit-css-links"/>
        </head>
        <body>
          <!-- Table of Contents -->
          <nav epub:type="toc" id="toc" role="doc-toc">
            <h1>
              <xsl:choose>
                <xsl:when test="starts-with(epub:get-language($map), 'fr')">Table des matières</xsl:when>
                <xsl:when test="starts-with(epub:get-language($map), 'de')">Inhaltsverzeichnis</xsl:when>
                <xsl:when test="starts-with(epub:get-language($map), 'es')">Tabla de contenidos</xsl:when>
                <xsl:when test="starts-with(epub:get-language($map), 'it')">Indice</xsl:when>
                <xsl:when test="starts-with(epub:get-language($map), 'pt')">Índice</xsl:when>
                <xsl:when test="starts-with(epub:get-language($map), 'nl')">Inhoudsopgave</xsl:when>
                <xsl:when test="starts-with(epub:get-language($map), 'ja')">目次</xsl:when>
                <xsl:when test="starts-with(epub:get-language($map), 'zh')">目录</xsl:when>
                <xsl:when test="starts-with(epub:get-language($map), 'ar')">جدول المحتويات</xsl:when>
                <xsl:when test="starts-with(epub:get-language($map), 'he')">תוכן עניינים</xsl:when>
                <xsl:otherwise>Table of Contents</xsl:otherwise>
              </xsl:choose>
            </h1>
            <!-- Flatten frontmatter/backmatter containers: promote their children to the top level -->
            <xsl:call-template name="generate-toc-list">
              <xsl:with-param name="topicrefs" select="
                $map/*[contains(@class, ' map/topicref ')]
                  [not(contains(@class, ' bookmap/frontmatter ') or contains(@class, ' bookmap/backmatter '))]
                | $map/*[contains(@class, ' bookmap/frontmatter ') or contains(@class, ' bookmap/backmatter ')]
                  /*[contains(@class, ' map/topicref ')]
              "/>
              <xsl:with-param name="depth" select="1"/>
              <xsl:with-param name="append-glossary" select="$nav-generate-glossary"/>
              <xsl:with-param name="append-lof" select="$nav-generate-lof"/>
              <xsl:with-param name="append-lot" select="$nav-generate-lot"/>
              <xsl:with-param name="append-index" select="$nav-generate-index"/>
              <xsl:with-param name="map" select="$map"/>
            </xsl:call-template>
          </nav>

          <!-- Landmarks navigation -->
          <xsl:if test="epub:is-true($epub.aria.landmarks)">
            <xsl:variable name="lang" select="epub:get-language($map)"/>
            <xsl:variable name="first-content-topic" select="($map//*[contains(@class, ' map/topicref ')][@href][not(@processing-role = 'resource-only')])[1]"/>
            <nav epub:type="landmarks" id="landmarks" hidden="">
              <h1>
                <xsl:choose>
                  <xsl:when test="starts-with($lang, 'fr')">Repères</xsl:when>
                  <xsl:when test="starts-with($lang, 'de')">Orientierungspunkte</xsl:when>
                  <xsl:when test="starts-with($lang, 'es')">Puntos de referencia</xsl:when>
                  <xsl:when test="starts-with($lang, 'it')">Punti di riferimento</xsl:when>
                  <xsl:when test="starts-with($lang, 'pt')">Pontos de referência</xsl:when>
                  <xsl:when test="starts-with($lang, 'nl')">Oriëntatiepunten</xsl:when>
                  <xsl:when test="starts-with($lang, 'ja')">ランドマーク</xsl:when>
                  <xsl:when test="starts-with($lang, 'zh')">导航标记</xsl:when>
                  <xsl:when test="starts-with($lang, 'ar')">نقاط مرجعية</xsl:when>
                  <xsl:when test="starts-with($lang, 'he')">ציוני דרך</xsl:when>
                  <xsl:otherwise>Landmarks</xsl:otherwise>
                </xsl:choose>
              </h1>
              <ol>
                <li>
                  <a epub:type="toc" href="nav.xhtml#toc">
                    <xsl:choose>
                      <xsl:when test="starts-with($lang, 'fr')">Table des matières</xsl:when>
                      <xsl:when test="starts-with($lang, 'de')">Inhaltsverzeichnis</xsl:when>
                      <xsl:when test="starts-with($lang, 'es')">Tabla de contenidos</xsl:when>
                      <xsl:when test="starts-with($lang, 'it')">Indice</xsl:when>
                      <xsl:when test="starts-with($lang, 'pt')">Índice</xsl:when>
                      <xsl:when test="starts-with($lang, 'nl')">Inhoudsopgave</xsl:when>
                      <xsl:when test="starts-with($lang, 'ja')">目次</xsl:when>
                      <xsl:when test="starts-with($lang, 'zh')">目录</xsl:when>
                      <xsl:when test="starts-with($lang, 'ar')">جدول المحتويات</xsl:when>
                      <xsl:when test="starts-with($lang, 'he')">תוכן עניינים</xsl:when>
                      <xsl:otherwise>Table of Contents</xsl:otherwise>
                    </xsl:choose>
                  </a>
                </li>
                <xsl:if test="$first-content-topic">
                  <li>
                    <a epub:type="bodymatter" href="{epub:get-topic-filename($first-content-topic)}">
                      <xsl:choose>
                        <xsl:when test="starts-with($lang, 'fr')">Début du contenu</xsl:when>
                        <xsl:when test="starts-with($lang, 'de')">Inhalt beginnt</xsl:when>
                        <xsl:when test="starts-with($lang, 'es')">Inicio del contenido</xsl:when>
                        <xsl:when test="starts-with($lang, 'it')">Inizio del contenuto</xsl:when>
                        <xsl:when test="starts-with($lang, 'pt')">Início do conteúdo</xsl:when>
                        <xsl:when test="starts-with($lang, 'nl')">Begin van de inhoud</xsl:when>
                        <xsl:when test="starts-with($lang, 'ja')">本文の始まり</xsl:when>
                        <xsl:when test="starts-with($lang, 'zh')">正文开始</xsl:when>
                        <xsl:when test="starts-with($lang, 'ar')">بداية المحتوى</xsl:when>
                        <xsl:when test="starts-with($lang, 'he')">תחילת התוכן</xsl:when>
                        <xsl:otherwise>Start of Content</xsl:otherwise>
                      </xsl:choose>
                    </a>
                  </li>
                </xsl:if>
                <xsl:if test="$nav-generate-glossary">
                  <li>
                    <a epub:type="glossary" href="glossary.xhtml">
                      <xsl:choose>
                        <xsl:when test="starts-with($lang, 'fr')">Glossaire</xsl:when>
                        <xsl:when test="starts-with($lang, 'de')">Glossar</xsl:when>
                        <xsl:when test="starts-with($lang, 'es')">Glosario</xsl:when>
                        <xsl:when test="starts-with($lang, 'it')">Glossario</xsl:when>
                        <xsl:when test="starts-with($lang, 'pt')">Glossário</xsl:when>
                        <xsl:when test="starts-with($lang, 'nl')">Woordenlijst</xsl:when>
                        <xsl:when test="starts-with($lang, 'ja')">用語集</xsl:when>
                        <xsl:when test="starts-with($lang, 'zh')">术语表</xsl:when>
                        <xsl:when test="starts-with($lang, 'ar')">مسرد المصطلحات</xsl:when>
                        <xsl:when test="starts-with($lang, 'he')">מילון מונחים</xsl:when>
                        <xsl:otherwise>Glossary</xsl:otherwise>
                      </xsl:choose>
                    </a>
                  </li>
                </xsl:if>
                <!-- LOF landmark -->
                <xsl:if test="$nav-generate-lof">
                  <li>
                    <a epub:type="loi" href="lof.xhtml">
                      <xsl:choose>
                        <xsl:when test="starts-with($lang, 'fr')">Liste des figures</xsl:when>
                        <xsl:when test="starts-with($lang, 'de')">Abbildungsverzeichnis</xsl:when>
                        <xsl:when test="starts-with($lang, 'es')">Lista de figuras</xsl:when>
                        <xsl:when test="starts-with($lang, 'it')">Elenco delle figure</xsl:when>
                        <xsl:when test="starts-with($lang, 'pt')">Lista de figuras</xsl:when>
                        <xsl:when test="starts-with($lang, 'nl')">Lijst van figuren</xsl:when>
                        <xsl:when test="starts-with($lang, 'ja')">図目次</xsl:when>
                        <xsl:when test="starts-with($lang, 'zh')">插图目录</xsl:when>
                        <xsl:when test="starts-with($lang, 'ar')">قائمة الأشكال</xsl:when>
                        <xsl:when test="starts-with($lang, 'he')">רשימת איורים</xsl:when>
                        <xsl:otherwise>List of Figures</xsl:otherwise>
                      </xsl:choose>
                    </a>
                  </li>
                </xsl:if>
                <!-- LOT landmark -->
                <xsl:if test="$nav-generate-lot">
                  <li>
                    <a epub:type="lot" href="lot.xhtml">
                      <xsl:choose>
                        <xsl:when test="starts-with($lang, 'fr')">Liste des tableaux</xsl:when>
                        <xsl:when test="starts-with($lang, 'de')">Tabellenverzeichnis</xsl:when>
                        <xsl:when test="starts-with($lang, 'es')">Lista de tablas</xsl:when>
                        <xsl:when test="starts-with($lang, 'it')">Elenco delle tabelle</xsl:when>
                        <xsl:when test="starts-with($lang, 'pt')">Lista de tabelas</xsl:when>
                        <xsl:when test="starts-with($lang, 'nl')">Lijst van tabellen</xsl:when>
                        <xsl:when test="starts-with($lang, 'ja')">表目次</xsl:when>
                        <xsl:when test="starts-with($lang, 'zh')">表格目录</xsl:when>
                        <xsl:when test="starts-with($lang, 'ar')">قائمة الجداول</xsl:when>
                        <xsl:when test="starts-with($lang, 'he')">רשימת טבלאות</xsl:when>
                        <xsl:otherwise>List of Tables</xsl:otherwise>
                      </xsl:choose>
                    </a>
                  </li>
                </xsl:if>
                <xsl:if test="$nav-generate-index">
                  <li>
                    <a epub:type="index" href="index.xhtml">
                      <xsl:choose>
                        <xsl:when test="starts-with($lang, 'fr')">Index</xsl:when>
                        <xsl:when test="starts-with($lang, 'de')">Stichwortverzeichnis</xsl:when>
                        <xsl:when test="starts-with($lang, 'es')">Índice</xsl:when>
                        <xsl:when test="starts-with($lang, 'it')">Indice analitico</xsl:when>
                        <xsl:when test="starts-with($lang, 'pt')">Índice remissivo</xsl:when>
                        <xsl:when test="starts-with($lang, 'nl')">Register</xsl:when>
                        <xsl:when test="starts-with($lang, 'ja')">索引</xsl:when>
                        <xsl:when test="starts-with($lang, 'zh')">索引</xsl:when>
                        <xsl:when test="starts-with($lang, 'ar')">الفهرس</xsl:when>
                        <xsl:when test="starts-with($lang, 'he')">מפתח</xsl:when>
                        <xsl:otherwise>Index</xsl:otherwise>
                      </xsl:choose>
                    </a>
                  </li>
                </xsl:if>
                <!-- Preface landmark -->
                <xsl:variable name="preface-ref" select="($map//*[contains(@class, ' bookmap/preface ')][@href] | $map//*[contains(@class, ' map/topicref ')][@type='preface'][@href])[1]"/>
                <xsl:if test="$preface-ref">
                  <li>
                    <a epub:type="preface" href="{epub:get-topic-filename($preface-ref)}">
                      <xsl:choose>
                        <xsl:when test="starts-with($lang, 'fr')">Préface</xsl:when>
                        <xsl:when test="starts-with($lang, 'de')">Vorwort</xsl:when>
                        <xsl:when test="starts-with($lang, 'es')">Prefacio</xsl:when>
                        <xsl:when test="starts-with($lang, 'it')">Prefazione</xsl:when>
                        <xsl:when test="starts-with($lang, 'pt')">Prefácio</xsl:when>
                        <xsl:when test="starts-with($lang, 'nl')">Voorwoord</xsl:when>
                        <xsl:when test="starts-with($lang, 'ja')">序文</xsl:when>
                        <xsl:when test="starts-with($lang, 'zh')">前言</xsl:when>
                        <xsl:when test="starts-with($lang, 'ar')">مقدمة</xsl:when>
                        <xsl:when test="starts-with($lang, 'he')">הקדמה</xsl:when>
                        <xsl:otherwise>Preface</xsl:otherwise>
                      </xsl:choose>
                    </a>
                  </li>
                </xsl:if>
                <!-- Dedication landmark -->
                <xsl:variable name="dedication-ref" select="($map//*[contains(@class, ' bookmap/dedication ')][@href]
                  | $map//*[contains(@class, ' map/topicref ')][@type='dedication'][@href])[1]"/>
                <xsl:if test="$dedication-ref">
                  <li>
                    <a epub:type="dedication" href="{epub:get-topic-filename($dedication-ref)}">
                      <xsl:choose>
                        <xsl:when test="starts-with($lang, 'fr')">Dédicace</xsl:when>
                        <xsl:when test="starts-with($lang, 'de')">Widmung</xsl:when>
                        <xsl:when test="starts-with($lang, 'es')">Dedicatoria</xsl:when>
                        <xsl:when test="starts-with($lang, 'it')">Dedica</xsl:when>
                        <xsl:when test="starts-with($lang, 'pt')">Dedicatória</xsl:when>
                        <xsl:when test="starts-with($lang, 'nl')">Opdracht</xsl:when>
                        <xsl:when test="starts-with($lang, 'ja')">献辞</xsl:when>
                        <xsl:when test="starts-with($lang, 'zh')">献词</xsl:when>
                        <xsl:when test="starts-with($lang, 'ar')">إهداء</xsl:when>
                        <xsl:when test="starts-with($lang, 'he')">הקדשה</xsl:when>
                        <xsl:otherwise>Dedication</xsl:otherwise>
                      </xsl:choose>
                    </a>
                  </li>
                </xsl:if>
                <!-- Appendix landmark (first appendix) -->
                <xsl:variable name="appendix-ref" select="($map//*[contains(@class, ' bookmap/appendix ')][@href])[1]"/>
                <xsl:if test="$appendix-ref">
                  <li>
                    <a epub:type="appendix" href="{epub:get-topic-filename($appendix-ref)}">
                      <xsl:choose>
                        <xsl:when test="starts-with($lang, 'fr')">Annexe</xsl:when>
                        <xsl:when test="starts-with($lang, 'de')">Anhang</xsl:when>
                        <xsl:when test="starts-with($lang, 'es')">Apéndice</xsl:when>
                        <xsl:when test="starts-with($lang, 'it')">Appendice</xsl:when>
                        <xsl:when test="starts-with($lang, 'pt')">Apêndice</xsl:when>
                        <xsl:when test="starts-with($lang, 'nl')">Bijlage</xsl:when>
                        <xsl:when test="starts-with($lang, 'ja')">付録</xsl:when>
                        <xsl:when test="starts-with($lang, 'zh')">附录</xsl:when>
                        <xsl:when test="starts-with($lang, 'ar')">ملحق</xsl:when>
                        <xsl:when test="starts-with($lang, 'he')">נספח</xsl:when>
                        <xsl:otherwise>Appendix</xsl:otherwise>
                      </xsl:choose>
                    </a>
                  </li>
                </xsl:if>
                <!-- Colophon landmark -->
                <xsl:variable name="colophon-ref" select="($map//*[contains(@class, ' bookmap/colophon ')][@href]
                  | $map//*[contains(@class, ' map/topicref ')][@type='colophon'][@href])[1]"/>
                <xsl:if test="$colophon-ref">
                  <li>
                    <a epub:type="colophon" href="{epub:get-topic-filename($colophon-ref)}">
                      <xsl:choose>
                        <xsl:when test="starts-with($lang, 'fr')">Colophon</xsl:when>
                        <xsl:when test="starts-with($lang, 'de')">Kolophon</xsl:when>
                        <xsl:when test="starts-with($lang, 'es')">Colofón</xsl:when>
                        <xsl:when test="starts-with($lang, 'it')">Colophon</xsl:when>
                        <xsl:when test="starts-with($lang, 'pt')">Colofão</xsl:when>
                        <xsl:when test="starts-with($lang, 'nl')">Colofon</xsl:when>
                        <xsl:when test="starts-with($lang, 'ja')">奥付</xsl:when>
                        <xsl:when test="starts-with($lang, 'zh')">版本记录</xsl:when>
                        <xsl:when test="starts-with($lang, 'ar')">بيانات النشر</xsl:when>
                        <xsl:when test="starts-with($lang, 'he')">קולופון</xsl:when>
                        <xsl:otherwise>Colophon</xsl:otherwise>
                      </xsl:choose>
                    </a>
                  </li>
                </xsl:if>
                <!-- Copyright page landmark (when auto-generated) -->
                <xsl:if test="$epub.copyright.page = 'yes' or ($epub.copyright.page = 'auto' and $map//*[contains(@class, ' bookmap/bookrights ')])">
                  <li>
                    <a epub:type="copyright-page" href="copyright.xhtml">
                      <xsl:choose>
                        <xsl:when test="starts-with($lang, 'fr')">Mentions légales</xsl:when>
                        <xsl:when test="starts-with($lang, 'de')">Impressum</xsl:when>
                        <xsl:when test="starts-with($lang, 'es')">Página de derechos</xsl:when>
                        <xsl:when test="starts-with($lang, 'it')">Pagina del copyright</xsl:when>
                        <xsl:when test="starts-with($lang, 'pt')">Página de direitos</xsl:when>
                        <xsl:when test="starts-with($lang, 'nl')">Copyrightpagina</xsl:when>
                        <xsl:when test="starts-with($lang, 'ja')">著作権ページ</xsl:when>
                        <xsl:when test="starts-with($lang, 'zh')">版权页</xsl:when>
                        <xsl:when test="starts-with($lang, 'ar')">صفحة حقوق النشر</xsl:when>
                        <xsl:when test="starts-with($lang, 'he')">עמוד זכויות יוצרים</xsl:when>
                        <xsl:otherwise>Copyright</xsl:otherwise>
                      </xsl:choose>
                    </a>
                  </li>
                </xsl:if>
              </ol>
            </nav>
          </xsl:if>
        </body>
      </html>
    </xsl:result-document>

    <xsl:message>EPUB3 navigation document generated.</xsl:message>
  </xsl:template>

  <!-- Generate TOC list recursively -->
  <xsl:template name="generate-toc-list">
    <xsl:param name="topicrefs" as="element()*"/>
    <xsl:param name="depth" as="xs:integer"/>
    <xsl:param name="append-glossary" as="xs:boolean" select="false()"/>
    <xsl:param name="append-lof" as="xs:boolean" select="false()"/>
    <xsl:param name="append-lot" as="xs:boolean" select="false()"/>
    <xsl:param name="append-index" as="xs:boolean" select="false()"/>
    <xsl:param name="map" as="element()?"/>

    <!-- Filter out booklists/frontmatter elements that don't have content -->
    <xsl:variable name="valid-topicrefs" select="$topicrefs[
      not(@processing-role = 'resource-only') and
      not(contains(@class, ' bookmap/booklists ')) and
      not(contains(@class, ' bookmap/toc ')) and
      not(contains(@class, ' bookmap/figurelist ')) and
      not(contains(@class, ' bookmap/tablelist ')) and
      not(contains(@class, ' bookmap/indexlist ')) and
      not(contains(@class, ' bookmap/glossarylist ')) and
      (@href or *[contains(@class, ' map/topicref ')][@href])
    ]"/>

    <xsl:if test="($valid-topicrefs or $append-glossary or $append-lof or $append-lot or $append-index) and $depth &lt;= $epub.toc.depth">
      <ol xmlns="http://www.w3.org/1999/xhtml">
        <xsl:for-each select="$valid-topicrefs">
          <li xmlns="http://www.w3.org/1999/xhtml">
            <xsl:choose>
              <xsl:when test="@href">
                <a xmlns="http://www.w3.org/1999/xhtml" href="{epub:get-topic-filename(.)}">
                  <xsl:call-template name="get-navtitle">
                    <xsl:with-param name="topicref" select="."/>
                  </xsl:call-template>
                </a>
              </xsl:when>
              <xsl:otherwise>
                <span xmlns="http://www.w3.org/1999/xhtml">
                  <xsl:call-template name="get-navtitle">
                    <xsl:with-param name="topicref" select="."/>
                  </xsl:call-template>
                </span>
              </xsl:otherwise>
            </xsl:choose>

            <!-- Process nested topicrefs -->
            <xsl:if test="*[contains(@class, ' map/topicref ')]">
              <xsl:call-template name="generate-toc-list">
                <xsl:with-param name="topicrefs" select="*[contains(@class, ' map/topicref ')]"/>
                <xsl:with-param name="depth" select="$depth + 1"/>
              </xsl:call-template>
            </xsl:if>
          </li>
        </xsl:for-each>
        <!-- Append Glossary entry before Index in top-level TOC list -->
        <xsl:if test="$append-glossary">
          <li xmlns="http://www.w3.org/1999/xhtml">
            <a xmlns="http://www.w3.org/1999/xhtml" href="glossary.xhtml">
              <xsl:choose>
                <xsl:when test="$map and starts-with(epub:get-language($map), 'fr')">Glossaire</xsl:when>
                <xsl:when test="$map and starts-with(epub:get-language($map), 'de')">Glossar</xsl:when>
                <xsl:when test="$map and starts-with(epub:get-language($map), 'es')">Glosario</xsl:when>
                <xsl:when test="$map and starts-with(epub:get-language($map), 'it')">Glossario</xsl:when>
                <xsl:when test="$map and starts-with(epub:get-language($map), 'pt')">Glossário</xsl:when>
                <xsl:when test="$map and starts-with(epub:get-language($map), 'nl')">Woordenlijst</xsl:when>
                <xsl:when test="$map and starts-with(epub:get-language($map), 'ja')">用語集</xsl:when>
                <xsl:when test="$map and starts-with(epub:get-language($map), 'zh')">术语表</xsl:when>
                <xsl:when test="$map and starts-with(epub:get-language($map), 'ar')">مسرد المصطلحات</xsl:when>
                <xsl:when test="$map and starts-with(epub:get-language($map), 'he')">מילון מונחים</xsl:when>
                <xsl:otherwise>Glossary</xsl:otherwise>
              </xsl:choose>
            </a>
          </li>
        </xsl:if>
        <!-- Append LOF entry -->
        <xsl:if test="$append-lof">
          <li xmlns="http://www.w3.org/1999/xhtml">
            <a xmlns="http://www.w3.org/1999/xhtml" href="lof.xhtml">
              <xsl:choose>
                <xsl:when test="$map and starts-with(epub:get-language($map), 'fr')">Liste des figures</xsl:when>
                <xsl:when test="$map and starts-with(epub:get-language($map), 'de')">Abbildungsverzeichnis</xsl:when>
                <xsl:when test="$map and starts-with(epub:get-language($map), 'es')">Lista de figuras</xsl:when>
                <xsl:when test="$map and starts-with(epub:get-language($map), 'it')">Elenco delle figure</xsl:when>
                <xsl:when test="$map and starts-with(epub:get-language($map), 'pt')">Lista de figuras</xsl:when>
                <xsl:when test="$map and starts-with(epub:get-language($map), 'nl')">Lijst van figuren</xsl:when>
                <xsl:when test="$map and starts-with(epub:get-language($map), 'ja')">図目次</xsl:when>
                <xsl:when test="$map and starts-with(epub:get-language($map), 'zh')">插图目录</xsl:when>
                <xsl:when test="$map and starts-with(epub:get-language($map), 'ar')">قائمة الأشكال</xsl:when>
                <xsl:when test="$map and starts-with(epub:get-language($map), 'he')">רשימת איורים</xsl:when>
                <xsl:otherwise>List of Figures</xsl:otherwise>
              </xsl:choose>
            </a>
          </li>
        </xsl:if>
        <!-- Append LOT entry -->
        <xsl:if test="$append-lot">
          <li xmlns="http://www.w3.org/1999/xhtml">
            <a xmlns="http://www.w3.org/1999/xhtml" href="lot.xhtml">
              <xsl:choose>
                <xsl:when test="$map and starts-with(epub:get-language($map), 'fr')">Liste des tableaux</xsl:when>
                <xsl:when test="$map and starts-with(epub:get-language($map), 'de')">Tabellenverzeichnis</xsl:when>
                <xsl:when test="$map and starts-with(epub:get-language($map), 'es')">Lista de tablas</xsl:when>
                <xsl:when test="$map and starts-with(epub:get-language($map), 'it')">Elenco delle tabelle</xsl:when>
                <xsl:when test="$map and starts-with(epub:get-language($map), 'pt')">Lista de tabelas</xsl:when>
                <xsl:when test="$map and starts-with(epub:get-language($map), 'nl')">Lijst van tabellen</xsl:when>
                <xsl:when test="$map and starts-with(epub:get-language($map), 'ja')">表目次</xsl:when>
                <xsl:when test="$map and starts-with(epub:get-language($map), 'zh')">表格目录</xsl:when>
                <xsl:when test="$map and starts-with(epub:get-language($map), 'ar')">قائمة الجداول</xsl:when>
                <xsl:when test="$map and starts-with(epub:get-language($map), 'he')">רשימת טבלאות</xsl:when>
                <xsl:otherwise>List of Tables</xsl:otherwise>
              </xsl:choose>
            </a>
          </li>
        </xsl:if>
        <!-- Append Index entry at end of top-level TOC list -->
        <xsl:if test="$append-index">
          <li xmlns="http://www.w3.org/1999/xhtml">
            <a xmlns="http://www.w3.org/1999/xhtml" href="index.xhtml">
              <xsl:choose>
                <xsl:when test="$map and starts-with(epub:get-language($map), 'fr')">Index</xsl:when>
                <xsl:when test="$map and starts-with(epub:get-language($map), 'de')">Stichwortverzeichnis</xsl:when>
                <xsl:when test="$map and starts-with(epub:get-language($map), 'es')">Índice alfabético</xsl:when>
                <xsl:when test="$map and starts-with(epub:get-language($map), 'it')">Indice analitico</xsl:when>
                <xsl:when test="$map and starts-with(epub:get-language($map), 'pt')">Índice remissivo</xsl:when>
                <xsl:when test="$map and starts-with(epub:get-language($map), 'nl')">Register</xsl:when>
                <xsl:when test="$map and starts-with(epub:get-language($map), 'ja')">索引</xsl:when>
                <xsl:when test="$map and starts-with(epub:get-language($map), 'zh')">索引</xsl:when>
                <xsl:when test="$map and starts-with(epub:get-language($map), 'ar')">الفهرس</xsl:when>
                <xsl:when test="$map and starts-with(epub:get-language($map), 'he')">מפתח</xsl:when>
                <xsl:otherwise>Index</xsl:otherwise>
              </xsl:choose>
            </a>
          </li>
        </xsl:if>
      </ol>
    </xsl:if>
  </xsl:template>

  <!-- Get navigation title for topicref -->
  <xsl:template name="get-navtitle">
    <xsl:param name="topicref" as="element()"/>

    <xsl:choose>
      <xsl:when test="$topicref/@navtitle">
        <xsl:value-of select="$topicref/@navtitle"/>
      </xsl:when>
      <xsl:when test="$topicref/*[contains(@class, ' map/topicmeta ')]/*[contains(@class, ' topic/navtitle ')]">
        <xsl:value-of select="normalize-space($topicref/*[contains(@class, ' map/topicmeta ')]/*[contains(@class, ' topic/navtitle ')])"/>
      </xsl:when>
      <xsl:when test="$topicref/@href">
        <xsl:value-of select="tokenize($topicref/@href, '/')[last()]"/>
      </xsl:when>
      <!-- Localized labels for bookmap structural containers -->
      <xsl:when test="contains($topicref/@class, ' bookmap/appendices ')">
        <xsl:variable name="lang" select="epub:get-language(root($topicref)/*)"/>
        <xsl:choose>
          <xsl:when test="starts-with($lang, 'fr')">Annexes</xsl:when>
          <xsl:when test="starts-with($lang, 'de')">Anhang</xsl:when>
          <xsl:when test="starts-with($lang, 'es')">Apéndices</xsl:when>
          <xsl:when test="starts-with($lang, 'it')">Appendici</xsl:when>
          <xsl:when test="starts-with($lang, 'pt')">Apêndices</xsl:when>
          <xsl:when test="starts-with($lang, 'nl')">Bijlagen</xsl:when>
          <xsl:when test="starts-with($lang, 'ja')">付録</xsl:when>
          <xsl:when test="starts-with($lang, 'zh')">附录</xsl:when>
          <xsl:when test="starts-with($lang, 'ar')">ملاحق</xsl:when>
          <xsl:when test="starts-with($lang, 'he')">נספחים</xsl:when>
          <xsl:otherwise>Appendices</xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="contains($topicref/@class, ' bookmap/frontmatter ')">
        <xsl:text>Front Matter</xsl:text>
      </xsl:when>
      <xsl:when test="contains($topicref/@class, ' bookmap/backmatter ')">
        <xsl:text>Back Matter</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:text>Untitled</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Generate content files -->
  <xsl:template name="generate-content">
    <xsl:param name="map" as="element()"/>

    <xsl:message>Generating content files...</xsl:message>

    <xsl:call-template name="generate-content-files">
      <xsl:with-param name="map" select="$map"/>
    </xsl:call-template>

    <xsl:message>Content files generated.</xsl:message>
  </xsl:template>

  <!-- Generate container.xml -->
  <xsl:template name="generate-container">
    <xsl:message>Generating META-INF/container.xml...</xsl:message>

    <xsl:result-document href="META-INF/container.xml"
                         format="xml-no-doctype">
      <container xmlns="urn:oasis:names:tc:opendocument:xmlns:container" version="1.0">
        <rootfiles>
          <rootfile full-path="{concat($epub.topics.dir, '/content.opf')}"
                    media-type="application/oebps-package+xml"/>
        </rootfiles>
      </container>
    </xsl:result-document>

    <xsl:message>container.xml generated.</xsl:message>
  </xsl:template>

  <!-- Add font items to manifest -->
  <xsl:template name="add-font-items">
    <xsl:message>Adding embedded fonts to manifest...</xsl:message>

    <xsl:choose>
      <!-- Use font file list passed from Ant pipeline -->
      <xsl:when test="normalize-space($epub.font.files) != ''">
        <xsl:for-each select="tokenize($epub.font.files, ',')">
          <xsl:variable name="filename" select="normalize-space(.)"/>
          <xsl:if test="string-length($filename) > 0">
            <item xmlns="http://www.idpf.org/2007/opf"
                  id="font-{position()}"
                  href="{epub:get-relative-path($epub.topics.dir, concat($epub.fonts.dir, '/', $filename))}"
                  media-type="{epub:get-font-media-type($filename)}"/>
          </xsl:if>
        </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
        <xsl:message>No font files list provided (epub.font.files is empty). Font manifest items skipped.</xsl:message>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Generate cover page XHTML -->
  <xsl:template name="generate-cover-page">
    <xsl:param name="map" as="element()"/>

    <xsl:if test="epub:is-true($epub.generate.cover.page) and $epub.cover.image != ''">
      <xsl:message>Generating cover page...</xsl:message>

      <xsl:variable name="cover-filename" select="tokenize(replace($epub.cover.image, '\\', '/'), '/')[last()]"/>

      <xsl:result-document href="{concat($epub.topics.dir, '/cover.xhtml')}"
                           method="xhtml"
                           encoding="UTF-8"
                           indent="yes">
        <html xmlns="http://www.w3.org/1999/xhtml"
              xml:lang="{epub:get-language($map)}"
              dir="{epub:get-dir(epub:get-language($map))}"
              class="cover-page-{if ($epub.cover.page.style = 'centered') then 'centered' else 'full'}">
          <head>
            <meta charset="UTF-8"/>
            <title>Cover</title>
            <xsl:call-template name="emit-css-links"/>
          </head>
          <body>
            <div class="cover">
              <img src="{epub:get-relative-path($epub.topics.dir, concat($epub.images.dir, '/', $cover-filename))}"
                   alt="Cover: {epub:get-title($map)}"
                   class="cover-image"/>
            </div>
          </body>
        </html>
      </xsl:result-document>

      <xsl:message>Cover page generated.</xsl:message>
    </xsl:if>
  </xsl:template>

  <!-- Generate title page XHTML -->
  <xsl:template name="generate-title-page">
    <xsl:param name="map" as="element()"/>

    <xsl:message>Generating title page...</xsl:message>

    <!-- Extract metadata from bookmap -->
    <xsl:variable name="main-title" select="epub:get-title($map)"/>
    <xsl:variable name="subtitle" select="($map//*[contains(@class, ' bookmap/booktitlealt ')])[1]"/>
    <xsl:variable name="edition" select="($map//*[contains(@class, ' bookmap/edition ')])[1]"/>
    <xsl:variable name="author-first" select="($map//*[contains(@class, ' xnal-d/firstname ')])[1]"/>
    <xsl:variable name="author-last" select="($map//*[contains(@class, ' xnal-d/lastname ')])[1]"/>
    <xsl:variable name="author-name">
      <xsl:choose>
        <xsl:when test="$author-first and $author-last">
          <xsl:value-of select="concat(normalize-space($author-first), ' ', normalize-space($author-last))"/>
        </xsl:when>
        <xsl:when test="$map//*[contains(@class, ' xnal-d/personname ')]">
          <xsl:value-of select="normalize-space(($map//*[contains(@class, ' xnal-d/personname ')])[1])"/>
        </xsl:when>
        <xsl:otherwise/>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="copyright-first" select="($map//*[contains(@class, ' bookmap/copyrfirst ')]/*[contains(@class, ' topic/year ')])[1]"/>
    <xsl:variable name="copyright-last" select="($map//*[contains(@class, ' bookmap/copyrlast ')]/*[contains(@class, ' topic/year ')])[1]"/>
    <xsl:variable name="translator" select="($map//*[contains(@class, ' topic/data ')][@name='translator'])[1]"/>
    <xsl:variable name="translator-url" select="($map//*[contains(@class, ' topic/data ')][@name='translator-url'])[1]"/>
    <xsl:variable name="license" select="($map//*[contains(@class, ' topic/data ')][@name='license'])[1]"/>
    <xsl:variable name="license-url" select="($map//*[contains(@class, ' topic/data ')][@name='license-url'])[1]"/>
    <xsl:variable name="lang" select="epub:get-language($map)"/>

    <xsl:result-document href="{concat($epub.topics.dir, '/titlepage.xhtml')}"
                         method="xhtml"
                         encoding="UTF-8"
                         indent="yes">
      <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="{$lang}" dir="{epub:get-dir($lang)}">
        <head>
          <meta charset="UTF-8"/>
          <title><xsl:value-of select="$main-title"/></title>
          <xsl:call-template name="emit-css-links"/>
        </head>
        <body>
          <div class="titlepage">
            <h1><xsl:value-of select="$main-title"/></h1>
            <xsl:if test="$subtitle and string-length(normalize-space($subtitle)) > 0">
              <h2 class="subtitle"><xsl:value-of select="normalize-space($subtitle)"/></h2>
            </xsl:if>

            <xsl:if test="$edition and string-length(normalize-space($edition)) > 0">
              <h2><xsl:value-of select="normalize-space($edition)"/></h2>
            </xsl:if>

            <p><br/></p>

            <xsl:if test="string-length($author-name) > 0">
              <h3>
                <xsl:choose>
                  <xsl:when test="starts-with($lang, 'fr')">Par : </xsl:when>
                  <xsl:when test="starts-with($lang, 'de')">Von: </xsl:when>
                  <xsl:when test="starts-with($lang, 'es')">Por: </xsl:when>
                  <xsl:when test="starts-with($lang, 'it')">Di: </xsl:when>
                  <xsl:when test="starts-with($lang, 'pt')">Por: </xsl:when>
                  <xsl:when test="starts-with($lang, 'nl')">Door: </xsl:when>
                  <xsl:when test="starts-with($lang, 'ja')">著者: </xsl:when>
                  <xsl:when test="starts-with($lang, 'zh')">作者: </xsl:when>
                  <xsl:when test="starts-with($lang, 'ar')">تأليف: </xsl:when>
                  <xsl:when test="starts-with($lang, 'he')">מאת: </xsl:when>
                  <xsl:otherwise>By: </xsl:otherwise>
                </xsl:choose>
                <xsl:value-of select="$author-name"/>
              </h3>
            </xsl:if>

            <p><br/><br/></p>

            <xsl:if test="$copyright-first">
              <p class="copyright">
                <xsl:text>Copyright © </xsl:text>
                <xsl:value-of select="normalize-space($copyright-first)"/>
                <xsl:if test="$copyright-last and normalize-space($copyright-last) != normalize-space($copyright-first)">
                  <xsl:text>-</xsl:text>
                  <xsl:value-of select="normalize-space($copyright-last)"/>
                </xsl:if>
                <xsl:if test="string-length($author-name) > 0">
                  <xsl:text> </xsl:text>
                  <xsl:value-of select="$author-name"/>
                </xsl:if>
              </p>
            </xsl:if>

            <xsl:if test="$translator and string-length(normalize-space($translator)) > 0">
              <p class="translator">
                <xsl:choose>
                  <xsl:when test="starts-with($lang, 'fr')">Traduction: </xsl:when>
                  <xsl:when test="starts-with($lang, 'de')">Übersetzung: </xsl:when>
                  <xsl:when test="starts-with($lang, 'es')">Traducción: </xsl:when>
                  <xsl:when test="starts-with($lang, 'it')">Traduzione: </xsl:when>
                  <xsl:when test="starts-with($lang, 'pt')">Tradução: </xsl:when>
                  <xsl:when test="starts-with($lang, 'nl')">Vertaling: </xsl:when>
                  <xsl:when test="starts-with($lang, 'ja')">翻訳: </xsl:when>
                  <xsl:when test="starts-with($lang, 'zh')">翻译: </xsl:when>
                  <xsl:when test="starts-with($lang, 'ar')">ترجمة: </xsl:when>
                  <xsl:when test="starts-with($lang, 'he')">תרגום: </xsl:when>
                  <xsl:otherwise>Translation: </xsl:otherwise>
                </xsl:choose>
                <xsl:choose>
                  <xsl:when test="$translator-url and string-length(normalize-space($translator-url)) > 0">
                    <a href="{normalize-space($translator-url)}"><xsl:value-of select="normalize-space($translator)"/></a>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="normalize-space($translator)"/>
                  </xsl:otherwise>
                </xsl:choose>
              </p>
            </xsl:if>

            <xsl:if test="$license and string-length(normalize-space($license)) > 0">
              <p class="license">
                <xsl:choose>
                  <xsl:when test="starts-with($lang, 'fr')">Sous licence </xsl:when>
                  <xsl:when test="starts-with($lang, 'de')">Lizenziert unter </xsl:when>
                  <xsl:when test="starts-with($lang, 'es')">Licenciado bajo </xsl:when>
                  <xsl:when test="starts-with($lang, 'it')">Rilasciato sotto licenza </xsl:when>
                  <xsl:when test="starts-with($lang, 'pt')">Licenciado sob </xsl:when>
                  <xsl:when test="starts-with($lang, 'nl')">Gelicenseerd onder </xsl:when>
                  <xsl:when test="starts-with($lang, 'ja')">ライセンス: </xsl:when>
                  <xsl:when test="starts-with($lang, 'zh')">授权协议: </xsl:when>
                  <xsl:when test="starts-with($lang, 'ar')">مرخص بموجب </xsl:when>
                  <xsl:when test="starts-with($lang, 'he')">ברישיון </xsl:when>
                  <xsl:otherwise>Licensed under </xsl:otherwise>
                </xsl:choose>
                <xsl:choose>
                  <xsl:when test="$license-url and string-length(normalize-space($license-url)) > 0">
                    <a href="{normalize-space($license-url)}"><xsl:value-of select="normalize-space($license)"/></a>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="normalize-space($license)"/>
                  </xsl:otherwise>
                </xsl:choose>
                <xsl:text>.</xsl:text>
              </p>
            </xsl:if>
          </div>
        </body>
      </html>
    </xsl:result-document>

    <xsl:message>Title page generated.</xsl:message>
  </xsl:template>

  <!-- Generate @font-face CSS from embedded font files -->
  <xsl:template name="generate-font-css">
    <xsl:if test="normalize-space($epub.font.files) != '' and epub:is-true($epub.generate.font.css)">
      <xsl:message>Generating font CSS from embedded fonts...</xsl:message>
      <xsl:result-document href="{$epub.css.dir}/epub-fonts.css" method="text" encoding="UTF-8">
        <xsl:text>/* Auto-generated @font-face declarations */&#10;&#10;</xsl:text>
        <xsl:for-each select="tokenize($epub.font.files, ',')">
          <xsl:variable name="filename" select="normalize-space(.)"/>
          <xsl:if test="string-length($filename) > 0">
            <xsl:variable name="family" select="epub:get-font-family($filename)"/>
            <xsl:variable name="weight" select="epub:get-font-weight($filename)"/>
            <xsl:variable name="style" select="epub:get-font-style($filename)"/>
            <xsl:variable name="format" select="epub:get-font-format($filename)"/>
            <xsl:text>@font-face {&#10;</xsl:text>
            <xsl:text>  font-family: '</xsl:text><xsl:value-of select="$family"/><xsl:text>';&#10;</xsl:text>
            <xsl:text>  src: url('../</xsl:text><xsl:value-of select="$epub.fonts.dir"/><xsl:text>/</xsl:text><xsl:value-of select="$filename"/><xsl:text>') format('</xsl:text><xsl:value-of select="$format"/><xsl:text>');&#10;</xsl:text>
            <xsl:text>  font-weight: </xsl:text><xsl:value-of select="$weight"/><xsl:text>;&#10;</xsl:text>
            <xsl:text>  font-style: </xsl:text><xsl:value-of select="$style"/><xsl:text>;&#10;</xsl:text>
            <xsl:text>  font-display: swap;&#10;</xsl:text>
            <xsl:text>}&#10;&#10;</xsl:text>
          </xsl:if>
        </xsl:for-each>
      </xsl:result-document>
      <xsl:message>Font CSS generated.</xsl:message>
    </xsl:if>
  </xsl:template>

  <!-- Generate copyright page XHTML -->
  <xsl:template name="generate-copyright-page">
    <xsl:param name="map" as="element()"/>

    <!-- Guard: only generate if epub.copyright.page is 'yes' or ('auto' and bookmap has copyright info) -->
    <xsl:variable name="should-generate" select="
      $epub.copyright.page = 'yes' or
      ($epub.copyright.page = 'auto' and $map//*[contains(@class, ' bookmap/bookrights ')])
    "/>

    <xsl:if test="$should-generate">
      <xsl:message>Generating copyright page...</xsl:message>

      <xsl:variable name="main-title" select="epub:get-title($map)"/>
      <xsl:variable name="id-value" select="epub:get-identifier($map)"/>
      <xsl:variable name="lang" select="epub:get-language($map)"/>

      <!-- Copyright info -->
      <xsl:variable name="copyright-first" select="($map//*[contains(@class, ' bookmap/copyrfirst ')]/*[contains(@class, ' topic/year ')])[1]"/>
      <xsl:variable name="copyright-last" select="($map//*[contains(@class, ' bookmap/copyrlast ')]/*[contains(@class, ' topic/year ')])[1]"/>
      <xsl:variable name="copyright-owner" select="($map//*[contains(@class, ' bookmap/bookowner ')]/*[contains(@class, ' bookmap/organization ')])[1]"/>
      <xsl:variable name="publisher-org" select="($map//*[contains(@class, ' bookmap/publisherinformation ')]//*[contains(@class, ' bookmap/organization ')])[1]"/>
      <xsl:variable name="license" select="($map//*[contains(@class, ' bookmap/bookmeta ')]//*[contains(@class, ' topic/data ')][@name='license'])[1]"/>

      <xsl:result-document href="{concat($epub.topics.dir, '/copyright.xhtml')}"
                           method="xhtml"
                           encoding="UTF-8"
                           indent="yes">
        <html xmlns="http://www.w3.org/1999/xhtml"
              xmlns:epub="http://www.idpf.org/2007/ops"
              xml:lang="{$lang}"
              dir="{epub:get-dir($lang)}">
          <head>
            <meta charset="UTF-8"/>
            <title>Copyright</title>
            <xsl:call-template name="emit-css-links"/>
          </head>
          <body>
            <section epub:type="copyright-page" class="copyright-page">
              <h1><xsl:value-of select="$main-title"/></h1>

              <!-- Copyright notice -->
              <xsl:if test="$copyright-first">
                <p>
                  <xsl:text>Copyright &#169; </xsl:text>
                  <xsl:value-of select="normalize-space($copyright-first)"/>
                  <xsl:if test="$copyright-last and normalize-space($copyright-last) != normalize-space($copyright-first)">
                    <xsl:text>&#8211;</xsl:text>
                    <xsl:value-of select="normalize-space($copyright-last)"/>
                  </xsl:if>
                  <xsl:if test="$copyright-owner">
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="normalize-space($copyright-owner)"/>
                  </xsl:if>
                </p>
              </xsl:if>

              <!-- All rights reserved -->
              <p class="rights">
                <xsl:choose>
                  <xsl:when test="starts-with($lang, 'fr')">Tous droits réservés.</xsl:when>
                  <xsl:when test="starts-with($lang, 'de')">Alle Rechte vorbehalten.</xsl:when>
                  <xsl:when test="starts-with($lang, 'es')">Todos los derechos reservados.</xsl:when>
                  <xsl:when test="starts-with($lang, 'it')">Tutti i diritti riservati.</xsl:when>
                  <xsl:when test="starts-with($lang, 'pt')">Todos os direitos reservados.</xsl:when>
                  <xsl:when test="starts-with($lang, 'nl')">Alle rechten voorbehouden.</xsl:when>
                  <xsl:when test="starts-with($lang, 'ja')">無断転載禁止。</xsl:when>
                  <xsl:when test="starts-with($lang, 'zh')">版权所有，翻印必究。</xsl:when>
                  <xsl:when test="starts-with($lang, 'ar')">جميع الحقوق محفوظة.</xsl:when>
                  <xsl:when test="starts-with($lang, 'he')">כל הזכויות שמורות.</xsl:when>
                  <xsl:otherwise>All rights reserved.</xsl:otherwise>
                </xsl:choose>
              </p>

              <!-- Publisher -->
              <xsl:if test="$publisher-org or normalize-space($epub.publisher) != ''">
                <p>
                  <xsl:choose>
                    <xsl:when test="starts-with($lang, 'fr')">Publié par </xsl:when>
                    <xsl:when test="starts-with($lang, 'de')">Veröffentlicht von </xsl:when>
                    <xsl:when test="starts-with($lang, 'es')">Publicado por </xsl:when>
                    <xsl:when test="starts-with($lang, 'it')">Pubblicato da </xsl:when>
                    <xsl:when test="starts-with($lang, 'pt')">Publicado por </xsl:when>
                    <xsl:when test="starts-with($lang, 'nl')">Uitgegeven door </xsl:when>
                    <xsl:when test="starts-with($lang, 'ja')">出版: </xsl:when>
                    <xsl:when test="starts-with($lang, 'zh')">出版: </xsl:when>
                    <xsl:when test="starts-with($lang, 'ar')">نشر بواسطة </xsl:when>
                    <xsl:when test="starts-with($lang, 'he')">בהוצאת </xsl:when>
                    <xsl:otherwise>Published by </xsl:otherwise>
                  </xsl:choose>
                  <xsl:value-of select="if (normalize-space($epub.publisher) != '') then $epub.publisher else normalize-space($publisher-org)"/>
                </p>
              </xsl:if>

              <!-- License -->
              <xsl:if test="$license and string-length(normalize-space($license)) > 0">
                <p>
                  <xsl:choose>
                    <xsl:when test="starts-with($lang, 'fr')">Sous licence </xsl:when>
                    <xsl:when test="starts-with($lang, 'de')">Lizenziert unter </xsl:when>
                    <xsl:when test="starts-with($lang, 'es')">Licenciado bajo </xsl:when>
                    <xsl:when test="starts-with($lang, 'it')">Rilasciato sotto licenza </xsl:when>
                    <xsl:when test="starts-with($lang, 'pt')">Licenciado sob </xsl:when>
                    <xsl:when test="starts-with($lang, 'nl')">Gelicenseerd onder </xsl:when>
                    <xsl:when test="starts-with($lang, 'ja')">ライセンス: </xsl:when>
                    <xsl:when test="starts-with($lang, 'zh')">授权协议: </xsl:when>
                    <xsl:when test="starts-with($lang, 'ar')">مرخص بموجب </xsl:when>
                    <xsl:when test="starts-with($lang, 'he')">ברישיון </xsl:when>
                    <xsl:otherwise>Licensed under </xsl:otherwise>
                  </xsl:choose>
                  <xsl:value-of select="normalize-space(if ($license/@value) then $license/@value else $license)"/>
                </p>
              </xsl:if>

              <!-- ISBN -->
              <xsl:if test="matches($id-value, '^\d{3}-?\d{1,5}-?\d{1,7}-?\d{1,6}-?\d$')">
                <p class="isbn">
                  <xsl:text>ISBN: </xsl:text>
                  <xsl:value-of select="$id-value"/>
                </p>
              </xsl:if>
            </section>
          </body>
        </html>
      </xsl:result-document>

      <xsl:message>Copyright page generated.</xsl:message>
    </xsl:if>
  </xsl:template>

  <!-- Generate NCX table of contents for backwards compatibility -->
  <xsl:template name="generate-ncx">
    <xsl:param name="map" as="element()"/>

    <xsl:message>Generating NCX table of contents...</xsl:message>

    <!-- Pre-compute flat list of all topicrefs WITH @href in document order for unique playOrder.
         Only topicrefs with @href get their own playOrder number; containers without @href
         share their first child's playOrder to avoid "different playOrder for same target" errors. -->
    <xsl:variable name="all-valid-ncx-topicrefs" select="$map//*[contains(@class, ' map/topicref ')][
      not(@processing-role = 'resource-only') and
      not(contains(@class, ' bookmap/booklists ')) and
      not(contains(@class, ' bookmap/toc ')) and
      not(contains(@class, ' bookmap/figurelist ')) and
      not(contains(@class, ' bookmap/tablelist ')) and
      not(contains(@class, ' bookmap/indexlist ')) and
      not(contains(@class, ' bookmap/glossarylist ')) and
      not(ancestor::*[contains(@class, ' bookmap/glossarylist ')]) and
      @href
    ]"/>

    <!-- NCX must be at root level for compatibility with older readers like Calibre -->
    <xsl:result-document href="toc.ncx"
                         method="xml"
                         encoding="UTF-8"
                         indent="yes"
                         omit-xml-declaration="no"
                         doctype-public="-//NISO//DTD ncx 2005-1//EN"
                         doctype-system="http://www.daisy.org/z3986/2005/ncx-2005-1.dtd">
      <ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1" xml:lang="{epub:get-language($map)}">
        <head>
          <meta name="dtb:uid" content="{epub:get-identifier($map)}"/>
          <meta name="dtb:depth" content="{$epub.toc.depth}"/>
          <meta name="dtb:generator" content="DITA2EPUB"/>
          <meta name="dtb:totalPageCount" content="0"/>
          <meta name="dtb:maxPageNumber" content="0"/>
        </head>
        <docTitle>
          <text><xsl:value-of select="epub:get-title($map)"/></text>
        </docTitle>
        <navMap>
          <!-- Flatten frontmatter/backmatter containers: promote their children to the top level -->
          <xsl:call-template name="generate-ncx-navpoints">
            <xsl:with-param name="topicrefs" select="
              $map/*[contains(@class, ' map/topicref ')]
                [not(contains(@class, ' bookmap/frontmatter ') or contains(@class, ' bookmap/backmatter '))]
              | $map/*[contains(@class, ' bookmap/frontmatter ') or contains(@class, ' bookmap/backmatter ')]
                /*[contains(@class, ' map/topicref ')]
            "/>
            <xsl:with-param name="depth" select="1"/>
            <xsl:with-param name="all-valid" select="$all-valid-ncx-topicrefs"/>
          </xsl:call-template>
        </navMap>
      </ncx>
    </xsl:result-document>

    <xsl:message>NCX table of contents generated.</xsl:message>
  </xsl:template>

  <!-- Generate NCX navPoints recursively with unique playOrder values -->
  <xsl:template name="generate-ncx-navpoints">
    <xsl:param name="topicrefs" as="element()*"/>
    <xsl:param name="depth" as="xs:integer"/>
    <xsl:param name="all-valid" as="element()*"/>

    <!-- Filter out booklists/frontmatter elements -->
    <xsl:variable name="valid-topicrefs" select="$topicrefs[
      not(@processing-role = 'resource-only') and
      not(contains(@class, ' bookmap/booklists ')) and
      not(contains(@class, ' bookmap/toc ')) and
      not(contains(@class, ' bookmap/figurelist ')) and
      not(contains(@class, ' bookmap/tablelist ')) and
      not(contains(@class, ' bookmap/indexlist ')) and
      not(contains(@class, ' bookmap/glossarylist ')) and
      not(ancestor::*[contains(@class, ' bookmap/glossarylist ')]) and
      (@href or *[contains(@class, ' map/topicref ')][@href])
    ]"/>

    <xsl:if test="$valid-topicrefs and $depth &lt;= $epub.toc.depth">
      <xsl:for-each select="$valid-topicrefs">
        <!-- Use position in the pre-computed flat list for unique playOrder.
             When a container has no @href, use the same playOrder as its first child
             to avoid "different playOrder values for same target" NCX errors. -->
        <xsl:variable name="play-order-target" select="if (@href) then . else (*[contains(@class, ' map/topicref ')][@href])[1]"/>
        <xsl:variable name="play-order" select="count($all-valid[. &lt;&lt; $play-order-target]) + 1"/>

        <navPoint xmlns="http://www.daisy.org/z3986/2005/ncx/" id="navpoint-{generate-id(.)}" playOrder="{$play-order}">
          <navLabel>
            <text>
              <xsl:call-template name="get-navtitle">
                <xsl:with-param name="topicref" select="."/>
              </xsl:call-template>
            </text>
          </navLabel>
          <xsl:choose>
            <xsl:when test="@href">
              <content src="{concat($epub.topics.dir, '/', epub:get-topic-filename(.))}"/>
            </xsl:when>
            <xsl:otherwise>
              <!-- For container elements without href, link to first child -->
              <xsl:variable name="first-child" select="(*[contains(@class, ' map/topicref ')][@href])[1]"/>
              <xsl:if test="$first-child">
                <content src="{concat($epub.topics.dir, '/', epub:get-topic-filename($first-child))}"/>
              </xsl:if>
            </xsl:otherwise>
          </xsl:choose>

          <!-- Process nested topicrefs -->
          <xsl:if test="*[contains(@class, ' map/topicref ')]">
            <xsl:call-template name="generate-ncx-navpoints">
              <xsl:with-param name="topicrefs" select="*[contains(@class, ' map/topicref ')]"/>
              <xsl:with-param name="depth" select="$depth + 1"/>
              <xsl:with-param name="all-valid" select="$all-valid"/>
            </xsl:call-template>
          </xsl:if>
        </navPoint>
      </xsl:for-each>
    </xsl:if>
  </xsl:template>

  <!-- ================================================================== -->
  <!-- List of Figures (LOF)                                               -->
  <!-- ================================================================== -->
  <xsl:template name="generate-lof">
    <xsl:param name="map" as="element()"/>

    <!-- Determine if LOF should be generated -->
    <xsl:variable name="has-figurelist" select="exists($map//*[contains(@class, ' bookmap/figurelist ')])"/>
    <xsl:variable name="should-generate" select="
      epub:is-true($epub.generate.lof) or
      ($epub.generate.lof = 'auto' and $has-figurelist)
    "/>

    <xsl:if test="$should-generate">
      <xsl:message>Generating List of Figures...</xsl:message>

      <xsl:variable name="lang" select="epub:get-language($map)"/>
      <xsl:variable name="all-topicrefs" select="$map//*[contains(@class, ' map/topicref ')][@href][not(@processing-role = 'resource-only')]"/>

      <!-- Collect all figures with titles from all topics (in document order) -->
      <xsl:variable name="fig-entries" as="element()*">
        <xsl:for-each select="$all-topicrefs">
          <xsl:variable name="topic-doc" select="document(@href, .)"/>
          <xsl:variable name="topic-filename" select="epub:get-topic-filename(.)"/>
          <xsl:for-each select="$topic-doc//*[contains(@class, ' topic/fig ')][*[contains(@class, ' topic/title ')]]">
            <xsl:variable name="fig-id" select="if (@id) then @id else generate-id(.)"/>
            <xsl:variable name="fig-title" select="normalize-space(*[contains(@class, ' topic/title ')])"/>
            <fig-entry id="{$fig-id}" title="{$fig-title}" file="{$topic-filename}"/>
          </xsl:for-each>
        </xsl:for-each>
      </xsl:variable>

      <xsl:if test="count($fig-entries) > 0">
        <xsl:variable name="lof-title">
          <xsl:choose>
            <xsl:when test="starts-with($lang, 'fr')">Liste des figures</xsl:when>
            <xsl:when test="starts-with($lang, 'de')">Abbildungsverzeichnis</xsl:when>
            <xsl:when test="starts-with($lang, 'es')">Lista de figuras</xsl:when>
            <xsl:when test="starts-with($lang, 'it')">Elenco delle figure</xsl:when>
            <xsl:when test="starts-with($lang, 'pt')">Lista de figuras</xsl:when>
            <xsl:when test="starts-with($lang, 'nl')">Lijst van figuren</xsl:when>
            <xsl:when test="starts-with($lang, 'ja')">図目次</xsl:when>
            <xsl:when test="starts-with($lang, 'zh')">插图目录</xsl:when>
            <xsl:when test="starts-with($lang, 'ar')">قائمة الأشكال</xsl:when>
            <xsl:when test="starts-with($lang, 'he')">רשימת איורים</xsl:when>
            <xsl:otherwise>List of Figures</xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <xsl:variable name="fig-label-prefix">
          <xsl:choose>
            <xsl:when test="starts-with($lang, 'fr')">Figure </xsl:when>
            <xsl:when test="starts-with($lang, 'de')">Abbildung </xsl:when>
            <xsl:when test="starts-with($lang, 'es')">Figura </xsl:when>
            <xsl:when test="starts-with($lang, 'it')">Figura </xsl:when>
            <xsl:when test="starts-with($lang, 'pt')">Figura </xsl:when>
            <xsl:when test="starts-with($lang, 'nl')">Figuur </xsl:when>
            <xsl:when test="starts-with($lang, 'ja')">図 </xsl:when>
            <xsl:when test="starts-with($lang, 'zh')">图 </xsl:when>
            <xsl:when test="starts-with($lang, 'ar')">شكل </xsl:when>
            <xsl:when test="starts-with($lang, 'he')">איור </xsl:when>
            <xsl:otherwise>Figure </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <xsl:result-document href="{concat($epub.topics.dir, '/lof.xhtml')}"
                             method="xhtml"
                             encoding="UTF-8"
                             indent="yes">
          <html xmlns="http://www.w3.org/1999/xhtml"
                xmlns:epub="http://www.idpf.org/2007/ops"
                xml:lang="{$lang}"
                dir="{epub:get-dir($lang)}">
            <head>
              <meta charset="UTF-8"/>
              <title><xsl:value-of select="$lof-title"/></title>
              <xsl:call-template name="emit-css-links"/>
            </head>
            <body>
              <nav epub:type="loi">
                <h1><xsl:value-of select="$lof-title"/></h1>
                <ol>
                  <xsl:for-each select="$fig-entries">
                    <li>
                      <a href="{@file}#{@id}">
                        <xsl:value-of select="concat($fig-label-prefix, position(), '. ', @title)"/>
                      </a>
                    </li>
                  </xsl:for-each>
                </ol>
              </nav>
            </body>
          </html>
        </xsl:result-document>

        <xsl:message>List of Figures generated with <xsl:value-of select="count($fig-entries)"/> entries.</xsl:message>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <!-- ================================================================== -->
  <!-- List of Tables (LOT)                                                -->
  <!-- ================================================================== -->
  <xsl:template name="generate-lot">
    <xsl:param name="map" as="element()"/>

    <!-- Determine if LOT should be generated -->
    <xsl:variable name="has-tablelist" select="exists($map//*[contains(@class, ' bookmap/tablelist ')])"/>
    <xsl:variable name="should-generate" select="
      epub:is-true($epub.generate.lot) or
      ($epub.generate.lot = 'auto' and $has-tablelist)
    "/>

    <xsl:if test="$should-generate">
      <xsl:message>Generating List of Tables...</xsl:message>

      <xsl:variable name="lang" select="epub:get-language($map)"/>
      <xsl:variable name="all-topicrefs" select="$map//*[contains(@class, ' map/topicref ')][@href][not(@processing-role = 'resource-only')]"/>

      <!-- Collect all tables with titles from all topics (in document order) -->
      <xsl:variable name="table-entries" as="element()*">
        <xsl:for-each select="$all-topicrefs">
          <xsl:variable name="topic-doc" select="document(@href, .)"/>
          <xsl:variable name="topic-filename" select="epub:get-topic-filename(.)"/>
          <xsl:for-each select="$topic-doc//*[contains(@class, ' topic/table ')][*[contains(@class, ' topic/title ')]]">
            <xsl:variable name="table-id" select="if (@id) then @id else generate-id(.)"/>
            <xsl:variable name="table-title" select="normalize-space(*[contains(@class, ' topic/title ')])"/>
            <table-entry id="{$table-id}" title="{$table-title}" file="{$topic-filename}"/>
          </xsl:for-each>
        </xsl:for-each>
      </xsl:variable>

      <xsl:if test="count($table-entries) > 0">
        <xsl:variable name="lot-title">
          <xsl:choose>
            <xsl:when test="starts-with($lang, 'fr')">Liste des tableaux</xsl:when>
            <xsl:when test="starts-with($lang, 'de')">Tabellenverzeichnis</xsl:when>
            <xsl:when test="starts-with($lang, 'es')">Lista de tablas</xsl:when>
            <xsl:when test="starts-with($lang, 'it')">Elenco delle tabelle</xsl:when>
            <xsl:when test="starts-with($lang, 'pt')">Lista de tabelas</xsl:when>
            <xsl:when test="starts-with($lang, 'nl')">Lijst van tabellen</xsl:when>
            <xsl:when test="starts-with($lang, 'ja')">表目次</xsl:when>
            <xsl:when test="starts-with($lang, 'zh')">表格目录</xsl:when>
            <xsl:when test="starts-with($lang, 'ar')">قائمة الجداول</xsl:when>
            <xsl:when test="starts-with($lang, 'he')">רשימת טבלאות</xsl:when>
            <xsl:otherwise>List of Tables</xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <xsl:variable name="table-label-prefix">
          <xsl:choose>
            <xsl:when test="starts-with($lang, 'fr')">Tableau </xsl:when>
            <xsl:when test="starts-with($lang, 'de')">Tabelle </xsl:when>
            <xsl:when test="starts-with($lang, 'es')">Tabla </xsl:when>
            <xsl:when test="starts-with($lang, 'it')">Tabella </xsl:when>
            <xsl:when test="starts-with($lang, 'pt')">Tabela </xsl:when>
            <xsl:when test="starts-with($lang, 'nl')">Tabel </xsl:when>
            <xsl:when test="starts-with($lang, 'ja')">表 </xsl:when>
            <xsl:when test="starts-with($lang, 'zh')">表 </xsl:when>
            <xsl:when test="starts-with($lang, 'ar')">جدول </xsl:when>
            <xsl:when test="starts-with($lang, 'he')">טבלה </xsl:when>
            <xsl:otherwise>Table </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <xsl:result-document href="{concat($epub.topics.dir, '/lot.xhtml')}"
                             method="xhtml"
                             encoding="UTF-8"
                             indent="yes">
          <html xmlns="http://www.w3.org/1999/xhtml"
                xmlns:epub="http://www.idpf.org/2007/ops"
                xml:lang="{$lang}"
                dir="{epub:get-dir($lang)}">
            <head>
              <meta charset="UTF-8"/>
              <title><xsl:value-of select="$lot-title"/></title>
              <xsl:call-template name="emit-css-links"/>
            </head>
            <body>
              <nav epub:type="lot">
                <h1><xsl:value-of select="$lot-title"/></h1>
                <ol>
                  <xsl:for-each select="$table-entries">
                    <li>
                      <a href="{@file}#{@id}">
                        <xsl:value-of select="concat($table-label-prefix, position(), '. ', @title)"/>
                      </a>
                    </li>
                  </xsl:for-each>
                </ol>
              </nav>
            </body>
          </html>
        </xsl:result-document>

        <xsl:message>List of Tables generated with <xsl:value-of select="count($table-entries)"/> entries.</xsl:message>
      </xsl:if>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>

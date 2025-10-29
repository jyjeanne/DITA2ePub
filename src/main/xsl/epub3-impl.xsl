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

  <!-- Generate OPF package document -->
  <xsl:template name="generate-opf">
    <xsl:param name="map" as="element()"/>

    <xsl:message>Generating OPF package document...</xsl:message>

    <!-- Collect all topicrefs for manifest and spine -->
    <xsl:variable name="all-topicrefs" select="$map//*[contains(@class, ' map/topicref ')][@href][not(@processing-role = 'resource-only')]"/>

    <xsl:result-document href="{concat($epub.topics.dir, '/content.opf')}"
                         method="xml"
                         encoding="UTF-8"
                         indent="yes">
      <package xmlns="http://www.idpf.org/2007/opf"
               version="3.0"
               unique-identifier="pub-id"
               xml:lang="{epub:get-language($map)}">

        <!-- Metadata -->
        <xsl:call-template name="extract-metadata">
          <xsl:with-param name="root" select="$map"/>
        </xsl:call-template>

        <!-- Manifest -->
        <manifest>
          <!-- Navigation document -->
          <item id="nav"
                href="nav.xhtml"
                media-type="application/xhtml+xml"
                properties="nav"/>

          <!-- CSS -->
          <item id="css-main"
                href="{concat($epub.css.dir, '/', $args.css)}"
                media-type="text/css"/>

          <!-- Cover image (if specified) -->
          <xsl:if test="$epub.cover.image != ''">
            <xsl:variable name="cover-filename" select="tokenize(replace($epub.cover.image, '\\', '/'), '/')[last()]"/>
            <item id="cover-image"
                  href="{concat($epub.images.dir, '/', $cover-filename)}"
                  media-type="{epub:get-media-type($cover-filename)}"
                  properties="cover-image"/>
          </xsl:if>

          <!-- Cover page (if generated) -->
          <xsl:if test="epub:is-true($epub.generate.cover.page) and $epub.cover.image != ''">
            <item id="cover"
                  href="cover.xhtml"
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

          <!-- Add images referenced in topics -->
          <xsl:variable name="all-images" select="$map//*[contains(@class, ' topic/image ')]/@href"/>
          <xsl:for-each select="distinct-values($all-images)">
            <xsl:variable name="image-filename" select="tokenize(., '/')[last()]"/>
            <xsl:variable name="image-id" select="concat('image-', replace($image-filename, '[\.\s]', '-'))"/>
            <xsl:variable name="image-path" select="concat($epub.images.dir, '/', $image-filename)"/>

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
        <spine>
          <!-- Cover page first if generated -->
          <xsl:if test="epub:is-true($epub.generate.cover.page) and $epub.cover.image != ''">
            <itemref idref="cover" linear="yes"/>
          </xsl:if>

          <!-- Main content -->
          <xsl:for-each select="$all-topicrefs">
            <xsl:variable name="filename" select="epub:get-topic-filename(.)"/>
            <xsl:variable name="topic-id" select="replace($filename, '\.xhtml$', '')"/>
            <itemref idref="{$topic-id}"/>
          </xsl:for-each>
        </spine>

        <!-- Guide (optional for backward compatibility) -->
        <xsl:if test="epub:is-true($epub.generate.cover.page) and $epub.cover.image != ''">
          <guide>
            <reference type="cover" title="Cover" href="cover.xhtml"/>
          </guide>
        </xsl:if>

      </package>
    </xsl:result-document>

    <xsl:message>OPF package document generated with <xsl:value-of select="count($all-topicrefs)"/> topics.</xsl:message>
  </xsl:template>

  <!-- Generate EPUB3 navigation document -->
  <xsl:template name="generate-nav">
    <xsl:param name="map" as="element()"/>

    <xsl:message>Generating EPUB3 navigation document...</xsl:message>

    <xsl:result-document href="{concat($epub.topics.dir, '/nav.xhtml')}"
                         method="xhtml"
                         encoding="UTF-8"
                         indent="yes">
      <html xmlns="http://www.w3.org/1999/xhtml"
            xmlns:epub="http://www.idpf.org/2007/ops"
            xml:lang="{epub:get-language($map)}">
        <head>
          <meta charset="UTF-8"/>
          <title>
            <xsl:text>Navigation - </xsl:text>
            <xsl:value-of select="epub:get-title($map)"/>
          </title>
          <link rel="stylesheet" type="text/css" href="{concat($epub.css.dir, '/', $args.css)}"/>
        </head>
        <body>
          <!-- Table of Contents -->
          <nav epub:type="toc" id="toc" role="doc-toc">
            <h1>Table of Contents</h1>
            <xsl:call-template name="generate-toc-list">
              <xsl:with-param name="topicrefs" select="$map/*[contains(@class, ' map/topicref ')]"/>
              <xsl:with-param name="depth" select="1"/>
            </xsl:call-template>
          </nav>

          <!-- Landmarks navigation -->
          <xsl:if test="epub:is-true($epub.aria.landmarks)">
            <nav epub:type="landmarks" id="landmarks" hidden="">
              <h1>Landmarks</h1>
              <ol>
                <li>
                  <a epub:type="toc" href="#toc">Table of Contents</a>
                </li>
                <xsl:if test="$map/*[contains(@class, ' map/topicref ')][1]">
                  <li>
                    <a epub:type="bodymatter" href="{epub:get-topic-filename($map/*[contains(@class, ' map/topicref ')][1])}">Start of Content</a>
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

    <xsl:if test="$topicrefs and $depth &lt;= $epub.toc.depth">
      <ol>
        <xsl:for-each select="$topicrefs[not(@processing-role = 'resource-only')]">
          <li>
            <xsl:choose>
              <xsl:when test="@href">
                <a href="{epub:get-topic-filename(.)}">
                  <xsl:call-template name="get-navtitle">
                    <xsl:with-param name="topicref" select="."/>
                  </xsl:call-template>
                </a>
              </xsl:when>
              <xsl:otherwise>
                <span>
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
                         method="xml"
                         encoding="UTF-8"
                         indent="yes">
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

    <!-- Common font file extensions to scan for -->
    <xsl:variable name="font-extensions" select="('ttf', 'otf', 'woff', 'woff2')"/>

    <!-- Generate manifest items for common font file names -->
    <!-- In a real implementation, this would scan the actual fonts directory -->
    <!-- For now, we'll create a placeholder that documents the approach -->

    <xsl:comment> Font manifest items will be added here </xsl:comment>
    <xsl:comment> Fonts should be placed in the fonts/ directory </xsl:comment>
    <xsl:comment> Common font media types: </xsl:comment>
    <xsl:comment>   .ttf  -> font/ttf or application/x-font-ttf </xsl:comment>
    <xsl:comment>   .otf  -> font/otf or application/x-font-opentype </xsl:comment>
    <xsl:comment>   .woff -> font/woff or application/font-woff </xsl:comment>
    <xsl:comment>   .woff2 -> font/woff2 or application/font-woff2 </xsl:comment>

    <!-- Example font items - these would be generated dynamically -->
    <!-- Uncomment and customize for your fonts:
    <item id="font-1"
          href="fonts/YourFont-Regular.ttf"
          media-type="font/ttf"/>
    <item id="font-2"
          href="fonts/YourFont-Bold.ttf"
          media-type="font/ttf"/>
    -->
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
        <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="{epub:get-language($map)}">
          <head>
            <meta charset="UTF-8"/>
            <title>Cover</title>
            <link rel="stylesheet" type="text/css" href="{concat($epub.css.dir, '/', $args.css)}"/>
            <style type="text/css">
              <xsl:choose>
                <xsl:when test="$epub.cover.page.style = 'full-page'">
                  body {
                    margin: 0;
                    padding: 0;
                    text-align: center;
                  }
                  .cover-image {
                    width: 100%;
                    height: 100vh;
                    object-fit: contain;
                  }
                </xsl:when>
                <xsl:when test="$epub.cover.page.style = 'centered'">
                  body {
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    min-height: 100vh;
                    margin: 0;
                    padding: 2em;
                  }
                  .cover-image {
                    max-width: 100%;
                    max-height: 90vh;
                  }
                </xsl:when>
              </xsl:choose>
            </style>
          </head>
          <body>
            <div class="cover">
              <img src="{concat($epub.images.dir, '/', $cover-filename)}"
                   alt="Cover: {epub:get-title($map)}"
                   class="cover-image"/>
            </div>
          </body>
        </html>
      </xsl:result-document>

      <xsl:message>Cover page generated.</xsl:message>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>

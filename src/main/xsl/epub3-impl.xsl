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
          <!-- NCX for backwards compatibility (at root level) -->
          <item id="ncx"
                href="../toc.ncx"
                media-type="application/x-dtbncx+xml"/>

          <!-- Navigation document -->
          <item id="nav"
                href="nav.xhtml"
                media-type="application/xhtml+xml"
                properties="nav"/>

          <!-- CSS - use relative path from content/ directory -->
          <item id="css-main"
                href="{epub:get-relative-path($epub.topics.dir, concat($epub.css.dir, '/', $args.css))}"
                media-type="text/css"/>

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

          <!-- Content documents -->
          <xsl:for-each select="$all-topicrefs">
            <xsl:variable name="filename" select="epub:get-topic-filename(.)"/>
            <xsl:variable name="topic-id" select="replace($filename, '\.xhtml$', '')"/>

            <item id="{$topic-id}"
                  href="{$filename}"
                  media-type="application/xhtml+xml"/>
          </xsl:for-each>

          <!-- Add images referenced in topics - use relative path from content/ directory -->
          <xsl:variable name="all-images" select="$map//*[contains(@class, ' topic/image ')]/@href"/>
          <xsl:for-each select="distinct-values($all-images)">
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
        <spine toc="ncx">
          <!-- Cover page first if generated -->
          <xsl:if test="epub:is-true($epub.generate.cover.page) and $epub.cover.image != ''">
            <itemref idref="cover" linear="yes"/>
          </xsl:if>

          <!-- Title page -->
          <itemref idref="titlepage"/>

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
          <link rel="stylesheet" type="text/css" href="{epub:get-relative-path($epub.topics.dir, concat($epub.css.dir, '/', $args.css))}"/>
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
                <xsl:otherwise>Table of Contents</xsl:otherwise>
              </xsl:choose>
            </h1>
            <xsl:call-template name="generate-toc-list">
              <xsl:with-param name="topicrefs" select="$map/*[contains(@class, ' map/topicref ')]"/>
              <xsl:with-param name="depth" select="1"/>
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
                  <xsl:otherwise>Landmarks</xsl:otherwise>
                </xsl:choose>
              </h1>
              <ol>
                <li>
                  <a epub:type="toc" href="#toc">
                    <xsl:choose>
                      <xsl:when test="starts-with($lang, 'fr')">Table des matières</xsl:when>
                      <xsl:when test="starts-with($lang, 'de')">Inhaltsverzeichnis</xsl:when>
                      <xsl:when test="starts-with($lang, 'es')">Tabla de contenidos</xsl:when>
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
                        <xsl:otherwise>Start of Content</xsl:otherwise>
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

    <!-- Filter out booklists/frontmatter elements that don't have content -->
    <xsl:variable name="valid-topicrefs" select="$topicrefs[
      not(@processing-role = 'resource-only') and
      not(contains(@class, ' bookmap/booklists ')) and
      not(contains(@class, ' bookmap/toc ')) and
      not(contains(@class, ' bookmap/figurelist ')) and
      not(contains(@class, ' bookmap/tablelist ')) and
      not(contains(@class, ' bookmap/indexlist ')) and
      (@href or *[contains(@class, ' map/topicref ')][@href])
    ]"/>

    <xsl:if test="$valid-topicrefs and $depth &lt;= $epub.toc.depth">
      <ol>
        <xsl:for-each select="$valid-topicrefs">
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
                         indent="yes"
                         standalone="omit">
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
            <link rel="stylesheet" type="text/css" href="{epub:get-relative-path($epub.topics.dir, concat($epub.css.dir, '/', $args.css))}"/>
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
    <xsl:variable name="copyright-first" select="($map//*[contains(@class, ' bookmap/copyrfirst ')]/*[contains(@class, ' bookmap/year ')])[1]"/>
    <xsl:variable name="copyright-last" select="($map//*[contains(@class, ' bookmap/copyrlast ')]/*[contains(@class, ' bookmap/year ')])[1]"/>
    <xsl:variable name="translator" select="($map//*[contains(@class, ' topic/data ')][@name='translator'])[1]"/>
    <xsl:variable name="translator-url" select="($map//*[contains(@class, ' topic/data ')][@name='translator-url'])[1]"/>
    <xsl:variable name="license" select="($map//*[contains(@class, ' topic/data ')][@name='license'])[1]"/>
    <xsl:variable name="license-url" select="($map//*[contains(@class, ' topic/data ')][@name='license-url'])[1]"/>
    <xsl:variable name="lang" select="epub:get-language($map)"/>

    <xsl:result-document href="{concat($epub.topics.dir, '/titlepage.xhtml')}"
                         method="xhtml"
                         encoding="UTF-8"
                         indent="yes">
      <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="{$lang}">
        <head>
          <meta charset="UTF-8"/>
          <title><xsl:value-of select="$main-title"/></title>
          <link rel="stylesheet" type="text/css" href="{epub:get-relative-path($epub.topics.dir, concat($epub.css.dir, '/', $args.css))}"/>
          <style type="text/css">
            .titlepage {
              text-align: center;
              padding: 2em;
            }
            .titlepage h1 {
              font-size: 2em;
              margin-bottom: 0.5em;
            }
            .titlepage h2 {
              font-size: 1.2em;
              font-weight: normal;
              margin-bottom: 2em;
            }
            .titlepage h3 {
              font-size: 1.1em;
              font-weight: normal;
              margin: 2em 0;
            }
            .titlepage p {
              margin: 1em 0;
            }
            .titlepage .copyright,
            .titlepage .translator,
            .titlepage .license {
              font-size: 0.9em;
            }
          </style>
        </head>
        <body>
          <div class="titlepage">
            <h1><xsl:value-of select="if ($subtitle and string-length(normalize-space($subtitle)) > 0) then normalize-space($subtitle) else $main-title"/></h1>

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

  <!-- Generate NCX table of contents for backwards compatibility -->
  <xsl:template name="generate-ncx">
    <xsl:param name="map" as="element()"/>

    <xsl:message>Generating NCX table of contents...</xsl:message>

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
          <xsl:call-template name="generate-ncx-navpoints">
            <xsl:with-param name="topicrefs" select="$map/*[contains(@class, ' map/topicref ')]"/>
            <xsl:with-param name="depth" select="1"/>
            <xsl:with-param name="play-order" select="1"/>
          </xsl:call-template>
        </navMap>
      </ncx>
    </xsl:result-document>

    <xsl:message>NCX table of contents generated.</xsl:message>
  </xsl:template>

  <!-- Generate NCX navPoints recursively -->
  <xsl:template name="generate-ncx-navpoints">
    <xsl:param name="topicrefs" as="element()*"/>
    <xsl:param name="depth" as="xs:integer"/>
    <xsl:param name="play-order" as="xs:integer"/>

    <!-- Filter out booklists/frontmatter elements -->
    <xsl:variable name="valid-topicrefs" select="$topicrefs[
      not(@processing-role = 'resource-only') and
      not(contains(@class, ' bookmap/booklists ')) and
      not(contains(@class, ' bookmap/toc ')) and
      not(contains(@class, ' bookmap/figurelist ')) and
      not(contains(@class, ' bookmap/tablelist ')) and
      not(contains(@class, ' bookmap/indexlist ')) and
      (@href or *[contains(@class, ' map/topicref ')][@href])
    ]"/>

    <xsl:if test="$valid-topicrefs and $depth &lt;= $epub.toc.depth">
      <xsl:for-each select="$valid-topicrefs">
        <xsl:variable name="pos" select="position()"/>
        <xsl:variable name="current-order" select="$play-order + $pos - 1"/>

        <navPoint xmlns="http://www.daisy.org/z3986/2005/ncx/" id="navpoint-{generate-id(.)}" playOrder="{$current-order}">
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
              <xsl:with-param name="play-order" select="$current-order + 1"/>
            </xsl:call-template>
          </xsl:if>
        </navPoint>
      </xsl:for-each>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>

<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xhtml="http://www.w3.org/1999/xhtml"
                xmlns:epub="http://www.idpf.org/2007/ops"
                xmlns:dita-ot="http://dita-ot.sourceforge.net"
                exclude-result-prefixes="xs xhtml dita-ot"
                version="3.0">

  <!--
    EPUB3 Content Generation

    Transforms DITA topics to XHTML5 content for EPUB3.
    All literal HTML elements use xmlns="http://www.w3.org/1999/xhtml"
    to ensure proper namespace serialization inside EPUB XHTML documents.
  -->

  <!-- Generate all content files from DITA map -->
  <xsl:template name="generate-content-files">
    <xsl:param name="map" as="element()"/>

    <xsl:message>Generating content files from DITA topics...</xsl:message>

    <!-- Process all topicrefs in the map -->
    <xsl:apply-templates select="$map//*[contains(@class, ' map/topicref ')]" mode="generate-content"/>

    <xsl:message>Content generation complete.</xsl:message>
  </xsl:template>

  <!-- Process topicref and generate XHTML file -->
  <xsl:template match="*[contains(@class, ' map/topicref ')]" mode="generate-content">
    <xsl:variable name="href" select="@href"/>
    <xsl:variable name="output-filename" select="epub:get-topic-filename(.)"/>

    <!-- Only process if topicref has an href -->
    <xsl:if test="$href and not(@processing-role = 'resource-only')">
      <xsl:message>Processing topic: <xsl:value-of select="$href"/></xsl:message>

      <xsl:result-document href="{concat($epub.topics.dir, '/', $output-filename)}"
                           method="xhtml"
                           encoding="UTF-8"
                           indent="yes"
                           omit-xml-declaration="no">
        <xsl:call-template name="generate-topic-content">
          <xsl:with-param name="topicref" select="."/>
          <xsl:with-param name="filename" select="$output-filename"/>
        </xsl:call-template>
      </xsl:result-document>
    </xsl:if>
  </xsl:template>

  <!-- Generate XHTML5 content for a single topic -->
  <xsl:template name="generate-topic-content">
    <xsl:param name="topicref" as="element()"/>
    <xsl:param name="filename" as="xs:string"/>

    <!-- Load topic to get its language and title -->
    <xsl:variable name="topic-doc" select="if ($topicref/@href) then document($topicref/@href, $topicref) else ()"/>
    <xsl:variable name="topic" select="$topic-doc/*[contains(@class, ' topic/topic ') or self::topic or self::concept or self::task or self::reference]"/>
    <xsl:variable name="topic-lang" select="($topic/@xml:lang, epub:get-language(/*))[1]"/>

    <xsl:variable name="topic-title">
      <xsl:choose>
        <xsl:when test="$topic/*[contains(@class, ' topic/title ') or self::title]">
          <xsl:value-of select="$topic/*[contains(@class, ' topic/title ') or self::title]"/>
        </xsl:when>
        <xsl:when test="$topicref/@navtitle">
          <xsl:value-of select="$topicref/@navtitle"/>
        </xsl:when>
        <xsl:when test="$topicref/*[contains(@class, ' map/topicmeta ')]/*[contains(@class, ' topic/navtitle ')]">
          <xsl:value-of select="$topicref/*[contains(@class, ' map/topicmeta ')]/*[contains(@class, ' topic/navtitle ')]"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>Topic</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <html xmlns="http://www.w3.org/1999/xhtml"
          xmlns:epub="http://www.idpf.org/2007/ops"
          xml:lang="{$topic-lang}">
      <head>
        <meta charset="UTF-8"/>
        <title><xsl:value-of select="epub:clean-text($topic-title)"/></title>
        <link rel="stylesheet" type="text/css" href="{epub:get-relative-path($epub.topics.dir, concat($epub.css.dir, '/', $args.css))}"/>

        <!-- Accessibility metadata -->
        <xsl:if test="epub:is-true($epub.accessibility)">
          <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        </xsl:if>
      </head>
      <body>
        <!-- Skip navigation link for accessibility -->
        <xsl:if test="epub:is-true($epub.skip.nav)">
          <a href="#content" class="skip-nav">Skip to main content</a>
        </xsl:if>

        <!-- Main content -->
        <main id="content" role="main">
          <xsl:call-template name="generate-topic-body">
            <xsl:with-param name="topicref" select="$topicref"/>
          </xsl:call-template>
        </main>
      </body>
    </html>
  </xsl:template>

  <!-- Generate topic body content -->
  <xsl:template name="generate-topic-body">
    <xsl:param name="topicref" as="element()"/>

    <!-- Load the DITA topic file -->
    <xsl:variable name="topic-href" select="$topicref/@href"/>
    <xsl:variable name="topic-doc" select="if ($topic-href) then document($topic-href, $topicref) else ()"/>
    <xsl:variable name="topic" select="$topic-doc/*[contains(@class, ' topic/topic ') or self::topic or self::concept or self::task or self::reference]"/>

    <!-- Fallback title from topicref -->
    <xsl:variable name="fallback-title">
      <xsl:choose>
        <xsl:when test="$topicref/@navtitle">
          <xsl:value-of select="$topicref/@navtitle"/>
        </xsl:when>
        <xsl:when test="$topicref/*[contains(@class, ' map/topicmeta ')]/*[contains(@class, ' topic/navtitle ')]">
          <xsl:value-of select="$topicref/*[contains(@class, ' map/topicmeta ')]/*[contains(@class, ' topic/navtitle ')]"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>Topic Content</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <article xmlns="http://www.w3.org/1999/xhtml">
      <!-- Determine epub:type from bookmap context (SSV vocabulary) -->
      <xsl:attribute name="epub:type">
        <xsl:choose>
          <xsl:when test="contains($topicref/@class, ' bookmap/preface ')">preface</xsl:when>
          <xsl:when test="$topicref/ancestor-or-self::*[contains(@class, ' bookmap/frontmatter ')]
                          and not(contains($topicref/@class, ' bookmap/preface '))">foreword</xsl:when>
          <xsl:when test="contains($topicref/@class, ' bookmap/appendix ')">appendix</xsl:when>
          <xsl:when test="$topicref/ancestor-or-self::*[contains(@class, ' bookmap/appendix ')]">appendix</xsl:when>
          <xsl:when test="contains($topicref/@class, ' bookmap/glossarylist ')
                          or contains($topicref/@class, ' glossentry/glossentry ')">glossary</xsl:when>
          <xsl:when test="contains($topicref/@class, ' bookmap/chapter ')">chapter</xsl:when>
          <xsl:when test="$topicref/ancestor::*[contains(@class, ' bookmap/chapter ')]">chapter</xsl:when>
          <xsl:otherwise>chapter</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:choose>
        <xsl:when test="$topic">
          <!-- Process actual topic content -->
          <xsl:apply-templates select="$topic/*[contains(@class, ' topic/title ') or self::title]" mode="topic-content"/>
          <xsl:apply-templates select="$topic/*[contains(@class, ' topic/shortdesc ') or self::shortdesc]" mode="topic-content"/>
          <xsl:apply-templates select="$topic/*[contains(@class, ' topic/body ') or self::body or self::conbody or self::taskbody or self::refbody]" mode="topic-content"/>
        </xsl:when>
        <xsl:otherwise>
          <!-- Fallback for missing topics -->
          <h1><xsl:value-of select="$fallback-title"/></h1>
          <p class="error">Topic file not found: <xsl:value-of select="$topic-href"/></p>
        </xsl:otherwise>
      </xsl:choose>
    </article>
  </xsl:template>

  <!--
    topic-content mode templates
    Each top-level literal element declares xmlns="http://www.w3.org/1999/xhtml"
    so the output is in the correct XHTML namespace.
  -->

  <!-- Transform DITA topic title to HTML h1 -->
  <xsl:template match="*[contains(@class, ' topic/title ')] | title" mode="topic-content">
    <h1 xmlns="http://www.w3.org/1999/xhtml">
      <xsl:if test="parent::*/@id">
        <xsl:attribute name="id" select="parent::*/@id"/>
      </xsl:if>
      <xsl:apply-templates mode="topic-content"/>
    </h1>
  </xsl:template>

  <!-- Transform DITA shortdesc to HTML p with class -->
  <xsl:template match="*[contains(@class, ' topic/shortdesc ')] | shortdesc" mode="topic-content">
    <p xmlns="http://www.w3.org/1999/xhtml" class="shortdesc">
      <xsl:apply-templates mode="topic-content"/>
    </p>
  </xsl:template>

  <!-- Transform DITA topic body - pass through to process children -->
  <xsl:template match="*[contains(@class, ' topic/body ')] | body | conbody | taskbody | refbody" mode="topic-content">
    <xsl:apply-templates mode="topic-content"/>
  </xsl:template>

  <!-- Transform DITA paragraph to HTML p -->
  <xsl:template match="*[contains(@class, ' topic/p ')] | p" mode="topic-content">
    <p xmlns="http://www.w3.org/1999/xhtml">
      <xsl:if test="@id">
        <xsl:attribute name="id" select="@id"/>
      </xsl:if>
      <xsl:apply-templates mode="topic-content"/>
    </p>
  </xsl:template>

  <!-- Transform DITA section to HTML section -->
  <xsl:template match="*[contains(@class, ' topic/section ')] | section" mode="topic-content">
    <section xmlns="http://www.w3.org/1999/xhtml">
      <xsl:if test="@id">
        <xsl:attribute name="id" select="@id"/>
      </xsl:if>
      <xsl:apply-templates mode="topic-content"/>
    </section>
  </xsl:template>

  <!-- Transform section title to h2 -->
  <xsl:template match="*[contains(@class, ' topic/section ')]/*[contains(@class, ' topic/title ')] | section/title" mode="topic-content" priority="10">
    <h2 xmlns="http://www.w3.org/1999/xhtml">
      <xsl:apply-templates mode="topic-content"/>
    </h2>
  </xsl:template>

  <!-- Transform DITA ul to HTML ul -->
  <xsl:template match="*[contains(@class, ' topic/ul ')] | ul" mode="topic-content">
    <ul xmlns="http://www.w3.org/1999/xhtml">
      <xsl:apply-templates select="node()" mode="topic-content"/>
    </ul>
  </xsl:template>

  <!-- Transform DITA ol to HTML ol -->
  <xsl:template match="*[contains(@class, ' topic/ol ')] | ol" mode="topic-content">
    <ol xmlns="http://www.w3.org/1999/xhtml">
      <xsl:apply-templates select="node()" mode="topic-content"/>
    </ol>
  </xsl:template>

  <!-- Transform DITA li to HTML li -->
  <xsl:template match="*[contains(@class, ' topic/li ')] | li" mode="topic-content">
    <li xmlns="http://www.w3.org/1999/xhtml">
      <xsl:apply-templates select="node()" mode="topic-content"/>
    </li>
  </xsl:template>

  <!-- Transform DITA note to HTML aside with class -->
  <xsl:template match="*[contains(@class, ' topic/note ')] | note" mode="topic-content">
    <aside xmlns="http://www.w3.org/1999/xhtml" class="note note-{(@type, 'note')[1]}" role="note">
      <xsl:if test="@type">
        <strong class="note-label">
          <xsl:choose>
            <xsl:when test="@type = 'tip'">Astuce : </xsl:when>
            <xsl:when test="@type = 'important'">Important : </xsl:when>
            <xsl:when test="@type = 'warning'">Attention : </xsl:when>
            <xsl:when test="@type = 'caution'">Attention : </xsl:when>
            <xsl:when test="@type = 'danger'">Danger : </xsl:when>
            <xsl:when test="@type = 'notice'">Remarque : </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="concat(upper-case(substring(@type, 1, 1)), substring(@type, 2), ' : ')"/>
            </xsl:otherwise>
          </xsl:choose>
        </strong>
      </xsl:if>
      <xsl:apply-templates select="node()" mode="topic-content"/>
    </aside>
  </xsl:template>

  <!-- Transform DITA xref to HTML a -->
  <xsl:template match="*[contains(@class, ' topic/xref ')] | xref" mode="topic-content">
    <a xmlns="http://www.w3.org/1999/xhtml">
      <xsl:attribute name="href">
        <xsl:choose>
          <xsl:when test="@scope = 'external'">
            <xsl:value-of select="@href"/>
          </xsl:when>
          <xsl:when test="@format = 'dita' or ends-with(@href, '.dita')">
            <!-- Convert .dita to .xhtml -->
            <xsl:value-of select="replace(@href, '\.dita$', '.xhtml')"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="@href"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:if test="@scope = 'external'">
        <xsl:attribute name="target">_blank</xsl:attribute>
        <xsl:attribute name="rel">noopener noreferrer</xsl:attribute>
      </xsl:if>
      <xsl:choose>
        <xsl:when test="node()">
          <xsl:apply-templates mode="topic-content"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="@href"/>
        </xsl:otherwise>
      </xsl:choose>
    </a>
  </xsl:template>

  <!-- Transform DITA image to HTML img -->
  <xsl:template match="*[contains(@class, ' topic/image ')]" mode="topic-content">
    <xsl:variable name="image-path" select="concat($epub.images.dir, '/', tokenize(@href, '/')[last()])"/>

    <figure xmlns="http://www.w3.org/1999/xhtml">
      <img src="{$image-path}">
        <xsl:if test="@alt">
          <xsl:attribute name="alt" select="@alt"/>
        </xsl:if>
        <xsl:if test="@width">
          <xsl:attribute name="width" select="@width"/>
        </xsl:if>
        <xsl:if test="@height">
          <xsl:attribute name="height" select="@height"/>
        </xsl:if>
      </img>

      <!-- Add caption if present -->
      <xsl:if test="following-sibling::*[contains(@class, ' topic/desc ')][1]">
        <figcaption>
          <xsl:apply-templates select="following-sibling::*[contains(@class, ' topic/desc ')][1]/node()" mode="topic-content"/>
        </figcaption>
      </xsl:if>
    </figure>
  </xsl:template>

  <!-- Transform DITA table to HTML table -->
  <xsl:template match="*[contains(@class, ' topic/table ')]" mode="topic-content">
    <table xmlns="http://www.w3.org/1999/xhtml">
      <xsl:if test="*[contains(@class, ' topic/title ')]">
        <caption>
          <xsl:apply-templates select="*[contains(@class, ' topic/title ')]/node()" mode="topic-content"/>
        </caption>
      </xsl:if>
      <xsl:apply-templates select="*[contains(@class, ' topic/tgroup ')]" mode="topic-content"/>
    </table>
  </xsl:template>

  <!-- Transform DITA tgroup -->
  <xsl:template match="*[contains(@class, ' topic/tgroup ')]" mode="topic-content">
    <xsl:apply-templates select="*[contains(@class, ' topic/thead ')]" mode="topic-content"/>
    <xsl:apply-templates select="*[contains(@class, ' topic/tbody ')]" mode="topic-content"/>
  </xsl:template>

  <!-- Transform DITA thead to HTML thead -->
  <xsl:template match="*[contains(@class, ' topic/thead ')]" mode="topic-content">
    <thead xmlns="http://www.w3.org/1999/xhtml">
      <xsl:apply-templates select="*[contains(@class, ' topic/row ')]" mode="topic-content"/>
    </thead>
  </xsl:template>

  <!-- Transform DITA tbody to HTML tbody -->
  <xsl:template match="*[contains(@class, ' topic/tbody ')]" mode="topic-content">
    <tbody xmlns="http://www.w3.org/1999/xhtml">
      <xsl:apply-templates select="*[contains(@class, ' topic/row ')]" mode="topic-content"/>
    </tbody>
  </xsl:template>

  <!-- Transform DITA row to HTML tr -->
  <xsl:template match="*[contains(@class, ' topic/row ')]" mode="topic-content">
    <tr xmlns="http://www.w3.org/1999/xhtml">
      <xsl:apply-templates select="*[contains(@class, ' topic/entry ')]" mode="topic-content"/>
    </tr>
  </xsl:template>

  <!-- Transform DITA entry to HTML td or th -->
  <xsl:template match="*[contains(@class, ' topic/entry ')]" mode="topic-content">
    <xsl:variable name="element-name">
      <xsl:choose>
        <xsl:when test="parent::*[contains(@class, ' topic/row ')]/parent::*[contains(@class, ' topic/thead ')]">th</xsl:when>
        <xsl:otherwise>td</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:element name="{$element-name}" namespace="http://www.w3.org/1999/xhtml">
      <xsl:apply-templates select="node()" mode="topic-content"/>
    </xsl:element>
  </xsl:template>

  <!-- Transform DITA codeblock to HTML pre/code -->
  <xsl:template match="*[contains(@class, ' pr-d/codeblock ')]" mode="topic-content">
    <pre xmlns="http://www.w3.org/1999/xhtml">
      <code>
        <xsl:apply-templates select="node()" mode="topic-content"/>
      </code>
    </pre>
  </xsl:template>

  <!-- Transform DITA codeph to HTML code -->
  <xsl:template match="*[contains(@class, ' pr-d/codeph ')]" mode="topic-content">
    <code xmlns="http://www.w3.org/1999/xhtml">
      <xsl:apply-templates select="node()" mode="topic-content"/>
    </code>
  </xsl:template>

  <!-- Transform DITA b to HTML strong -->
  <xsl:template match="*[contains(@class, ' hi-d/b ')]" mode="topic-content">
    <strong xmlns="http://www.w3.org/1999/xhtml">
      <xsl:apply-templates select="node()" mode="topic-content"/>
    </strong>
  </xsl:template>

  <!-- Transform DITA i to HTML em -->
  <xsl:template match="*[contains(@class, ' hi-d/i ')]" mode="topic-content">
    <em xmlns="http://www.w3.org/1999/xhtml">
      <xsl:apply-templates select="node()" mode="topic-content"/>
    </em>
  </xsl:template>

  <!-- Copy text nodes -->
  <xsl:template match="text()" mode="topic-content">
    <xsl:value-of select="."/>
  </xsl:template>

  <!-- Insert index anchor spans for indexterm elements (linked from back-of-book index) -->
  <xsl:template match="indexterm | *[contains(@class, ' topic/indexterm ')]" mode="topic-content">
    <!-- Compute deterministic anchor ID matching epub3-index.xsl collection -->
    <xsl:variable name="all-indexterms" select="root()//*[self::indexterm or contains(@class, ' topic/indexterm ')]"/>
    <xsl:variable name="pos" select="count($all-indexterms[. &lt;&lt; current()]) + 1"/>
    <xsl:variable name="topic-id" select="(root()//*[contains(@class, ' topic/topic ') or self::topic or self::concept or self::task or self::reference])[1]/@id"/>
    <span xmlns="http://www.w3.org/1999/xhtml" id="ixa-{$topic-id}-{$pos}"/>
    <!-- Process nested indexterms to generate their anchors too -->
    <xsl:apply-templates select="*[self::indexterm or contains(@class, ' topic/indexterm ')]" mode="topic-content"/>
  </xsl:template>

  <!-- Default template - ignore unknown elements but process children -->
  <xsl:template match="*" mode="topic-content">
    <xsl:apply-templates select="node()" mode="topic-content"/>
  </xsl:template>

</xsl:stylesheet>

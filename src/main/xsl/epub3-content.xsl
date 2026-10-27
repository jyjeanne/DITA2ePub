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

    <!-- Pre-compute global numbering offsets for cross-topic figure/table numbering.
         The preceding:: axis only works within a single document tree, so when each
         topic is loaded via document(), numbering restarts from 1. This pre-computes
         cumulative counts so each topic can offset its local numbers correctly. -->
    <xsl:variable name="all-content-topicrefs" select="epub:content-topicrefs($map)"/>
    <xsl:variable name="numbering-offsets" as="element()*">
      <xsl:iterate select="$all-content-topicrefs">
        <xsl:param name="fig-total" as="xs:integer" select="0"/>
        <xsl:param name="table-total" as="xs:integer" select="0"/>

        <xsl:variable name="topic-doc" select="epub:topic-document(.)"/>
        <xsl:variable name="fig-count" select="if ($topic-doc) then count($topic-doc//*[contains(@class, ' topic/fig ')]) else 0"/>
        <xsl:variable name="table-count" select="if ($topic-doc) then count($topic-doc//*[contains(@class, ' topic/table ')]) else 0"/>

        <numbering-offset href="{@href}" fig="{$fig-total}" table="{$table-total}"/>

        <xsl:next-iteration>
          <xsl:with-param name="fig-total" select="$fig-total + $fig-count"/>
          <xsl:with-param name="table-total" select="$table-total + $table-count"/>
        </xsl:next-iteration>
      </xsl:iterate>
    </xsl:variable>

    <!-- Process every content topicref once (external links, resources and duplicates are skipped) -->
    <xsl:apply-templates select="$all-content-topicrefs" mode="generate-content">
      <xsl:with-param name="numbering-offsets" select="$numbering-offsets" tunnel="yes"/>
    </xsl:apply-templates>

    <xsl:message>Content generation complete.</xsl:message>
  </xsl:template>

  <!-- Process topicref and generate XHTML file -->
  <xsl:template match="*[contains(@class, ' map/topicref ')]" mode="generate-content">
    <xsl:param name="numbering-offsets" as="element()*" tunnel="yes" select="()"/>
    <xsl:variable name="href" select="@href"/>
    <xsl:variable name="output-filename" select="epub:get-topic-filename(.)"/>

    <!-- Only process if topicref has an href; skip glossarylist descendants when glossary is consolidated -->
    <xsl:variable name="in-glossarylist" select="exists(ancestor::*[contains(@class, ' bookmap/glossarylist ')])"/>
    <xsl:variable name="glossary-consolidated" select="
      epub:is-true($epub.generate.glossary) or
      ($epub.generate.glossary = 'auto' and $in-glossarylist)
    "/>
    <xsl:if test="$href and not(@processing-role = 'resource-only') and not($in-glossarylist and $glossary-consolidated)">
      <xsl:message>Processing topic: <xsl:value-of select="$href"/></xsl:message>

      <xsl:result-document href="{concat($epub.topics.dir, '/', $output-filename)}"
                           method="xhtml"
                           encoding="UTF-8"
                           indent="yes"
                           omit-xml-declaration="no">
        <xsl:call-template name="generate-topic-content">
          <xsl:with-param name="topicref" select="."/>
          <xsl:with-param name="filename" select="$output-filename"/>
          <xsl:with-param name="numbering-offsets" select="$numbering-offsets"/>
        </xsl:call-template>
      </xsl:result-document>
    </xsl:if>
  </xsl:template>

  <!-- Generate XHTML5 content for a single topic -->
  <xsl:template name="generate-topic-content">
    <xsl:param name="topicref" as="element()"/>
    <xsl:param name="filename" as="xs:string"/>
    <xsl:param name="numbering-offsets" as="element()*" select="()"/>

    <!-- Load topic to get its language and title (first topic: a <dita> file holds several) -->
    <xsl:variable name="topic-doc" select="epub:topic-document($topicref)"/>
    <xsl:variable name="topic" select="($topic-doc//*[contains(@class, ' topic/topic ') or self::topic or self::concept or self::task or self::reference])[1]"/>
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
          xml:lang="{$topic-lang}"
          dir="{epub:get-dir($topic-lang)}">
      <head>
        <meta charset="UTF-8"/>
        <title><xsl:value-of select="epub:clean-text($topic-title)"/></title>
        <xsl:call-template name="emit-css-links"/>

        <!-- Accessibility viewport (reflowable only — FXL viewport is emitted by emit-css-links) -->
        <xsl:if test="not($is-fixed-layout) and normalize-space($epub.accessibility) != '' and not(lower-case($epub.accessibility) = ('no', 'false', '0', 'none'))">
          <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        </xsl:if>
      </head>
      <body>
        <!-- Skip navigation link for accessibility -->
        <xsl:if test="epub:is-true($epub.skip.nav)">
          <a href="#epub-main-content" class="skip-nav">Skip to main content</a>
        </xsl:if>

        <!-- Main content -->
        <!-- Prefixed id: topics may use "content" themselves -->
        <main id="epub-main-content" role="main">
          <xsl:call-template name="generate-topic-body">
            <xsl:with-param name="topicref" select="$topicref"/>
            <xsl:with-param name="numbering-offsets" select="$numbering-offsets"/>
          </xsl:call-template>
        </main>
      </body>
    </html>
  </xsl:template>

  <!-- Generate topic body content -->
  <xsl:template name="generate-topic-body">
    <xsl:param name="topicref" as="element()"/>
    <xsl:param name="numbering-offsets" as="element()*" select="()"/>

    <!-- Load the DITA topic file -->
    <xsl:variable name="topic-href" select="$topicref/@href"/>
    <xsl:variable name="topic-doc" select="epub:topic-document($topicref)"/>
    <xsl:variable name="topic" select="($topic-doc//*[contains(@class, ' topic/topic ') or self::topic or self::concept or self::task or self::reference])[1]"/>
    <!-- Nested topics, then the other topics of a <dita> file, are rendered after the main topic -->
    <xsl:variable name="more-topics" select="$topic/*[contains(@class, ' topic/topic ')] | $topic/following-sibling::*[contains(@class, ' topic/topic ')]"/>

    <!-- Look up global numbering offsets for this topic -->
    <xsl:variable name="current-offset" select="$numbering-offsets[@href = $topic-href]"/>
    <xsl:variable name="fig-offset" as="xs:integer" select="if ($current-offset) then xs:integer($current-offset/@fig) else 0"/>
    <xsl:variable name="table-offset" as="xs:integer" select="if ($current-offset) then xs:integer($current-offset/@table) else 0"/>

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
      <xsl:variable name="epub-type">
        <xsl:choose>
          <!-- @type attribute override for explicit epub:type mapping -->
          <xsl:when test="$topicref/@type = 'dedication'">dedication</xsl:when>
          <xsl:when test="$topicref/@type = 'acknowledgments'">acknowledgments</xsl:when>
          <xsl:when test="$topicref/@type = 'colophon'">colophon</xsl:when>
          <xsl:when test="$topicref/@type = 'halftitle'">halftitlepage</xsl:when>
          <xsl:when test="$topicref/@type = 'copyright'">copyright-page</xsl:when>
          <xsl:when test="$topicref/@type = 'foreword'">foreword</xsl:when>
          <xsl:when test="$topicref/@type = 'introduction'">introduction</xsl:when>
          <xsl:when test="$topicref/@type = 'epilogue'">epilogue</xsl:when>
          <xsl:when test="$topicref/@type = 'preface'">preface</xsl:when>
          <!-- Bookmap structural elements -->
          <xsl:when test="contains($topicref/@class, ' bookmap/dedication ')">dedication</xsl:when>
          <xsl:when test="contains($topicref/@class, ' bookmap/colophon ')">colophon</xsl:when>
          <xsl:when test="contains($topicref/@class, ' bookmap/notices ')">copyright-page</xsl:when>
          <xsl:when test="contains($topicref/@class, ' bookmap/amendments ')">errata</xsl:when>
          <xsl:when test="contains($topicref/@class, ' bookmap/preface ')">preface</xsl:when>
          <xsl:when test="$topicref/ancestor-or-self::*[contains(@class, ' bookmap/frontmatter ')]
                          and not(contains($topicref/@class, ' bookmap/preface '))
                          and not($topicref/@type = 'preface')">foreword</xsl:when>
          <xsl:when test="contains($topicref/@class, ' bookmap/appendix ')">appendix</xsl:when>
          <xsl:when test="$topicref/ancestor-or-self::*[contains(@class, ' bookmap/appendix ')]">appendix</xsl:when>
          <xsl:when test="contains($topicref/@class, ' bookmap/glossarylist ')
                          or contains($topicref/@class, ' glossentry/glossentry ')
                          or $topicref/ancestor-or-self::*[contains(@class, ' bookmap/glossarylist ')]">glossary</xsl:when>
          <xsl:when test="contains($topicref/@class, ' bookmap/chapter ')">chapter</xsl:when>
          <xsl:when test="$topicref/ancestor::*[contains(@class, ' bookmap/chapter ')]">chapter</xsl:when>
          <xsl:otherwise>chapter</xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:attribute name="epub:type" select="$epub-type"/>
      <!-- DPUB-ARIA roles are not valid on <article> per HTML-ARIA spec.
           epub:type provides the semantic information for EPUB reading systems.
           Only set role="doc-..." on elements where HTML-ARIA allows it. -->
      <xsl:choose>
        <xsl:when test="$topic">
          <!-- Process actual topic content -->
          <xsl:apply-templates select="$topic/*[contains(@class, ' topic/title ') or self::title]" mode="topic-content"/>
          <!-- The prolog is not rendered, but the back-of-book index links to its index terms -->
          <xsl:apply-templates select="$topic/*[contains(@class, ' topic/prolog ')]//*[contains(@class, ' topic/indexterm ')]
                                         [not(parent::*[contains(@class, ' topic/indexterm ')])]" mode="topic-content"/>
          <xsl:apply-templates select="$topic/*[contains(@class, ' topic/shortdesc ') or contains(@class, ' topic/abstract ') or self::shortdesc]" mode="topic-content"/>
          <xsl:apply-templates select="$topic/*[contains(@class, ' topic/body ') or self::body or self::conbody or self::taskbody or self::refbody]
                                       | $topic/*[contains(@class, ' topic/related-links ')] | $more-topics" mode="topic-content">
            <xsl:with-param name="fig-offset" select="$fig-offset" tunnel="yes"/>
            <xsl:with-param name="table-offset" select="$table-offset" tunnel="yes"/>
          </xsl:apply-templates>

          <!-- Collect footnotes from this topic -->
          <xsl:variable name="footnotes" select="($topic | $more-topics)//*[contains(@class, ' topic/fn ')]"/>
          <xsl:if test="count($footnotes) > 0">
            <aside xmlns="http://www.w3.org/1999/xhtml" epub:type="footnotes" class="footnotes">
              <hr class="fn-separator"/>
              <ol class="fn-list">
                <xsl:for-each select="$footnotes">
                  <xsl:variable name="fn-id" select="if (@id) then @id else concat('fn-', generate-id(.))"/>
                  <li id="{$fn-id}" epub:type="footnote">
                    <xsl:apply-templates select="node()" mode="topic-content"/>
                    <xsl:text> </xsl:text>
                    <a href="#fnref-{$fn-id}" role="doc-backlink">&#x21A9;</a>
                  </li>
                </xsl:for-each>
              </ol>
            </aside>
          </xsl:if>
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

  <!-- Emit lang and dir attributes when an element has @xml:lang.
       Sets dir only when the element's language direction differs from
       the document language, enabling mixed-direction (bidi) content. -->
  <xsl:template name="emit-lang-dir">
    <xsl:if test="@xml:lang">
      <xsl:attribute name="lang" select="@xml:lang"/>
      <xsl:variable name="elem-dir" select="epub:get-dir(@xml:lang)"/>
      <xsl:variable name="doc-dir" select="epub:get-dir($epub.language)"/>
      <xsl:if test="$elem-dir != $doc-dir">
        <xsl:attribute name="dir" select="$elem-dir"/>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <!-- Transform DITA topic title to HTML h1 (h2... for nested topics) -->
  <xsl:template match="*[contains(@class, ' topic/title ')] | title" mode="topic-content">
    <xsl:variable name="level" select="max((1, min((count(ancestor::*[contains(@class, ' topic/topic ')]), 6))))"/>
    <xsl:element name="h{$level}" namespace="http://www.w3.org/1999/xhtml">
      <!-- A topic's id goes on its heading; other titled elements (example...) keep their own -->
      <xsl:if test="parent::*[contains(@class, ' topic/topic ')]/@id">
        <xsl:attribute name="id" select="parent::*/@id"/>
      </xsl:if>
      <xsl:apply-templates mode="topic-content"/>
    </xsl:element>
  </xsl:template>

  <!-- Nested topic, or further topic of a <dita> file: a section of the same content document -->
  <xsl:template match="*[contains(@class, ' topic/topic ')]" mode="topic-content">
    <section xmlns="http://www.w3.org/1999/xhtml" class="topic">
      <xsl:call-template name="emit-lang-dir"/>
      <xsl:apply-templates select="*[contains(@class, ' topic/title ')]" mode="topic-content"/>
      <xsl:apply-templates select="*[contains(@class, ' topic/prolog ')]//*[contains(@class, ' topic/indexterm ')]
                                     [not(parent::*[contains(@class, ' topic/indexterm ')])]" mode="topic-content"/>
      <xsl:apply-templates select="*[contains(@class, ' topic/shortdesc ') or contains(@class, ' topic/abstract ')
                                     or contains(@class, ' topic/body ') or contains(@class, ' topic/related-links ')
                                     or contains(@class, ' topic/topic ')]" mode="topic-content"/>
    </section>
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

  <!-- Transform DITA paragraph to HTML p (with optional drop caps) -->
  <xsl:template match="*[contains(@class, ' topic/p ')] | p" mode="topic-content">
    <xsl:variable name="is-first-body-p" select="
      epub:is-true($epub.drop.caps) and
      parent::*[contains(@class, ' topic/body ') or self::body or self::conbody or self::taskbody or self::refbody] and
      not(preceding-sibling::*[contains(@class, ' topic/p ')])
    "/>
    <!-- DITA paragraphs may hold lists, code blocks, notes...; HTML <p> may not -->
    <xsl:element name="{if (epub:has-block-content(.)) then 'div' else 'p'}" namespace="http://www.w3.org/1999/xhtml">
      <xsl:call-template name="emit-lang-dir"/>
      <xsl:call-template name="emit-id"/>
      <xsl:choose>
        <xsl:when test="$is-first-body-p">
          <xsl:attribute name="class">drop-cap</xsl:attribute>
        </xsl:when>
        <xsl:when test="epub:has-block-content(.)">
          <xsl:attribute name="class">p</xsl:attribute>
        </xsl:when>
      </xsl:choose>
      <xsl:apply-templates mode="topic-content"/>
    </xsl:element>
  </xsl:template>

  <!-- Transform DITA section to HTML section -->
  <xsl:template match="*[contains(@class, ' topic/section ')] | section" mode="topic-content">
    <section xmlns="http://www.w3.org/1999/xhtml">
      <xsl:call-template name="emit-lang-dir"/>
      <xsl:call-template name="emit-id"/>
      <xsl:apply-templates mode="topic-content"/>
    </section>
  </xsl:template>

  <!-- Transform section (and example) title to h2 -->
  <xsl:template match="*[contains(@class, ' topic/section ') or contains(@class, ' topic/example ')]/*[contains(@class, ' topic/title ')] | section/title" mode="topic-content" priority="10">
    <h2 xmlns="http://www.w3.org/1999/xhtml">
      <xsl:apply-templates mode="topic-content"/>
    </h2>
  </xsl:template>

  <!-- Transform DITA ul to HTML ul -->
  <xsl:template match="*[contains(@class, ' topic/ul ')] | ul" mode="topic-content">
    <ul xmlns="http://www.w3.org/1999/xhtml">
      <xsl:call-template name="emit-id"/>
      <xsl:apply-templates select="node()" mode="topic-content"/>
    </ul>
  </xsl:template>

  <!-- Transform DITA ol to HTML ol -->
  <xsl:template match="*[contains(@class, ' topic/ol ')] | ol" mode="topic-content">
    <ol xmlns="http://www.w3.org/1999/xhtml">
      <xsl:call-template name="emit-id"/>
      <xsl:apply-templates select="node()" mode="topic-content"/>
    </ol>
  </xsl:template>

  <!-- Transform DITA li to HTML li -->
  <xsl:template match="*[contains(@class, ' topic/li ')] | li" mode="topic-content">
    <li xmlns="http://www.w3.org/1999/xhtml">
      <xsl:call-template name="emit-id"/>
      <xsl:apply-templates select="node()" mode="topic-content"/>
    </li>
  </xsl:template>

  <!-- Transform DITA note to HTML aside with class (i18n labels) -->
  <xsl:template match="*[contains(@class, ' topic/note ')] | note" mode="topic-content">
    <aside xmlns="http://www.w3.org/1999/xhtml" role="note">
      <xsl:attribute name="class">
        <xsl:choose>
          <xsl:when test="@type and @type != 'note'">
            <xsl:value-of select="concat('note ', @type, ' note-', @type)"/>
          </xsl:when>
          <xsl:otherwise>note</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <xsl:call-template name="emit-id"/>
      <xsl:if test="@type">
        <xsl:variable name="lang" select="(ancestor-or-self::*/@xml:lang, $epub.language)[1]"/>
        <strong class="note-label">
          <xsl:choose>
            <!-- Tip -->
            <xsl:when test="@type = 'tip'">
              <xsl:choose>
                <xsl:when test="starts-with($lang, 'fr')">Astuce : </xsl:when>
                <xsl:when test="starts-with($lang, 'de')">Tipp: </xsl:when>
                <xsl:when test="starts-with($lang, 'es')">Consejo: </xsl:when>
                <xsl:when test="starts-with($lang, 'it')">Suggerimento: </xsl:when>
                <xsl:when test="starts-with($lang, 'pt')">Dica: </xsl:when>
                <xsl:when test="starts-with($lang, 'nl')">Tip: </xsl:when>
                <xsl:when test="starts-with($lang, 'ja')">ヒント: </xsl:when>
                <xsl:when test="starts-with($lang, 'zh')">提示: </xsl:when>
                <xsl:when test="starts-with($lang, 'ar')">&#x0646;&#x0635;&#x064A;&#x062D;&#x0629;: </xsl:when>
                <xsl:when test="starts-with($lang, 'he')">&#x05E2;&#x05E6;&#x05D4;: </xsl:when>
                <xsl:otherwise>Tip: </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <!-- Important -->
            <xsl:when test="@type = 'important'">
              <xsl:choose>
                <xsl:when test="starts-with($lang, 'fr')">Important : </xsl:when>
                <xsl:when test="starts-with($lang, 'de')">Wichtig: </xsl:when>
                <xsl:when test="starts-with($lang, 'es')">Importante: </xsl:when>
                <xsl:when test="starts-with($lang, 'it')">Importante: </xsl:when>
                <xsl:when test="starts-with($lang, 'pt')">Importante: </xsl:when>
                <xsl:when test="starts-with($lang, 'nl')">Belangrijk: </xsl:when>
                <xsl:when test="starts-with($lang, 'ja')">重要: </xsl:when>
                <xsl:when test="starts-with($lang, 'zh')">重要: </xsl:when>
                <xsl:when test="starts-with($lang, 'ar')">&#x0645;&#x0647;&#x0645;: </xsl:when>
                <xsl:when test="starts-with($lang, 'he')">&#x05D7;&#x05E9;&#x05D5;&#x05D1;: </xsl:when>
                <xsl:otherwise>Important: </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <!-- Warning -->
            <xsl:when test="@type = 'warning'">
              <xsl:choose>
                <xsl:when test="starts-with($lang, 'fr')">Avertissement : </xsl:when>
                <xsl:when test="starts-with($lang, 'de')">Warnung: </xsl:when>
                <xsl:when test="starts-with($lang, 'es')">Advertencia: </xsl:when>
                <xsl:when test="starts-with($lang, 'it')">Avvertenza: </xsl:when>
                <xsl:when test="starts-with($lang, 'pt')">Aviso: </xsl:when>
                <xsl:when test="starts-with($lang, 'nl')">Waarschuwing: </xsl:when>
                <xsl:when test="starts-with($lang, 'ja')">警告: </xsl:when>
                <xsl:when test="starts-with($lang, 'zh')">警告: </xsl:when>
                <xsl:when test="starts-with($lang, 'ar')">&#x062A;&#x062D;&#x0630;&#x064A;&#x0631;: </xsl:when>
                <xsl:when test="starts-with($lang, 'he')">&#x05D0;&#x05D6;&#x05D4;&#x05E8;&#x05D4;: </xsl:when>
                <xsl:otherwise>Warning: </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <!-- Caution -->
            <xsl:when test="@type = 'caution'">
              <xsl:choose>
                <xsl:when test="starts-with($lang, 'fr')">Attention : </xsl:when>
                <xsl:when test="starts-with($lang, 'de')">Vorsicht: </xsl:when>
                <xsl:when test="starts-with($lang, 'es')">Precaución: </xsl:when>
                <xsl:when test="starts-with($lang, 'it')">Attenzione: </xsl:when>
                <xsl:when test="starts-with($lang, 'pt')">Cuidado: </xsl:when>
                <xsl:when test="starts-with($lang, 'nl')">Let op: </xsl:when>
                <xsl:when test="starts-with($lang, 'ja')">注意: </xsl:when>
                <xsl:when test="starts-with($lang, 'zh')">注意: </xsl:when>
                <xsl:when test="starts-with($lang, 'ar')">&#x062A;&#x0646;&#x0628;&#x064A;&#x0647;: </xsl:when>
                <xsl:when test="starts-with($lang, 'he')">&#x05D6;&#x05D4;&#x05D9;&#x05E8;&#x05D5;&#x05EA;: </xsl:when>
                <xsl:otherwise>Caution: </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <!-- Danger -->
            <xsl:when test="@type = 'danger'">
              <xsl:choose>
                <xsl:when test="starts-with($lang, 'fr')">Danger : </xsl:when>
                <xsl:when test="starts-with($lang, 'de')">Gefahr: </xsl:when>
                <xsl:when test="starts-with($lang, 'es')">Peligro: </xsl:when>
                <xsl:when test="starts-with($lang, 'it')">Pericolo: </xsl:when>
                <xsl:when test="starts-with($lang, 'pt')">Perigo: </xsl:when>
                <xsl:when test="starts-with($lang, 'nl')">Gevaar: </xsl:when>
                <xsl:when test="starts-with($lang, 'ja')">危険: </xsl:when>
                <xsl:when test="starts-with($lang, 'zh')">危险: </xsl:when>
                <xsl:when test="starts-with($lang, 'ar')">&#x062E;&#x0637;&#x0631;: </xsl:when>
                <xsl:when test="starts-with($lang, 'he')">&#x05E1;&#x05DB;&#x05E0;&#x05D4;: </xsl:when>
                <xsl:otherwise>Danger: </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <!-- Note (default/notice) -->
            <xsl:when test="@type = 'note' or @type = 'notice'">
              <xsl:choose>
                <xsl:when test="starts-with($lang, 'fr')">Remarque : </xsl:when>
                <xsl:when test="starts-with($lang, 'de')">Hinweis: </xsl:when>
                <xsl:when test="starts-with($lang, 'es')">Nota: </xsl:when>
                <xsl:when test="starts-with($lang, 'it')">Nota: </xsl:when>
                <xsl:when test="starts-with($lang, 'pt')">Nota: </xsl:when>
                <xsl:when test="starts-with($lang, 'nl')">Opmerking: </xsl:when>
                <xsl:when test="starts-with($lang, 'ja')">注: </xsl:when>
                <xsl:when test="starts-with($lang, 'zh')">注: </xsl:when>
                <xsl:when test="starts-with($lang, 'ar')">&#x0645;&#x0644;&#x0627;&#x062D;&#x0638;&#x0629;: </xsl:when>
                <xsl:when test="starts-with($lang, 'he')">&#x05D4;&#x05E2;&#x05E8;&#x05D4;: </xsl:when>
                <xsl:otherwise>Note: </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="concat(upper-case(substring(@type, 1, 1)), substring(@type, 2), ': ')"/>
            </xsl:otherwise>
          </xsl:choose>
        </strong>
      </xsl:if>
      <xsl:apply-templates select="node()" mode="topic-content"/>
    </aside>
  </xsl:template>

  <!-- Transform DITA xref to HTML a -->
  <xsl:template match="*[contains(@class, ' topic/xref ')] | xref" mode="topic-content">
    <xsl:variable name="target" select="epub:get-xref-href(.)"/>
    <xsl:choose>
      <xsl:when test="$target != ''">
        <a xmlns="http://www.w3.org/1999/xhtml" href="{$target}">
          <xsl:if test="@scope = 'external'">
            <xsl:attribute name="rel">noopener noreferrer</xsl:attribute>
          </xsl:if>
          <xsl:call-template name="xref-label"/>
        </a>
      </xsl:when>
      <xsl:otherwise>
        <!-- Target is not in the EPUB (resource not packaged, element not rendered): keep the text -->
        <span xmlns="http://www.w3.org/1999/xhtml" class="xref">
          <xsl:call-template name="xref-label"/>
        </span>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Link text of an xref. DITA-OT adds the target's short description as <desc>, which is not
       part of the text (it may even contain links, and <a> cannot be nested) -->
  <xsl:template name="xref-label">
    <xsl:variable name="label" select="node()[not(self::*[contains(@class, ' topic/desc ')])]"/>
    <xsl:choose>
      <xsl:when test="$label[self::* or normalize-space(.) != '']">
        <xsl:apply-templates select="$label" mode="topic-content"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="@href"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Remote image: EPUB 3.3 (3.6) requires images to be inside the publication, so the image is
       replaced by a link to it, labelled with its alternative text -->
  <xsl:template match="*[contains(@class, ' topic/image ')][epub:is-remote-image(.)]" mode="topic-content" priority="20">
    <xsl:variable name="alt-text" select="normalize-space((@alt, *[contains(@class, ' topic/alt ')])[1])"/>
    <xsl:message>[WARN] Remote image replaced by a link, because EPUB requires images inside the publication: <xsl:value-of select="@href"/></xsl:message>
    <!-- Inside a cross-reference the text alone is kept: links cannot be nested -->
    <xsl:element name="{if (ancestor::*[contains(@class, ' topic/xref ')]) then 'span' else 'a'}" namespace="http://www.w3.org/1999/xhtml">
      <xsl:if test="not(ancestor::*[contains(@class, ' topic/xref ')])">
        <xsl:attribute name="href" select="@href"/>
        <xsl:attribute name="rel">noopener noreferrer</xsl:attribute>
      </xsl:if>
      <xsl:attribute name="class">remote-image</xsl:attribute>
      <xsl:call-template name="emit-id"/>
      <xsl:value-of select="if ($alt-text != '') then $alt-text else @href"/>
    </xsl:element>
  </xsl:template>

  <!-- Transform DITA image to HTML img -->
  <xsl:template match="*[contains(@class, ' topic/image ')]" mode="topic-content">
    <xsl:variable name="image-path" select="epub:get-relative-path($epub.topics.dir, concat($epub.images.dir, '/', epub:get-image-path(.)))"/>
    <xsl:variable name="is-decorative" select="@outputclass = 'decorative' or @alt = ''"/>
    <!-- Alt text: DITA 1.2+ <alt> element, or the older @alt attribute -->
    <xsl:variable name="alt-text" select="(@alt, *[contains(@class, ' topic/alt ')])[1]"/>
    <xsl:variable name="desc-sibling" select="following-sibling::*[contains(@class, ' topic/desc ')][1]"/>
    <xsl:variable name="desc-id" select="if ($desc-sibling) then concat('desc-', generate-id(.)) else ''"/>
    <!-- An inline image inside running text stays an <img>; <figure> is block content -->
    <xsl:variable name="is-inline" select="not(@placement = 'break') and parent::*[
      contains(@class, ' topic/p ') or contains(@class, ' topic/ph ') or contains(@class, ' topic/xref ')
      or contains(@class, ' topic/title ') or contains(@class, ' topic/shortdesc ') or contains(@class, ' topic/q ')
      or contains(@class, ' topic/term ') or contains(@class, ' topic/keyword ')]"/>

    <xsl:variable name="img" as="element()">
      <img xmlns="http://www.w3.org/1999/xhtml" src="{$image-path}">
        <xsl:if test="$is-inline">
          <xsl:attribute name="class">inline</xsl:attribute>
        </xsl:if>
        <xsl:call-template name="emit-id"/>
        <xsl:choose>
          <!-- Decorative image: empty alt, presentation role -->
          <xsl:when test="$is-decorative">
            <xsl:attribute name="alt"/>
            <xsl:attribute name="role">presentation</xsl:attribute>
          </xsl:when>
          <!-- Image with alt text -->
          <xsl:when test="exists($alt-text)">
            <xsl:attribute name="alt" select="normalize-space($alt-text)"/>
          </xsl:when>
          <!-- Missing alt text: warn and use empty alt -->
          <xsl:otherwise>
            <xsl:message>[WARN] Image missing alt text: <xsl:value-of select="@href"/></xsl:message>
            <xsl:attribute name="alt"/>
          </xsl:otherwise>
        </xsl:choose>
        <!-- Extended description via aria-describedby -->
        <xsl:if test="$desc-sibling and not($is-decorative) and not($is-inline)">
          <xsl:attribute name="aria-describedby" select="$desc-id"/>
        </xsl:if>
        <xsl:call-template name="emit-image-size"/>
      </img>
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="$is-inline">
        <xsl:sequence select="$img"/>
      </xsl:when>
      <xsl:otherwise>
        <figure xmlns="http://www.w3.org/1999/xhtml">
          <xsl:sequence select="$img"/>

          <!-- Caption from desc (visible) -->
          <xsl:if test="$desc-sibling">
            <figcaption>
              <xsl:apply-templates select="$desc-sibling/node()" mode="topic-content"/>
            </figcaption>
            <!-- Hidden extended description for screen readers -->
            <xsl:if test="not($is-decorative)">
              <div id="{$desc-id}" class="visually-hidden">
                <xsl:apply-templates select="$desc-sibling/node()" mode="topic-content"/>
              </div>
            </xsl:if>
          </xsl:if>
        </figure>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Image size: HTML width/height only take pixels, so other DITA units (in, cm, %...) go to CSS -->
  <xsl:template name="emit-image-size">
    <xsl:variable name="pixel-pattern" select="'^[0-9]+(px)?$'"/>
    <xsl:for-each select="(@width, @height)[matches(normalize-space(.), $pixel-pattern)]">
      <xsl:attribute name="{local-name()}" select="replace(normalize-space(.), 'px$', '')"/>
    </xsl:for-each>
    <xsl:variable name="css" select="string-join(
      for $size in (@width, @height)[normalize-space(.) != ''][not(matches(normalize-space(.), $pixel-pattern))]
      return concat(local-name($size), ': ', normalize-space($size),
                    if (matches(normalize-space($size), '^[0-9.]+$')) then 'px' else ''), '; ')"/>
    <xsl:if test="$css != ''">
      <xsl:attribute name="style" select="$css"/>
    </xsl:if>
  </xsl:template>

  <!-- Transform DITA table to HTML table -->
  <xsl:template match="*[contains(@class, ' topic/table ')]" mode="topic-content">
    <xsl:param name="table-offset" as="xs:integer" select="0" tunnel="yes"/>
    <table xmlns="http://www.w3.org/1999/xhtml">
      <xsl:call-template name="emit-id"/>
      <xsl:if test="*[contains(@class, ' topic/title ') or contains(@class, ' topic/desc ')]">
        <caption>
          <xsl:if test="$epub.table.numbering = 'global' and *[contains(@class, ' topic/title ')]">
            <xsl:variable name="table-number" select="count(preceding::*[contains(@class, ' topic/table ')]) + 1 + $table-offset"/>
            <xsl:variable name="lang" select="(ancestor-or-self::*/@xml:lang, $epub.language)[1]"/>
            <span class="table-label">
              <xsl:choose>
                <xsl:when test="starts-with($lang, 'fr')">Tableau </xsl:when>
                <xsl:when test="starts-with($lang, 'de')">Tabelle </xsl:when>
                <xsl:when test="starts-with($lang, 'es')">Tabla </xsl:when>
                <xsl:when test="starts-with($lang, 'it')">Tabella </xsl:when>
                <xsl:when test="starts-with($lang, 'pt')">Tabela </xsl:when>
                <xsl:when test="starts-with($lang, 'nl')">Tabel </xsl:when>
                <xsl:when test="starts-with($lang, 'ja')">表 </xsl:when>
                <xsl:when test="starts-with($lang, 'zh')">表 </xsl:when>
                <xsl:when test="starts-with($lang, 'ar')">&#x062C;&#x062F;&#x0648;&#x0644; </xsl:when>
                <xsl:when test="starts-with($lang, 'he')">&#x05D8;&#x05D1;&#x05DC;&#x05D4; </xsl:when>
                <xsl:otherwise>Table </xsl:otherwise>
              </xsl:choose>
              <xsl:value-of select="$table-number"/>
              <xsl:text>. </xsl:text>
            </span>
          </xsl:if>
          <xsl:apply-templates select="*[contains(@class, ' topic/title ')]/node()" mode="topic-content"/>
          <xsl:apply-templates select="*[contains(@class, ' topic/desc ')]" mode="topic-content"/>
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

  <!-- Transform DITA row to HTML tr with zebra striping -->
  <xsl:template match="*[contains(@class, ' topic/row ')]" mode="topic-content">
    <tr xmlns="http://www.w3.org/1999/xhtml">
      <xsl:if test="epub:is-true($epub.table.zebra) and parent::*[contains(@class, ' topic/tbody ')]">
        <xsl:variable name="pos" select="count(preceding-sibling::*[contains(@class, ' topic/row ')]) + 1"/>
        <xsl:attribute name="class" select="if ($pos mod 2 = 1) then 'row-odd' else 'row-even'"/>
      </xsl:if>
      <xsl:apply-templates select="*[contains(@class, ' topic/entry ')]" mode="topic-content"/>
    </tr>
  </xsl:template>

  <!-- Transform DITA entry to HTML td or th with colspan/rowspan/alignment -->
  <xsl:template match="*[contains(@class, ' topic/entry ')]" mode="topic-content">
    <xsl:variable name="element-name">
      <xsl:choose>
        <xsl:when test="parent::*[contains(@class, ' topic/row ')]/parent::*[contains(@class, ' topic/thead ')]">th</xsl:when>
        <xsl:otherwise>td</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:element name="{$element-name}" namespace="http://www.w3.org/1999/xhtml">
      <!-- rowspan from @morerows -->
      <xsl:if test="@morerows">
        <xsl:attribute name="rowspan" select="xs:integer(@morerows) + 1"/>
      </xsl:if>
      <!-- colspan from @namest/@nameend -->
      <xsl:if test="@namest and @nameend">
        <xsl:variable name="tgroup" select="ancestor::*[contains(@class, ' topic/tgroup ')][1]"/>
        <xsl:variable name="colspecs" select="$tgroup/*[contains(@class, ' topic/colspec ')]"/>
        <xsl:variable name="start-col" select="$colspecs[@colname = current()/@namest]"/>
        <xsl:variable name="end-col" select="$colspecs[@colname = current()/@nameend]"/>
        <xsl:if test="$start-col and $end-col">
          <xsl:variable name="start-pos" select="count($start-col/preceding-sibling::*[contains(@class, ' topic/colspec ')]) + 1"/>
          <xsl:variable name="end-pos" select="count($end-col/preceding-sibling::*[contains(@class, ' topic/colspec ')]) + 1"/>
          <xsl:attribute name="colspan" select="$end-pos - $start-pos + 1"/>
        </xsl:if>
      </xsl:if>
      <!-- alignment from colspec (prefer @colname/@namest for accurate column mapping) -->
      <xsl:variable name="tgroup-for-align" select="ancestor::*[contains(@class, ' topic/tgroup ')][1]"/>
      <xsl:variable name="col-name" select="(@colname, @namest)[1]"/>
      <xsl:variable name="colspec-align">
        <xsl:choose>
          <xsl:when test="$col-name">
            <xsl:value-of select="$tgroup-for-align/*[contains(@class, ' topic/colspec ')][@colname = $col-name]/@align"/>
          </xsl:when>
          <xsl:otherwise>
            <!-- Fallback: compute actual column position accounting for preceding colspans -->
            <xsl:variable name="actual-col">
              <xsl:variable name="preceding-entries" select="preceding-sibling::*[contains(@class, ' topic/entry ')]"/>
              <xsl:variable name="span-sum" as="xs:integer">
                <xsl:value-of select="sum(for $e in $preceding-entries return
                  if ($e/@namest and $e/@nameend) then
                    (let $cs := $tgroup-for-align/*[contains(@class, ' topic/colspec ')],
                         $s := count($cs[@colname = $e/@namest]/preceding-sibling::*[contains(@class, ' topic/colspec ')]) + 1,
                         $en := count($cs[@colname = $e/@nameend]/preceding-sibling::*[contains(@class, ' topic/colspec ')]) + 1
                     return $en - $s + 1)
                  else 1)"/>
              </xsl:variable>
              <xsl:value-of select="$span-sum + 1"/>
            </xsl:variable>
            <xsl:value-of select="$tgroup-for-align/*[contains(@class, ' topic/colspec ')][position() = xs:integer($actual-col)]/@align"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:if test="string-length($colspec-align) > 0">
        <!-- Map physical left/right to logical start/end for bidi support -->
        <xsl:variable name="logical-align">
          <xsl:choose>
            <xsl:when test="$colspec-align = 'left'">start</xsl:when>
            <xsl:when test="$colspec-align = 'right'">end</xsl:when>
            <xsl:otherwise><xsl:value-of select="$colspec-align"/></xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:attribute name="style" select="concat('text-align: ', $logical-align)"/>
      </xsl:if>
      <xsl:apply-templates select="node()" mode="topic-content"/>
    </xsl:element>
  </xsl:template>

  <!-- Transform DITA codeblock to HTML pre/code with language class and line numbers -->
  <xsl:template match="*[contains(@class, ' pr-d/codeblock ')]" mode="topic-content">
    <xsl:variable name="raw-lang" select="if (starts-with(@outputclass, 'language-'))
                                           then substring-after(@outputclass, 'language-')
                                           else @outputclass"/>
    <xsl:variable name="lang-class" select="if ($raw-lang and epub:is-true($epub.code.syntax.classes))
                                             then concat('language-', $raw-lang)
                                             else ''"/>
    <pre xmlns="http://www.w3.org/1999/xhtml">
      <xsl:call-template name="emit-id"/>
      <xsl:if test="string-length($lang-class) > 0">
        <xsl:attribute name="class" select="$lang-class"/>
      </xsl:if>
      <code>
        <xsl:if test="string-length($lang-class) > 0">
          <xsl:attribute name="class" select="$lang-class"/>
        </xsl:if>
        <xsl:choose>
          <xsl:when test="epub:is-true($epub.code.line.numbers)">
            <xsl:variable name="text" select="string(.)"/>
            <xsl:variable name="lines" select="tokenize($text, '&#10;')"/>
            <xsl:for-each select="$lines">
              <span class="line"><span class="line-number"><xsl:value-of select="position()"/></span><span class="line-content"><xsl:value-of select="."/></span></span>
              <xsl:if test="position() != last()"><xsl:text>&#10;</xsl:text></xsl:if>
            </xsl:for-each>
          </xsl:when>
          <xsl:otherwise>
            <xsl:apply-templates select="node()" mode="topic-content"/>
          </xsl:otherwise>
        </xsl:choose>
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

  <!-- Transform DITA footnote (fn) to inline superscript reference -->
  <xsl:template match="*[contains(@class, ' topic/fn ')]" mode="topic-content">
    <xsl:variable name="fn-id" select="if (@id) then @id else concat('fn-', generate-id(.))"/>
    <xsl:variable name="fn-number" select="count(preceding::*[contains(@class, ' topic/fn ')]) + 1"/>
    <sup xmlns="http://www.w3.org/1999/xhtml" class="fn-ref">
      <a epub:type="noteref" role="doc-noteref" href="#{$fn-id}" id="fnref-{$fn-id}">
        <xsl:value-of select="$fn-number"/>
      </a>
    </sup>
  </xsl:template>

  <!-- Transform DITA fig to HTML figure with optional numbering -->
  <xsl:template match="*[contains(@class, ' topic/fig ')]" mode="topic-content" priority="10">
    <xsl:param name="fig-offset" as="xs:integer" select="0" tunnel="yes"/>
    <xsl:variable name="fig-id" select="if (@id) then @id else generate-id(.)"/>
    <figure xmlns="http://www.w3.org/1999/xhtml" id="{$fig-id}" class="numbered-figure">
      <!-- Process image and other content (not title) -->
      <xsl:apply-templates select="node()[not(contains(@class, ' topic/title '))]" mode="topic-content"/>
      <!-- Figcaption from title -->
      <xsl:if test="*[contains(@class, ' topic/title ')]">
        <figcaption>
          <xsl:if test="$epub.figure.numbering = 'global'">
            <xsl:variable name="fig-number" select="count(preceding::*[contains(@class, ' topic/fig ')]) + 1 + $fig-offset"/>
            <xsl:variable name="lang" select="(ancestor-or-self::*/@xml:lang, $epub.language)[1]"/>
            <span class="fig-label">
              <xsl:choose>
                <xsl:when test="starts-with($lang, 'fr')">Figure </xsl:when>
                <xsl:when test="starts-with($lang, 'de')">Abbildung </xsl:when>
                <xsl:when test="starts-with($lang, 'es')">Figura </xsl:when>
                <xsl:when test="starts-with($lang, 'it')">Figura </xsl:when>
                <xsl:when test="starts-with($lang, 'pt')">Figura </xsl:when>
                <xsl:when test="starts-with($lang, 'nl')">Figuur </xsl:when>
                <xsl:when test="starts-with($lang, 'ja')">図 </xsl:when>
                <xsl:when test="starts-with($lang, 'zh')">图 </xsl:when>
                <xsl:when test="starts-with($lang, 'ar')">&#x0634;&#x0643;&#x0644; </xsl:when>
                <xsl:when test="starts-with($lang, 'he')">&#x05D0;&#x05D9;&#x05D5;&#x05E8; </xsl:when>
                <xsl:otherwise>Figure </xsl:otherwise>
              </xsl:choose>
              <xsl:value-of select="$fig-number"/>
              <xsl:text>. </xsl:text>
            </span>
          </xsl:if>
          <xsl:apply-templates select="*[contains(@class, ' topic/title ')]/node()" mode="topic-content"/>
        </figcaption>
      </xsl:if>
    </figure>
  </xsl:template>

  <!-- Image inside fig: no wrapping figure element -->
  <xsl:template match="*[contains(@class, ' topic/fig ')]//*[contains(@class, ' topic/image ')]" mode="topic-content" priority="15">
    <xsl:variable name="image-path" select="epub:get-relative-path($epub.topics.dir, concat($epub.images.dir, '/', epub:get-image-path(.)))"/>
    <xsl:variable name="is-decorative" select="@outputclass = 'decorative' or @alt = ''"/>
    <xsl:variable name="alt-text" select="(@alt, *[contains(@class, ' topic/alt ')])[1]"/>
    <img xmlns="http://www.w3.org/1999/xhtml" src="{$image-path}">
      <xsl:call-template name="emit-id"/>
      <xsl:choose>
        <xsl:when test="$is-decorative">
          <xsl:attribute name="alt"/>
          <xsl:attribute name="role">presentation</xsl:attribute>
        </xsl:when>
        <xsl:when test="exists($alt-text)">
          <xsl:attribute name="alt" select="normalize-space($alt-text)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:message>[WARN] Image missing alt text: <xsl:value-of select="@href"/></xsl:message>
          <xsl:attribute name="alt"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:call-template name="emit-image-size"/>
    </img>
  </xsl:template>

  <!-- Transform DITA lq to HTML blockquote (pull quote) -->
  <xsl:template match="*[contains(@class, ' topic/lq ')]" mode="topic-content">
    <blockquote xmlns="http://www.w3.org/1999/xhtml" class="pull-quote">
      <xsl:call-template name="emit-lang-dir"/>
      <xsl:call-template name="emit-id"/>
      <xsl:apply-templates select="node()" mode="topic-content"/>
      <xsl:if test="@href or *[contains(@class, ' topic/longquoteref ')]">
        <footer class="quote-attribution">
          <xsl:variable name="source-href" select="(@href, *[contains(@class, ' topic/longquoteref ')]/@href)[1]"/>
          <xsl:variable name="source-label" select="if (@reftitle and string-length(@reftitle) > 0) then @reftitle else $source-href"/>
          <cite>
            <a href="{$source-href}" rel="noopener noreferrer">
              <xsl:value-of select="$source-label"/>
            </a>
          </cite>
        </footer>
      </xsl:if>
    </blockquote>
  </xsl:template>

  <!-- Transform DITA q to locale-aware quotation marks or HTML q -->
  <xsl:template match="*[contains(@class, ' topic/q ')]" mode="topic-content">
    <xsl:variable name="q-lang" select="(ancestor-or-self::*/@xml:lang, $epub.language)[1]"/>
    <xsl:choose>
      <xsl:when test="epub:is-true($epub.locale.quotes)">
        <xsl:variable name="quotes" select="epub:get-quotes($q-lang)"/>
        <span xmlns="http://www.w3.org/1999/xhtml" class="q">
          <xsl:call-template name="emit-lang-dir"/>
          <xsl:value-of select="$quotes[1]"/>
          <xsl:apply-templates mode="topic-content"/>
          <xsl:value-of select="$quotes[2]"/>
        </span>
      </xsl:when>
      <xsl:otherwise>
        <q xmlns="http://www.w3.org/1999/xhtml">
          <xsl:apply-templates mode="topic-content"/>
        </q>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Sidebar section (outputclass='sidebar') -->
  <xsl:template match="*[contains(@class, ' topic/section ')][@outputclass='sidebar']" mode="topic-content" priority="10">
    <aside xmlns="http://www.w3.org/1999/xhtml" class="sidebar" role="complementary">
      <xsl:call-template name="emit-id"/>
      <xsl:apply-templates mode="topic-content"/>
    </aside>
  </xsl:template>

  <!-- ================================================================== -->
  <!-- Lists, simple tables, divisions, task blocks and domain phrases    -->
  <!-- ================================================================== -->

  <!-- Copy @id, unless an earlier element of the content document already uses it -->
  <xsl:template name="emit-id">
    <xsl:if test="@id and epub:is-first-id(.)">
      <xsl:attribute name="id" select="@id"/>
    </xsl:if>
  </xsl:template>

  <!-- Definition list, and parameter list (parml) -->
  <xsl:template match="*[contains(@class, ' topic/dl ')]" mode="topic-content">
    <dl xmlns="http://www.w3.org/1999/xhtml" class="{local-name()}">
      <xsl:call-template name="emit-lang-dir"/>
      <xsl:call-template name="emit-id"/>
      <xsl:apply-templates select="*[contains(@class, ' topic/dlhead ') or contains(@class, ' topic/dlentry ')]" mode="topic-content"/>
    </dl>
  </xsl:template>

  <!-- List entry (dlentry, plentry) and list heading: no HTML wrapper, only their terms and definitions -->
  <xsl:template match="*[contains(@class, ' topic/dlentry ') or contains(@class, ' topic/dlhead ')]" mode="topic-content">
    <xsl:apply-templates select="*" mode="topic-content"/>
  </xsl:template>

  <!-- Term (dt, pt) and heading term; the first term also carries the entry's id -->
  <xsl:template match="*[contains(@class, ' topic/dt ') or contains(@class, ' topic/dthd ')]" mode="topic-content">
    <dt xmlns="http://www.w3.org/1999/xhtml">
      <xsl:if test="contains(@class, ' topic/dthd ')">
        <xsl:attribute name="class">dlhead</xsl:attribute>
      </xsl:if>
      <xsl:call-template name="emit-id"/>
      <xsl:if test="not(preceding-sibling::*) and ../@id and epub:is-first-id(..)">
        <span id="{../@id}"/>
      </xsl:if>
      <xsl:apply-templates mode="topic-content"/>
    </dt>
  </xsl:template>

  <!-- Definition (dd, pd) and heading definition -->
  <xsl:template match="*[contains(@class, ' topic/dd ') or contains(@class, ' topic/ddhd ')]" mode="topic-content">
    <dd xmlns="http://www.w3.org/1999/xhtml">
      <xsl:if test="contains(@class, ' topic/ddhd ')">
        <xsl:attribute name="class">dlhead</xsl:attribute>
      </xsl:if>
      <xsl:call-template name="emit-id"/>
      <xsl:apply-templates mode="topic-content"/>
    </dd>
  </xsl:template>

  <!-- Simple list -->
  <xsl:template match="*[contains(@class, ' topic/sl ')]" mode="topic-content">
    <ul xmlns="http://www.w3.org/1999/xhtml" class="sl">
      <xsl:call-template name="emit-id"/>
      <xsl:apply-templates select="*[contains(@class, ' topic/sli ')]" mode="topic-content"/>
    </ul>
  </xsl:template>

  <xsl:template match="*[contains(@class, ' topic/sli ')]" mode="topic-content">
    <li xmlns="http://www.w3.org/1999/xhtml">
      <xsl:call-template name="emit-id"/>
      <xsl:apply-templates mode="topic-content"/>
    </li>
  </xsl:template>

  <!-- Simple table (also properties and choicetable); @keycol turns that column into row headers -->
  <xsl:template match="*[contains(@class, ' topic/simpletable ')]" mode="topic-content">
    <table xmlns="http://www.w3.org/1999/xhtml" class="{distinct-values(('simpletable', local-name()))}">
      <xsl:call-template name="emit-id"/>
      <xsl:if test="*[contains(@class, ' topic/title ')]">
        <caption>
          <xsl:apply-templates select="*[contains(@class, ' topic/title ')]/node()" mode="topic-content"/>
        </caption>
      </xsl:if>
      <xsl:if test="*[contains(@class, ' topic/sthead ')]">
        <thead>
          <xsl:apply-templates select="*[contains(@class, ' topic/sthead ')]" mode="topic-content"/>
        </thead>
      </xsl:if>
      <tbody>
        <xsl:apply-templates select="*[contains(@class, ' topic/strow ')]" mode="topic-content"/>
      </tbody>
    </table>
  </xsl:template>

  <xsl:template match="*[contains(@class, ' topic/sthead ') or contains(@class, ' topic/strow ')]" mode="topic-content">
    <tr xmlns="http://www.w3.org/1999/xhtml">
      <xsl:if test="contains(@class, ' topic/strow ') and epub:is-true($epub.table.zebra)">
        <xsl:variable name="pos" select="count(preceding-sibling::*[contains(@class, ' topic/strow ')]) + 1"/>
        <xsl:attribute name="class" select="if ($pos mod 2 = 1) then 'row-odd' else 'row-even'"/>
      </xsl:if>
      <xsl:call-template name="emit-id"/>
      <xsl:apply-templates select="*[contains(@class, ' topic/stentry ')]" mode="topic-content"/>
    </tr>
  </xsl:template>

  <xsl:template match="*[contains(@class, ' topic/stentry ')]" mode="topic-content">
    <xsl:variable name="keycol" select="ancestor::*[contains(@class, ' topic/simpletable ')][1]/@keycol"/>
    <xsl:variable name="in-head" select="exists(parent::*[contains(@class, ' topic/sthead ')])"/>
    <xsl:variable name="is-key" select="$keycol castable as xs:integer
      and count(preceding-sibling::*[contains(@class, ' topic/stentry ')]) + 1 = xs:integer($keycol)"/>
    <xsl:element name="{if ($in-head or $is-key) then 'th' else 'td'}" namespace="http://www.w3.org/1999/xhtml">
      <xsl:if test="$in-head or $is-key">
        <xsl:attribute name="scope" select="if ($in-head) then 'col' else 'row'"/>
      </xsl:if>
      <xsl:call-template name="emit-id"/>
      <xsl:apply-templates mode="topic-content"/>
    </xsl:element>
  </xsl:template>

  <!-- Example: a section of its own (its title is handled with section titles) -->
  <xsl:template match="*[contains(@class, ' topic/example ')]" mode="topic-content">
    <section xmlns="http://www.w3.org/1999/xhtml" class="example">
      <xsl:call-template name="emit-lang-dir"/>
      <xsl:call-template name="emit-id"/>
      <xsl:apply-templates mode="topic-content"/>
    </section>
  </xsl:template>

  <!-- Divisions: div, bodydiv, sectiondiv, figgroup (syntax diagram groups), and task item groups
       (info, stepxmp, stepresult, tutorialinfo); abstract (also glossdef) -->
  <xsl:template match="*[contains(@class, ' topic/div ') or contains(@class, ' topic/bodydiv ') or contains(@class, ' topic/sectiondiv ')
                         or contains(@class, ' topic/figgroup ') or contains(@class, ' topic/itemgroup ') or contains(@class, ' topic/abstract ')]" mode="topic-content">
    <div xmlns="http://www.w3.org/1999/xhtml" class="{local-name()}">
      <xsl:call-template name="emit-lang-dir"/>
      <xsl:call-template name="emit-id"/>
      <xsl:apply-templates mode="topic-content"/>
    </div>
  </xsl:template>

  <!-- Description of a figure or object (xref and link descriptions are not rendered as text) -->
  <xsl:template match="*[contains(@class, ' topic/desc ')]" mode="topic-content">
    <div xmlns="http://www.w3.org/1999/xhtml" class="desc">
      <xsl:call-template name="emit-id"/>
      <xsl:apply-templates mode="topic-content"/>
    </div>
  </xsl:template>

  <!-- Preformatted text other than code blocks: pre, screen, msgblock (codeblock has its own template) -->
  <xsl:template match="*[contains(@class, ' topic/pre ')]" mode="topic-content" priority="0.4">
    <pre xmlns="http://www.w3.org/1999/xhtml" class="{local-name()}">
      <xsl:call-template name="emit-id"/>
      <xsl:apply-templates mode="topic-content"/>
    </pre>
  </xsl:template>

  <!-- Lines: line breaks are significant (kept by CSS white-space) -->
  <xsl:template match="*[contains(@class, ' topic/lines ')]" mode="topic-content">
    <p xmlns="http://www.w3.org/1999/xhtml" class="lines">
      <xsl:call-template name="emit-lang-dir"/>
      <xsl:call-template name="emit-id"/>
      <xsl:apply-templates mode="topic-content"/>
    </p>
  </xsl:template>

  <!-- Related links: child topics first, then related information (relationship tables and authored
       links). Parent, sibling and sequence links are left out: reading systems provide that navigation -->
  <xsl:template match="*[contains(@class, ' topic/related-links ')]" mode="topic-content">
    <xsl:variable name="links" as="element()*">
      <xsl:for-each-group select=".//*[contains(@class, ' topic/link ')][not(@role = ('parent', 'ancestor', 'sibling', 'cousin', 'next', 'previous'))]"
                          group-by="epub:get-xref-href(.)">
        <xsl:if test="current-grouping-key() != ''">
          <xsl:sequence select="(current-group()[@role = ('child', 'descendant')], .)[1]"/>
        </xsl:if>
      </xsl:for-each-group>
    </xsl:variable>
    <xsl:variable name="child-links" select="$links[@role = ('child', 'descendant')]"/>
    <xsl:variable name="other-links" select="$links except $child-links"/>
    <xsl:if test="exists($links)">
      <xsl:variable name="lang" select="(ancestor-or-self::*[@xml:lang][1]/@xml:lang, $epub.language)[1]"/>
      <section xmlns="http://www.w3.org/1999/xhtml" class="related-links">
        <xsl:if test="exists($child-links)">
          <ul class="child-links">
            <xsl:apply-templates select="$child-links" mode="related-link"/>
          </ul>
        </xsl:if>
        <xsl:if test="exists($other-links)">
          <h2 class="related-links-title">
            <xsl:choose>
              <xsl:when test="starts-with($lang, 'fr')">Informations associées</xsl:when>
              <xsl:when test="starts-with($lang, 'de')">Zugehörige Informationen</xsl:when>
              <xsl:when test="starts-with($lang, 'es')">Información relacionada</xsl:when>
              <xsl:when test="starts-with($lang, 'it')">Informazioni correlate</xsl:when>
              <xsl:when test="starts-with($lang, 'pt')">Informações relacionadas</xsl:when>
              <xsl:when test="starts-with($lang, 'nl')">Gerelateerde informatie</xsl:when>
              <xsl:when test="starts-with($lang, 'ja')">関連情報</xsl:when>
              <xsl:when test="starts-with($lang, 'zh')">相关信息</xsl:when>
              <xsl:when test="starts-with($lang, 'ar')">معلومات ذات صلة</xsl:when>
              <xsl:when test="starts-with($lang, 'he')">מידע קשור</xsl:when>
              <xsl:otherwise>Related information</xsl:otherwise>
            </xsl:choose>
          </h2>
          <ul>
            <xsl:apply-templates select="$other-links" mode="related-link"/>
          </ul>
        </xsl:if>
      </section>
    </xsl:if>
  </xsl:template>

  <xsl:template match="*[contains(@class, ' topic/link ')]" mode="related-link">
    <li xmlns="http://www.w3.org/1999/xhtml">
      <a href="{epub:get-xref-href(.)}">
        <xsl:if test="@scope = 'external'">
          <xsl:attribute name="rel">noopener noreferrer</xsl:attribute>
        </xsl:if>
        <xsl:choose>
          <xsl:when test="*[contains(@class, ' topic/linktext ')][normalize-space(.) != '']">
            <xsl:apply-templates select="*[contains(@class, ' topic/linktext ')]/node()" mode="topic-content"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="@href"/>
          </xsl:otherwise>
        </xsl:choose>
      </a>
      <!-- Child links show the child topic's short description, as in DITA-OT HTML5 output -->
      <xsl:if test="@role = ('child', 'descendant') and *[contains(@class, ' topic/desc ')][normalize-space(.) != '']">
        <div class="link-desc">
          <xsl:apply-templates select="*[contains(@class, ' topic/desc ')]/node()" mode="topic-content"/>
        </div>
      </xsl:if>
    </li>
  </xsl:template>

  <!-- Code-like phrases: programming, software and markup names -->
  <xsl:template match="*[contains(@class, ' pr-d/parmname ') or contains(@class, ' pr-d/option ') or contains(@class, ' pr-d/apiname ')
                         or contains(@class, ' pr-d/kwd ') or contains(@class, ' pr-d/synph ') or contains(@class, ' sw-d/cmdname ')
                         or contains(@class, ' sw-d/filepath ') or contains(@class, ' sw-d/msgnum ') or contains(@class, ' markup-d/markupname ')]" mode="topic-content">
    <code xmlns="http://www.w3.org/1999/xhtml" class="{local-name()}">
      <xsl:call-template name="emit-id"/>
      <xsl:apply-templates mode="topic-content"/>
    </code>
  </xsl:template>

  <!-- XML mention domain: names shown with their markup delimiters (<element>, @attribute, &entity;...) -->
  <xsl:template match="*[contains(@class, ' xml-d/')]" mode="topic-content" priority="0.6">
    <xsl:variable name="delimiters" as="xs:string+">
      <xsl:choose>
        <xsl:when test="contains(@class, ' xml-d/xmlelement ')"><xsl:sequence select="('&lt;', '&gt;')"/></xsl:when>
        <xsl:when test="contains(@class, ' xml-d/xmlatt ')"><xsl:sequence select="('@', '')"/></xsl:when>
        <xsl:when test="contains(@class, ' xml-d/textentity ')"><xsl:sequence select="('&amp;', ';')"/></xsl:when>
        <xsl:when test="contains(@class, ' xml-d/parameterentity ')"><xsl:sequence select="('%', ';')"/></xsl:when>
        <xsl:when test="contains(@class, ' xml-d/numcharref ')"><xsl:sequence select="('&amp;#', ';')"/></xsl:when>
        <xsl:when test="contains(@class, ' xml-d/xmlpi ')"><xsl:sequence select="('&lt;?', '?&gt;')"/></xsl:when>
        <xsl:otherwise><xsl:sequence select="('', '')"/></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <code xmlns="http://www.w3.org/1999/xhtml" class="{local-name()}">
      <xsl:call-template name="emit-id"/>
      <xsl:value-of select="$delimiters[1]"/>
      <xsl:apply-templates mode="topic-content"/>
      <xsl:value-of select="$delimiters[2]"/>
    </code>
  </xsl:template>

  <!-- Variables (varname, var) -->
  <xsl:template match="*[contains(@class, ' sw-d/varname ') or contains(@class, ' pr-d/var ')]" mode="topic-content">
    <var xmlns="http://www.w3.org/1999/xhtml" class="{local-name()}">
      <xsl:call-template name="emit-id"/>
      <xsl:apply-templates mode="topic-content"/>
    </var>
  </xsl:template>

  <!-- User input and system output -->
  <xsl:template match="*[contains(@class, ' sw-d/userinput ')]" mode="topic-content">
    <kbd xmlns="http://www.w3.org/1999/xhtml" class="userinput">
      <xsl:call-template name="emit-id"/>
      <xsl:apply-templates mode="topic-content"/>
    </kbd>
  </xsl:template>

  <xsl:template match="*[contains(@class, ' sw-d/systemoutput ') or contains(@class, ' sw-d/msgph ')]" mode="topic-content">
    <samp xmlns="http://www.w3.org/1999/xhtml" class="{local-name()}">
      <xsl:call-template name="emit-id"/>
      <xsl:apply-templates mode="topic-content"/>
    </samp>
  </xsl:template>

  <!-- Menu path: its controls joined with ">" -->
  <xsl:template match="*[contains(@class, ' ui-d/menucascade ')]" mode="topic-content">
    <span xmlns="http://www.w3.org/1999/xhtml" class="menucascade">
      <xsl:call-template name="emit-id"/>
      <xsl:for-each select="*[contains(@class, ' ui-d/uicontrol ')]">
        <xsl:if test="position() gt 1">
          <xsl:text> &gt; </xsl:text>
        </xsl:if>
        <xsl:apply-templates select="." mode="topic-content"/>
      </xsl:for-each>
    </span>
  </xsl:template>

  <!-- Phrases styled by CSS class: UI labels, task commands, syntax punctuation, highlighting -->
  <xsl:template match="*[contains(@class, ' ui-d/uicontrol ') or contains(@class, ' ui-d/wintitle ') or contains(@class, ' ui-d/shortcut ')
                         or contains(@class, ' task/cmd ') or contains(@class, ' pr-d/oper ') or contains(@class, ' pr-d/delim ')
                         or contains(@class, ' pr-d/sep ') or contains(@class, ' pr-d/repsep ') or contains(@class, ' hi-d/tt ')
                         or contains(@class, ' hi-d/line-through ') or contains(@class, ' hi-d/overline ')]" mode="topic-content">
    <span xmlns="http://www.w3.org/1999/xhtml" class="{local-name()}">
      <xsl:call-template name="emit-id"/>
      <xsl:apply-templates mode="topic-content"/>
    </span>
  </xsl:template>

  <!-- Highlighting with a direct HTML equivalent (b and i have their own templates) -->
  <xsl:template match="*[contains(@class, ' hi-d/sup ') or contains(@class, ' hi-d/sub ') or contains(@class, ' hi-d/u ')]" mode="topic-content">
    <xsl:element name="{if (contains(@class, ' hi-d/sup ')) then 'sup' else if (contains(@class, ' hi-d/sub ')) then 'sub' else 'u'}"
                 namespace="http://www.w3.org/1999/xhtml">
      <xsl:call-template name="emit-id"/>
      <xsl:apply-templates mode="topic-content"/>
    </xsl:element>
  </xsl:template>

  <!-- Term and citation -->
  <xsl:template match="*[contains(@class, ' topic/term ')]" mode="topic-content">
    <dfn xmlns="http://www.w3.org/1999/xhtml" class="term">
      <xsl:call-template name="emit-id"/>
      <xsl:apply-templates mode="topic-content"/>
    </dfn>
  </xsl:template>

  <xsl:template match="*[contains(@class, ' topic/cite ')]" mode="topic-content">
    <cite xmlns="http://www.w3.org/1999/xhtml">
      <xsl:call-template name="emit-id"/>
      <xsl:apply-templates mode="topic-content"/>
    </cite>
  </xsl:template>

  <!-- Trademark: text followed by its symbol -->
  <xsl:template match="*[contains(@class, ' topic/tm ')]" mode="topic-content">
    <xsl:apply-templates mode="topic-content"/>
    <xsl:choose>
      <xsl:when test="@tmtype = 'reg'">&#x00AE;</xsl:when>
      <xsl:when test="@tmtype = 'service'">&#x2120;</xsl:when>
      <xsl:otherwise>&#x2122;</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Not part of the published text: review comments, metadata, DITA-OT filtering markers -->
  <xsl:template match="*[contains(@class, ' topic/draft-comment ') or contains(@class, ' topic/required-cleanup ')
                         or contains(@class, ' topic/data ') or contains(@class, ' topic/data-about ') or contains(@class, ' topic/foreign ')
                         or contains(@class, ' topic/unknown ') or contains(@class, ' topic/titlealts ') or contains(@class, ' topic/indextermref ')]"
                mode="topic-content"/>

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

  <!-- Default template - ignore unknown elements but process children; keep their id as an
       anchor so cross-references to them still resolve -->
  <xsl:template match="*" mode="topic-content">
    <xsl:if test="@id and epub:is-first-id(.)">
      <span xmlns="http://www.w3.org/1999/xhtml" id="{@id}"/>
    </xsl:if>
    <xsl:apply-templates select="node()" mode="topic-content"/>
  </xsl:template>

</xsl:stylesheet>

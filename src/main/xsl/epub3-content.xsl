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
    <xsl:variable name="all-content-topicrefs" select="$map//*[contains(@class, ' map/topicref ')][@href][not(@processing-role = 'resource-only')]"/>
    <xsl:variable name="numbering-offsets" as="element()*">
      <xsl:iterate select="$all-content-topicrefs">
        <xsl:param name="fig-total" as="xs:integer" select="0"/>
        <xsl:param name="table-total" as="xs:integer" select="0"/>

        <xsl:variable name="topic-doc" select="document(@href, .)"/>
        <xsl:variable name="fig-count" select="if ($topic-doc) then count($topic-doc//*[contains(@class, ' topic/fig ')]) else 0"/>
        <xsl:variable name="table-count" select="if ($topic-doc) then count($topic-doc//*[contains(@class, ' topic/table ')]) else 0"/>

        <numbering-offset href="{@href}" fig="{$fig-total}" table="{$table-total}"/>

        <xsl:next-iteration>
          <xsl:with-param name="fig-total" select="$fig-total + $fig-count"/>
          <xsl:with-param name="table-total" select="$table-total + $table-count"/>
        </xsl:next-iteration>
      </xsl:iterate>
    </xsl:variable>

    <!-- Process all topicrefs in the map -->
    <xsl:apply-templates select="$map//*[contains(@class, ' map/topicref ')]" mode="generate-content">
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
          xml:lang="{$topic-lang}"
          dir="{epub:get-dir($topic-lang)}">
      <head>
        <meta charset="UTF-8"/>
        <title><xsl:value-of select="epub:clean-text($topic-title)"/></title>
        <xsl:call-template name="emit-css-links"/>

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
    <xsl:variable name="topic-doc" select="if ($topic-href) then document($topic-href, $topicref) else ()"/>
    <xsl:variable name="topic" select="$topic-doc/*[contains(@class, ' topic/topic ') or self::topic or self::concept or self::task or self::reference]"/>

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
          <xsl:apply-templates select="$topic/*[contains(@class, ' topic/shortdesc ') or self::shortdesc]" mode="topic-content"/>
          <xsl:apply-templates select="$topic/*[contains(@class, ' topic/body ') or self::body or self::conbody or self::taskbody or self::refbody]" mode="topic-content">
            <xsl:with-param name="fig-offset" select="$fig-offset" tunnel="yes"/>
            <xsl:with-param name="table-offset" select="$table-offset" tunnel="yes"/>
          </xsl:apply-templates>

          <!-- Collect footnotes from this topic -->
          <xsl:variable name="footnotes" select="$topic//*[contains(@class, ' topic/fn ')]"/>
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

  <!-- Transform DITA paragraph to HTML p (with optional drop caps) -->
  <xsl:template match="*[contains(@class, ' topic/p ')] | p" mode="topic-content">
    <xsl:variable name="is-first-body-p" select="
      epub:is-true($epub.drop.caps) and
      parent::*[contains(@class, ' topic/body ') or self::body or self::conbody or self::taskbody or self::refbody] and
      not(preceding-sibling::*[contains(@class, ' topic/p ')])
    "/>
    <p xmlns="http://www.w3.org/1999/xhtml">
      <xsl:call-template name="emit-lang-dir"/>
      <xsl:if test="@id">
        <xsl:attribute name="id" select="@id"/>
      </xsl:if>
      <xsl:if test="$is-first-body-p">
        <xsl:attribute name="class">drop-cap</xsl:attribute>
      </xsl:if>
      <xsl:apply-templates mode="topic-content"/>
    </p>
  </xsl:template>

  <!-- Transform DITA section to HTML section -->
  <xsl:template match="*[contains(@class, ' topic/section ')] | section" mode="topic-content">
    <section xmlns="http://www.w3.org/1999/xhtml">
      <xsl:call-template name="emit-lang-dir"/>
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
    <xsl:variable name="image-path" select="epub:get-relative-path($epub.topics.dir, concat($epub.images.dir, '/', tokenize(@href, '/')[last()]))"/>
    <xsl:variable name="is-decorative" select="@outputclass = 'decorative' or @alt = ''"/>
    <xsl:variable name="desc-sibling" select="following-sibling::*[contains(@class, ' topic/desc ')][1]"/>
    <xsl:variable name="desc-id" select="if ($desc-sibling) then concat('desc-', generate-id(.)) else ''"/>

    <figure xmlns="http://www.w3.org/1999/xhtml">
      <img src="{$image-path}">
        <xsl:choose>
          <!-- Decorative image: empty alt, presentation role -->
          <xsl:when test="$is-decorative">
            <xsl:attribute name="alt"/>
            <xsl:attribute name="role">presentation</xsl:attribute>
          </xsl:when>
          <!-- Image with alt text -->
          <xsl:when test="@alt">
            <xsl:attribute name="alt" select="@alt"/>
          </xsl:when>
          <!-- Missing alt text: warn and use empty alt -->
          <xsl:otherwise>
            <xsl:message>[WARN] Image missing alt text: <xsl:value-of select="@href"/></xsl:message>
            <xsl:attribute name="alt"/>
          </xsl:otherwise>
        </xsl:choose>
        <!-- Extended description via aria-describedby -->
        <xsl:if test="$desc-sibling and not($is-decorative)">
          <xsl:attribute name="aria-describedby" select="$desc-id"/>
        </xsl:if>
        <xsl:if test="@width">
          <xsl:attribute name="width" select="@width"/>
        </xsl:if>
        <xsl:if test="@height">
          <xsl:attribute name="height" select="@height"/>
        </xsl:if>
      </img>

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
  </xsl:template>

  <!-- Transform DITA table to HTML table -->
  <xsl:template match="*[contains(@class, ' topic/table ')]" mode="topic-content">
    <xsl:param name="table-offset" as="xs:integer" select="0" tunnel="yes"/>
    <table xmlns="http://www.w3.org/1999/xhtml">
      <xsl:if test="@id">
        <xsl:attribute name="id" select="@id"/>
      </xsl:if>
      <xsl:if test="*[contains(@class, ' topic/title ')]">
        <caption>
          <xsl:if test="$epub.table.numbering = 'global'">
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
    <xsl:variable name="image-path" select="epub:get-relative-path($epub.topics.dir, concat($epub.images.dir, '/', tokenize(@href, '/')[last()]))"/>
    <xsl:variable name="is-decorative" select="@outputclass = 'decorative' or @alt = ''"/>
    <img xmlns="http://www.w3.org/1999/xhtml" src="{$image-path}">
      <xsl:choose>
        <xsl:when test="$is-decorative">
          <xsl:attribute name="alt"/>
          <xsl:attribute name="role">presentation</xsl:attribute>
        </xsl:when>
        <xsl:when test="@alt">
          <xsl:attribute name="alt" select="@alt"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:message>[WARN] Image missing alt text: <xsl:value-of select="@href"/></xsl:message>
          <xsl:attribute name="alt"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:if test="@width">
        <xsl:attribute name="width" select="@width"/>
      </xsl:if>
      <xsl:if test="@height">
        <xsl:attribute name="height" select="@height"/>
      </xsl:if>
    </img>
  </xsl:template>

  <!-- Transform DITA lq to HTML blockquote (pull quote) -->
  <xsl:template match="*[contains(@class, ' topic/lq ')]" mode="topic-content">
    <blockquote xmlns="http://www.w3.org/1999/xhtml" class="pull-quote">
      <xsl:call-template name="emit-lang-dir"/>
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
      <xsl:if test="@id">
        <xsl:attribute name="id" select="@id"/>
      </xsl:if>
      <xsl:apply-templates mode="topic-content"/>
    </aside>
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

<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xhtml="http://www.w3.org/1999/xhtml"
                xmlns:epub="http://www.idpf.org/2007/ops"
                exclude-result-prefixes="xs xhtml"
                version="3.0">

  <!--
    EPUB3 Back-of-Book Index Generation

    Collects <indexterm> elements from all DITA topics, groups them
    alphabetically, and generates index.xhtml with EPUB 3 semantic markup.
    Locators use chapter.section numbers (e.g., "6.2") with precise anchor
    links that jump directly to the indexterm location in content.
  -->

  <!-- Generate back-of-book index -->
  <xsl:template name="generate-index">
    <xsl:param name="map" as="element()"/>

    <!-- Determine if index should be generated -->
    <xsl:variable name="has-indexlist" select="exists($map//*[contains(@class, ' bookmap/indexlist ')])"/>
    <xsl:variable name="should-generate" select="
      epub:is-true($epub.generate.index) or
      ($epub.generate.index = 'auto' and $has-indexlist)
    "/>

    <xsl:if test="$should-generate">
      <xsl:message>Generating back-of-book index...</xsl:message>

      <!-- Collect all topicrefs with content -->
      <xsl:variable name="all-topicrefs" select="$map//*[contains(@class, ' map/topicref ')][@href][not(@processing-role = 'resource-only')]"/>

      <!-- Build chapter number lookup: map each topicref href to its chapter label -->
      <xsl:variable name="chapter-labels" as="element()*">
        <!-- Top-level chapters -->
        <xsl:for-each select="$map/*[contains(@class, ' bookmap/chapter ') or contains(@class, ' map/topicref ')][not(contains(@class, ' bookmap/frontmatter ')) and not(contains(@class, ' bookmap/backmatter ')) and not(contains(@class, ' bookmap/appendices '))]">
          <xsl:variable name="chapter-pos" select="position()"/>
          <xsl:if test="@href">
            <label file="{epub:get-topic-filename(.)}" num="{$chapter-pos}"/>
          </xsl:if>
          <!-- Sub-topics of this chapter inherit the chapter number -->
          <xsl:for-each select=".//*[contains(@class, ' map/topicref ')][@href]">
            <label file="{epub:get-topic-filename(.)}" num="{$chapter-pos}"/>
          </xsl:for-each>
        </xsl:for-each>
        <!-- Appendices get letters -->
        <xsl:for-each select="$map//*[contains(@class, ' bookmap/appendix ')][@href]">
          <xsl:variable name="app-pos" select="position()"/>
          <xsl:variable name="app-letter" select="codepoints-to-string(string-to-codepoints('A') + $app-pos - 1)"/>
          <label file="{epub:get-topic-filename(.)}" num="{$app-letter}"/>
          <!-- Sub-topics of this appendix -->
          <xsl:for-each select=".//*[contains(@class, ' map/topicref ')][@href]">
            <label file="{epub:get-topic-filename(.)}" num="{$app-letter}"/>
          </xsl:for-each>
        </xsl:for-each>
      </xsl:variable>

      <!-- Collect all top-level indexterms from all topics -->
      <xsl:variable name="index-entries" as="element()*">
        <xsl:for-each select="$all-topicrefs">
          <xsl:variable name="topicref" select="."/>
          <xsl:variable name="topic-doc" select="document(@href, .)"/>
          <xsl:variable name="topic-filename" select="epub:get-topic-filename(.)"/>
          <xsl:variable name="topic" select="$topic-doc/*[contains(@class, ' topic/topic ') or self::topic or self::concept or self::task or self::reference]"/>
          <xsl:variable name="topic-title" select="normalize-space(($topic/*[contains(@class, ' topic/title ') or self::title])[1])"/>
          <!-- Look up chapter label for this topic -->
          <xsl:variable name="chapter-label" select="($chapter-labels[@file = $topic-filename]/@num, '')[1]"/>

          <!-- All indexterms in this document (for anchor position computation) -->
          <xsl:variable name="all-doc-indexterms" select="$topic-doc//*[self::indexterm or contains(@class, ' topic/indexterm ')]"/>
          <xsl:variable name="topic-root-id" select="($topic/@id, 'topic')[1]"/>

          <!-- Select only top-level indexterms (not nested inside another indexterm) -->
          <xsl:for-each select="$topic-doc//*[self::indexterm or contains(@class, ' topic/indexterm ')][not(parent::indexterm or parent::*[contains(@class, ' topic/indexterm ')])]">
            <xsl:variable name="primary-term" select="epub:index-term-text(.)"/>
            <xsl:variable name="sort-key" select="epub:index-sort-key(.)"/>
            <xsl:variable name="see" select="(*[self::index-see or contains(@class, ' indexing-d/index-see ')])[1]"/>
            <xsl:variable name="see-also" select="(*[self::index-see-also or contains(@class, ' indexing-d/index-see-also ')])[1]"/>
            <xsl:variable name="sub-indexterms" select="*[self::indexterm or contains(@class, ' topic/indexterm ')]"/>

            <!-- Anchor position for this indexterm (matches epub3-content.xsl anchor generation) -->
            <xsl:variable name="anchor-pos" select="count($all-doc-indexterms[. &lt;&lt; current()]) + 1"/>
            <xsl:variable name="anchor-id" select="concat('ixa-', $topic-root-id, '-', $anchor-pos)"/>

            <!-- Section position within topic for display text (e.g., chapter "6" section "2" = "6.2") -->
            <xsl:variable name="containing-section" select="ancestor::*[self::section or contains(@class, ' topic/section ')][1]"/>
            <xsl:variable name="section-pos" select="if ($containing-section) then string(count($containing-section/preceding-sibling::*[self::section or contains(@class, ' topic/section ')]) + 1) else '0'"/>

            <xsl:choose>
              <!-- Indexterm with sub-entries -->
              <xsl:when test="$sub-indexterms">
                <xsl:for-each select="$sub-indexterms">
                  <xsl:variable name="sub-term" select="epub:index-term-text(.)"/>
                  <xsl:variable name="sub-sort-key" select="epub:index-sort-key(.)"/>
                  <xsl:variable name="sub-see" select="(*[self::index-see or contains(@class, ' indexing-d/index-see ')])[1]"/>
                  <xsl:variable name="sub-see-also" select="(*[self::index-see-also or contains(@class, ' indexing-d/index-see-also ')])[1]"/>
                  <!-- Sub-indexterm gets its own anchor (nested inside parent in the content) -->
                  <xsl:variable name="sub-anchor-pos" select="count($all-doc-indexterms[. &lt;&lt; current()]) + 1"/>
                  <xsl:variable name="sub-anchor-id" select="concat('ixa-', $topic-root-id, '-', $sub-anchor-pos)"/>
                  <entry primary="{$primary-term}"
                         primary-sort="{$sort-key}"
                         sub="{$sub-term}"
                         sub-sort="{$sub-sort-key}"
                         topic-file="{$topic-filename}"
                         topic-title="{$topic-title}"
                         chapter-label="{$chapter-label}"
                         anchor-id="{$sub-anchor-id}"
                         section-pos="{$section-pos}">
                    <xsl:if test="$see-also">
                      <xsl:attribute name="primary-see-also" select="normalize-space($see-also)"/>
                    </xsl:if>
                    <xsl:if test="$see">
                      <xsl:attribute name="primary-see" select="normalize-space($see)"/>
                    </xsl:if>
                    <xsl:if test="$sub-see">
                      <xsl:attribute name="sub-see" select="normalize-space($sub-see)"/>
                    </xsl:if>
                    <xsl:if test="$sub-see-also">
                      <xsl:attribute name="sub-see-also" select="normalize-space($sub-see-also)"/>
                    </xsl:if>
                  </entry>
                </xsl:for-each>
                <!-- Also emit the primary entry itself if it has a see or see-also -->
                <xsl:if test="$see">
                  <entry primary="{$primary-term}"
                         primary-sort="{$sort-key}"
                         sub=""
                         sub-sort=""
                         topic-file=""
                         topic-title=""
                         chapter-label=""
                         anchor-id=""
                         section-pos="0"
                         primary-see="{normalize-space($see)}"/>
                </xsl:if>
                <xsl:if test="$see-also and not($see)">
                  <entry primary="{$primary-term}"
                         primary-sort="{$sort-key}"
                         sub=""
                         sub-sort=""
                         topic-file="{$topic-filename}"
                         topic-title="{$topic-title}"
                         chapter-label="{$chapter-label}"
                         anchor-id="{$anchor-id}"
                         section-pos="{$section-pos}"
                         primary-see-also="{normalize-space($see-also)}"/>
                </xsl:if>
              </xsl:when>

              <!-- Simple indexterm (no sub-entries) -->
              <xsl:otherwise>
                <entry primary="{$primary-term}"
                       primary-sort="{$sort-key}"
                       sub=""
                       sub-sort=""
                       topic-file="{if ($see) then '' else $topic-filename}"
                       topic-title="{if ($see) then '' else $topic-title}"
                       chapter-label="{if ($see) then '' else $chapter-label}"
                       anchor-id="{if ($see) then '' else $anchor-id}"
                       section-pos="{if ($see) then '0' else $section-pos}">
                  <xsl:if test="$see">
                    <xsl:attribute name="primary-see" select="normalize-space($see)"/>
                  </xsl:if>
                  <xsl:if test="$see-also">
                    <xsl:attribute name="primary-see-also" select="normalize-space($see-also)"/>
                  </xsl:if>
                </entry>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
        </xsl:for-each>
      </xsl:variable>

      <xsl:if test="count($index-entries) > 0">
        <xsl:message>Collected <xsl:value-of select="count($index-entries)"/> index entries from topics.</xsl:message>

        <xsl:result-document href="{concat($epub.topics.dir, '/index.xhtml')}"
                             method="xhtml"
                             encoding="UTF-8"
                             indent="yes">
          <html xmlns="http://www.w3.org/1999/xhtml"
                xmlns:epub="http://www.idpf.org/2007/ops"
                xml:lang="{epub:get-language($map)}"
                dir="{epub:get-dir(epub:get-language($map))}">
            <head>
              <meta charset="UTF-8"/>
              <title>Index</title>
              <xsl:call-template name="emit-css-links"/>
            </head>
            <body epub:type="index">
              <h1>
                <xsl:choose>
                  <xsl:when test="starts-with(epub:get-language($map), 'fr')">Index</xsl:when>
                  <xsl:when test="starts-with(epub:get-language($map), 'de')">Stichwortverzeichnis</xsl:when>
                  <xsl:when test="starts-with(epub:get-language($map), 'es')">Índice</xsl:when>
                  <xsl:when test="starts-with(epub:get-language($map), 'it')">Indice analitico</xsl:when>
                  <xsl:when test="starts-with(epub:get-language($map), 'pt')">Índice remissivo</xsl:when>
                  <xsl:when test="starts-with(epub:get-language($map), 'nl')">Register</xsl:when>
                  <xsl:when test="starts-with(epub:get-language($map), 'ja')">索引</xsl:when>
                  <xsl:when test="starts-with(epub:get-language($map), 'zh')">索引</xsl:when>
                  <xsl:when test="starts-with(epub:get-language($map), 'ar')">الفهرس</xsl:when>
                  <xsl:when test="starts-with(epub:get-language($map), 'he')">מפתח</xsl:when>
                  <xsl:otherwise>Index</xsl:otherwise>
                </xsl:choose>
              </h1>

              <!-- Group by first letter of primary sort key -->
              <xsl:for-each-group select="$index-entries" group-by="upper-case(substring(@primary-sort, 1, 1))">
                <xsl:sort select="upper-case(substring(@primary-sort, 1, 1))"/>

                <xsl:variable name="letter" select="upper-case(substring(@primary-sort, 1, 1))"/>

                <section epub:type="index-group" id="index-{$letter}">
                  <h2><xsl:value-of select="$letter"/></h2>
                  <ul epub:type="index-entry-list">
                    <!-- Group by primary term -->
                    <xsl:for-each-group select="current-group()" group-by="@primary">
                      <xsl:sort select="lower-case(current-group()[1]/@primary-sort)"/>

                      <xsl:variable name="primary" select="@primary"/>
                      <xsl:variable name="primary-entries" select="current-group()"/>
                      <xsl:variable name="primary-see" select="($primary-entries[@primary-see != ''])[1]/@primary-see"/>
                      <xsl:variable name="primary-see-also" select="($primary-entries[@primary-see-also != ''])[1]/@primary-see-also"/>
                      <xsl:variable name="has-sub-entries" select="exists($primary-entries[@sub != ''])"/>
                      <!-- Locators for the primary term itself (entries with no sub-term and a topic-file) -->
                      <xsl:variable name="primary-locators" select="$primary-entries[@sub = '' and @topic-file != '']"/>

                      <li epub:type="index-entry" id="idx-{generate-id(.)}">
                        <span epub:type="index-term"><xsl:value-of select="$primary"/></span>

                        <xsl:choose>
                          <!-- See-only entry: no locators, just cross-reference -->
                          <xsl:when test="$primary-see and not($has-sub-entries) and count($primary-locators) = 0">
                            <xsl:text>. </xsl:text>
                            <span epub:type="index-xref-preferred">
                              <em>See</em>
                              <xsl:text> </xsl:text>
                              <xsl:value-of select="$primary-see"/>
                            </span>
                          </xsl:when>

                          <xsl:otherwise>
                            <!-- Primary-level locators with precise anchor links -->
                            <xsl:if test="count($primary-locators) > 0">
                              <xsl:text>, </xsl:text>
                              <span epub:type="index-locator-list">
                                <xsl:for-each-group select="$primary-locators" group-by="@anchor-id">
                                  <xsl:sort select="epub:index-locator-sort-key(.)" data-type="text"/>
                                  <xsl:if test="position() > 1">
                                    <xsl:text>, </xsl:text>
                                  </xsl:if>
                                  <a epub:type="index-locator" href="{@topic-file}#{@anchor-id}"><xsl:value-of select="epub:index-locator-text(.)"/></a>
                                </xsl:for-each-group>
                              </span>
                            </xsl:if>

                            <!-- See also at primary level -->
                            <xsl:if test="$primary-see-also">
                              <xsl:text>. </xsl:text>
                              <span epub:type="index-xref-related">
                                <em>See also</em>
                                <xsl:text> </xsl:text>
                                <xsl:value-of select="$primary-see-also"/>
                              </span>
                            </xsl:if>

                            <!-- Sub-entries -->
                            <xsl:if test="$has-sub-entries">
                              <ul epub:type="index-entry-list">
                                <xsl:for-each-group select="$primary-entries[@sub != '']" group-by="@sub">
                                  <xsl:sort select="lower-case(current-group()[1]/@sub-sort)"/>

                                  <xsl:variable name="sub-entries" select="current-group()"/>
                                  <xsl:variable name="sub-see" select="($sub-entries[@sub-see != ''])[1]/@sub-see"/>
                                  <xsl:variable name="sub-see-also" select="($sub-entries[@sub-see-also != ''])[1]/@sub-see-also"/>
                                  <xsl:variable name="sub-locators" select="$sub-entries[@topic-file != '']"/>

                                  <li epub:type="index-entry">
                                    <span epub:type="index-term"><xsl:value-of select="@sub"/></span>

                                    <xsl:choose>
                                      <xsl:when test="$sub-see and count($sub-locators) = 0">
                                        <xsl:text>. </xsl:text>
                                        <span epub:type="index-xref-preferred">
                                          <em>See</em>
                                          <xsl:text> </xsl:text>
                                          <xsl:value-of select="$sub-see"/>
                                        </span>
                                      </xsl:when>
                                      <xsl:otherwise>
                                        <xsl:if test="count($sub-locators) > 0">
                                          <xsl:text>, </xsl:text>
                                          <span epub:type="index-locator-list">
                                            <xsl:for-each-group select="$sub-locators" group-by="@anchor-id">
                                              <xsl:sort select="epub:index-locator-sort-key(.)" data-type="text"/>
                                              <xsl:if test="position() > 1">
                                                <xsl:text>, </xsl:text>
                                              </xsl:if>
                                              <a epub:type="index-locator" href="{@topic-file}#{@anchor-id}"><xsl:value-of select="epub:index-locator-text(.)"/></a>
                                            </xsl:for-each-group>
                                          </span>
                                        </xsl:if>
                                        <xsl:if test="$sub-see-also">
                                          <xsl:text>. </xsl:text>
                                          <span epub:type="index-xref-related">
                                            <em>See also</em>
                                            <xsl:text> </xsl:text>
                                            <xsl:value-of select="$sub-see-also"/>
                                          </span>
                                        </xsl:if>
                                      </xsl:otherwise>
                                    </xsl:choose>
                                  </li>
                                </xsl:for-each-group>
                              </ul>
                            </xsl:if>
                          </xsl:otherwise>
                        </xsl:choose>
                      </li>
                    </xsl:for-each-group>
                  </ul>
                </section>
              </xsl:for-each-group>
            </body>
          </html>
        </xsl:result-document>

        <xsl:message>Back-of-book index generated with <xsl:value-of select="count(distinct-values($index-entries/@primary))"/> unique primary entries.</xsl:message>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <!-- Compute locator display text: chapter.section if available, chapter only otherwise -->
  <xsl:function name="epub:index-locator-text" as="xs:string">
    <xsl:param name="entry" as="element()"/>
    <xsl:choose>
      <xsl:when test="$entry/@chapter-label != '' and $entry/@section-pos != '0'">
        <xsl:sequence select="concat($entry/@chapter-label, '.', $entry/@section-pos)"/>
      </xsl:when>
      <xsl:when test="$entry/@chapter-label != ''">
        <xsl:sequence select="string($entry/@chapter-label)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="string($entry/@topic-title)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- Compute sort key for locator ordering (chapter number then section) -->
  <xsl:function name="epub:index-locator-sort-key" as="xs:string">
    <xsl:param name="entry" as="element()"/>
    <xsl:variable name="ch" select="string($entry/@chapter-label)"/>
    <xsl:variable name="sec" select="string($entry/@section-pos)"/>
    <!-- Numeric chapters: 0-padded. Letter appendices: sort after all numeric chapters -->
    <xsl:variable name="ch-sort" select="
      if (matches($ch, '^\d+$')) then format-number(xs:integer($ch), '0000')
      else if ($ch != '') then concat('9999-', $ch)
      else '9999-ZZZ'
    "/>
    <xsl:variable name="sec-sort" select="
      if ($sec != '' and $sec != '0') then format-number(xs:integer($sec), '0000')
      else '0000'
    "/>
    <xsl:sequence select="concat($ch-sort, '-', $sec-sort)"/>
  </xsl:function>

  <!-- Extract display text from an indexterm (excluding child indexterm, index-see, index-see-also, index-sort-as) -->
  <xsl:function name="epub:index-term-text" as="xs:string">
    <xsl:param name="indexterm" as="element()"/>
    <xsl:variable name="text-nodes" select="$indexterm/node()[
      not(self::indexterm or self::*[contains(@class, ' topic/indexterm ')]) and
      not(self::index-see or self::*[contains(@class, ' indexing-d/index-see ')]) and
      not(self::index-see-also or self::*[contains(@class, ' indexing-d/index-see-also ')]) and
      not(self::index-sort-as or self::*[contains(@class, ' indexing-d/index-sort-as ')])
    ]"/>
    <xsl:sequence select="normalize-space(string-join($text-nodes, ''))"/>
  </xsl:function>

  <!-- Compute sort key for an indexterm -->
  <xsl:function name="epub:index-sort-key" as="xs:string">
    <xsl:param name="indexterm" as="element()"/>
    <xsl:variable name="sort-as" select="$indexterm/*[self::index-sort-as or contains(@class, ' indexing-d/index-sort-as ')]"/>
    <xsl:choose>
      <xsl:when test="$sort-as">
        <xsl:sequence select="normalize-space($sort-as[1])"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="epub:index-term-text($indexterm)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

</xsl:stylesheet>

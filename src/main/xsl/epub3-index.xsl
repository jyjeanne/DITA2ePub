<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xhtml="http://www.w3.org/1999/xhtml"
                xmlns:epub="http://www.idpf.org/2007/ops"
                exclude-result-prefixes="xs xhtml"
                version="3.0">

  <!--
    EPUB3 Back-of-Book Index Generation

    Collects <indexterm> elements from all DITA topics, groups them by initial letter, and
    generates index.xhtml with EPUB 3 semantic markup. Groups and entries follow the collation
    of the publication's language: in French, "élevage" belongs to E; in Swedish, "Å" comes
    after "Z".

    Each locator links to the first index anchor of a topic, and is labeled with the topic's
    position in the reading order: "3" for a chapter, "3.2" for the second topic under it,
    "A.1" in an appendix. Only entries that lead to content are numbered.
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
      <xsl:variable name="all-topicrefs" select="epub:content-topicrefs($map)"/>

      <!-- Position of each topic in the reading order, used as its locator label -->
      <xsl:variable name="chapter-labels" select="epub:index-chapter-labels($map)"/>

      <!-- Collect all top-level indexterms from all topics -->
      <xsl:variable name="index-entries" as="element()*">
        <xsl:for-each select="$all-topicrefs">
          <xsl:variable name="topicref" select="."/>
          <xsl:variable name="topic-doc" select="epub:topic-document(.)"/>
          <xsl:variable name="topic-filename" select="epub:get-topic-filename(.)"/>
          <!-- First topic, as in epub3-content.xsl (a <dita> file holds several) -->
          <xsl:variable name="topic" select="($topic-doc//*[contains(@class, ' topic/topic ') or self::topic or self::concept or self::task or self::reference])[1]"/>
          <xsl:variable name="topic-title" select="normalize-space(($topic/*[contains(@class, ' topic/title ') or self::title])[1])"/>
          <!-- Look up the locator label of this topic (the first reference to a topic wins) -->
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
                         anchor-id="{$sub-anchor-id}">
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
                       anchor-id="{if ($see) then '' else $anchor-id}">
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
              <xsl:call-template name="index-groups">
                <xsl:with-param name="entries" select="$index-entries"/>
                <xsl:with-param name="lang" select="epub:get-language($map)"/>
              </xsl:call-template>
            </body>
          </html>
        </xsl:result-document>

        <xsl:message>Back-of-book index generated with <xsl:value-of select="count(distinct-values($index-entries/@primary))"/> unique primary entries.</xsl:message>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <!-- The letter groups of the index, from the collected entries -->
  <xsl:template name="index-groups">
    <xsl:param name="entries" as="element()*"/>
    <xsl:param name="lang" as="xs:string"/>

    <!-- Entries sort by the collation of the language; groups compare letters at primary
         strength, so that a letter and its accented forms share a group where the language
         treats them as one letter (French É and E), and not where it does not (Swedish Å) -->
    <xsl:variable name="collation" select="epub:index-collation($lang, false())"/>
    <xsl:variable name="group-collation" select="epub:index-collation($lang, true())"/>

    <xsl:for-each-group select="$entries" group-by="substring(@primary-sort, 1, 1)" collation="{$group-collation}">
      <xsl:sort select="current-grouping-key()" collation="{$group-collation}"/>

      <xsl:variable name="first-key" select="sort(current-group()/@primary-sort/string(), $collation)[1]"/>
      <xsl:variable name="letter" select="epub:index-group-label(substring($first-key, 1, 1), $group-collation)"/>

      <section xmlns="http://www.w3.org/1999/xhtml" epub:type="index-group" id="index-{$letter}">
        <h2><xsl:value-of select="$letter"/></h2>
        <ul epub:type="index-entry-list">
          <!-- Group by primary term -->
          <xsl:for-each-group select="current-group()" group-by="@primary">
            <xsl:sort select="current-group()[1]/@primary-sort" collation="{$collation}"/>

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
                  <!-- Primary-level locators -->
                  <xsl:if test="count($primary-locators) > 0">
                    <xsl:text>, </xsl:text>
                    <xsl:call-template name="index-locator-list">
                      <xsl:with-param name="locators" select="$primary-locators"/>
                    </xsl:call-template>
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
                        <xsl:sort select="current-group()[1]/@sub-sort" collation="{$collation}"/>

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
                                <xsl:call-template name="index-locator-list">
                                  <xsl:with-param name="locators" select="$sub-locators"/>
                                </xsl:call-template>
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
  </xsl:template>

  <!-- One locator per topic, in reading order, linked to the topic's first matching anchor -->
  <xsl:template name="index-locator-list">
    <xsl:param name="locators" as="element()*"/>
    <span xmlns="http://www.w3.org/1999/xhtml" epub:type="index-locator-list">
      <xsl:for-each-group select="$locators" group-by="@topic-file">
        <xsl:sort select="epub:index-locator-sort-key(.)"/>
        <xsl:if test="position() > 1">
          <xsl:text>, </xsl:text>
        </xsl:if>
        <a epub:type="index-locator" href="{@topic-file}#{@anchor-id}"><xsl:value-of select="epub:index-locator-text(.)"/></a>
      </xsl:for-each-group>
    </span>
  </xsl:template>

  <!-- Collation URI for the index of a language; primary strength ignores accents and case -->
  <xsl:function name="epub:index-collation" as="xs:string">
    <xsl:param name="lang" as="xs:string"/>
    <xsl:param name="primary" as="xs:boolean"/>
    <xsl:sequence select="concat('http://www.w3.org/2013/collation/UCA?lang=',
                                 if (normalize-space($lang) != '') then normalize-space($lang) else 'en',
                                 if ($primary) then ';strength=primary' else '')"/>
  </xsl:function>

  <!-- Heading of a letter group: the initial, upper-cased, without its accent when the language
       treats the accented letter as the base letter (É under E in French, Å kept in Swedish) -->
  <xsl:function name="epub:index-group-label" as="xs:string">
    <xsl:param name="initial" as="xs:string"/>
    <xsl:param name="group-collation" as="xs:string"/>
    <xsl:variable name="letter" select="upper-case($initial)"/>
    <xsl:variable name="base" select="replace(normalize-unicode($letter, 'NFD'), '\p{Mn}', '')"/>
    <xsl:sequence select="if ($base != '' and compare($base, $letter, $group-collation) = 0) then $base else $letter"/>
  </xsl:function>

  <!-- Locator label of each topic: its position in the reading order. Chapters are numbered
       1, 2, 3; the topics under them 1.1, 1.2, 1.2.1; appendices A, B and A.1. Entries that lead
       to no content (key definitions, subject definitions, resource-only references) take no
       number, and groups without a title (such as the wrappers of referenced maps) are
       transparent. -->
  <xsl:function name="epub:index-chapter-labels" as="element()*">
    <xsl:param name="map" as="element()"/>
    <xsl:variable name="chapters" select="epub:index-numbered-children($map)
      [not(contains(@class, ' bookmap/frontmatter ') or contains(@class, ' bookmap/backmatter ')
           or contains(@class, ' bookmap/appendices ') or contains(@class, ' bookmap/appendix '))]"/>
    <xsl:for-each select="$chapters">
      <xsl:sequence select="epub:index-number-entry(., string(position()))"/>
    </xsl:for-each>
    <xsl:for-each select="$map//*[contains(@class, ' bookmap/appendix ')][epub:index-leads-to-content(.)]">
      <xsl:sequence select="epub:index-number-entry(., codepoints-to-string(64 + position()))"/>
    </xsl:for-each>
  </xsl:function>

  <!-- Labels of an entry and of the entries under it -->
  <xsl:function name="epub:index-number-entry" as="element()*">
    <xsl:param name="entry" as="element()"/>
    <xsl:param name="number" as="xs:string"/>
    <xsl:if test="epub:is-content-topicref($entry)">
      <label file="{epub:get-topic-filename($entry)}" num="{$number}"/>
    </xsl:if>
    <xsl:for-each select="epub:index-numbered-children($entry)">
      <xsl:sequence select="epub:index-number-entry(., concat($number, '.', position()))"/>
    </xsl:for-each>
  </xsl:function>

  <!-- Child entries that take a number: those that lead to content, looking through untitled
       groups and through bookmap parts, so that chapters are numbered across parts as in a book -->
  <xsl:function name="epub:index-numbered-children" as="element()*">
    <xsl:param name="parent" as="element()"/>
    <xsl:for-each select="$parent/*[contains(@class, ' map/topicref ')][epub:index-leads-to-content(.)]">
      <xsl:choose>
        <xsl:when test="contains(@class, ' bookmap/part ')
                        or (not(@href) and not(@navtitle or *[contains(@class, ' map/topicmeta ')]/*[contains(@class, ' topic/navtitle ')]))">
          <xsl:sequence select="epub:index-numbered-children(.)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:sequence select="."/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:function>

  <!-- Whether an entry is, or contains, a reference to content -->
  <xsl:function name="epub:index-leads-to-content" as="xs:boolean">
    <xsl:param name="entry" as="element()"/>
    <xsl:sequence select="epub:is-content-topicref($entry)
      or exists($entry//*[contains(@class, ' map/topicref ')][epub:is-content-topicref(.)])"/>
  </xsl:function>

  <!-- Locator display text: the topic's position label, or its title when it has none -->
  <xsl:function name="epub:index-locator-text" as="xs:string">
    <xsl:param name="entry" as="element()"/>
    <xsl:sequence select="if ($entry/@chapter-label != '') then string($entry/@chapter-label)
                          else string($entry/@topic-title)"/>
  </xsl:function>

  <!-- Sort key of a locator: each part of its label, numbers padded, appendices after chapters,
       and topics without a label last -->
  <xsl:function name="epub:index-locator-sort-key" as="xs:string">
    <xsl:param name="entry" as="element()"/>
    <xsl:variable name="label" select="string($entry/@chapter-label)"/>
    <xsl:sequence select="if ($label = '') then concat('~', $entry/@topic-title)
      else string-join(for $part in tokenize($label, '\.')
                       return if (matches($part, '^\d+$')) then format-number(xs:integer($part), '00000')
                              else concat('~', $part), '.')"/>
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

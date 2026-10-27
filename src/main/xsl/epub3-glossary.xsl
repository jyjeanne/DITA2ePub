<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xhtml="http://www.w3.org/1999/xhtml"
                xmlns:epub="http://www.idpf.org/2007/ops"
                exclude-result-prefixes="xs xhtml"
                version="3.0">

  <!--
    EPUB3 Glossary Generation

    Collects <glossentry> topics referenced from a bookmap <glossarylist>,
    groups them alphabetically, and generates glossary.xhtml with EPUB 3.3
    Structural Semantics Vocabulary markup.
  -->

  <!-- Generate consolidated glossary page -->
  <xsl:template name="generate-glossary">
    <xsl:param name="map" as="element()"/>

    <!-- Determine if glossary should be generated -->
    <xsl:variable name="glossary-topicrefs" select="$map//*[contains(@class, ' bookmap/glossarylist ')]//*[contains(@class, ' map/topicref ')][@href][not(@processing-role = 'resource-only')]"/>
    <xsl:variable name="should-generate" select="
      count($glossary-topicrefs) > 0 and (
        epub:is-true($epub.generate.glossary) or
        $epub.generate.glossary = 'auto'
      )
    "/>

    <xsl:if test="$should-generate">
      <xsl:message>Generating consolidated glossary...</xsl:message>

      <!-- Collect glossary entries from referenced topics -->
      <xsl:variable name="glossary-entries" as="element()*">
        <xsl:for-each select="$glossary-topicrefs">
          <xsl:variable name="topic-doc" select="epub:topic-document(.)"/>
          <xsl:variable name="glossentry" select="$topic-doc/*[contains(@class, ' glossentry/glossentry ') or self::glossentry]"/>

          <xsl:if test="$glossentry">
            <xsl:variable name="term" select="normalize-space(($glossentry/*[contains(@class, ' glossentry/glossterm ') or self::glossterm])[1])"/>
            <xsl:variable name="def" select="normalize-space(($glossentry/*[contains(@class, ' glossentry/glossdef ') or self::glossdef])[1])"/>
            <xsl:variable name="sort-key" select="upper-case($term)"/>

            <xsl:if test="string-length($term) > 0">
              <gloss-entry term="{$term}" def="{$def}" sort-key="{$sort-key}"/>
            </xsl:if>
          </xsl:if>
        </xsl:for-each>
      </xsl:variable>

      <xsl:if test="count($glossary-entries) > 0">
        <xsl:message>Collected <xsl:value-of select="count($glossary-entries)"/> glossary entries from topics.</xsl:message>

        <xsl:variable name="lang" select="epub:get-language($map)"/>
        <xsl:variable name="glossary-title">
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
        </xsl:variable>

        <xsl:result-document href="{concat($epub.topics.dir, '/glossary.xhtml')}"
                             method="xhtml"
                             encoding="UTF-8"
                             indent="yes">
          <html xmlns="http://www.w3.org/1999/xhtml"
                xmlns:epub="http://www.idpf.org/2007/ops"
                xml:lang="{$lang}"
                dir="{epub:get-dir($lang)}">
            <head>
              <meta charset="UTF-8"/>
              <title><xsl:value-of select="$glossary-title"/></title>
              <xsl:call-template name="emit-css-links"/>
            </head>
            <body>
              <article epub:type="glossary">
                <h1><xsl:value-of select="$glossary-title"/></h1>

                <!-- Group by first letter of sort key -->
                <xsl:for-each-group select="$glossary-entries" group-by="substring(@sort-key, 1, 1)">
                  <xsl:sort select="substring(@sort-key, 1, 1)"/>

                  <xsl:variable name="letter" select="upper-case(substring(@sort-key, 1, 1))"/>

                  <section id="glossary-{$letter}">
                    <h2><xsl:value-of select="$letter"/></h2>
                    <dl epub:type="glossary">
                      <xsl:for-each select="current-group()">
                        <xsl:sort select="@sort-key"/>
                        <dt><xsl:value-of select="@term"/></dt>
                        <dd><xsl:value-of select="@def"/></dd>
                      </xsl:for-each>
                    </dl>
                  </section>
                </xsl:for-each-group>
              </article>
            </body>
          </html>
        </xsl:result-document>

        <xsl:message>Consolidated glossary generated with <xsl:value-of select="count($glossary-entries)"/> entries.</xsl:message>
      </xsl:if>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>

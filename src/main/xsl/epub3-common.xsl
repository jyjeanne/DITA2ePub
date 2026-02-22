<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:epub="http://www.idpf.org/2007/ops"
                xmlns:opf="http://www.idpf.org/2007/opf"
                exclude-result-prefixes="xs"
                version="3.0">

  <!--
    EPUB3 Common Utilities

    Common templates and functions used across EPUB3 transformation
  -->

  <!-- Generate unique identifier in RFC 4122 UUID v4 format -->
  <xsl:function name="epub:generate-uuid" as="xs:string">
    <!-- Build a deterministic hex string from the current timestamp -->
    <xsl:variable name="ts" select="format-dateTime(current-dateTime(), '[Y0001][M01][D01][H01][m01][s01][f001]')"/>
    <!-- Pad to 32 hex chars: timestamp digits + static suffix -->
    <xsl:variable name="raw" select="concat($ts, 'a1b2c3d4e5f60789')"/>
    <xsl:variable name="hex" select="substring($raw, 1, 32)"/>
    <!-- Format as 8-4-4-4-12 with UUID v4 version (4) and variant (8) bits -->
    <xsl:sequence select="concat('urn:uuid:',
      substring($hex, 1, 8), '-',
      substring($hex, 9, 4), '-',
      '4', substring($hex, 14, 3), '-',
      'a', substring($hex, 18, 3), '-',
      substring($hex, 21, 12))"/>
  </xsl:function>

  <!-- Get publication identifier -->
  <xsl:function name="epub:get-identifier" as="xs:string">
    <xsl:param name="root" as="element()"/>
    <xsl:choose>
      <xsl:when test="$epub.identifier.scheme = 'UUID'">
        <xsl:sequence select="epub:generate-uuid()"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="epub:generate-uuid()"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- Get publication title -->
  <xsl:function name="epub:get-title" as="xs:string">
    <xsl:param name="root" as="element()"/>
    <xsl:variable name="title">
      <xsl:choose>
        <xsl:when test="$root//*[contains(@class, ' bookmap/booktitle ')]/*[contains(@class, ' bookmap/mainbooktitle ')]">
          <xsl:value-of select="normalize-space($root//*[contains(@class, ' bookmap/booktitle ')]/*[contains(@class, ' bookmap/mainbooktitle ')][1])"/>
        </xsl:when>
        <xsl:when test="$root/*[contains(@class, ' map/map ')]/@title">
          <xsl:value-of select="normalize-space($root/*[contains(@class, ' map/map ')]/@title)"/>
        </xsl:when>
        <xsl:when test="$root//*[contains(@class, ' topic/title ')][1]">
          <xsl:value-of select="normalize-space($root//*[contains(@class, ' topic/title ')][1])"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>Untitled</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:sequence select="$title"/>
  </xsl:function>

  <!-- Get publication language -->
  <xsl:function name="epub:get-language" as="xs:string">
    <xsl:param name="root" as="element()"/>
    <xsl:variable name="lang">
      <xsl:choose>
        <!-- Check for xml:lang on root element -->
        <xsl:when test="$root/@xml:lang">
          <xsl:value-of select="$root/@xml:lang"/>
        </xsl:when>
        <!-- Check on direct child (bookmap/map) -->
        <xsl:when test="$root/*/@xml:lang">
          <xsl:value-of select="$root/*/@xml:lang"/>
        </xsl:when>
        <!-- Check epub.language parameter -->
        <xsl:when test="$epub.language != ''">
          <xsl:value-of select="$epub.language"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:text>en</xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:sequence select="$lang"/>
  </xsl:function>

  <!-- Generate opaque filename for topic -->
  <xsl:function name="epub:generate-filename" as="xs:string">
    <xsl:param name="topic" as="element()"/>
    <xsl:sequence select="concat('topic-', generate-id($topic), '.xhtml')"/>
  </xsl:function>

  <!-- Get relative path -->
  <xsl:function name="epub:get-relative-path" as="xs:string">
    <xsl:param name="from-dir" as="xs:string"/>
    <xsl:param name="to-path" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="$from-dir = ''">
        <xsl:sequence select="$to-path"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="concat('../', $to-path)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- Format date for Dublin Core -->
  <xsl:function name="epub:format-dc-date" as="xs:string">
    <xsl:param name="date" as="xs:string?"/>
    <xsl:choose>
      <xsl:when test="normalize-space($date) != ''">
        <xsl:sequence select="$date"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="format-dateTime(current-dateTime(), '[Y0001]-[M01]-[D01]')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- Clean text for metadata -->
  <xsl:function name="epub:clean-text" as="xs:string">
    <xsl:param name="text" as="xs:string"/>
    <xsl:sequence select="normalize-space($text)"/>
  </xsl:function>

  <!-- Get media type from file extension -->
  <xsl:function name="epub:get-media-type" as="xs:string">
    <xsl:param name="filename" as="xs:string"/>
    <xsl:variable name="ext" select="lower-case(tokenize($filename, '\.')[last()])"/>
    <xsl:choose>
      <xsl:when test="$ext = 'xhtml' or $ext = 'html'">application/xhtml+xml</xsl:when>
      <xsl:when test="$ext = 'css'">text/css</xsl:when>
      <xsl:when test="$ext = 'js'">application/javascript</xsl:when>
      <xsl:when test="$ext = 'png'">image/png</xsl:when>
      <xsl:when test="$ext = 'jpg' or $ext = 'jpeg'">image/jpeg</xsl:when>
      <xsl:when test="$ext = 'gif'">image/gif</xsl:when>
      <xsl:when test="$ext = 'svg'">image/svg+xml</xsl:when>
      <xsl:when test="$ext = 'webp'">image/webp</xsl:when>
      <xsl:when test="$ext = 'mp3'">audio/mpeg</xsl:when>
      <xsl:when test="$ext = 'm4a'">audio/mp4</xsl:when>
      <xsl:when test="$ext = 'mp4'">video/mp4</xsl:when>
      <xsl:when test="$ext = 'webm'">video/webm</xsl:when>
      <xsl:when test="$ext = 'woff'">font/woff</xsl:when>
      <xsl:when test="$ext = 'woff2'">font/woff2</xsl:when>
      <xsl:when test="$ext = 'ttf'">font/ttf</xsl:when>
      <xsl:when test="$ext = 'otf'">font/otf</xsl:when>
      <xsl:otherwise>application/octet-stream</xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- Generate unique filename from topicref -->
  <xsl:function name="epub:get-topic-filename" as="xs:string">
    <xsl:param name="topicref" as="element()"/>

    <xsl:variable name="href" select="$topicref/@href"/>
    <xsl:choose>
      <xsl:when test="$href">
        <!-- Use the href filename without path and .dita extension -->
        <xsl:variable name="filename" select="tokenize(replace(string($href), '\\', '/'), '/')[last()]"/>
        <xsl:sequence select="concat(replace($filename, '\.dita$', ''), '.xhtml')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="concat('topic-', generate-id($topicref), '.xhtml')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

</xsl:stylesheet>

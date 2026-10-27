<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:epub="http://www.idpf.org/2007/ops"
                xmlns:opf="http://www.idpf.org/2007/opf"
                xmlns:map="http://www.w3.org/2005/xpath-functions/map"
                exclude-result-prefixes="xs map"
                version="3.0">

  <!--
    EPUB3 Common Utilities

    Common templates and functions used across EPUB3 transformation
  -->

  <!-- Stable publication identifier: a UUID derived from the title, language and root map file name.
       Rebuilding the same publication keeps its identity (reading positions, annotations, store
       listings), as EPUB recommends across revisions; different publications get different ones -->
  <xsl:function name="epub:generate-uuid" as="xs:string">
    <xsl:param name="root" as="element()"/>
    <xsl:variable name="key" select="string-join((epub:get-title($root), epub:get-language($root),
                                                  tokenize(base-uri($root), '/')[last()]), '|')"/>
    <xsl:variable name="codepoints" select="string-to-codepoints($key)"/>
    <!-- Two 64-bit multiplicative hashes (FNV-1 offset and prime, Knuth's MMIX multiplier) -->
    <xsl:variable name="h1" select="fold-left($codepoints, 14695981039346656037,
                                      function($h, $c) { ($h * 1099511628211 + $c) mod 18446744073709551616 })"/>
    <xsl:variable name="h2" select="fold-left($codepoints, 1442695040888963407,
                                      function($h, $c) { ($h * 6364136223846793005 + $c) mod 18446744073709551616 })"/>
    <xsl:variable name="hex" select="concat(epub:to-hex($h1, 16), epub:to-hex($h2, 16))"/>
    <!-- RFC 9562 layout: version 8 (custom, derived from a name) and variant 10xx -->
    <xsl:sequence select="concat('urn:uuid:',
      substring($hex, 1, 8), '-',
      substring($hex, 9, 4), '-',
      '8', substring($hex, 14, 3), '-',
      substring('89ab', $h2 mod 4 + 1, 1), substring($hex, 18, 3), '-',
      substring($hex, 21, 12))"/>
  </xsl:function>

  <!-- Lowercase hexadecimal form of a non-negative integer, left-padded to $digits -->
  <xsl:function name="epub:to-hex" as="xs:string">
    <xsl:param name="n" as="xs:integer"/>
    <xsl:param name="digits" as="xs:integer"/>
    <xsl:sequence select="if ($digits le 0) then ''
                          else concat(epub:to-hex($n idiv 16, $digits - 1), substring('0123456789abcdef', $n mod 16 + 1, 1))"/>
  </xsl:function>

  <!-- Get publication identifier -->
  <xsl:function name="epub:get-identifier" as="xs:string">
    <xsl:param name="root" as="element()"/>
    <xsl:choose>
      <!-- 1. Explicit epub.isbn parameter -->
      <xsl:when test="normalize-space($epub.isbn) != ''">
        <xsl:sequence select="normalize-space($epub.isbn)"/>
      </xsl:when>
      <!-- 2. ISBN from bookmap bookid/isbn -->
      <xsl:when test="$root//*[contains(@class, ' bookmap/bookid ')]/*[contains(@class, ' bookmap/isbn ')]
                       [normalize-space(.) != '']">
        <xsl:sequence select="normalize-space(($root//*[contains(@class, ' bookmap/bookid ')]/*[contains(@class, ' bookmap/isbn ')][normalize-space(.) != ''])[1])"/>
      </xsl:when>
      <!-- 3. Fallback to a UUID that is stable across builds -->
      <xsl:otherwise>
        <xsl:sequence select="epub:generate-uuid($root)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- MARC relator code lookup -->
  <xsl:function name="epub:marc-relator" as="xs:string">
    <xsl:param name="role" as="xs:string"/>
    <xsl:variable name="lower" select="lower-case($role)"/>
    <xsl:choose>
      <xsl:when test="$lower = 'author'">aut</xsl:when>
      <xsl:when test="$lower = 'editor'">edt</xsl:when>
      <xsl:when test="$lower = 'translator'">trl</xsl:when>
      <xsl:when test="$lower = 'illustrator'">ill</xsl:when>
      <xsl:when test="$lower = 'reviewer'">rev</xsl:when>
      <xsl:when test="$lower = 'narrator'">nrt</xsl:when>
      <xsl:when test="$lower = 'photographer'">pht</xsl:when>
      <xsl:when test="$lower = 'designer'">bkd</xsl:when>
      <xsl:when test="$lower = 'foreword'">aui</xsl:when>
      <xsl:when test="$lower = 'afterword'">aft</xsl:when>
      <!-- If already a 3-letter MARC code, pass through -->
      <xsl:when test="string-length($lower) = 3"><xsl:value-of select="$lower"/></xsl:when>
      <xsl:otherwise>oth</xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- Check if a language is right-to-left -->
  <xsl:function name="epub:is-rtl" as="xs:boolean">
    <xsl:param name="lang" as="xs:string"/>
    <xsl:sequence select="starts-with($lang, 'ar') or starts-with($lang, 'he')
      or starts-with($lang, 'fa') or starts-with($lang, 'ur')"/>
  </xsl:function>

  <!-- Get text direction for a language -->
  <xsl:function name="epub:get-dir" as="xs:string">
    <xsl:param name="lang" as="xs:string"/>
    <xsl:sequence select="if (epub:is-rtl($lang)) then 'rtl' else 'ltr'"/>
  </xsl:function>

  <!-- Get locale-aware quotation marks (open, close) -->
  <xsl:function name="epub:get-quotes" as="xs:string+">
    <xsl:param name="lang" as="xs:string"/>
    <xsl:choose>
      <xsl:when test="starts-with($lang, 'fr')"><xsl:sequence select="('&#xAB;&#xA0;', '&#xA0;&#xBB;')"/></xsl:when>
      <xsl:when test="starts-with($lang, 'de')"><xsl:sequence select="('&#x201E;', '&#x201C;')"/></xsl:when>
      <xsl:when test="starts-with($lang, 'ja')"><xsl:sequence select="('&#x300C;', '&#x300D;')"/></xsl:when>
      <xsl:when test="starts-with($lang, 'zh')"><xsl:sequence select="('&#x201C;', '&#x201D;')"/></xsl:when>
      <xsl:when test="starts-with($lang, 'ar') or starts-with($lang, 'he')"><xsl:sequence select="('&#xAB;', '&#xBB;')"/></xsl:when>
      <xsl:when test="starts-with($lang, 'es')"><xsl:sequence select="('&#xAB;', '&#xBB;')"/></xsl:when>
      <xsl:when test="starts-with($lang, 'it')"><xsl:sequence select="('&#xAB;', '&#xBB;')"/></xsl:when>
      <xsl:when test="starts-with($lang, 'pt')"><xsl:sequence select="('&#x201C;', '&#x201D;')"/></xsl:when>
      <xsl:otherwise><xsl:sequence select="('&#x201C;', '&#x201D;')"/></xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- Get publication title -->
  <xsl:function name="epub:get-title" as="xs:string">
    <xsl:param name="root" as="element()"/>
    <xsl:variable name="title">
      <xsl:choose>
        <xsl:when test="$root//*[contains(@class, ' bookmap/booktitle ')]/*[contains(@class, ' bookmap/mainbooktitle ')]">
          <xsl:value-of select="normalize-space(($root//*[contains(@class, ' bookmap/booktitle ')]/*[contains(@class, ' bookmap/mainbooktitle ')])[1])"/>
        </xsl:when>
        <xsl:when test="$root/@title">
          <xsl:value-of select="normalize-space($root/@title)"/>
        </xsl:when>
        <xsl:when test="$root//*[contains(@class, ' topic/title ')]">
          <xsl:value-of select="normalize-space(($root//*[contains(@class, ' topic/title ')])[1])"/>
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

  <!-- Get font media type from file extension -->
  <xsl:function name="epub:get-font-media-type" as="xs:string">
    <xsl:param name="filename" as="xs:string"/>
    <xsl:variable name="ext" select="lower-case(tokenize($filename, '\.')[last()])"/>
    <xsl:choose>
      <xsl:when test="$ext = 'ttf'">font/ttf</xsl:when>
      <xsl:when test="$ext = 'otf'">font/otf</xsl:when>
      <xsl:when test="$ext = 'woff'">font/woff</xsl:when>
      <xsl:when test="$ext = 'woff2'">font/woff2</xsl:when>
      <xsl:otherwise>application/octet-stream</xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- ================================================================== -->
  <!-- Font filename parsing functions for @font-face CSS generation     -->
  <!-- ================================================================== -->

  <!-- Extract font family name from filename: Roboto-BoldItalic.woff2 → Roboto
       Source-Code-Pro-Bold.woff2 → Source-Code-Pro
       Strategy: strip known weight/style suffixes from the end of the basename. -->
  <xsl:function name="epub:get-font-family" as="xs:string">
    <xsl:param name="filename" as="xs:string"/>
    <xsl:variable name="basename" select="replace($filename, '\.[^.]+$', '')"/>
    <!-- Remove trailing weight/style tokens (case-insensitive): Thin, ExtraLight, UltraLight,
         Light, Regular, Medium, SemiBold, DemiBold, Bold, ExtraBold, UltraBold, Black, Heavy,
         Italic, Oblique.  These may appear after a hyphen or concatenated (e.g. BoldItalic). -->
    <xsl:variable name="stripped" select="replace($basename,
      '[-]?(Thin|Hairline|ExtraLight|UltraLight|Light|Regular|Medium|SemiBold|DemiBold|ExtraBold|UltraBold|Bold|Black|Heavy|Italic|Oblique)+$',
      '', 'i')"/>
    <!-- If stripping removed everything (e.g. "Bold.woff2"), fall back to full basename -->
    <xsl:sequence select="if (string-length($stripped) > 0) then $stripped else $basename"/>
  </xsl:function>

  <!-- Detect font weight from filename -->
  <xsl:function name="epub:get-font-weight" as="xs:string">
    <xsl:param name="filename" as="xs:string"/>
    <xsl:variable name="lower" select="lower-case($filename)"/>
    <xsl:choose>
      <xsl:when test="contains($lower, 'thin') or contains($lower, 'hairline')">100</xsl:when>
      <xsl:when test="contains($lower, 'extralight') or contains($lower, 'ultralight')">200</xsl:when>
      <xsl:when test="contains($lower, 'light')">300</xsl:when>
      <xsl:when test="contains($lower, 'medium')">500</xsl:when>
      <xsl:when test="contains($lower, 'semibold') or contains($lower, 'demibold')">600</xsl:when>
      <xsl:when test="contains($lower, 'extrabold') or contains($lower, 'ultrabold')">800</xsl:when>
      <xsl:when test="contains($lower, 'black') or contains($lower, 'heavy')">900</xsl:when>
      <xsl:when test="contains($lower, 'bold')">700</xsl:when>
      <xsl:otherwise>400</xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- Detect font style from filename -->
  <xsl:function name="epub:get-font-style" as="xs:string">
    <xsl:param name="filename" as="xs:string"/>
    <xsl:variable name="lower" select="lower-case($filename)"/>
    <xsl:choose>
      <xsl:when test="contains($lower, 'italic')">italic</xsl:when>
      <xsl:when test="contains($lower, 'oblique')">oblique</xsl:when>
      <xsl:otherwise>normal</xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- Get CSS font format from file extension -->
  <xsl:function name="epub:get-font-format" as="xs:string">
    <xsl:param name="filename" as="xs:string"/>
    <xsl:variable name="ext" select="lower-case(tokenize($filename, '\.')[last()])"/>
    <xsl:choose>
      <xsl:when test="$ext = 'woff2'">woff2</xsl:when>
      <xsl:when test="$ext = 'woff'">woff</xsl:when>
      <xsl:when test="$ext = 'ttf'">truetype</xsl:when>
      <xsl:when test="$ext = 'otf'">opentype</xsl:when>
      <xsl:otherwise>woff2</xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- Normalized topic path from a topicref href: forward slashes, no fragment, no leading ../ -->
  <xsl:function name="epub:get-topic-path" as="xs:string">
    <xsl:param name="href" as="xs:string"/>
    <xsl:sequence select="replace(substring-before(concat(replace($href, '\\', '/'), '#'), '#'), '^(\./|\.\./)+', '')"/>
  </xsl:function>

  <!-- True when a topicref points to a local DITA topic that becomes an EPUB content document:
       not an external/peer link, not a non-DITA resource (html, pdf, ...), not a key definition
       under a resource-only branch, not a relationship table cell, and not a missing file
       (DITA-OT already reports those as DOTX008E and carries on) -->
  <xsl:function name="epub:is-content-topicref" as="xs:boolean">
    <xsl:param name="ref" as="element()"/>
    <xsl:sequence select="exists($ref/@href)
      and not($ref/@scope = ('external', 'peer'))
      and (not($ref/@format) or $ref/@format = 'dita')
      and not($ref/ancestor-or-self::*[@processing-role = 'resource-only'])
      and not($ref/ancestor::*[contains(@class, ' map/reltable ')])
      and doc-available(epub:resolve-href($ref/@href, $ref))"/>
  </xsl:function>

  <!-- Content topicrefs of a map in document order, one per topic file (the first reference wins) -->
  <xsl:function name="epub:content-topicrefs" as="element()*">
    <xsl:param name="map" as="element()"/>
    <xsl:for-each-group select="$map//*[contains(@class, ' map/topicref ')][epub:is-content-topicref(.)]"
                        group-by="epub:get-topic-path(@href)">
      <xsl:sequence select="."/>
    </xsl:for-each-group>
  </xsl:function>

  <!-- Absolute URI of the file an href points to, without its fragment -->
  <xsl:function name="epub:resolve-href" as="xs:string">
    <xsl:param name="href" as="xs:string"/>
    <xsl:param name="context" as="node()"/>
    <xsl:sequence select="string(resolve-uri(substring-before(concat(replace($href, '\\', '/'), '#'), '#'), base-uri($context)))"/>
  </xsl:function>

  <!-- File a topicref points to. Its href may end with #topicid (a topic inside a <dita> file),
       which document() cannot load, so the fragment is dropped: the whole file is rendered -->
  <xsl:function name="epub:topic-document" as="document-node()?">
    <xsl:param name="ref" as="element()"/>
    <xsl:sequence select="if ($ref/@href) then document(epub:resolve-href($ref/@href, $ref)) else ()"/>
  </xsl:function>

  <!-- Link from navigation to a topicref: its content document, plus the topic's id when the
       topicref points to one topic of a multi-topic file -->
  <xsl:function name="epub:get-topicref-link" as="xs:string">
    <xsl:param name="ref" as="element()"/>
    <xsl:variable name="target-id" select="if (contains($ref/@href, '#'))
                                           then epub:get-output-id(epub:topic-document($ref), substring-after($ref/@href, '#'))
                                           else ''"/>
    <xsl:sequence select="concat(epub:get-topic-filename($ref), if ($target-id != '') then concat('#', $target-id) else '')"/>
  </xsl:function>

  <!-- Directory of the root map in the temp dir; topics and images keep their paths relative to it -->
  <xsl:variable name="epub:map-dir" as="xs:string" select="string(resolve-uri('.', base-uri(/*)))"/>

  <!-- Content document of every packaged topic, keyed by the topic's absolute URI -->
  <xsl:variable name="epub:topic-files" as="map(xs:string, xs:string)" select="map:merge(
    for $ref in epub:content-topicrefs(/*)
    return map:entry(epub:resolve-href($ref/@href, $ref), epub:get-topic-filename($ref)),
    map{'duplicates': 'use-first'})"/>

  <!-- Path of an image inside the EPUB images directory. The Ant build copies images with their
       folders relative to the root map, so the path is the image location relative to that map -->
  <xsl:function name="epub:get-image-path" as="xs:string">
    <xsl:param name="image" as="element()"/>
    <xsl:variable name="uri" select="epub:resolve-href($image/@href, $image)"/>
    <xsl:sequence select="if (starts-with($uri, $epub:map-dir))
                          then substring-after($uri, $epub:map-dir)
                          else tokenize($uri, '/')[last()]"/>
  </xsl:function>

  <!-- Id that a DITA fragment (topicid or topicid/elementid) has in the content document made from
       $doc, or '' when that element is not rendered there (prolog, related links, unknown id) -->
  <xsl:function name="epub:get-output-id" as="xs:string">
    <xsl:param name="doc" as="document-node()?"/>
    <xsl:param name="fragment" as="xs:string"/>
    <xsl:variable name="topic-id" select="if (contains($fragment, '/')) then substring-before($fragment, '/') else $fragment"/>
    <xsl:variable name="element-id" select="substring-after($fragment, '/')"/>
    <xsl:variable name="topics" select="$doc//*[contains(@class, ' topic/topic ')]"/>
    <xsl:variable name="target-topics" select="if ($topic-id = '.') then $topics else $topics[@id = $topic-id]"/>
    <xsl:variable name="rendered" select="$target-topics/*[contains(@class, ' topic/title ') or contains(@class, ' topic/shortdesc ')
                                          or contains(@class, ' topic/abstract ') or contains(@class, ' topic/body ')]"/>
    <xsl:sequence select="
      if ($fragment = '' or empty($target-topics)) then ''
      else if ($element-id = '') then $topic-id
      else if ($rendered/descendant-or-self::*[@id = $element-id]) then $element-id
      else ''"/>
  </xsl:function>

  <!-- Href of a cross-reference in the EPUB, or '' when its target is not part of the publication.
       External links are kept; links to packaged topics point to their content document -->
  <xsl:function name="epub:get-xref-href" as="xs:string">
    <xsl:param name="xref" as="element()"/>
    <xsl:variable name="href" select="normalize-space($xref/@href)"/>
    <xsl:variable name="same-file" select="starts-with($href, '#')"/>
    <xsl:choose>
      <xsl:when test="$href = ''">
        <xsl:sequence select="''"/>
      </xsl:when>
      <xsl:when test="$xref/@scope = 'external' or matches($href, '^[a-zA-Z][a-zA-Z0-9+.\-]*:')">
        <xsl:sequence select="$href"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="uri" select="epub:resolve-href($href, $xref)"/>
        <xsl:variable name="file" select="$epub:topic-files($uri)"/>
        <xsl:variable name="doc" select="if (empty($file)) then () else if ($same-file) then root($xref) else document($uri)"/>
        <xsl:variable name="target-id" select="epub:get-output-id($doc, substring-after($href, '#'))"/>
        <xsl:sequence select="
          if (empty($file)) then ''
          else if ($same-file) then (if ($target-id != '') then concat('#', $target-id) else '')
          else concat($file, if ($target-id != '') then concat('#', $target-id) else '')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- True when no enclosing or earlier element of the document has the same id. DITA ids are only
       unique per topic, but nested topics share one content document, where ids must be unique -->
  <xsl:function name="epub:is-first-id" as="xs:boolean">
    <xsl:param name="elem" as="element()"/>
    <xsl:sequence select="not(($elem/ancestor::* | $elem/preceding::*)[@id = $elem/@id])"/>
  </xsl:function>

  <!-- True when a DITA element contains block content, which HTML does not allow inside <p> -->
  <xsl:function name="epub:has-block-content" as="xs:boolean">
    <xsl:param name="elem" as="element()"/>
    <xsl:sequence select="exists($elem//*[
      contains(@class, ' topic/pre ') or contains(@class, ' topic/ul ') or contains(@class, ' topic/ol ')
      or contains(@class, ' topic/sl ') or contains(@class, ' topic/dl ') or contains(@class, ' topic/note ')
      or contains(@class, ' topic/fig ') or contains(@class, ' topic/lq ') or contains(@class, ' topic/table ')
      or contains(@class, ' topic/simpletable ') or contains(@class, ' topic/p ') or contains(@class, ' topic/lines ')
      or contains(@class, ' topic/object ') or contains(@class, ' topic/div ')
      or (contains(@class, ' topic/image ') and @placement = 'break')])"/>
  </xsl:function>

  <!-- Topic filename from a normalized topic path, without folder and extension -->
  <xsl:function name="epub:get-topic-name" as="xs:string">
    <xsl:param name="path" as="xs:string"/>
    <xsl:sequence select="replace(tokenize($path, '/')[last()], '\.[^.]+$', '')"/>
  </xsl:function>

  <!-- Generate unique filename from topicref -->
  <xsl:function name="epub:get-topic-filename" as="xs:string">
    <xsl:param name="topicref" as="element()"/>

    <xsl:variable name="href" select="$topicref/@href"/>
    <xsl:choose>
      <xsl:when test="$href">
        <xsl:variable name="path" select="epub:get-topic-path($href)"/>
        <xsl:variable name="name" select="epub:get-topic-name($path)"/>
        <!-- Topics are flattened into one directory: when topics in different folders share a
             name (e.g. chapter1/overview.dita and chapter2/overview.dita), use their path instead -->
        <xsl:variable name="same-name-paths" select="distinct-values(
          for $ref in $topicref/ancestor-or-self::*[last()]//*[contains(@class, ' map/topicref ')][@href]
          return epub:get-topic-path($ref/@href))[epub:get-topic-name(.) = $name]"/>
        <xsl:variable name="base" select="
          if (count($same-name-paths) gt 1)
          then replace(replace($path, '\.[^./]+$', ''), '[^A-Za-z0-9._-]+', '-')
          else $name"/>
        <!-- Never reuse the name of a page the plugin generates itself (e.g. index.dita vs. index.xhtml) -->
        <xsl:sequence select="concat(
          if ($base = ('cover', 'titlepage', 'copyright', 'nav', 'glossary', 'index', 'lof', 'lot'))
          then concat('topic-', $base) else $base,
          '.xhtml')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="concat('topic-', generate-id($topicref), '.xhtml')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

</xsl:stylesheet>

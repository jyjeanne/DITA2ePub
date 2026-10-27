<?xml version="1.0" encoding="UTF-8"?>
<!--
  Stylesheet under test for the XSpec tests: the plugin modules as map2epub3.xsl includes them,
  without its DITA-OT HTML5 import (which needs a DITA-OT installation and only provides the
  fallback for elements the plugin does not render). XSpecTest checks that both include lists match.

  The tests run it with fn:transform() (run-as="external"), so that a map can be the global context
  item the modules read; fn:transform() only invokes public components, hence the package and its
  xsl:expose declarations.
-->
<xsl:package xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
             name="urn:io.github.jyjeanne.dita2epub:xspec" package-version="1.0.0"
             declared-modes="no" version="3.0">

  <xsl:include href="../../main/xsl/epub3-params.xsl"/>
  <xsl:include href="../../main/xsl/epub3-common.xsl"/>
  <xsl:include href="../../main/xsl/epub3-metadata.xsl"/>
  <xsl:include href="../../main/xsl/epub3-content.xsl"/>
  <xsl:include href="../../main/xsl/epub3-impl.xsl"/>
  <xsl:include href="../../main/xsl/epub3-index.xsl"/>
  <xsl:include href="../../main/xsl/epub3-glossary.xsl"/>
  <xsl:include href="../../main/xsl/epub3-platform.xsl"/>

  <!-- Declared by map2epub3.xsl and used by the modules' xsl:result-document -->
  <xsl:output name="xml-no-doctype" method="xml" encoding="UTF-8" indent="yes" omit-xml-declaration="no"/>

  <xsl:expose component="function" names="*" visibility="public"/>
  <xsl:expose component="template" names="*" visibility="public"/>
  <xsl:expose component="variable" names="*" visibility="public"/>
  <xsl:expose component="mode" names="*" visibility="public"/>

</xsl:package>

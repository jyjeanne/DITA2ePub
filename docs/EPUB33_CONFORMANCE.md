# EPUB 3.3 Conformance Review

Review of the DITA2ePub output against the creator requirements of
[EPUB 3.3](https://www.w3.org/TR/epub-33/) (W3C Recommendation), with
[EPUB Accessibility 1.1](https://www.w3.org/TR/epub-a11y-11/) for accessibility metadata.

| | |
|---|---|
| **Plugin version** | 2.0.0 |
| **Review date** | 2026-10-27 |
| **Last update** | 2026-10-27 — C1 to C5 fixed |
| **Validator** | EPUBCheck 5.3.0, also run with `--usage` |

## Method

1. Extract every creator requirement (MUST / SHOULD / MAY) from EPUB 3.3: publication resources, OCF
   container, package document, content documents, navigation document, fixed layout, vocabularies,
   deprecated features.
2. Compare them with the plugin code and with real output:
   - the DITA-OT 4.4.1 user guide (`dita-ot/docs`, `userguide-book.ditamap`, 234 topics);
   - the test datasets `dita/`, `dita-kdp/`, `dita-comprehensive/`;
   - fixed-layout (`epub.layout=fixed`) and Apple (`epub.platform=apple`) builds;
   - a synthetic map of inputs the datasets never use, now kept as
     [`src/test/resources/dita-edge-cases/`](../src/test/resources/dita-edge-cases/).
3. Requirements that EPUBCheck cannot verify (font obfuscation key, file name rules) are checked by tests.

## Summary

| Level | Found | Fixed | Open |
|-------|-------|-------|------|
| MUST  | 6     | 5     | 1    |
| SHOULD / recommended | 9 | 0 | 9 |

All builds above pass EPUBCheck with 0 errors and 0 warnings, including the edge-case map.

## Findings

Levels: **MUST** = conformance requirement, **SHOULD** = recommendation. Status: **Fixed**, **Open**.

### MUST

| ID | Finding | EPUB 3.3 | Status | Evidence / resolution |
|----|---------|----------|--------|-----------------------|
| C1 | Font obfuscation key removed hyphens from the unique identifier (and not tabs, CR, LF). Every identifier the plugin writes is hyphenated (`urn:uuid:…-…`, `978-0-…`), so reading systems derived another key and de-obfuscated fonts into garbage. Invisible to EPUBCheck. | 4.4.3: only U+0020, U+0009, U+000D, U+000A are removed | **Fixed** | `FontObfuscator.deriveKey` removes exactly those four code points. Tested by `FontObfuscatorTest` (key, XOR of the first 1040 bytes, `encryption.xml`). |
| C2 | Topic file names that differ only in case (`Readme.dita` / `readme.dita` in two folders) produced `Readme.xhtml` and `readme.xhtml`: the build crashed on Windows, and elsewhere the EPUB broke the uniqueness rule. Same risk for `Index.dita` next to the generated `index.xhtml`. | 4.2.3: names unique after case folding | **Fixed** | File names are assigned once for all topics (`epub:topic-outputs`, `epub3-common.xsl`), compared case-insensitively: shared names get path-based names, generated page names a `topic-` prefix, any remaining clash a numeric suffix. Tested by `EpubConformanceIntegrationTest`. |
| C3 | Manifest item ids were the file name without extension, so `My Topic.dita` gave `id="My Topic"`, an invalid XML name. | 5.3: valid `id` values | **Fixed** | Ids are XML names, unique, and distinct from the plugin's own items (`ncx`, `nav`, `css-*`, `image-*`…). Was EPUBCheck `RSC-005`. Tested by `EpubConformanceIntegrationTest`. |
| C4 | When `epub.toc.depth` cut below a topichead, the navigation document had an `li` with a `span` and no nested `ol`. | 7.3: a `span` label needs a nested `ol` | **Fixed** | At the depth limit, a heading without content of its own links to its first topic. Was EPUBCheck `RSC-005`. Tested by `EpubConformanceIntegrationTest` (`epub.toc.depth=1`). |
| C5 | A remote image (`scope="external"`, `https:`) became a reference to a missing local file. | 3.6: only audio, video, fonts and scripts may be remote | **Fixed** | Rendered as a link to the image, labelled with its alt text (text only inside a cross-reference), with a build warning; left out of the manifest and of the accessibility image count. Was EPUBCheck `RSC-007`. Tested by `EpubConformanceIntegrationTest`. |
| C6 | `file:` URLs in cross-references are kept as links. | 3.8: no `file:` URLs | Open | Treat them as unresolvable (text only), like links to resources outside the publication. |

### SHOULD / recommended

| ID | Finding | EPUB 3.3 | Status | Evidence / suggestion |
|----|---------|----------|--------|-----------------------|
| S1 | Every reflowable page has `<meta name="viewport" content="width=device-width…">`, which reading systems must ignore. | 8.2 (viewport is for fixed layout) | Open | EPUBCheck usage `HTM_060b` (234× in the user guide). Write it for fixed layout only. |
| S2 | The image copy step packages every image under the map folder, referenced or not. | 5.6.1 | Open | EPUBCheck usage `OPF-003` (2 SVGs in the user guide, unused covers in the datasets). Copy referenced images only. |
| S3 | ISBNs are written as plain strings. | 5.5.3.1: identifiers SHOULD be URLs or URNs | Open | Write `urn:isbn:9780134685991`. This changes the identifier, so the obfuscation key and NCX uid too. |
| S4 | The subtitle is a second `dc:title` with `title-type`. | 5.5.3.1: SHOULD use a single `dc:title` | Open | `title-type` is valid but poorly supported by reading systems; consider "Title: Subtitle". |
| S5 | BISAC codes are written as the subject text (`COM051360`). | 5.5.3.2: human-readable subjects; codes via `authority` + `term` (Example 94) | Open | `<dc:subject>COMPUTERS / …</dc:subject>` refined by `authority` = `BISAC` and `term` = the code. |
| S6 | XHTML documents declare `<!DOCTYPE html SYSTEM "about:legacy-compat">`. | 3.9 and Appendix B: no external identifier is listed for XHTML | Open | EPUBCheck accepts it; `<!DOCTYPE html>` is the unambiguous form. Low risk. |
| S7 | The `package` element has no `dir`. | 5.2: SHOULD set directionality | Open | Matters for RTL titles only; `page-progression-direction` and per-page `dir` are already set. |
| S8 | `belongs-to-collection` has no `dcterms:identifier` refinement. | D.3 vocabulary | Open | Only when a series identifier is known. |
| S9 | An image with a `data:` URL is treated as a local file, so its `src` is broken. | 3.7: data URLs are allowed in `img` | Open | Keep `data:` URLs as they are. |

## Verified compliant

- **OCF container:** `mimetype` first, stored, no extra field; `META-INF/container.xml` with one rootfile;
  ZIP rules (checked by EPUBCheck).
- **Publication resources:** core media types only; fonts obfuscated before packaging and listed in
  `encryption.xml` (algorithm `http://www.idpf.org/2008/embedding`, key never stored).
- **Package document:** `version="3.0"`, `unique-identifier`, `xml:lang`; `dc:identifier`, `dc:title`,
  `dc:language`, a single `dcterms:modified` in `YYYY-MM-DDThh:mm:ssZ`, at most one `dc:date`; reserved
  prefixes only (`a11y`, `dcterms`, `marc`, `onix`, `rendition`, `schema`).
- **Manifest and spine:** every used resource listed, exactly one `nav` item, `cover-image` when a cover is
  configured; at least one linear item, the navigation document non-linear.
- **Content documents:** XHTML (XML syntax) with a `title`, no `epub:type` on `head`; no `direction` or
  `unicode-bidi` in the CSS; UTF-8; relative URLs.
- **Navigation document:** one `toc` nav, landmarks nav `hidden` with `epub:type` on every entry.
- **Fixed layout:** `rendition:layout`, `orientation` and `spread` declared once with valid values;
  first viewport meta with `width` and `height` on every page.
- **Not used:** deprecated features (`epub:switch`, `epub:trigger`, `bindings`, `rendition:viewport`,
  `spread portrait`), data URLs in links, scripting.
- **Accessibility:** EPUB Accessibility 1.1 discovery metadata derived from the content; conformance claimed
  only when declared with an evaluator (see the README).

## Optional features not implemented

Allowed by the specification: media overlays, `page-list`, `rendition:flow` and page-spread placement,
collections, inline SVG and MathML (currently not rendered; rendering them requires the `svg` and `mathml`
manifest properties).

## How to re-check

```bash
# Unit tests and the edge-case conformance test (needs DITA-OT, see README "Testing")
./gradlew installLocalPlugin
DITA_HOME=build/dita-ot/dita-ot-4.4.1 ./gradlew check

# Usage-level messages, which the default EPUBCheck run hides (S1, S2)
java -jar epubcheck.jar book.epub --usage
```

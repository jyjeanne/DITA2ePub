# DITA2ePub Roadmap

Planned milestones and improvements after release 2.0.0. Released versions are described in
[CHANGELOG.md](CHANGELOG.md); EPUB 3.3 findings referenced below (C*n*, S*n*) are tracked in
[EPUB33_CONFORMANCE.md](EPUB33_CONFORMANCE.md).

| | |
|---|---|
| **Current release** | 2.0.0 (2026-03-09) |
| **Next release** | 2.1.0, version set on branch `fix/real-world-dita-output`, to be merged and tagged |
| **Last update** | 2026-10-27 |

Milestones are listed in priority order. Versions follow [semantic versioning](https://semver.org/):
items that change existing output in a way users may depend on (CSS classes, file names, identifiers)
are called out, and incompatible ones wait for 3.0.0.

## 2.1.0 — Real-world DITA

Goal: publications made of many maps, folders and topic types build as valid EPUB 3.3, as verified on
the DITA-OT 4.4.1 user guide (234 topics), which now passes EPUBCheck with no errors or warnings.

Done (on the branch, not yet released):

- [x] Multi-map publications: only the root map is transformed; external links, non-DITA resources,
      key definitions and relationship tables are no longer treated as topics
- [x] Nested topics and multi-topic (`<dita>`) files rendered; cross-folder cross-references resolved
      to the flattened output files (was the "cross-folder xref resolution" item of the 2.0 roadmap)
- [x] Definition and parameter lists, simple tables, examples, task blocks, related links and the
      programming, software, UI, XML-mention and highlighting domains rendered
- [x] Package metadata read from the publication's own metadata; identifier stable across builds
- [x] EPUB Accessibility 1.1 metadata derived from the content; conformance claimed only when declared
      in the bookmap with its evaluator
- [x] Single version source with the `verifyPluginVersion` check
- [x] EPUB 3.3 MUST fixes C1–C5: font obfuscation key, file names unique after case folding, valid
      manifest ids, navigation headings at the TOC depth limit, remote images
- [x] **C6** — `file:` URLs in cross-references treated as unresolvable
- [x] **S1** — viewport `meta` written for fixed layout only
- [x] **S2** — only the images the publication references are packaged
- [x] **S9** — `data:` URLs of images kept as they are
- [x] XSpec unit tests of the XSLT modules (`xspecTest` suite, run by `check`)
- [x] NCX: a topic referenced twice in the map keeps the `playOrder` of its first reference (it got a second one,
      which EPUBCheck reports as `RSC-005` on KDP builds); found by the XSpec tests
- [x] CHANGELOG section 2.1.0; version 2.1.0 in `build.gradle.kts`, `plugin.xml` and `plugin-info.xml`
- [x] Copyrighted reference EPUBs in `src/test/resources/epub` replaced by public-domain ones
- [x] Registry entry of 2.1.0 in `io.github.jyjeanne.dita2epub.json`, tested with a local registry; the release
      workflow attaches the entry with the checksum of the released ZIP

Remaining before the release:

- [ ] Make the GitHub repository public: the registry needs a ZIP that downloads without authentication
- [ ] Merge the branch and tag `v2.1.0` (the release workflow publishes the ZIP and the registry entry), record the
      checksum, and submit the entry to `dita-ot/registry` in a signed-off pull request, following
      [REGISTRY.md](REGISTRY.md)

Changes to mention in the release notes: topic file names are sanitized (no spaces, `topic-` prefix for
names of generated pages, path-based names when names clash ignoring case); the fallback identifier is
now stable; `epub.accessibility` has no effect on the output any more (no conformance claim, no viewport
on reflowable pages); only referenced images are packaged, and DITA-OT no longer copies images into the
output folder next to the EPUB.

## 2.2.0 — Standards polish and validation tooling

Goal: close the remaining EPUB 3.3 recommendations and make validation part of every build and test.

- [ ] **S3** — write ISBNs as `urn:isbn:…` URNs *(changes the identifier, hence the font obfuscation key
      and NCX uid of existing books: call it out)*
- [ ] **S4** — a single `dc:title` ("Title: Subtitle") instead of a second `dc:title` for the subtitle
- [ ] **S5** — BISAC codes as `authority` + `term` refinements of a human-readable `dc:subject`
- [ ] **S6** — `<!DOCTYPE html>` without the `about:legacy-compat` system identifier
- [ ] **S7** — `dir` on the package element for right-to-left publications
- [ ] **S8** — `dcterms:identifier` refinement for series when an identifier is known
- [ ] `EpubValidator` runs the EPUBCheck library (today it only checks the file size) and is used by all
      integration tests
- [ ] CI runs EPUBCheck, including `--usage`, on every dataset and on the edge-case map
- [ ] Optional accessibility checking with DAISY Ace in CI

## 2.3.0 — Content coverage

Goal: render the DITA content that is still dropped or approximated.

- [ ] Inline SVG (`svg-d`) and MathML (`mathml-d`), with the `svg` and `mathml` manifest properties and
      text fallbacks *(both are currently hidden)*
- [ ] Syntax diagrams (`syntaxdiagram`, `groupseq`, `groupchoice`, `groupcomp`, `fragment`) laid out
      instead of rendered as nested blocks
- [ ] Extended image descriptions from `longdescref`
- [ ] Terms and abbreviated forms linked to their glossary entries
- [ ] DITA 2.0 elements supported by DITA-OT 4.4 (`keytext`, `linktitle`, media domain audio and video,
      which EPUB allows to be remote)
- [ ] Optional download of remote images into the package (C5 currently replaces them with links)

## 2.4.0 — Reading-system features

Optional EPUB 3.3 features, depending on demand.

- [ ] Per-spine-item layout overrides: mixed reflowable and fixed-layout content in one EPUB, with
      `page-spread-left` / `page-spread-right` placement
- [ ] `rendition:flow` option (paginated or scrolled)
- [ ] `page-list` navigation, when the source carries print page references
- [ ] Media overlays (synchronized audio), low priority

## 3.0.0 — Architecture (under consideration)

Changes that would alter the generated markup, hence custom stylesheets.

- [ ] Reuse the DITA-OT HTML5 topic rendering (`org.dita.html5`) instead of the plugin's own
      `topic-content` templates, so that new DITA-OT and DITA features no longer need a parallel
      implementation; the CSS class names would change
- [ ] Topic-scoped element ids (`topicid__elementid`, as in DITA-OT HTML5) instead of keeping the first
      of duplicate ids within a content document

## Tooling and documentation

Continuous work, not tied to a release.

- [ ] Windows support for the Gradle EPUB tasks: pass DITA properties through `--propertyfile` in
      `dita-ot-gradle` to stay under the `cmd.exe` command-line limit
- [ ] Gradle task or script that builds the DITA-OT user guide EPUB as a real-world regression test:
      clone `dita-ot/docs` at the DITA-OT release tag, generate its reference topics, build, run EPUBCheck
- [ ] Reading-system smoke tests (Calibre viewer, Thorium) for navigation and links
- [ ] Refresh documents still describing 1.0.1: `TEST_COVERAGE.md`, `TEST_SUMMARY.md`,
      `PROJECT_STATUS.md` (body), `RELEASE_NOTES.md`, the "New in v1.0.1" sections of `QUICKSTART.md`,
      `.github/ACTIONS_SETUP.md`
- [ ] Measure large publications: id de-duplication scans preceding elements, which grows with
      document size

## Ideas from earlier roadmaps

Kept for reference, not scheduled.

- Font subsetting to reduce embedded font size
- Dark mode stylesheet
- More cover page layouts

Not planned: MOBI / KF8 output (Amazon KDP accepts EPUB) and a cloud build service.

# Publishing to the DITA-OT Plugin Registry

This document describes how to publish the `io.github.jyjeanne.dita2epub` plugin to the
[DITA-OT plugin registry](https://www.dita-ot.org/dev/topics/plugins-registry.html).

## Prerequisites

- A GitHub release with the distribution ZIP attached
- SHA-256 checksum of the distribution ZIP
- A fork of the [dita-ot/registry](https://github.com/dita-ot/registry) repository

## Step 1: Build the Distribution ZIP

```bash
./gradlew distChecksum
```

This produces:
- `build/dist/io.github.jyjeanne.dita2epub-<version>.zip` — the distribution package
- `build/dist/io.github.jyjeanne.dita2epub-<version>.zip.SHA-256` — the SHA-256 checksum

## Step 2: Create a GitHub Release

1. Tag the release:
   ```bash
   git tag -a v1.2.0 -m "Release v1.2.0"
   git push origin v1.2.0
   ```

2. Create a GitHub release from the tag at:
   `https://github.com/jyjeanne/dita2epub/releases/new`

3. Attach the distribution ZIP (`io.github.jyjeanne.dita2epub-1.2.0.zip`) as a release asset.

4. The download URL will be:
   ```
   https://github.com/jyjeanne/dita2epub/releases/download/v1.2.0/io.github.jyjeanne.dita2epub-1.2.0.zip
   ```

## Step 3: Update the Registry JSON

1. Update `cksum` in `io.github.jyjeanne.dita2epub.json` with the SHA-256 hash from Step 1.

2. Verify the JSON is valid:
   ```bash
   python -m json.tool io.github.jyjeanne.dita2epub.json
   ```

## Step 4: Submit to the Registry

1. Fork the [dita-ot/registry](https://github.com/dita-ot/registry) repository.

2. Copy the registry JSON into the fork:
   ```bash
   cp io.github.jyjeanne.dita2epub.json <registry-fork>/
   ```

3. Commit with sign-off (required by the registry):
   ```bash
   cd <registry-fork>
   git add io.github.jyjeanne.dita2epub.json
   git commit --signoff -m "Add io.github.jyjeanne.dita2epub plugin"
   ```

4. Push and create a pull request to `dita-ot/registry`.

## Step 5: Verify Installation

Once the PR is merged, users can install the plugin via:

```bash
dita install io.github.jyjeanne.dita2epub
```

Or a specific version:

```bash
dita install io.github.jyjeanne.dita2epub@1.2.0
```

## Adding New Versions

When releasing a new version:

1. Build and tag the new release (Steps 1-2).
2. Add a new entry to the JSON array in `io.github.jyjeanne.dita2epub.json` (newest first).
3. Submit a PR to `dita-ot/registry` with the updated JSON, signed off.

## Registry JSON Format Reference

```json
{
  "name": "io.github.jyjeanne.dita2epub",
  "description": "Plugin description",
  "keywords": ["EPUB", "EPUB3"],
  "homepage": "https://github.com/jyjeanne/dita2epub",
  "vers": "1.2.0",
  "license": "Apache-2.0",
  "deps": [
    { "name": "org.dita.base", "req": ">=4.4.0" }
  ],
  "url": "https://github.com/jyjeanne/dita2epub/releases/download/v1.2.0/io.github.jyjeanne.dita2epub-1.2.0.zip",
  "cksum": "<sha256-hash>"
}
```

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Plugin ID (must match `plugin.xml`) |
| `vers` | Yes | Semantic version (x.y.z) |
| `deps` | Yes | Dependencies with version requirements |
| `url` | Yes | Absolute URL to distribution ZIP |
| `cksum` | No | SHA-256 hash of distribution ZIP |
| `description` | No | Short plugin description |
| `keywords` | No | Search keywords |
| `homepage` | No | Project homepage URL |
| `license` | No | SPDX license identifier |

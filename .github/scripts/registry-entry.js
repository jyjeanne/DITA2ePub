// Writes the DITA-OT plugin registry entry of one release: the entry of that version in
// io.github.jyjeanne.dita2epub.json, with the download URL and the SHA-256 checksum of the released ZIP.
// The registry rejects an installation whose ZIP does not match the checksum, so it must be computed
// from the file attached to the release.
// Usage: node registry-entry.js <version> <zip> <url> <output.json>
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const [version, zip, url, output] = process.argv.slice(2);
if (!output) {
  console.error('Usage: node registry-entry.js <version> <zip> <url> <output.json>');
  process.exit(2);
}

const source = path.join(__dirname, '..', '..', 'io.github.jyjeanne.dita2epub.json');
const entry = JSON.parse(fs.readFileSync(source, 'utf8')).find(candidate => candidate.vers === version);
if (!entry) {
  console.error(`${path.basename(source)} has no entry for version ${version}`);
  process.exit(1);
}

const cksum = crypto.createHash('sha256').update(fs.readFileSync(zip)).digest('hex');
fs.writeFileSync(output, JSON.stringify([{ ...entry, url, cksum }], null, 2) + '\n');
console.log(fs.readFileSync(output, 'utf8'));

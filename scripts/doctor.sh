#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

test -f package.json
test -f .claude-plugin/marketplace.json
test -f .agents/plugins/marketplace.json
test -f .codex-plugin/plugin.json
test -f .mcp.json
test -f hooks/hooks.json

node -e 'JSON.parse(require("fs").readFileSync("package.json","utf8"))'
node -e 'JSON.parse(require("fs").readFileSync(".agents/plugins/marketplace.json","utf8"))'
node -e 'JSON.parse(require("fs").readFileSync(".codex-plugin/plugin.json","utf8"))'
node -e 'JSON.parse(require("fs").readFileSync(".mcp.json","utf8"))'
node -e 'JSON.parse(require("fs").readFileSync("hooks/hooks.json","utf8"))'

# Parity: every skills/<set>/<name>/SKILL.md must be claimed by exactly one
# entry in .claude-plugin/marketplace.json, and every claimed path must exist.
node <<'EOF'
const fs = require("fs");
const path = require("path");

const manifest = JSON.parse(fs.readFileSync(".claude-plugin/marketplace.json", "utf8"));
const claimed = [];
for (const plugin of manifest.plugins ?? []) {
  for (const p of plugin.skills ?? []) claimed.push(path.normalize(p));
}

const onDisk = [];
for (const set of fs.readdirSync("skills")) {
  const setDir = path.join("skills", set);
  if (!fs.statSync(setDir).isDirectory()) continue;
  for (const name of fs.readdirSync(setDir)) {
    const dir = path.join(setDir, name);
    if (fs.existsSync(path.join(dir, "SKILL.md"))) onDisk.push(path.normalize(dir));
  }
}

const claimedSet = new Set(claimed);
const diskSet = new Set(onDisk);
const unclaimed = onDisk.filter((d) => !claimedSet.has(d));
const dangling = claimed.filter((c) => !diskSet.has(c));
const dupes = claimed.filter((c, i) => claimed.indexOf(c) !== i);

if (unclaimed.length) throw new Error(`skills on disk not claimed in marketplace.json: ${unclaimed.join(", ")}`);
if (dangling.length) throw new Error(`marketplace.json claims missing skills: ${dangling.join(", ")}`);
if (dupes.length) throw new Error(`skills claimed by more than one plugin: ${dupes.join(", ")}`);
if (onDisk.length === 0) throw new Error("no skills found under skills/<set>/<name>/SKILL.md");

console.log(`parity ok (${onDisk.length} skills, ${(manifest.plugins ?? []).length} sets)`);
EOF

echo "doctor ok"

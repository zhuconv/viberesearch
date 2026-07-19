#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

test -f package.json
test -f .claude-plugin/marketplace.json
test -f .claude-plugin/plugin.json
test -f .agents/plugins/marketplace.json
test -f .codex-plugin/plugin.json
test -f .mcp.json
test -f hooks/hooks.json

node -e 'JSON.parse(require("fs").readFileSync("package.json","utf8"))'
node -e 'JSON.parse(require("fs").readFileSync(".claude-plugin/marketplace.json","utf8"))'
node -e 'JSON.parse(require("fs").readFileSync(".claude-plugin/plugin.json","utf8"))'
node -e 'JSON.parse(require("fs").readFileSync(".agents/plugins/marketplace.json","utf8"))'
node -e 'JSON.parse(require("fs").readFileSync(".codex-plugin/plugin.json","utf8"))'
node -e 'JSON.parse(require("fs").readFileSync(".mcp.json","utf8"))'
node -e 'JSON.parse(require("fs").readFileSync("hooks/hooks.json","utf8"))'

shopt -s nullglob
found=0
for f in skills/*/SKILL.md; do
  test -f "$f"
  found=$((found + 1))
done
shopt -u nullglob
test "$found" -gt 0

echo "doctor ok ($found skills)"

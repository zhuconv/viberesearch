#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT"

test -f package.json
test -f .claude-plugin/marketplace.json
test -f .agents/plugins/marketplace.json
test -f plugins/jiajun-core/.claude-plugin/plugin.json
test -f plugins/jiajun-core/.codex-plugin/plugin.json
test -f plugins/jiajun-core/.mcp.json
test -f plugins/jiajun-core/hooks/hooks.json

node -e 'JSON.parse(require("fs").readFileSync("package.json","utf8"))'
node -e 'JSON.parse(require("fs").readFileSync(".claude-plugin/marketplace.json","utf8"))'
node -e 'JSON.parse(require("fs").readFileSync(".agents/plugins/marketplace.json","utf8"))'
node -e 'JSON.parse(require("fs").readFileSync("plugins/jiajun-core/.claude-plugin/plugin.json","utf8"))'
node -e 'JSON.parse(require("fs").readFileSync("plugins/jiajun-core/.codex-plugin/plugin.json","utf8"))'
node -e 'JSON.parse(require("fs").readFileSync("plugins/jiajun-core/.mcp.json","utf8"))'
node -e 'JSON.parse(require("fs").readFileSync("plugins/jiajun-core/hooks/hooks.json","utf8"))'

for f in plugins/jiajun-core/skills/*/SKILL.md; do
  test -f "$f"
done

echo "doctor ok"

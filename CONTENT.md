# CONTENT — what this repo ships

Live inventory of every artifact this repo contributes to Claude Code and Codex — and of every skill `npx skills add zhuconv/viberesearch` installs. Skills here are ours to maintain, not live aliases of someone else's repo (that pattern — a marketplace entry that just points at upstream — is what the README's "Useful content from elsewhere" is for). Where a skill started from someone else's work, its row below names the source and the exact commit it was taken from, so a later update check has something concrete to diff against. Skills are grouped into sets by directory; each set is a Claude plugin, and every other agent (Codex included) gets them through the `npx skills add` route. README.md describes the structure and authoring grammar; this file describes the artifacts.

**Update this file every time you add or remove an artifact** — the README intentionally avoids naming specifics so that drift only ever happens here.

---

## Skills (auto-invoked)

Skills load when their `description` matches user intent. There is no `/<name>` slash command unless one is explicitly added.

### Set: `engineer` — producing output (`engineer@viberesearch`)

| Name               | Trigger description                                                                                                                                                                                                                                                                       |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`slidev-deck`](skills/engineer/slidev-deck/SKILL.md) | Author or refactor a Slidev deck (a `slides.md`, especially under jiajun's `slides-hub` repo) following the concise "one-claim-per-slide" house style; covers layout grammar, page-size budgets, the build/verify loop, and the recurring overflow / separator / illustration pitfalls.   |
| [`svg-to-png-render`](skills/engineer/svg-to-png-render/SKILL.md) | Render SVG files to exact-dimension PNG screenshots using a real Chromium browser. Use when converting SVG diagrams or vector artifacts into PNGs for GitHub README display, documentation, visual verification, or non-cropped export.                                           |

### Set: `research` — investigating and writing up (`research@viberesearch`)

| Name               | Trigger description                                                                                                                                                                                                                                                                       |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`readme-generator`](skills/research/readme-generator/SKILL.md) | Use when creating or rewriting README.md for projects. Triggers on "write README", "create README", "update README". Creates human-focused documentation with proper structure. Takes content from [serejaris/personal-corp-skills](https://github.com/serejaris/personal-corp-skills/tree/b517d36f4e047fcc38f3430df6e0bfe86ed44555/skills/readme-generator) at that pinned commit — diff against it to pick up upstream changes. Step 1 calls `mcp__exa__web_search_exa`; without an Exa MCP server configured, that step has nothing to call. |

The set a local skill belongs to is declared in `.claude-plugin/marketplace.json` (the `skills` array of the set's plugin entry) — the directory placement under `skills/<set>/` mirrors it for humans, and `scripts/doctor.sh` enforces that the two stay in sync.

---

## Sub-agents (Claude Code only)

None shipped by default. Add to `agents/<name>.md` when a sub-task warrants its own context, persona, or tool budget — see [`INSTRUCTION.md`](./INSTRUCTION.md) §2.

---

## MCP servers (Claude Code plugin route)

None registered by default. Add to `.mcp.json` when the agent needs a new tool or data source — see [`INSTRUCTION.md`](./INSTRUCTION.md) §5. Spawned MCP servers receive the live shell environment at startup; required env vars must be exported before launching the CLI.

---

## Hooks (Claude Code only)

`hooks/hooks.json` is `{ "hooks": {} }`. Add `PreToolUse` / `PostToolUse` / `Stop` etc. entries when a deterministic lifecycle rule is needed — see [`INSTRUCTION.md`](./INSTRUCTION.md) §3.

---

## Scripts

| Path                | Role                                                                                       |
| ------------------- | ------------------------------------------------------------------------------------------ |
| `scripts/doctor.sh` | Pre-push validator. Confirms manifests parse and expected files exist. Run before pushing. |
| `skills/engineer/svg-to-png-render/scripts/render_svg_png.py` | Skill-bundled helper that renders SVG diagrams to exact-dimension PNGs through Playwright/Chromium. |

---

## Verification

### Inside Claude Code

```
/reload-plugins
/skills           # should list every skill above (prefixed `engineer:` / `research:` when ambiguous)
/mcp              # should be empty until MCP servers are added to .mcp.json
/doctor           # plugin health summary
```

### Inside Codex

After running the bootstrap (or installing manually with `npx skills add zhuconv/viberesearch -g -a codex -y --skill '*'`), start a new Codex session and run:

```
/skills           # same skill list (only skills ship to Codex)
```

### From the shell

```bash
bash scripts/doctor.sh
```

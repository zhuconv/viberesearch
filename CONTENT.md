# CONTENT — what this repo ships

Live inventory of every artifact this repo contributes to Claude Code and Codex — and of every skill `npx skills add zhuconv/viberesearch` installs. Only skills we wrote ourselves ship here (no vendored or aliased upstream content — see the README's "Useful content from elsewhere" for that). Skills are grouped into sets by directory; each set is a Claude plugin, and every other agent (Codex included) gets them through the `npx skills add` route. README.md describes the structure and authoring grammar; this file describes the artifacts.

**Update this file every time you add or remove an artifact** — the README intentionally avoids naming specifics so that drift only ever happens here.

---

## Skills (auto-invoked)

Skills load when their `description` matches user intent. There is no `/<name>` slash command unless one is explicitly added.

### Set: `engineer` — producing output (`engineer@viberesearch`)

| Name               | Trigger description                                                                                                                                                                                                                                                                       |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`slidev-deck`](skills/engineer/slidev-deck/SKILL.md) | Author or refactor a Slidev deck (a `slides.md`, especially under jiajun's `slides-hub` repo) following the concise "one-claim-per-slide" house style; covers layout grammar, page-size budgets, the build/verify loop, and the recurring overflow / separator / illustration pitfalls.   |
| [`svg-to-png-render`](skills/engineer/svg-to-png-render/SKILL.md) | Render SVG files to exact-dimension PNG screenshots using a real Chromium browser. Use when converting SVG diagrams or vector artifacts into PNGs for GitHub README display, documentation, visual verification, or non-cropped export.                                           |

No other sets ship yet — see [`INSTRUCTION.md`](./INSTRUCTION.md) §1 for how to add one (e.g. a future `research` set) when there's an original skill to put in it.

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
/skills           # should list every skill above (prefixed `engineer:` when ambiguous)
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

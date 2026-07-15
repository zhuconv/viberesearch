# CONTENT — what the `core` plugin ships

Live inventory of every artifact `plugins/core/` contributes to Claude Code and Codex. README.md describes the structure and authoring grammar; this file describes the artifacts.

**Update this file every time you add or remove an artifact** — the README intentionally avoids naming specifics so that drift only ever happens here.

---

## Skills (auto-invoked)

Skills load when their `description` matches user intent. There is no `/<name>` slash command unless one is explicitly added.

| Name               | Trigger description                                                                                                                                                                                                                                                                       |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`grill-me`](plugins/core/skills/grill-me/SKILL.md) | Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree. Use when the user wants to stress-test a plan, get grilled on their design, or says "grill me". Adapted from `mattpocock/skills`.                  |
| [`grill-with-docs`](plugins/core/skills/grill-with-docs/SKILL.md) | Same grilling loop, but anchored to the project's existing domain model: sharpens terminology and updates docs (CONTEXT.md, ADRs) inline as decisions crystallise. Ships supporting templates `ADR-FORMAT.md` and `CONTEXT-FORMAT.md` in the skill dir. Adapted from `mattpocock/skills`.   |
| [`slidev-deck`](plugins/core/skills/slidev-deck/SKILL.md) | Author or refactor a Slidev deck (a `slides.md`, especially under jiajun's `slides-hub` repo) following the concise "one-claim-per-slide" house style; covers layout grammar, page-size budgets, the build/verify loop, and the recurring overflow / separator / illustration pitfalls.   |
| [`svg-to-png-render`](plugins/core/skills/svg-to-png-render/SKILL.md) | Render SVG files to exact-dimension PNG screenshots using a real Chromium browser. Use when converting SVG diagrams or vector artifacts into PNGs for GitHub README display, documentation, visual verification, or non-cropped export.                                           |

Both Claude Code and Codex consume `skills/`.

---

## Sub-agents (Claude Code only)

None shipped by default. Add to `plugins/core/agents/<name>.md` when a sub-task warrants its own context, persona, or tool budget — see [`INSTRUCTION.md`](./INSTRUCTION.md) §2.

---

## MCP servers (shared between Claude Code and Codex)

None registered by default. Add to `plugins/core/.mcp.json` when the agent needs a new tool or data source — see [`INSTRUCTION.md`](./INSTRUCTION.md) §5. Spawned MCP servers receive the live shell environment at startup; required env vars must be exported before launching the CLI.

---

## Hooks (Claude Code only)

`hooks/hooks.json` is `{ "hooks": {} }`. Add `PreToolUse` / `PostToolUse` / `Stop` etc. entries when a deterministic lifecycle rule is needed — see [`INSTRUCTION.md`](./INSTRUCTION.md) §3.

---

## Scripts

| Path                | Role                                                                                       |
| ------------------- | ------------------------------------------------------------------------------------------ |
| `scripts/doctor.sh` | Pre-push validator. Confirms manifests parse and expected files exist. Run before pushing. |
| `skills/svg-to-png-render/scripts/render_svg_png.py` | Skill-bundled helper that renders SVG diagrams to exact-dimension PNGs through Playwright/Chromium. |

---

## Verification

### Inside Claude Code

```
/reload-plugins
/skills           # should list every skill in the table above (prefixed `core:` when ambiguous)
/mcp              # should be empty until MCP servers are added to .mcp.json
/doctor           # plugin health summary
```

### Inside Codex

After running the bootstrap (or installing manually with `codex plugin add core@viberesearch`), start a new Codex session and run:

```
/skills           # same skill list (Codex skips agents/ and hooks/)
```

### From the shell

```bash
bash plugins/core/scripts/doctor.sh
```

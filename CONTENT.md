# CONTENT — what this repo ships

Live inventory of every artifact this repo contributes to Claude Code and Codex — and of every skill `npx skills add zhuconv/viberesearch` installs. Skills are grouped into two sets, `report` and `research`; each set is a Claude plugin, and every other agent (Codex included) gets them through the `npx skills add` route. README.md describes the structure and authoring grammar; this file describes the artifacts.

**Update this file every time you add or remove an artifact** — the README intentionally avoids naming specifics so that drift only ever happens here.

---

## Skills (auto-invoked)

Skills load when their `description` matches user intent. There is no `/<name>` slash command unless one is explicitly added.

### Set: `report` — producing output (`report@viberesearch`)

| Name               | Trigger description                                                                                                                                                                                                                                                                       |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`slidev-deck`](skills/report/slidev-deck/SKILL.md) | Author or refactor a Slidev deck (a `slides.md`, especially under jiajun's `slides-hub` repo) following the concise "one-claim-per-slide" house style; covers layout grammar, page-size budgets, the build/verify loop, and the recurring overflow / separator / illustration pitfalls.   |
| [`svg-to-png-render`](skills/report/svg-to-png-render/SKILL.md) | Render SVG files to exact-dimension PNG screenshots using a real Chromium browser. Use when converting SVG diagrams or vector artifacts into PNGs for GitHub README display, documentation, visual verification, or non-cropped export.                                           |

### Set: `research` — stress-testing thinking (`research@viberesearch`)

| Name               | Trigger description                                                                                                                                                                                                                                                                       |
| ------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [`grill-me`](skills/research/grill-me/SKILL.md) | Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree. Use when the user wants to stress-test a plan, get grilled on their design, or says "grill me". Adapted from `mattpocock/skills`.                  |
| [`grill-with-docs`](skills/research/grill-with-docs/SKILL.md) | Same grilling loop, but anchored to the project's existing domain model: sharpens terminology and updates docs (CONTEXT.md, ADRs) inline as decisions crystallise. Ships supporting templates `ADR-FORMAT.md` and `CONTEXT-FORMAT.md` in the skill dir. Adapted from `mattpocock/skills`.   |

### Set: `engineering` — alias of `mattpocock/skills` (`engineering@viberesearch`)

No files in this repo. The marketplace entry's source points at [mattpocock/skills](https://github.com/mattpocock/skills); installing it delivers Matt's promoted set (grilling, spec/ticket flows, TDD, code review, domain modelling — maintained upstream). Claude route only: `claude plugin install engineering@viberesearch`. Other agents: `npx skills add mattpocock/skills/skills/engineering -y`.

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
| `skills/report/svg-to-png-render/scripts/render_svg_png.py` | Skill-bundled helper that renders SVG diagrams to exact-dimension PNGs through Playwright/Chromium. |

---

## Verification

### Inside Claude Code

```
/reload-plugins
/skills           # should list every skill above (prefixed `report:` / `research:` when ambiguous)
/mcp              # should be empty until MCP servers are added to .mcp.json
/doctor           # plugin health summary
```

### Inside Codex

After running the bootstrap (or installing manually with `npx skills add zhuconv/viberesearch -g -a codex`), start a new Codex session and run:

```
/skills           # same skill list (only skills ship to Codex)
```

### From the shell

```bash
bash scripts/doctor.sh
```

# CONTENT — what the `core` plugin ships

Live inventory of every artifact `plugins/core/` contributes to Claude Code and Codex. README.md describes the structure and authoring grammar; this file describes the artifacts.

**Update this file every time you add or remove an artifact** — the README intentionally avoids naming specifics so that drift only ever happens here.

---

## Skills (auto-invoked)

Skills load when their `description` matches user intent. There is no `/<name>` slash command unless one is explicitly added.

| Name           | Trigger description                                                                                                                                                                                                  |
| -------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `slidev-deck`  | Author or refactor a Slidev deck (a `slides.md`, especially under jiajun's `slides-hub` repo) following the concise "one-claim-per-slide" house style; covers layout grammar, page-size budgets, the build/verify loop, and the recurring overflow / separator / illustration pitfalls. |

Both Claude Code and Codex consume `skills/`.

---

## Sub-agents (Claude Code only)

Sub-agents are dispatched by the parent agent when it decides the description matches the sub-task. Codex doesn't read `agents/`.

| Name                  | Description                                                                                            | Model  | Effort | Max turns |
| --------------------- | ------------------------------------------------------------------------------------------------------ | ------ | ------ | --------- |
| `reviewer`            | Reviews code, experiments, and research artifacts for correctness and hidden failure modes.            | sonnet | medium | 20        |
| `experiment-designer` | Designs minimal, controlled, reproducible experiments — hypothesis, baseline, metric, failure modes.   | sonnet | medium | 20        |

---

## MCP servers (shared between Claude Code and Codex)

Spawned by the CLI on session start. The CLI substitutes `${VAR}` placeholders in `.mcp.json` from the live shell environment at spawn time — so any required env var must be exported in the shell that launches the CLI.

| Name           | Purpose                                                                  | Transport          | Env var required               |
| -------------- | ------------------------------------------------------------------------ | ------------------ | ------------------------------ |
| `context7`     | Fetch up-to-date documentation for libraries, frameworks, SDKs, CLI tools | stdio (`npx`)      | none                           |
| `supermemory`  | Persistent cross-session memory via the supermemory.ai remote MCP        | remote (mcp-remote) | none (uses remote auth flow)   |
| `github`       | GitHub repo / issue / PR / search operations                             | stdio (`npx`)      | `GITHUB_PERSONAL_ACCESS_TOKEN` |

If `/mcp` shows `github` as unhealthy, your shell didn't have the token exported when the CLI launched — restart the CLI from a shell that does.

---

## Hooks (Claude Code only)

`hooks/hooks.json` is currently `{ "hooks": {} }` — no hooks ship by default. Add `PreToolUse` / `PostToolUse` / `Stop` etc. entries when a deterministic lifecycle rule is needed; see [`INSTRUCTION.md`](./INSTRUCTION.md) §3.

---

## Scripts

| Path                | Role                                                                                  |
| ------------------- | ------------------------------------------------------------------------------------- |
| `scripts/doctor.sh` | Pre-push validator. Confirms manifests parse and expected files exist. Run before pushing. |

---

## Secrets / environment

The github MCP server reads `GITHUB_PERSONAL_ACCESS_TOKEN` from the shell that launched the CLI. Two recommended flows:

**Plain `.env`** (already gitignored):

```bash
# in ~/.env
export GITHUB_PERSONAL_ACCESS_TOKEN=ghp_xxx
```

```bash
# in ~/.zshrc or ~/.bashrc
[ -f ~/.env ] && source ~/.env
```

**1Password CLI**:

```bash
export GITHUB_PERSONAL_ACCESS_TOKEN="$(op read 'op://Personal/GitHub PAT/token')"
```

`.gitignore` already covers `.env`, `.env.*`, `.DS_Store`, `*.log`, `node_modules/` — but `.env.example` is intentionally allowed for templates.

---

## Verification

### Inside Claude Code

```
/reload-plugins
/skills           # should list every skill in the table above (prefixed `core:` when ambiguous)
/mcp              # should list every MCP server above
/doctor           # plugin health summary
```

### Inside Codex

After picking the marketplace via `/plugins` and installing `core`:

```
/skills           # same skill list (Codex skips agents/ and hooks/)
```

### From the shell

```bash
bash plugins/core/scripts/doctor.sh
```

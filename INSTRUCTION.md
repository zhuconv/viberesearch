# INSTRUCTION — when to add what to viberesearch

This guide tells you, given a thing you want your dev environment to do, **which kind of viberesearch tool to build for it**: a skill, a sub-agent, a hook, a script, an MCP server, an existing set, or a brand-new plugin.

Read the [decision framework](#decision-framework) first. Then jump to the matching section for schema, examples, and how to verify it loaded.

---

## Decision framework

Choose by three criteria:

1. **Impact scope** — does this affect one task, every task, or every machine?
2. **Independent context** — does the work need its own conversation history, persona, or tool budget?
3. **Deterministic execution** — must this happen exactly, every time, without depending on the LLM remembering to do it?

The table below maps intent to the right artifact:

| What you want                                          | Add a…             | When to choose it                                                                                |
| ------------------------------------------------------ | ------------------ | ------------------------------------------------------------------------------------------------ |
| Give the agent a reusable workflow / methodology       | **Skill**          | "When the task looks like X, follow this procedure."                                             |
| Dispatch a specialist for a self-contained sub-task    | **Sub-agent**      | "I want it to have its own context, persona, and tool permissions."                              |
| Enforce a rule at a specific lifecycle point           | **Hook**           | "This must happen automatically — I don't trust the LLM to remember."                            |
| Provide an executable command or check                 | **Script** (`bin/` or `scripts/`) | "This is fundamentally a deterministic CLI / utility."                                           |
| Connect to an external system, API, or data source     | **MCP server**     | "I need to give the agent a new tool — GitHub, memory, browser, DB."                             |
| Bundle a coherent set of capabilities for distribution | **Plugin**         | "I want skills + agents + hooks + MCP + scripts shipped and updated together."                   |
| Carve a capability into its own distributable unit     | **New plugin**     | "Different audience, permission risk, dependencies, release cadence, or use-case boundary."      |

If two rows feel like they apply, prefer the simpler one (Skill < Sub-agent < Hook). Skills compose; agents accumulate context cost; hooks run unconditionally.

---

## Compatibility matrix

Not every artifact type is consumed by every CLI. Author once, but know who picks it up:

| Artifact          | Claude Code | Codex | Notes                                                                       |
| ----------------- | ----------- | ----- | --------------------------------------------------------------------------- |
| Skill             | yes         | yes   | Auto-invoked by description match. Same `SKILL.md` works in both.           |
| Sub-agent         | yes         | no    | Codex doesn't read `agents/`. Skip or recreate behaviour as a skill.        |
| MCP server        | yes         | no    | Only the Claude plugin route ships `.mcp.json`. Register Codex MCPs via `codex mcp`. |
| Hook              | yes         | no    | Codex has no equivalent today. Don't rely on hooks for cross-CLI behaviour. |
| Script (`scripts/`) | yes         | yes   | Just files. Either CLI can call them via Bash.                              |
| Bin (`bin/`)      | n/a         | n/a   | Top-level npm bin, invoked via `npx`. Independent of either CLI.            |

If you need a behaviour that must work in both CLIs, prefer **skills + MCP servers** — those are the portable layer.

---

## 1. Skill — reusable workflow / methodology

**When to choose it.** You catch yourself re-typing the same set of instructions ("when reviewing code, check correctness, then reproducibility, then…"). The model already knows how to do the underlying work; you just want it to follow your procedure when the right kind of task shows up.

**Where it lives.** `skills/<set>/<skill-name>/SKILL.md`, where `<set>` is `report` or `research`. Directory name and frontmatter `name` must match. After creating the skill, **claim it** by appending its path to the matching set entry's `skills` array in `.claude-plugin/marketplace.json` — Claude Code and the skills.sh set grouping both read that array (unclaimed skills are invisible to the Claude plugin and show under "Other" in `npx skills add`). Codex needs no registration; the `npx skills add` route discovers the catalog on its own. `scripts/doctor.sh` fails if disk and claims drift.

**Minimum schema:**

```md
---
name: <skill-name>
description: <one sentence describing exactly when this skill should be invoked>
---

<the procedure — bullet list, numbered steps, or checklist>
```

**Example** — `skills/dataset-card/SKILL.md`:

```md
---
name: dataset-card
description: Produce a dataset card with provenance, schema, license, splits, and known biases for a dataset under analysis.
---

For the dataset in scope:
- list source URL and licence,
- describe schema (columns, dtypes, units),
- report row count and split sizes,
- record collection date and any preprocessing,
- list known biases and exclusions.

Return a single Markdown file ready to drop into the repo.
```

**Verify.** Inside Claude Code: `/reload-plugins` then `/skills` — your skill should be listed. Skills are **auto-invoked** when the description matches user intent; there is no `/dataset-card` command unless you also add one.

**Anti-patterns.** A skill description like "for code tasks" routes to nothing because everything is a code task. Be specific about the trigger.

---

## 2. Sub-agent — independent expert

**When to choose it.** The sub-task needs its own conversation context (separate token budget, no pollution from the parent), its own persona ("be skeptical / be terse"), or restricted tools. Typical: code review, deep research, large-output generation that you don't want bloating the parent.

**Where it lives.** `agents/<agent-name>.md`. Claude Code only — Codex does not consume this directory.

**Minimum schema:**

```md
---
name: <agent-name>
description: <when the parent should delegate to this agent — this is the routing prompt>
model: sonnet
effort: medium
maxTurns: 20
---

<the system prompt for this agent — persona, priorities, output format>
```

**Example** — `agents/literature-scout.md`:

```md
---
name: literature-scout
description: Surveys recent papers on a topic, summarises findings, and reports gaps in the current literature.
model: sonnet
effort: medium
maxTurns: 30
---

You are a research librarian. Be exhaustive on retrieval, ruthless on relevance.
For each cited paper, report: venue, year, claim, method, and limitation.
Return a markdown table plus a short narrative on what is missing.
```

**Verify.** `/reload-plugins`, then trigger via prompt — the parent agent will pick the sub-agent based on its `description`. Bad descriptions cause silent non-routing.

**Anti-patterns.** Don't reach for a sub-agent when a skill would do. Sub-agents cost a full turn budget. Use them when context isolation actually matters.

---

## 3. Hook — deterministic lifecycle rule

**When to choose it.** You need a guarantee, not a request. Examples: "log every shell command before it runs", "block writes to `.env`", "format on save". The LLM forgetting is not an option.

**Where it lives.** `hooks/hooks.json`. Claude Code only.

**Lifecycle events.** `PreToolUse`, `PostToolUse`, `UserPromptSubmit`, `Stop`, `SubagentStop`, `Notification`. The harness — not the model — runs the configured shell command at the matching event.

**Minimum schema:**

```json
{
  "hooks": {
    "<EventName>": [
      {
        "matcher": "<tool-name-or-pattern>",
        "hooks": [
          { "type": "command", "command": "<shell command>" }
        ]
      }
    ]
  }
}
```

**Example — log every Bash invocation:**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          { "type": "command", "command": "echo \"$(date -Iseconds) bash\" >> ~/.viberesearch.log" }
        ]
      }
    ]
  }
}
```

**Verify.** `/reload-plugins`, run any Bash tool call, check `~/.viberesearch.log`. If nothing appears, the matcher is wrong or the JSON didn't parse.

**Anti-patterns.**
- Don't put destructive commands in hooks (`rm -rf`, `git push --force`). Hooks fire without confirmation.
- Don't use hooks for behaviour the model can already follow via a skill or CLAUDE.md instruction. Hooks are for things that **must** happen even when the model is mistaken.

---

## 4. Script — deterministic CLI / utility

There are two homes, depending on who runs it:

### 4a. Plugin-internal script — `scripts/<name>.sh`

Run by the plugin author or the agent during a session. Examples: `doctor.sh` (already present), data prep, repo bootstraps, validators.

**Convention.**
- Bash, `set -euo pipefail` at the top.
- Resolve repo root via `BASH_SOURCE`, don't assume CWD.
- `chmod +x` after creation.

**Example skeleton:**

```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT"
# ... your checks / actions ...
echo "ok"
```

**Verify.** Run it directly: `bash scripts/<name>.sh`.

### 4b. Top-level npm bin — `bin/<name>.mjs`

Run by `npx` from anywhere. The current bootstrap (`bin/viberesearch.mjs`) is the canonical example: it detects which CLIs are installed and configures them. Add another bin only if you have a second `npx`-launchable command (rare).

To register a new bin, add it to `package.json`:

```json
{
  "bin": {
    "viberesearch": "./bin/viberesearch.mjs",
    "viberesearch-uninstall": "./bin/uninstall.mjs"
  }
}
```

`chmod +x` and a `#!/usr/bin/env node` shebang are required.

---

## 5. MCP server — external tool / data source

**When to choose it.** You want to give the agent a *new tool* it can call — something outside Bash + file editing. GitHub API, vector memory, browser, database, internal services.

**Where it lives.** `.mcp.json`, under `mcpServers`. Only the Claude plugin route ships this.

**Two common shapes.**

**Stdio command (most servers):**

```json
{
  "mcpServers": {
    "<name>": {
      "command": "npx",
      "args": ["-y", "<package>"]
    }
  }
}
```

**With secrets:** reference env vars as `${VAR_NAME}` — never literals.

```json
{
  "mcpServers": {
    "<name>": {
      "command": "npx",
      "args": ["-y", "<package>"],
      "env": {
        "<NAME>_API_KEY": "${<NAME>_API_KEY}"
      }
    }
  }
}
```

**Remote (HTTP) server:** use the `mcp-remote` shim:

```json
{
  "mcpServers": {
    "<name>": {
      "command": "npx",
      "args": ["-y", "mcp-remote@latest", "https://<host>/mcp"]
    }
  }
}
```

**Verify.** Claude: `/reload-plugins`, then `/mcp` — the server should appear, and `…` next to it should show available tools. If a server is unhealthy, run its `command` directly in a shell and read the real error.

**Anti-patterns.**
- Never commit a literal token. Always `${VAR_NAME}` and document the var in the README.
- Don't add an MCP server "in case it's useful" — they cost startup time and clutter the tool list. Add one when you actually need it.

---

## 6. Plugin — the existing bundle

The repo root (with its set entries in `marketplace.json`) is itself the answer to "I want skills + agents + hooks + MCP + scripts shipped together." If your new artifact fits the same audience, permission boundary, and release cadence as what's already there, **add it to an existing set directly** using the sections above. You don't create a new plugin for every new skill.

You're touching the right files when:
- you want the installed set plugins (`report@viberesearch`, `research@viberesearch`) and the `npx skills add` route to keep delivering more capability over time,
- the artifact serves the same workflow as the rest (research / coding loops),
- it doesn't introduce dependencies or risks the rest of the repo doesn't already accept.

---

## 7. New plugin — separate distributable unit

**When to choose it.** Use a new plugin when at least one of the following is true:

- **Different audience.** A teaching plugin for students vs. your personal research plugin.
- **Different permission profile.** A plugin that ships a hook running `git push` should be opt-in, not bundled with `core`.
- **Different dependencies.** A plugin that requires `cuda` or `op` shouldn't force those on every install of `core`.
- **Different release cadence.** Something experimental you want to iterate on without bumping `core`.
- **Different scope of side effects.** A plugin that writes to your filesystem outside the project belongs in its own unit.

**How to add one:**

1. First consider whether a new **set** is enough (a `strict: false` entry in `.claude-plugin/marketplace.json` claiming skills — no new directory tree). A separate plugin directory is only needed for non-skill artifacts with a different risk profile. If so, create it under `plugins/`:
   ```bash
   mkdir -p plugins/<new-plugin>/.claude-plugin plugins/<new-plugin>/skills
   ```
2. Write the manifest inside the new directory:
   - `plugins/<new-plugin>/.claude-plugin/plugin.json` — change `name` and `description`.
3. Register it in `.claude-plugin/marketplace.json` at the repo root: append a new object to `plugins[]` with `"source": "./plugins/<new-plugin>"`.
4. Extend `scripts/doctor.sh` so it also checks the new plugin's manifests and skills.
5. Install it from inside the CLIs:
   ```bash
   claude plugin install <new-plugin>@viberesearch --scope user
   ```

**Anti-patterns.**
- Don't fork a plugin just to add one skill — that's a `skills/<set>/<name>/` change plus a claim in the set's `marketplace.json` entry. A new *set* is also cheap: a new `skills/<set>/` directory plus a new `strict: false` entry in `.claude-plugin/marketplace.json` claiming its skills.

---

## After adding anything

In this order:

1. **Validate structure:** `bash scripts/doctor.sh` — JSON parses, required files exist.
2. **Reload Claude Code:** `/reload-plugins`. (Codex: re-run `npx skills add zhuconv/viberesearch` and start a new session.)
3. **Smoke-test the artifact:** see the per-section "Verify" block above.
4. **Commit and push.** Plugins are versioned by git ref, so users on `npx --yes github:zhuconv/viberesearch` pick up `HEAD` of `master` on their next bootstrap; users who installed via `claude plugin install` need `claude plugin marketplace update viberesearch` to refresh; users who installed skills via `npx skills add zhuconv/viberesearch` re-run that same command to refresh.

If `doctor.sh` doesn't catch a class of mistake you just ran into, extend it — that's the right place for repo-wide invariants.

---

## Where things go (cheat sheet)

```text
viberesearch/
├── bin/<name>.mjs                       # 4b. top-level npx bin
├── .claude-plugin/
│   └── marketplace.json                 # 6+7. Claude marketplace; set entries claim skills inline
├── .mcp.json                            # 5. MCP servers (Claude plugin route)
├── hooks/hooks.json                     # 3. hooks (Claude only)
├── agents/<name>.md                     # 2. sub-agents (Claude only)
├── skills/<set>/<name>/SKILL.md         # 1. skills (sets: report, research) — also what `npx skills add` installs
├── scripts/<name>.sh                    # 4a. repo scripts
└── plugins/<new-plugin>/                # 7. additional plugins live here
```

If a category of artifact you want to add isn't listed here (slash commands, statusline scripts, output styles, etc.), it follows the same pattern: a directory at the repo root, referenced from the set entries in `.claude-plugin/marketplace.json`. Check the Claude Code plugin docs for exact key names.

# viberesearch

A personal, opinionated environment for vibe-coding and vibe-research with Claude Code and Codex. One repo, two CLIs, one shared bundle of skills, sub-agents, hooks, and MCP servers — installed in a single `npx` command.

This repo is three things at once:

1. A **Claude Code plugin marketplace** (`.claude-plugin/marketplace.json`).
2. A **Codex plugin marketplace** (`.agents/plugins/marketplace.json`).
3. An **`npx` bootstrap installer** (`bin/viberesearch.mjs`) that wires both CLIs to this repo on a fresh machine.

Both marketplaces point to the same plugin directory: `plugins/jiajun-core/`. So every skill you add, every agent you write, every MCP server you register lives in one place and shows up in both CLIs.

---

## Quick install

On any machine with `git`, `node`, and `npm`:

```bash
npx --yes github:zhuconv/viberesearch
```

What this does, in order:

1. Confirms `git`, `node`, and `npm` exist.
2. If `claude` (Claude Code CLI) is on your `PATH`: adds the marketplace, updates it, installs `jiajun-core` at user scope, and lists installed plugins.
3. If `codex` is on your `PATH`: adds and upgrades the marketplace, then prints instructions to finish the install via `/plugins` inside Codex.
4. If `gh` is installed, runs `gh auth status` so you know whether the GitHub MCP server will work.
5. If `op` (1Password CLI) is installed, runs `op whoami` for the same reason.

If a CLI isn't installed, that section is skipped silently — re-run the same command after you install it.

---

## Manual install

If you'd rather not run the bootstrap, register the marketplace directly inside each CLI.

### Claude Code

```bash
claude plugin marketplace add zhuconv/viberesearch
claude plugin marketplace update viberesearch
claude plugin install jiajun-core@viberesearch --scope user
claude plugin list
```

Then verify inside a Claude Code session:

```
/reload-plugins
/skills
/mcp
/doctor
```

`/skills` should list `code-review`, `paper-polish`, `experiment-loop`, and `repo-bootstrap`. `/mcp` should show `context7`, `supermemory`, and `github` (the last may be unhealthy until you set `GITHUB_PERSONAL_ACCESS_TOKEN`). `/doctor` summarizes plugin health.

### Codex

```bash
codex plugin marketplace add zhuconv/viberesearch
codex plugin marketplace upgrade viberesearch
```

Then inside Codex:

```
/plugins
```

Pick the `Viberesearch` marketplace, install `jiajun-core`, and confirm with:

```
/skills
```

Codex consumes `skills/` and `.mcp.json` from the same plugin directory but ignores the `agents/` and `hooks/` directories — those are Claude Code only.

---

## Repository layout

```
viberesearch/
├── package.json                      # Declares the `viberesearch` npx bin
├── bin/
│   └── viberesearch.mjs              # Bootstrap: wires Claude + Codex on a fresh machine
├── .claude-plugin/
│   └── marketplace.json              # Marketplace manifest consumed by Claude Code
├── .agents/
│   └── plugins/
│       └── marketplace.json          # Marketplace manifest consumed by Codex
├── .gitignore                        # Ignores node_modules, .env, .DS_Store, *.log
└── plugins/
    └── jiajun-core/                  # The single plugin both marketplaces expose
        ├── .claude-plugin/
        │   └── plugin.json           # Plugin manifest (Claude Code variant)
        ├── .codex-plugin/
        │   └── plugin.json           # Plugin manifest (Codex variant)
        ├── .mcp.json                 # MCP server registrations (shared)
        ├── skills/                   # Auto-invoked skills (shared)
        │   ├── code-review/SKILL.md
        │   ├── paper-polish/SKILL.md
        │   ├── experiment-loop/SKILL.md
        │   └── repo-bootstrap/SKILL.md
        ├── agents/                   # Sub-agents (Claude Code only)
        │   ├── reviewer.md
        │   └── experiment-designer.md
        ├── hooks/
        │   └── hooks.json            # Lifecycle hooks (Claude Code only); empty by default
        └── scripts/
            └── doctor.sh             # Pre-push validator
```

The top-level files are **marketplace-level** — they describe a catalog of plugins. Everything inside `plugins/jiajun-core/` is **plugin-level** — it describes one installable unit.

### Mental model: three layers

When something looks broken, ask which of these three layers it lives in.

1. **Marketplace manifest** — `.claude-plugin/marketplace.json` and `.agents/plugins/marketplace.json`. These are catalogs. Each lists the plugins this repo exposes and where to find them. The two files exist because Claude Code and Codex use slightly different schemas. Adding a new plugin means editing both.

2. **Plugin manifest** — `plugins/jiajun-core/.claude-plugin/plugin.json` and `plugins/jiajun-core/.codex-plugin/plugin.json`. These declare a single plugin's metadata and tell the CLI where to find its artifacts (skills, agents, hooks, MCP servers). They live inside the plugin directory, not at the repo root. Both files point at the same `./skills/`, the same `./.mcp.json`, etc. — that's how Claude Code and Codex share a single artifact tree.

3. **Artifacts** — the actual content the model uses at runtime: `skills/<name>/SKILL.md`, `agents/<name>.md`, `hooks/hooks.json`, and the entries in `.mcp.json`. This is what you'll touch most often.

So when you "add a skill," you're editing layer 3. When you "add a plugin," you're editing all three layers. When you "publish to a new marketplace," you'd edit layer 1.

Quick glossary, since these terms collide:

- **Skill** — a Markdown file the CLI auto-loads when its `description` matches user intent. Triggered conversationally, not by a slash command.
- **Sub-agent** — a separate Claude conversation the main one can delegate work to. Has its own model, effort, and turn budget.
- **MCP** (Model Context Protocol) — a standard for plugging external tools and data sources into the CLI. An MCP server is a process the CLI spawns and talks to over stdio.
- **Hook** — a shell command the CLI runs at a defined lifecycle event (before a tool call, after a prompt, on stop, etc.).
- **Marketplace** — a catalog of plugins. A repo can be its own marketplace.

---

## Extending the plugin

Everything below modifies files under `plugins/jiajun-core/`. After any change: run `bash plugins/jiajun-core/scripts/doctor.sh`, then `/reload-plugins` inside Claude Code (or restart Codex) to pick up the new artifact.

### Add a new skill

**Where:** `plugins/jiajun-core/skills/<skill-name>/SKILL.md`. The directory name and the frontmatter `name` should match.

**Minimum frontmatter:**

```md
---
name: <skill-name>
description: <one sentence describing exactly when this skill should be invoked>
---

<the actual instructions the model will follow when this skill is loaded>
```

**Example** — `plugins/jiajun-core/skills/dataset-card/SKILL.md`:

```md
---
name: dataset-card
description: Generate or update a dataset card with provenance, license, splits, and known limitations for an ML dataset.
---

When asked about a dataset, produce a card with these sections:
- source URL and version,
- license and redistribution terms,
- splits and sample counts,
- preprocessing applied,
- known biases and failure modes.

Cite the file or URL each fact came from.
```

**Verify:** open Claude Code, run `/reload-plugins`, then `/skills`. The new skill should appear. To test it, prompt something the description matches ("write a dataset card for ..."). Skills are auto-invoked when the description matches user intent — there is no slash command. That makes the description the routing key: vague descriptions silently fail to load.

### Add a new sub-agent

**Where:** `plugins/jiajun-core/agents/<agent-name>.md`. Claude Code only — Codex does not consume this directory.

**Minimum frontmatter:**

```md
---
name: <agent-name>
description: <one sentence the parent agent uses to decide when to delegate>
model: sonnet
effort: medium
maxTurns: 20
---

<system prompt for this sub-agent>
```

**Example** — `plugins/jiajun-core/agents/literature-scout.md`:

```md
---
name: literature-scout
description: Surveys recent papers on a given research topic and returns a ranked, deduplicated reading list with one-sentence summaries.
model: sonnet
effort: medium
maxTurns: 15
---

You are a literature scout. Search recent venues (NeurIPS, ICML, ICLR, ACL, EMNLP, arXiv) for the topic the user names.
Return at most 12 entries, deduplicated, ranked by relevance, each with: title, venue/year, one-sentence summary, link.
Skip surveys older than three years unless explicitly requested.
```

**Verify:** `/reload-plugins`, then ask the main conversation to delegate ("use the literature-scout sub-agent to..."). Sub-agents are spawned from the parent conversation; the parent reads the `description` to decide when to delegate. Tighter descriptions delegate more reliably. `effort` and `maxTurns` cap cost — match them to how much exploration the agent actually needs.

### Add an MCP server

**Where:** `plugins/jiajun-core/.mcp.json`. Add an entry under `mcpServers`. This file is shared — both Claude Code and Codex pick it up.

**Minimum schema:**

```json
{
  "mcpServers": {
    "<server-name>": {
      "command": "<executable>",
      "args": ["<arg1>", "<arg2>"],
      "env": {
        "SOME_TOKEN": "${SOME_TOKEN}"
      }
    }
  }
}
```

**Example — `npx` form (no secrets):**

```json
"filesystem": {
  "command": "npx",
  "args": ["-y", "@modelcontextprotocol/server-filesystem", "/Users/me/notes"]
}
```

**Example — `env` form (with secrets):**

```json
"linear": {
  "command": "npx",
  "args": ["-y", "@linear/mcp-server"],
  "env": {
    "LINEAR_API_KEY": "${LINEAR_API_KEY}"
  }
}
```

**Critical:** secrets must be referenced as `${VAR_NAME}` placeholders. The CLI resolves them from your shell environment at spawn time. Never paste a literal token into `.mcp.json` — this file is committed.

The current `.mcp.json` already wires three servers as a reference: `context7` (no secrets), `supermemory` (uses `mcp-remote` to proxy a hosted endpoint), and `github` (env-var secret).

**Verify:** `/reload-plugins` then `/mcp` inside Claude Code. The new server appears with a status. If it's unhealthy, copy the `command` and `args` and run them in a terminal — you'll see the real startup error.

### Add a hook

**Where:** `plugins/jiajun-core/hooks/hooks.json`. Claude Code only. Default content is `{ "hooks": {} }` — wide open and intentional.

**Hook events** (the most common ones):

- `PreToolUse` — fires before a tool call. The matcher selects which tools.
- `PostToolUse` — fires after a tool call returns.
- `UserPromptSubmit` — fires when the user submits a prompt.
- `Stop` — fires when the agent stops responding.

**Safe example** — log every shell command before it runs:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "printf '[%s] %s\\n' \"$(date -u +%FT%TZ)\" \"$CLAUDE_TOOL_INPUT\" >> ~/.claude/bash-history.log"
          }
        ]
      }
    ]
  }
}
```

**Warning:** hooks are shell commands the harness executes. A `PreToolUse` matcher of `.*` paired with `rm` will happily delete things before you can blink. Start with `PostToolUse` logging hooks until you trust the matcher; never put irreversible commands in a hook unless you have read it three times.

**Verify:** `/reload-plugins`, run a tool the matcher targets, and check the side effect (log file, notification, etc.). If nothing fires, the matcher likely doesn't match — `Bash` matches the Bash tool exactly; regex matchers are stricter than they look.

### Add a new plugin to the marketplace

This is the "marketplace is not the plugin" lesson. To ship a second plugin alongside `jiajun-core`:

1. **Duplicate the plugin directory:** `cp -r plugins/jiajun-core plugins/<new-plugin>`.

2. **Update both plugin manifests inside it:**
   - `plugins/<new-plugin>/.claude-plugin/plugin.json` — change `name` and `description`.
   - `plugins/<new-plugin>/.codex-plugin/plugin.json` — change `name` and `description`.

3. **Register it in both marketplace manifests.** Add a new object to the `plugins` array in each.

   `.claude-plugin/marketplace.json`:

   ```json
   {
     "name": "<new-plugin>",
     "source": "./plugins/<new-plugin>",
     "description": "<short description>",
     "category": "productivity"
   }
   ```

   `.agents/plugins/marketplace.json`:

   ```json
   {
     "name": "<new-plugin>",
     "source": {
       "source": "local",
       "path": "./plugins/<new-plugin>"
     },
     "policy": {
       "installation": "AVAILABLE",
       "authentication": "ON_INSTALL"
     },
     "category": "Productivity"
   }
   ```

4. **Validate and reinstall:**

   ```bash
   bash plugins/jiajun-core/scripts/doctor.sh
   claude plugin marketplace update viberesearch
   claude plugin install <new-plugin>@viberesearch --scope user
   ```

If you forget the marketplace edits, `claude plugin install` reports the plugin as not found — the manifest is the source of truth, not the directory's existence.

---

## Authoring tips

- **Be specific in skill descriptions.** "Reviews code" loses to "Reviews the recent git diff for correctness, hidden assumptions, and reproducibility issues." The model routes on these strings.
- **Read current code, don't bake constants.** A skill that says "the loss is MSE" goes stale; one that says "open `train.py` and report the loss function" stays correct.
- **Never commit secrets.** Tokens go in `.env` (gitignored) or 1Password; `.mcp.json` only ever holds `${VAR}` placeholders.
- **Run `bash plugins/jiajun-core/scripts/doctor.sh` before pushing.** It catches most of the structural mistakes that would only surface inside the CLI.
- **One skill, one job.** If a skill description starts to grow conjunctions ("and also..."), split it. The router picks one skill at a time.

---

## Secrets and environment

The github MCP server needs `GITHUB_PERSONAL_ACCESS_TOKEN`. Two recommended ways:

**Option 1 — `.env` (already gitignored):** create `~/.env` or a per-shell file:

```bash
export GITHUB_PERSONAL_ACCESS_TOKEN=ghp_xxx
```

Source it in your shell rc (`~/.zshrc`, `~/.bashrc`):

```bash
[ -f ~/.env ] && source ~/.env
```

**Option 2 — 1Password CLI:** store the token in a 1Password item, then export it on shell start:

```bash
export GITHUB_PERSONAL_ACCESS_TOKEN="$(op read 'op://Personal/GitHub PAT/token')"
```

Either way, the CLI substitutes `${GITHUB_PERSONAL_ACCESS_TOKEN}` in `.mcp.json` from your live environment when it spawns the server. If `/mcp` shows the github entry as unhealthy, your shell didn't have the variable set when you launched Claude Code — restart the CLI from a shell that does.

The `.gitignore` already excludes `.env`, `.env.*`, `.DS_Store`, `*.log`, and `node_modules/` — but `.env.example` is intentionally allowed through if you want to publish a template.

---

## Validation

Before pushing or filing a bug:

```bash
bash plugins/jiajun-core/scripts/doctor.sh
```

It checks that:

- `package.json` exists and parses as JSON.
- Both marketplace manifests exist and parse.
- Both plugin manifests inside `jiajun-core` exist and parse.
- `.mcp.json` and `hooks/hooks.json` exist and parse.
- Every `skills/*/SKILL.md` exists.

It does not validate frontmatter inside `SKILL.md` or `agents/*.md` — those errors only show up when the CLI tries to load them. So after a structural pass, also re-run:

```bash
npx --yes github:zhuconv/viberesearch
```

from a shell that has `claude` and/or `codex` on its `PATH`. The bootstrap re-registers and updates the marketplace, which forces both CLIs to re-read your edits.

---

## Troubleshooting

**Skill not appearing in `/skills`.** Check the YAML frontmatter — it must start with `---` on the first line, end with `---`, and contain at least `name:` and `description:`. The directory name and `name:` should match. After fixing, run `/reload-plugins` (don't restart — reload is faster and tests the same path).

**MCP server fails to start (red status in `/mcp`).** Copy the `command` and `args` from `.mcp.json` and run them in a normal terminal. The real error (missing package, bad token, network) will print there. Most often: the CLI was launched from a shell that didn't have the required env var.

**`marketplace not found` when running `claude plugin install`.** You haven't run `claude plugin marketplace add zhuconv/viberesearch` yet, or the marketplace was added under a different name. List with `claude plugin marketplace list` and re-add if missing.

**Hook not firing.** The `matcher` is the most common culprit. `Bash` matches the Bash tool literally; partial strings and unanchored patterns may not. Reduce to a hook with `"matcher": "Bash"` and an obvious side effect (e.g., `command: 'echo fired >> /tmp/hook.log'`) to confirm the event itself is reaching you, then narrow the matcher.

**Sub-agent not delegated to.** The parent decides based on the `description`. If it never picks your agent, the description is too generic or overlaps with another agent. Tighten it, then `/reload-plugins`.

**Codex shows the marketplace but not the plugin.** Codex installs are interactive: `codex plugin marketplace add` only registers the catalog; you still need `/plugins` inside the Codex session to install `jiajun-core` from it. The bootstrap prints this reminder for the same reason.

---

## License

MIT.

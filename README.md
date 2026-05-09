# viberesearch

A personal, opinionated environment for vibe-coding and vibe-research with Claude Code and Codex. One repo, two CLIs, one shared bundle of skills, sub-agents, hooks, and MCP servers — installed in a single `npx` command.

This repo is three things at once:

1. A **Claude Code plugin marketplace** (`.claude-plugin/marketplace.json`).
2. A **Codex plugin marketplace** (`.agents/plugins/marketplace.json`).
3. An **`npx` bootstrap installer** (`bin/viberesearch.mjs`) that wires both CLIs to this repo on a fresh machine.

Both marketplaces point to the same plugin directory: `plugins/core/`. So every skill you add, every agent you write, every MCP server you register lives in one place and shows up in both CLIs.

> **What's actually shipped today** lives in [`CONTENT.md`](./CONTENT.md) — the live inventory of skills, sub-agents, MCP servers, and hooks the `core` plugin contributes.
> **How to add new artifacts** (decision framework, schemas, examples) lives in [`INSTRUCTION.md`](./INSTRUCTION.md).

---

## Quick install

On any machine with `git`, `node`, and `npm`:

```bash
npx --yes github:zhuconv/viberesearch
```

What this does, in order:

1. Confirms `git`, `node`, and `npm` exist.
2. If `claude` (Claude Code CLI) is on your `PATH`: adds the marketplace, updates it, installs `core` at user scope, and lists installed plugins.
3. If `codex` is on your `PATH`: adds and upgrades the marketplace, then prints instructions to finish the install via `/plugins` inside Codex.
4. If `gh` is installed, runs `gh auth status` so you know GitHub-token-using MCP servers will resolve when you add them.
5. If `op` (1Password CLI) is installed, runs `op whoami` for the same reason.

If a CLI isn't installed, that section is skipped silently — re-run the same command after you install it.

---

## Manual install

If you'd rather not run the bootstrap, register the marketplace directly inside each CLI.

### Claude Code

```bash
claude plugin marketplace add zhuconv/viberesearch
claude plugin marketplace update viberesearch
claude plugin install core@viberesearch --scope user
claude plugin list
```

Then verify inside a Claude Code session:

```
/reload-plugins
/skills
/mcp
/doctor
```

The expected `/skills` and `/mcp` output matches what's listed in [`CONTENT.md`](./CONTENT.md). `/doctor` summarizes plugin health.

### Codex

```bash
codex plugin marketplace add zhuconv/viberesearch
codex plugin marketplace upgrade viberesearch
```

Then inside Codex:

```
/plugins
```

Pick the `Viberesearch` marketplace, install `core`, and confirm with:

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
├── README.md                         # This file — structure + authoring grammar
├── CONTENT.md                        # Live inventory of what the `core` plugin ships
├── INSTRUCTION.md                    # Authoring guide: when to add what
├── .gitignore                        # Ignores node_modules, .env, .DS_Store, *.log
└── plugins/
    └── core/                         # The single plugin both marketplaces expose
        ├── .claude-plugin/
        │   └── plugin.json           # Plugin manifest (Claude Code variant)
        ├── .codex-plugin/
        │   └── plugin.json           # Plugin manifest (Codex variant)
        ├── .mcp.json                 # MCP server registrations (shared)
        ├── skills/                   # Auto-invoked skills (shared) — see CONTENT.md
        ├── agents/                   # Sub-agents (Claude Code only) — see CONTENT.md
        ├── hooks/
        │   └── hooks.json            # Lifecycle hooks (Claude Code only); empty by default
        └── scripts/
            └── doctor.sh             # Pre-push validator
```

The top-level files are **marketplace-level** — they describe a catalog of plugins. Everything inside `plugins/core/` is **plugin-level** — it describes one installable unit.

### Mental model: three layers

When something looks broken, ask which of these three layers it lives in.

1. **Marketplace manifest** — `.claude-plugin/marketplace.json` and `.agents/plugins/marketplace.json`. These are catalogs. Each lists the plugins this repo exposes and where to find them. The two files exist because Claude Code and Codex use slightly different schemas. Adding a new plugin means editing both.

2. **Plugin manifest** — `plugins/core/.claude-plugin/plugin.json` and `plugins/core/.codex-plugin/plugin.json`. These declare a single plugin's metadata. Skills, agents, hooks, and MCP servers are auto-discovered by convention from the sibling directories — the manifest itself only carries metadata, not paths.

3. **Artifacts** — the actual content the model uses at runtime: `skills/<name>/SKILL.md`, `agents/<name>.md`, `hooks/hooks.json`, and the entries in `.mcp.json`. This is what you'll touch most often. Their current contents are catalogued in [`CONTENT.md`](./CONTENT.md).

So when you "add a skill," you're editing layer 3 (and its CONTENT.md row). When you "add a plugin," you're editing all three layers. When you "publish to a new marketplace," you'd edit layer 1.

Quick glossary, since these terms collide:

- **Skill** — a Markdown file the CLI auto-loads when its `description` matches user intent. Triggered conversationally, not by a slash command.
- **Sub-agent** — a separate Claude conversation the main one can delegate work to. Has its own model, effort, and turn budget.
- **MCP** (Model Context Protocol) — a standard for plugging external tools and data sources into the CLI. An MCP server is a process the CLI spawns and talks to over stdio (or a remote endpoint).
- **Hook** — a shell command the CLI runs at a defined lifecycle event (before a tool call, after a prompt, on stop, etc.).
- **Marketplace** — a catalog of plugins. A repo can be its own marketplace.

---

## Extending the plugin

For the full authoring guide — when to add a skill vs. a sub-agent vs. a hook vs. an MCP server vs. a new plugin, with schemas, examples, and verification steps for each — see [`INSTRUCTION.md`](./INSTRUCTION.md).

The short version, by intent:

| You want to…                                       | Add a…       | Lives at                                                            |
| -------------------------------------------------- | ------------ | ------------------------------------------------------------------- |
| Give the agent a reusable workflow                 | Skill        | `plugins/core/skills/<name>/SKILL.md`                               |
| Dispatch a specialist with its own context         | Sub-agent    | `plugins/core/agents/<name>.md`                                     |
| Enforce a deterministic lifecycle rule             | Hook         | `plugins/core/hooks/hooks.json`                                     |
| Provide a deterministic CLI / utility              | Script       | `plugins/core/scripts/<name>.sh` or `bin/<name>.mjs`                |
| Connect to an external system / API                | MCP server   | `plugins/core/.mcp.json`                                            |
| Carve a different audience or risk profile         | New plugin   | `plugins/<new-plugin>/` + register in both `marketplace.json` files |

After any change: update [`CONTENT.md`](./CONTENT.md) to reflect the new artifact, run `bash plugins/core/scripts/doctor.sh`, then `/reload-plugins` inside Claude Code (or restart Codex).

---

## Authoring tips

- **Be specific in skill descriptions.** "Reviews code" loses to "Reviews the recent git diff for correctness, hidden assumptions, and reproducibility issues." The model routes on these strings.
- **Read current code, don't bake constants.** A skill that says "the loss is MSE" goes stale; one that says "open `train.py` and report the loss function" stays correct.
- **Never commit secrets.** Tokens go in `.env` (gitignored) or 1Password; `.mcp.json` only ever holds `${VAR}` placeholders. CONTENT.md lists which env vars each MCP server needs.
- **Run `bash plugins/core/scripts/doctor.sh` before pushing.** It catches most of the structural mistakes that would only surface inside the CLI.
- **One skill, one job.** If a skill description starts to grow conjunctions ("and also..."), split it. The router picks one skill at a time.

---

## Validation

Before pushing or filing a bug:

```bash
bash plugins/core/scripts/doctor.sh
```

It checks that:

- `package.json` exists and parses as JSON.
- Both marketplace manifests exist and parse.
- Both plugin manifests inside `core` exist and parse.
- `.mcp.json` and `hooks/hooks.json` exist and parse.
- Every `skills/*/SKILL.md` exists.

It does not validate frontmatter inside `SKILL.md` or `agents/*.md` — those errors only show up when the CLI tries to load them. So after a structural pass, also re-run:

```bash
npx --yes github:zhuconv/viberesearch
```

from a shell that has `claude` and/or `codex` on its `PATH`. The bootstrap re-registers and updates the marketplace, which forces both CLIs to re-read your edits.

---

## Troubleshooting

**Skill not appearing in `/skills`.** Check the YAML frontmatter — it must start with `---` on the first line, end with `---`, and contain at least `name:` and `description:`. The directory name and `name:` should match. After fixing, run `/reload-plugins`.

**MCP server fails to start (red status in `/mcp`).** Copy the `command` and `args` from `.mcp.json` and run them in a normal terminal. The real error (missing package, bad token, network) will print there. Most often: the CLI was launched from a shell that didn't have the required env var. CONTENT.md lists which servers need which vars.

**`marketplace not found` when running `claude plugin install`.** You haven't run `claude plugin marketplace add zhuconv/viberesearch` yet, or the marketplace was added under a different name. List with `claude plugin marketplace list` and re-add if missing.

**Hook not firing.** The `matcher` is the most common culprit. `Bash` matches the Bash tool literally; partial strings and unanchored patterns may not. Reduce to a hook with `"matcher": "Bash"` and an obvious side effect (e.g., `command: 'echo fired >> /tmp/hook.log'`) to confirm the event itself is reaching you, then narrow the matcher.

**Sub-agent not delegated to.** The parent decides based on the `description`. If it never picks your agent, the description is too generic or overlaps with another agent. Tighten it, then `/reload-plugins`.

**Codex shows the marketplace but not the plugin.** Codex installs are interactive: `codex plugin marketplace add` only registers the catalog; you still need `/plugins` inside the Codex session to install `core` from it. The bootstrap prints this reminder for the same reason.

**Plugin install fails with `agents: Invalid input` (or similar manifest validation error).** `plugin.json` should declare metadata only — drop any `skills`/`agents`/`hooks`/`mcpServers` path fields, since Claude Code auto-discovers those directories by convention.

---

## License

MIT.

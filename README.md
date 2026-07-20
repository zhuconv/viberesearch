# viberesearch

A personal, opinionated environment for vibe-coding and vibe-research with Claude Code and Codex. One repo, one shared bundle of skills, sub-agents, hooks, and MCP servers — installable into 60+ coding agents with a single command.

This repo is three things at once:

1. A **skills repo** in the [skills.sh](https://www.skills.sh) catalog layout (`skills/<set>/<name>/SKILL.md`) — `npx skills add zhuconv/viberesearch` installs the skills into Claude Code, Codex, Cursor, and any other agent the [`skills` CLI](https://github.com/vercel-labs/skills) supports. **This is the primary install route.**
2. A **Claude Code plugin marketplace** (`.claude-plugin/marketplace.json`).
3. An **`npx` bootstrap installer** (`bin/viberesearch.mjs`) that wires a fresh machine: Claude Code via the plugin marketplace, Codex via the `skills` CLI.

**This repo ships only skills we wrote ourselves** — no vendored or aliased upstream content. Skills are organized into sets by directory (`skills/<set>/<name>/`), one directory per set; today that's just **`engineer`** (Slidev decks, SVG→PNG rendering). More sets (e.g. `research`) land here the same way, as we build original skills for them.

In the `npx skills add` interactive picker, sets appear as toggleable groups. The grouping comes from `.claude-plugin/marketplace.json`, where each set is a plugin entry claiming its skills via an explicit `skills` path array — not from the directory names; a skill nobody claims would show under "Other". Claude Code installs the same entry as a plugin (`engineer@viberesearch`). Codex has no native plugin here — it gets skills through the `npx skills add` route like every other non-Claude agent. (A native Codex plugin was shipped briefly and removed: its manifest takes a single recursive skills path, so it can't express per-set installs, and the subscription route added little over the skills CLI.)

Every skill lives in exactly one place (`skills/<set>/<name>/`) and ships through every route. The plugin route only adds value over the skills.sh route for artifact types the skills standard doesn't cover — sub-agents, hooks, MCP servers — which are empty today; use it when this repo starts shipping those.

> **Looking for Matt Pocock's skills too?** See [Useful content from elsewhere](#useful-content-from-elsewhere) below — install his directly, rather than through an alias here, so you always get exactly what he ships.

> **What's actually shipped today** lives in [`CONTENT.md`](./CONTENT.md) — the live inventory of skills, sub-agents, MCP servers, and hooks this repo contributes.
> **How to add new artifacts** (decision framework, schemas, examples) lives in [`INSTRUCTION.md`](./INSTRUCTION.md).

---

## Quick install

### Skills — via skills.sh (recommended)

On any machine with `node`/`npm`:

```bash
npx skills add zhuconv/viberesearch -g    # user scope: skills available everywhere
npx skills add zhuconv/viberesearch       # or: current project only
```

The [`skills` CLI](https://github.com/vercel-labs/skills) detects the coding agents installed on the machine (Claude Code, Codex, Cursor, Copilot, …) and links every skill into each agent's own skills directory (`~/.claude/skills/` for Claude Code, the shared `~/.agents/skills/` for Codex, …) — no marketplace registration, no per-CLI adaptation. Re-run the same command any time to refresh to the latest `master`. Browse the repo's listing at [skills.sh](https://www.skills.sh) once indexed.

> **Pick one route per machine (Claude Code).** If you also install the set plugins below, the same skills load twice — once from the plugin, once from `~/.claude/skills/`.

### Full environment — plugin marketplaces + bootstrap

On any machine with `git`, `node`, and `npm`:

```bash
npx --yes github:zhuconv/viberesearch
```

What this does, in order:

1. Confirms `git`, `node`, and `npm` exist.
2. If `claude` (Claude Code CLI) is on your `PATH`: adds the marketplace, updates it, installs each set plugin (currently just `engineer`) at user scope, and lists installed plugins.
3. If `codex` is on your `PATH`: runs `npx skills add zhuconv/viberesearch -g -a codex -y --skill '*'`, installing every skill into `~/.agents/skills/`.
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
claude plugin install engineer@viberesearch --scope user
claude plugin list
```

Each set is an independent plugin — install by name as more sets ship.

Then verify inside a Claude Code session:

```
/reload-plugins
/skills
/mcp
/doctor
```

The expected `/skills` and `/mcp` output matches what's listed in [`CONTENT.md`](./CONTENT.md). `/doctor` summarizes plugin health.

### Codex

Codex is served by the skills CLI route (there is no native Codex plugin — see above):

```bash
npx skills add zhuconv/viberesearch -g -a codex
```

Then start a new Codex session and confirm with:

```
/skills
```

Re-run the same command to refresh after the repo updates. Only skills ship to Codex — `agents/`, `hooks/`, and `.mcp.json` are Claude Code plugin artifacts.

---

## Repository layout

```
viberesearch/
├── package.json                      # Declares the `viberesearch` npx bin
├── bin/
│   └── viberesearch.mjs              # Bootstrap: Claude via plugins, Codex via the skills CLI
├── .claude-plugin/
│   └── marketplace.json              # Claude marketplace; defines each set-plugin inline
│                                     #   (strict: false + a skills array)
├── .mcp.json                         # MCP server registrations (Claude plugin route)
├── skills/                           # Skills (shared) — skills.sh catalog layout
│   └── engineer/                     #   set: decks + figures
├── agents/                           # Sub-agents (Claude Code only) — see CONTENT.md
├── hooks/
│   └── hooks.json                    # Lifecycle hooks (Claude Code only); empty by default
├── scripts/
│   └── doctor.sh                     # Pre-push validator
├── README.md                         # This file — structure + authoring grammar
├── CONTENT.md                        # Live inventory of what this repo ships
├── INSTRUCTION.md                    # Authoring guide: when to add what
└── .gitignore                        # Ignores node_modules, .env, .DS_Store, *.log
```

The repo root is the plugin root, and one file does double duty: Claude Code plugins can't auto-discover skills nested two levels deep (`skills/<set>/<name>/`), so each Claude set-plugin lists its skill directories explicitly in `marketplace.json` (a `strict: false` entry with a `skills` array — no separate `plugin.json` needed), and the `skills` CLI reads those same skill claims to group its install picker into sets.

### Mental model: three layers

When something looks broken, ask which of these three layers it lives in.

1. **Marketplace manifest** — `.claude-plugin/marketplace.json`. A catalog of the plugins this repo exposes (one per set). Also read by the `skills` CLI for set grouping.

2. **Plugin manifest** — the plugin definitions live inline in `marketplace.json`: each set entry carries `strict: false` plus an explicit `skills` path array, because Claude does not auto-discover skills nested under set directories. There is no separate `plugin.json`.

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
| Give the agent a reusable workflow                 | Skill        | `skills/<set>/<name>/SKILL.md` + claim it in the set's `marketplace.json` entry |
| Dispatch a specialist with its own context         | Sub-agent    | `agents/<name>.md`                                     |
| Enforce a deterministic lifecycle rule             | Hook         | `hooks/hooks.json`                                     |
| Provide a deterministic CLI / utility              | Script       | `scripts/<name>.sh` or `bin/<name>.mjs`                |
| Connect to an external system / API                | MCP server   | `.mcp.json`                                            |
| Carve a different audience or risk profile         | New plugin   | `plugins/<new-plugin>/` + register in both `marketplace.json` files |

After any change: update [`CONTENT.md`](./CONTENT.md) to reflect the new artifact, run `bash scripts/doctor.sh`, then `/reload-plugins` inside Claude Code (Codex users re-run `npx skills add` and start a new session).

---

## Authoring tips

- **Be specific in skill descriptions.** "Reviews code" loses to "Reviews the recent git diff for correctness, hidden assumptions, and reproducibility issues." The model routes on these strings.
- **Read current code, don't bake constants.** A skill that says "the loss is MSE" goes stale; one that says "open `train.py` and report the loss function" stays correct.
- **Never commit secrets.** Tokens go in `.env` (gitignored) or 1Password; `.mcp.json` only ever holds `${VAR}` placeholders. CONTENT.md lists which env vars each MCP server needs.
- **Run `bash scripts/doctor.sh` before pushing.** It catches most of the structural mistakes that would only surface inside the CLI.
- **One skill, one job.** If a skill description starts to grow conjunctions ("and also..."), split it. The router picks one skill at a time.

---

## Validation

Before pushing or filing a bug:

```bash
bash scripts/doctor.sh
```

It checks that:

- `package.json` exists and parses as JSON.
- `.claude-plugin/marketplace.json`, `.mcp.json`, and `hooks/hooks.json` exist and parse.
- Every `skills/<set>/<name>/SKILL.md` on disk is claimed by exactly one set entry in `.claude-plugin/marketplace.json`, every claimed path exists, and at least one skill is present.

It does not validate frontmatter inside `SKILL.md` or `agents/*.md` — those errors only show up when the CLI tries to load them. So after a structural pass, also re-run:

```bash
npx --yes github:zhuconv/viberesearch
```

from a shell that has `claude` and/or `codex` on its `PATH`. The bootstrap re-registers and updates the marketplace, then installs or refreshes the plugin so both CLIs can pick up your edits.

---

## Troubleshooting

**Skill appears twice in `/skills`.** Both install routes are active on this machine: the set plugins and the standalone skills from `npx skills add`. Remove one — `claude plugin uninstall engineer@viberesearch`, or delete the duplicates from `~/.claude/skills/` (they're symlinks created by the `skills` CLI).

**Skill not appearing in `/skills`.** Check the YAML frontmatter — it must start with `---` on the first line, end with `---`, and contain at least `name:` and `description:`. The directory name and `name:` should match. After fixing, run `/reload-plugins`.

**MCP server fails to start (red status in `/mcp`).** Copy the `command` and `args` from `.mcp.json` and run them in a normal terminal. The real error (missing package, bad token, network) will print there. Most often: the CLI was launched from a shell that didn't have the required env var. CONTENT.md lists which servers need which vars.

**`marketplace not found` when running `claude plugin install`.** You haven't run `claude plugin marketplace add zhuconv/viberesearch` yet, or the marketplace was added under a different name. List with `claude plugin marketplace list` and re-add if missing.

**Hook not firing.** The `matcher` is the most common culprit. `Bash` matches the Bash tool literally; partial strings and unanchored patterns may not. Reduce to a hook with `"matcher": "Bash"` and an obvious side effect (e.g., `command: 'echo fired >> /tmp/hook.log'`) to confirm the event itself is reaching you, then narrow the matcher.

**Sub-agent not delegated to.** The parent decides based on the `description`. If it never picks your agent, the description is too generic or overlaps with another agent. Tighten it, then `/reload-plugins`.

**Codex doesn't see the skills.** Codex has no plugin route here — install with `npx skills add zhuconv/viberesearch -g -a codex -y --skill '*'`, confirm files landed in `~/.agents/skills/`, then start a new Codex session. Don't use `--all`: it overrides `-a` and installs to every detected agent, duplicating the Claude plugin skills.

**Plugin install fails with a manifest validation error.** Run `claude plugin validate .` for the real message. The Claude set entries in `marketplace.json` rely on `strict: false` plus explicit `skills` arrays; a typo in a claimed path, or a claimed directory missing its `SKILL.md`, fails the install. `bash scripts/doctor.sh` catches path/claim mismatches before pushing.

---

## Useful content from elsewhere

Skills we didn't write aren't vendored or aliased here — installing them directly from the source keeps you on exactly what the author ships, with no drift or duplicate-maintenance burden on this repo.

- **[Matt Pocock's skills](https://github.com/mattpocock/skills)** — grilling, spec/ticket flows, TDD, code review, domain modelling.

  `-y` means fully unattended: it skips every prompt, including the group picker, and just installs everything discovered. There is no flag to select a group non-interactively — `--skill` only matches individual skill names, not group/plugin names — so "unattended" and "curated (no drafts)" don't fit in one line the same way. Pick by what you want:

  - **Curated, unattended, one command each (recommended)** — his `skills/` splits into buckets; `engineering/` + `productivity/` are the ones he promotes (verified: 17 + 5 = his plugin's exact 22-skill curated list, same as the Claude plugin below). Run both:
    ```bash
    npx skills add mattpocock/skills/skills/engineering -y
    npx skills add mattpocock/skills/skills/productivity -y
    ```
  - **Curated, by hand** — drop `-y` so the group picker appears, then **toggle on "Mattpocock Skills", leave "Other" unchecked**, and confirm:
    ```bash
    npx skills add mattpocock/skills
    ```
  - **Everything, unattended** — also pulls his `deprecated/`, `in-progress/`, `personal/`, `misc/` buckets (41 skills total, not curated):
    ```bash
    npx skills add mattpocock/skills -y
    ```
  - **Claude Code plugin** — a native subscription, always exactly his curated 22, updates when he bumps his version:
    ```bash
    claude plugin marketplace add mattpocock/skills
    claude plugin install mattpocock-skills@mattpocock
    ```

---

## License

MIT.

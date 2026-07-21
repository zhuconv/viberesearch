#!/usr/bin/env node
import { spawnSync } from "node:child_process";

function has(cmd) {
  return spawnSync("bash", ["-lc", `command -v ${cmd}`], {
    stdio: "ignore"
  }).status === 0;
}

function run(cmd, args, opts = {}) {
  console.log(`\n$ ${cmd} ${args.join(" ")}`);
  const r = spawnSync(cmd, args, { stdio: "inherit" });
  if (!opts.allowFail && r.status !== 0) process.exit(r.status ?? 1);
  return r.status ?? 0;
}

const repo = "zhuconv/viberesearch";
const marketplace = "viberesearch";
const claudePlugins = ["engineer", "research"];

console.log("Equipping viberesearch environment...");

if (!has("git")) {
  console.error("Missing git.");
  process.exit(1);
}

if (!has("node")) {
  console.error("Missing node.");
  process.exit(1);
}

if (!has("npm")) {
  console.error("Missing npm.");
  process.exit(1);
}

if (has("claude")) {
  console.log("\nConfiguring Claude Code...");
  run("claude", ["plugin", "marketplace", "add", repo], { allowFail: true });
  run("claude", ["plugin", "marketplace", "update", marketplace], { allowFail: true });
  for (const plugin of claudePlugins) {
    run("claude", ["plugin", "install", `${plugin}@${marketplace}`, "--scope", "user"], { allowFail: true });
    run("claude", ["plugin", "update", `${plugin}@${marketplace}`, "--scope", "user"], { allowFail: true });
  }
  run("claude", ["plugin", "list"], { allowFail: true });
} else {
  console.log("\nClaude Code CLI not found; skipping Claude setup.");
}

if (has("codex")) {
  console.log("\nConfiguring Codex (skills installed via the skills CLI)...");
  run("npx", ["-y", "skills", "add", repo, "-g", "-a", "codex", "-y", "--skill", "*"], { allowFail: true });

  console.log(`
Codex skills installed to ~/.agents/skills (the shared agent-skills directory Codex reads).

Start a new Codex session so it picks them up. Re-run this bootstrap any time to refresh.
`);
} else {
  console.log("\nCodex CLI not found; skipping Codex setup.");
}

if (has("gh")) {
  run("gh", ["auth", "status"], { allowFail: true });
}

if (has("op")) {
  run("op", ["whoami"], { allowFail: true });
}

console.log(`
Done.

Claude Code verification:
  claude
  /reload-plugins
  /skills
  /mcp
  /doctor

Codex verification:
  codex
  /skills
`);

---
name: tool-guard
description: >-
  Create runtime-aware hook enforcement for repo tool constraints. Use this whenever a
  project must force a package manager, task runner, formatter, linter, or test runner;
  when the user asks to "create a hook", "enforce pnpm not npm", "block banned commands",
  "generate Copilot hooks", or "generate OpenCode plugin enforcement"; and whenever setup
  should move operational tool policy out of AGENTS.md and into hooks.
---

# Tool Guard

Generate canonical hook policy plus runtime-native enforcement artifacts for the selected runtime(s).

## Goal

Keep tool policy out of `AGENTS.md`. Store it canonically in `hooks/tool-guard/`, then emit the real enforcement files each runtime needs.

## Inputs to collect

Use `ask_user` when these are not already known:

- Target runtimes: `GitHub Copilot CLI`, `OpenCode`, or both
- Package manager
- Task runner / scripts
- Formatter
- Linter
- Test runner
- Extra banned commands
- Strictness per category: hard-block or warning-only

If the repo already contains config files or scripts that answer these questions, inspect the codebase first and only ask for what remains ambiguous.

## Canonical output

Always create:

- `hooks/tool-guard/README.md`
- `hooks/tool-guard/policy.json`

### `policy.json` contents

Capture the policy as structured data:

- `runtimes`
- `categories`
- per-category `preferred`
- per-category `blocked`
- per-category `mode` (`deny` or `warn`)
- `extra_banned_commands`

Prefer a stable, explicit schema over freeform prose so runtime generators can consume it deterministically.

## Runtime generation

Generate only for the runtimes the user selected.

### GitHub Copilot CLI

Create runtime-native enforcement under `.github/hooks/`.

Use `preToolUse` hooks to inspect tool invocations and deny or warn when commands violate policy. Prefer dedicated scripts when the logic is non-trivial rather than stuffing everything into inline shell.

Outputs should typically include:

- `.github/hooks/tool-guard.json`
- helper scripts under `.github/hooks/scripts/` when needed

Requirements:

- do not overwrite unrelated existing hooks
- merge or add new hook files safely
- support PowerShell when the environment is Windows
- return the hook output format required to deny execution when policy says `deny`

### OpenCode

Create runtime-native enforcement as an OpenCode plugin.

Outputs should typically include:

- `.opencode/plugins/tool-guard/index.ts`
- any required updates to `opencode.json`

Use `tool.execute.before` to inspect tool execution and throw for denied commands. If the policy mode is `warn`, log or annotate without blocking.

Requirements:

- do not overwrite unrelated plugins
- merge config safely if `opencode.json` already exists
- keep the plugin narrowly focused on tool policy enforcement

## Generation rules

- Reuse existing repo structure and config when present
- Keep the canonical policy in `hooks/tool-guard/` as the source of truth
- Do not duplicate policy text in `AGENTS.md`
- If both runtimes are requested, generate both from the same canonical policy
- If only one runtime is requested, still write the canonical hook artifacts first

## Review checklist

Before finishing, verify:

- canonical files exist in `hooks/tool-guard/`
- runtime-native files exist for each selected runtime
- `policy.json` matches the user’s chosen tools and blocked alternatives
- config wiring was added without clobbering unrelated settings
- `AGENTS.md` does not contain the operational tool policy you just moved into hooks

## Example use cases

**Example 1:**
User asks: "Force pnpm and turbo, and block npm and yarn."
Action: write canonical policy, then generate Copilot/OpenCode enforcement that denies banned commands.

**Example 2:**
User asks: "We use biome for formatting, eslint for linting, and vitest for tests. OpenCode only."
Action: generate `hooks/tool-guard/` plus only the OpenCode plugin/config.

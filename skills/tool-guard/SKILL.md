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

Generate canonical hook policy plus runtime-native enforcement for GitHub Copilot CLI,
OpenCode, and/or Claude Code. All scripts read `hooks/tool-guard/policy.json` at runtime —
update the policy file and enforcement takes effect immediately without regenerating scripts.

## References

Load the relevant file(s) for the selected runtimes before generating:

| Runtime | Reference file |
|---|---|
| GitHub Copilot CLI | `references/copilot-cli.md` |
| OpenCode | `references/opencode.md` |
| Claude Code | `references/claude-code.md` |

Each reference file contains the complete file list, protocol notes, and copy-paste templates for that runtime.

---

## Step 1: Collect inputs

Inspect existing config files first and pre-fill what you can infer. Use `ask_user` for anything not already known:

- **Target runtimes** — `GitHub Copilot CLI`, `OpenCode`, `Claude Code` (any combination)
- **Package manager** — preferred tool and blocked alternatives (e.g., pnpm preferred, npm/yarn blocked)
- **Task runner** — preferred and blocked
- **Formatter**, **linter**, **test runner** — preferred and blocked
- **Extra banned commands** — specific substrings to always block
- **Mode per category** — `deny` (firm block) or `warn` (advisory — still blocks, but prefixed with ⚠️)

## Step 2: Create canonical files

Always create these two files regardless of which runtimes are selected.
They are the single source of truth — runtime scripts reference them, never duplicate them.

### `hooks/tool-guard/README.md`

Plain-English summary: what is blocked, what is warned, what is allowed, and why.

### `hooks/tool-guard/policy.json`

```json
{
  "version": 1,
  "runtimes": ["github-copilot-cli", "opencode", "claude-code"],
  "categories": {
    "<category-name>": {
      "preferred": ["<preferred-tool>"],
      "blocked": ["<blocked-pattern>"],
      "mode": "deny",
      "reason": "<human-readable explanation>"
    }
  },
  "extra_banned_commands": [
    {
      "pattern": "<case-insensitive substring>",
      "match": "contains",
      "mode": "deny",
      "reason": "<human-readable explanation>"
    }
  ]
}
```

Matching is always **case-insensitive substring**. Both `deny` and `warn` block execution;
warn prefixes the reason with `⚠️ Advisory:`.

## Step 3: Generate runtime files

Read the reference file(s) for each selected runtime and generate all files listed there.

## Generation rules

- Canonical `hooks/tool-guard/` files come first — always
- Scripts read `policy.json` at runtime; never hardcode patterns into scripts
- For Copilot CLI and Claude Code: generate both `.sh` and `.ps1`
- Mark `.sh` files executable with `chmod +x`
- If runtime config files already exist: merge — do not overwrite unrelated content
- Keep tool policy out of `AGENTS.md`

## Review checklist

- `hooks/tool-guard/README.md` and `policy.json` exist
- Runtime files exist for every selected runtime
- `policy.json` accurately reflects the user's choices
- `.sh` files are executable
- `.claude/settings.json` merged without losing other keys
- `AGENTS.md` contains no operational tool policy
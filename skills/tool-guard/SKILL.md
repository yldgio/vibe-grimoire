---
name: tool-guard
description: >-
  Create runtime-aware hook enforcement for repo tool constraints. Use this whenever a
  project must force a package manager, task runner, formatter, linter, or test runner;
  when the user asks to "create a hook", "enforce pnpm not npm", "block banned commands",
  "generate Copilot hooks", or "generate OpenCode plugin enforcement"; and whenever setup
  should move operational tool policy out of AGENTS.md and into hooks.
  Also use for: "add git safety guards", "block git push force", "block rm -rf",
  "prevent dangerous deletes", "add git guardrails", "add default tool guards",
  "protect against destructive commands", or "apply default hooks".
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

## Step 0: Offer default presets (optional but recommended)

Before collecting custom inputs, offer to apply one or both default presets.
Read the relevant file(s) from `defaults/` and merge their `extra_banned_commands`
into the project `policy.json`. Presets are composable — apply any combination.

| Preset | File | What it covers |
|--------|------|----------------|
| Git safety | `defaults/git-safety.json` | Blocks force-push, reset --hard, clean -f; warns on bare push, branch -D, checkout/restore . |
| Destructive file ops | `defaults/destructive-ops.json` | Blocks rm -rf variants; warns on mv with .. or absolute path; includes PowerShell equivalents |

**Merge rule:** append preset entries to `extra_banned_commands[]` in `policy.json`. If a
conflicting pattern already exists, keep the stricter mode (`deny` beats `warn`). After
merging git-safety, ensure deny rules for specific force variants (`git push --force`,
`git push -f`) appear before the broader warn rule for bare `git push` — reorder if needed.

## Step 1: Collect inputs

Inspect existing config files first and pre-fill what you can infer. Use `ask_user` for anything not already known:

- **Target runtimes** — `GitHub Copilot CLI`, `OpenCode`, `Claude Code` (any combination)
- **Package manager** — preferred tool and blocked alternatives (e.g., pnpm preferred, npm/yarn blocked)
- **Task runner** — preferred and blocked
- **Formatter**, **linter**, **test runner** — preferred and blocked
- **Extra banned commands** — specific substrings to always block
- **Mode per category** — `deny` (firm block) or `warn` (advisory only; call still proceeds)

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

Matching is always **case-insensitive substring** after stripping quoted string segments from the command. `deny` blocks execution; `warn` emits advisory output and allows the call to proceed.

## Step 3: Generate runtime files

Read the reference file(s) for each selected runtime and generate all files listed there.

## Generation rules

- Canonical `hooks/tool-guard/` files come first — always
- Scripts read `policy.json` at runtime; never hardcode patterns into scripts
- For Copilot CLI and Claude Code: generate both `.sh` and `.ps1`
- Mark `.sh` files executable with `chmod +x`
- If runtime config files already exist: merge — do not overwrite unrelated content
- Keep tool policy out of `AGENTS.md`
- **PowerShell emoji**: do NOT embed literal `⚠️` in `.ps1` files — use `$([char]0x26A0)$([char]0xFE0F)` and add `[Console]::OutputEncoding = [System.Text.Encoding]::UTF8` at the top; `ConvertTo-Json` must use `-EscapeHandling EscapeNonAscii` (PS 7.1+). The reference templates already do this.

## Review checklist

- `hooks/tool-guard/README.md` and `policy.json` exist
- Runtime files exist for every selected runtime
- `policy.json` accurately reflects the user's choices
- `.sh` files are executable
- `.claude/settings.json` merged without losing other keys
- `AGENTS.md` contains no operational tool policy

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
update the policy file and the change takes effect immediately without regenerating scripts.

## Step 1: Collect inputs

Use `ask_user` for anything not already known:

- **Target runtimes** — `GitHub Copilot CLI`, `OpenCode`, `Claude Code` (any combination)
- **Package manager** — preferred tool and blocked alternatives
- **Task runner** — preferred and blocked
- **Formatter**, **linter**, **test runner** — same
- **Extra banned commands** — specific substrings to hard-block
- **Mode per category** — `deny` (firm block) or `warn` (advisory block with ⚠️ prefix)

Inspect existing config files first and pre-fill what you can infer.

## Step 2: Canonical files

Always create these two files regardless of which runtimes are selected. They are the
single source of truth — runtime scripts reference them, never duplicate them.

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

- Matching is always **case-insensitive substring** (`contains`)
- `deny` → firm block; `warn` → block with `⚠️ Advisory:` prefix (both modes block execution)

## Step 3: Runtime generation

Generate only for the runtimes the user selected.

---

### GitHub Copilot CLI

Files:
```
.github/hooks/tool-guard.json              ← hook config
.github/hooks/scripts/pre-tool-guard.sh   ← bash (Mac/Linux)
.github/hooks/scripts/pre-tool-guard.ps1  ← PowerShell (Windows)
```

**Protocol:**
- Hooks are loaded from `.github/hooks/*.json` automatically
- `preToolUse` stdin: `{ "toolName": "bash", "toolArgs": "{\"command\": \"...\"}" }`
- ⚠️ `toolArgs` is a **JSON string** — parse it with a second `jq` / `ConvertFrom-Json` call
- Deny: write `{ "permissionDecision": "deny", "permissionDecisionReason": "..." }` to stdout, exit 0
- Allow: exit 0 with no output
- Both `bash` and `powershell` script paths can be set in one hook entry for cross-platform

**`.github/hooks/tool-guard.json`:**
```json
{
  "version": 1,
  "hooks": {
    "preToolUse": [
      {
        "type": "command",
        "bash": "./scripts/pre-tool-guard.sh",
        "powershell": "./scripts/pre-tool-guard.ps1",
        "cwd": ".github/hooks",
        "timeoutSec": 15
      }
    ]
  }
}
```

**`.github/hooks/scripts/pre-tool-guard.sh`:**
```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT="$(cat)"
TOOL_NAME="$(printf '%s' "$INPUT" | jq -r '.toolName // empty')"
TOOL_ARGS_RAW="$(printf '%s' "$INPUT" | jq -r '.toolArgs // empty')"

case "$TOOL_NAME" in bash|powershell|shell|run_terminal_cmd) ;; *) exit 0 ;; esac

# toolArgs is a JSON string — parse it
if ! TOOL_ARGS="$(printf '%s' "$TOOL_ARGS_RAW" | jq -e . 2>/dev/null)"; then exit 0; fi

COMMAND="$(printf '%s' "$TOOL_ARGS" | jq -r '.command // .bash // .input // empty')"
[ -z "$COMMAND" ] && exit 0
NORM="$(printf '%s' "$COMMAND" | tr '[:upper:]' '[:lower:]')"

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
POLICY_FILE="$REPO_ROOT/hooks/tool-guard/policy.json"
[ -f "$POLICY_FILE" ] || exit 0
POLICY="$(cat "$POLICY_FILE")"

deny() {
  printf '%s\n' "$(jq -cn --arg r "$1" '{"permissionDecision":"deny","permissionDecisionReason":$r}')"
  exit 0
}

# extra_banned_commands
while IFS= read -r rule; do
  pattern="$(printf '%s' "$rule" | jq -r '.pattern' | tr '[:upper:]' '[:lower:]')"
  reason="$(printf '%s' "$rule" | jq -r '.reason')"
  mode="$(printf '%s' "$rule" | jq -r '.mode')"
  printf '%s' "$NORM" | grep -qF "$pattern" || continue
  [ "$mode" = "warn" ] && deny "⚠️ Advisory: $reason" || deny "$reason"
done < <(printf '%s' "$POLICY" | jq -c '.extra_banned_commands[]? // empty')

# categories
while IFS= read -r cat; do
  mode="$(printf '%s' "$cat" | jq -r '.mode')"
  reason="$(printf '%s' "$cat" | jq -r '.reason')"
  while IFS= read -r pattern; do
    printf '%s' "$NORM" | grep -qiF "$pattern" || continue
    [ "$mode" = "warn" ] && deny "⚠️ Advisory: $reason" || deny "$reason"
  done < <(printf '%s' "$cat" | jq -r '.blocked[]? // empty')
done < <(printf '%s' "$POLICY" | jq -c '.categories | to_entries[] | {mode:.value.mode,reason:.value.reason,blocked:.value.blocked}')

exit 0
```

Run `chmod +x .github/hooks/scripts/pre-tool-guard.sh` after creating.

**`.github/hooks/scripts/pre-tool-guard.ps1`:**
```powershell
$ErrorActionPreference = 'Stop'

function Get-ToolCommand([object]$ToolArgs) {
    foreach ($prop in @('command','bash','powershell','input','text')) {
        $v = $ToolArgs.PSObject.Properties[$prop]
        if ($null -ne $v -and $v.Value -is [string] -and $v.Value.Trim().Length -gt 0) { return $v.Value }
    }
    return $null
}

$rawInput = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($rawInput)) { exit 0 }

$payload  = $rawInput | ConvertFrom-Json
$toolName = [string]$payload.toolName
if ($toolName -notin @('bash','powershell','shell','run_terminal_cmd')) { exit 0 }

# toolArgs is a JSON string — parse it
$toolArgsRaw = [string]$payload.toolArgs
if ([string]::IsNullOrWhiteSpace($toolArgsRaw)) { exit 0 }
try { $toolArgs = $toolArgsRaw | ConvertFrom-Json } catch { exit 0 }

$command = Get-ToolCommand $toolArgs
if ([string]::IsNullOrWhiteSpace($command)) { exit 0 }
$norm = $command.ToLowerInvariant()

$repoRoot  = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$policyPath = Join-Path $repoRoot 'hooks\tool-guard\policy.json'
if (-not (Test-Path $policyPath)) { exit 0 }
$policy = Get-Content $policyPath -Raw | ConvertFrom-Json

function Deny([string]$reason) {
    @{ permissionDecision = 'deny'; permissionDecisionReason = $reason } | ConvertTo-Json -Compress
    exit 0
}

foreach ($rule in $policy.extra_banned_commands) {
    $pattern = ([string]$rule.pattern).ToLowerInvariant()
    if (-not $norm.Contains($pattern)) { continue }
    if ([string]$rule.mode -eq 'warn') { Deny "⚠️ Advisory: $([string]$rule.reason)" }
    else { Deny ([string]$rule.reason) }
}

foreach ($prop in $policy.categories.PSObject.Properties) {
    $cat    = $prop.Value
    $mode   = [string]$cat.mode
    $reason = [string]$cat.reason
    foreach ($pattern in $cat.blocked) {
        if (-not $norm.Contains($pattern.ToLowerInvariant())) { continue }
        if ($mode -eq 'warn') { Deny "⚠️ Advisory: $reason" }
        else { Deny $reason }
    }
}

exit 0
```

**Test:**
```bash
# Allow
echo '{"toolName":"bash","toolArgs":"{\"command\":\"git status\"}"}' \
  | .github/hooks/scripts/pre-tool-guard.sh

# Deny (pattern from your policy)
echo '{"toolName":"bash","toolArgs":"{\"command\":\"npm install\"}"}' \
  | .github/hooks/scripts/pre-tool-guard.sh
```

---

### OpenCode

Files:
```
.opencode/plugins/tool-guard/index.ts
```

No `opencode.json` entry needed — files in `.opencode/plugins/` are loaded automatically.
OpenCode runs `.ts` files directly via Bun; no compilation step required.

**Protocol:**
- `tool.execute.before` receives `input.tool` (tool name) and `output.args` (args object)
- Deny: `throw new Error(reason)` — OpenCode surfaces the message to the AI
- Warn (Option A: block with message): same as deny, prefix with `⚠️ Advisory:`

**`.opencode/plugins/tool-guard/index.ts`:**
```typescript
import type { Plugin } from "@opencode-ai/plugin"
import fs from "node:fs/promises"
import path from "node:path"

type Mode = "deny" | "warn"

type CommandRule = {
  pattern: string
  match?: "contains"
  mode: Mode
  reason: string
}

type CategoryPolicy = {
  preferred: string[]
  blocked: string[]
  mode: Mode
  reason: string
}

type Policy = {
  extra_banned_commands?: CommandRule[]
  categories?: Record<string, CategoryPolicy>
}

const SHELL_TOOLS = new Set(["bash", "powershell", "run_terminal_cmd", "shell"])

function extractCommand(args: Record<string, unknown> | undefined): string | null {
  for (const key of ["command", "bash", "powershell", "input", "text"]) {
    const v = args?.[key]
    if (typeof v === "string" && v.trim().length > 0) return v
  }
  return null
}

export const ToolGuard: Plugin = async ({ worktree }) => {
  const policyPath = path.join(worktree, "hooks", "tool-guard", "policy.json")
  const policy = JSON.parse(await fs.readFile(policyPath, "utf8")) as Policy

  return {
    "tool.execute.before": async (input, output) => {
      if (!SHELL_TOOLS.has(String(input.tool ?? ""))) return

      const command = extractCommand(output.args as Record<string, unknown>)
      if (!command) return

      const norm = command.toLowerCase()

      for (const rule of policy.extra_banned_commands ?? []) {
        if (!norm.includes(rule.pattern.toLowerCase())) continue
        const msg = rule.mode === "warn" ? `⚠️ Advisory: ${rule.reason}` : rule.reason
        throw new Error(msg)
      }

      for (const [, category] of Object.entries(policy.categories ?? {})) {
        const match = category.blocked.find((p) => norm.includes(p.toLowerCase()))
        if (!match) continue
        const msg = category.mode === "warn" ? `⚠️ Advisory: ${category.reason}` : category.reason
        throw new Error(msg)
      }
    },
  }
}
```

---

### Claude Code

Files:
```
.claude/hooks/pre-tool-guard.sh    ← bash (Mac/Linux)
.claude/hooks/pre-tool-guard.ps1   ← PowerShell (Windows)
.claude/settings.json              ← hook wiring (merge if exists)
```

**Protocol:**
- Hooks are configured in `.claude/settings.json` (project) or `~/.claude/settings.json` (global)
- `PreToolUse` stdin: `{ "session_id": "...", "hook_event_name": "PreToolUse", "tool_name": "Bash", "tool_input": { "command": "..." } }`
- `tool_input` is already a parsed JSON object (unlike Copilot CLI where toolArgs is a string)
- Deny: write `{ "hookSpecificOutput": { "hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "..." } }` to stdout, exit 0
- Allow: exit 0 with no output
- Ask the user: project scope (`.claude/settings.json`) or global (`~/.claude/settings.json`)?

**`.claude/settings.json`** (project scope):
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/pre-tool-guard.sh"
          }
        ]
      }
    ]
  }
}
```

If the file already exists, **merge** — add the `PreToolUse` array entry, do not overwrite other keys.

**`.claude/hooks/pre-tool-guard.sh`:**
```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT="$(cat)"
TOOL_NAME="$(printf '%s' "$INPUT" | jq -r '.tool_name // empty')"

# tool_input is already a parsed object (not a JSON string)
[ "$TOOL_NAME" = "Bash" ] || exit 0

COMMAND="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')"
[ -z "$COMMAND" ] && exit 0
NORM="$(printf '%s' "$COMMAND" | tr '[:upper:]' '[:lower:]')"

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
POLICY_FILE="$REPO_ROOT/hooks/tool-guard/policy.json"
[ -f "$POLICY_FILE" ] || exit 0
POLICY="$(cat "$POLICY_FILE")"

deny() {
  printf '%s\n' "$(jq -cn --arg r "$1" \
    '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":$r}}')"
  exit 0
}

while IFS= read -r rule; do
  pattern="$(printf '%s' "$rule" | jq -r '.pattern' | tr '[:upper:]' '[:lower:]')"
  reason="$(printf '%s' "$rule" | jq -r '.reason')"
  mode="$(printf '%s' "$rule" | jq -r '.mode')"
  printf '%s' "$NORM" | grep -qF "$pattern" || continue
  [ "$mode" = "warn" ] && deny "⚠️ Advisory: $reason" || deny "$reason"
done < <(printf '%s' "$POLICY" | jq -c '.extra_banned_commands[]? // empty')

while IFS= read -r cat; do
  mode="$(printf '%s' "$cat" | jq -r '.mode')"
  reason="$(printf '%s' "$cat" | jq -r '.reason')"
  while IFS= read -r pattern; do
    printf '%s' "$NORM" | grep -qiF "$pattern" || continue
    [ "$mode" = "warn" ] && deny "⚠️ Advisory: $reason" || deny "$reason"
  done < <(printf '%s' "$cat" | jq -r '.blocked[]? // empty')
done < <(printf '%s' "$POLICY" | jq -c '.categories | to_entries[] | {mode:.value.mode,reason:.value.reason,blocked:.value.blocked}')

exit 0
```

Run `chmod +x .claude/hooks/pre-tool-guard.sh` after creating.

**`.claude/hooks/pre-tool-guard.ps1`:**
```powershell
$ErrorActionPreference = 'Stop'

$rawInput = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($rawInput)) { exit 0 }

$payload = $rawInput | ConvertFrom-Json
if ($payload.tool_name -ne 'Bash') { exit 0 }

# tool_input is already a parsed object
$command = $payload.tool_input?.command
if ([string]::IsNullOrWhiteSpace($command)) { exit 0 }
$norm = $command.ToLowerInvariant()

$repoRoot   = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$policyPath = Join-Path $repoRoot 'hooks\tool-guard\policy.json'
if (-not (Test-Path $policyPath)) { exit 0 }
$policy = Get-Content $policyPath -Raw | ConvertFrom-Json

function Deny([string]$reason) {
    @{
        hookSpecificOutput = @{
            hookEventName            = 'PreToolUse'
            permissionDecision       = 'deny'
            permissionDecisionReason = $reason
        }
    } | ConvertTo-Json -Depth 3 -Compress
    exit 0
}

foreach ($rule in $policy.extra_banned_commands) {
    if (-not $norm.Contains(([string]$rule.pattern).ToLowerInvariant())) { continue }
    if ([string]$rule.mode -eq 'warn') { Deny "⚠️ Advisory: $([string]$rule.reason)" }
    else { Deny ([string]$rule.reason) }
}

foreach ($prop in $policy.categories.PSObject.Properties) {
    $cat    = $prop.Value
    $mode   = [string]$cat.mode
    $reason = [string]$cat.reason
    foreach ($pattern in $cat.blocked) {
        if (-not $norm.Contains($pattern.ToLowerInvariant())) { continue }
        if ($mode -eq 'warn') { Deny "⚠️ Advisory: $reason" }
        else { Deny $reason }
    }
}

exit 0
```

**Test:**
```bash
# Allow
echo '{"tool_name":"Bash","tool_input":{"command":"git status"}}' \
  | .claude/hooks/pre-tool-guard.sh

# Deny
echo '{"tool_name":"Bash","tool_input":{"command":"npm install"}}' \
  | .claude/hooks/pre-tool-guard.sh
```

---

## Generation rules

- Create canonical `hooks/tool-guard/` files first — always
- Scripts read `policy.json` at runtime; never hardcode patterns into scripts
- Both deny and warn block execution; warn prefixes the reason with `⚠️ Advisory:`
- For Copilot CLI and Claude Code: generate both `.sh` and `.ps1`
- Mark all `.sh` files executable with `chmod +x`
- If runtime config files already exist: merge — do not overwrite unrelated content
- Keep tool policy out of `AGENTS.md`

## Review checklist

- `hooks/tool-guard/README.md` and `policy.json` exist
- Runtime files exist for every selected runtime
- `policy.json` accurately reflects the user's choices
- `.sh` files are executable
- `.claude/settings.json` merges without losing other keys
- `AGENTS.md` contains no operational tool policy
# Claude Code — Tool Guard Templates

## Files to generate

```
.claude/hooks/pre-tool-guard.sh    ← bash (Mac/Linux)
.claude/hooks/pre-tool-guard.ps1   ← PowerShell (Windows)
.claude/settings.json              ← hook wiring (merge if exists)
```

Ask the user: **project scope** (`.claude/settings.json`) or **global** (`~/.claude/settings.json`)?
Project scope is the right default for team repos.

## Protocol notes

- Hooks are configured in `.claude/settings.json` (or `~/.claude/settings.json` for global)
- `PreToolUse` stdin: `{ "session_id": "...", "hook_event_name": "PreToolUse", "tool_name": "Bash", "tool_input": { "command": "..." } }`
- ⚠️ `tool_input` is **already a parsed JSON object** (unlike Copilot CLI where `toolArgs` is a string)
- Deny: write `{ "hookSpecificOutput": { "hookEventName": "PreToolUse", "permissionDecision": "deny", "permissionDecisionReason": "..." } }` to stdout, exit 0
- Allow: exit 0 with no output

## `.claude/settings.json` (project scope)

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

## `.claude/hooks/pre-tool-guard.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT="$(cat)"
TOOL_NAME="$(printf '%s' "$INPUT" | jq -r '.tool_name // empty')"

# tool_input is already a parsed object (not a JSON string — no second parse needed)
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

## `.claude/hooks/pre-tool-guard.ps1`

```powershell
$ErrorActionPreference = 'Stop'

$rawInput = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($rawInput)) { exit 0 }

$payload = $rawInput | ConvertFrom-Json
if ($payload.tool_name -ne 'Bash') { exit 0 }

# tool_input is already a parsed object — no second parse needed
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

## Test commands

```bash
# Should allow
echo '{"tool_name":"Bash","tool_input":{"command":"git status"}}' \
  | .claude/hooks/pre-tool-guard.sh

# Should deny (adjust pattern to match your policy)
echo '{"tool_name":"Bash","tool_input":{"command":"npm install"}}' \
  | .claude/hooks/pre-tool-guard.sh
```

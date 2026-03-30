# Copilot CLI — Tool Guard Templates

## Files to generate

```
.github/hooks/tool-guard.json
.github/hooks/scripts/pre-tool-guard.sh
.github/hooks/scripts/pre-tool-guard.ps1
```

## Protocol notes

- Hooks are auto-loaded from `.github/hooks/*.json`
- `preToolUse` stdin: `{ "toolName": "bash", "toolArgs": "{\"command\": \"...\"}" }`
- ⚠️ `toolArgs` is a **JSON string inside JSON** — always parse it a second time
- Deny: write `{ "permissionDecision": "deny", "permissionDecisionReason": "..." }` to stdout, exit 0
- Warn: print advisory to stderr, exit 0 (non-blocking)
- Allow: exit 0 with no output

## `.github/hooks/tool-guard.json`

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

## `.github/hooks/scripts/pre-tool-guard.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

INPUT="$(cat)"
TOOL_NAME="$(printf '%s' "$INPUT" | jq -r '.toolName // empty')"
TOOL_ARGS_RAW="$(printf '%s' "$INPUT" | jq -r '.toolArgs // empty')"

case "$TOOL_NAME" in bash|powershell|shell|run_terminal_cmd) ;; *) exit 0 ;; esac

# toolArgs is a JSON string — parse it a second time
if ! TOOL_ARGS="$(printf '%s' "$TOOL_ARGS_RAW" | jq -e . 2>/dev/null)"; then exit 0; fi

COMMAND="$(printf '%s' "$TOOL_ARGS" | jq -r '.command // .bash // .input // empty')"
[ -z "$COMMAND" ] && exit 0
NORM="$(printf '%s' "$COMMAND" | tr '[:upper:]' '[:lower:]')"
NORM_STRIPPED="$(printf '%s' "$NORM" | sed -E "s/'[^']*'//g; s/\"[^\"]*\"//g")"

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
POLICY_FILE="$REPO_ROOT/hooks/tool-guard/policy.json"
[ -f "$POLICY_FILE" ] || exit 0
POLICY="$(cat "$POLICY_FILE")"

deny() {
  printf '%s\n' "$(jq -cn --arg r "$1" '{"permissionDecision":"deny","permissionDecisionReason":$r}')"
  exit 0
}

advisory=""

while IFS= read -r rule; do
  pattern="$(printf '%s' "$rule" | jq -r '.pattern' | tr '[:upper:]' '[:lower:]')"
  reason="$(printf '%s' "$rule" | jq -r '.reason')"
  mode="$(printf '%s' "$rule" | jq -r '.mode')"
  printf '%s' "$NORM_STRIPPED" | grep -qF "$pattern" || continue
  if [ "$mode" = "warn" ]; then
    [ -n "$advisory" ] || advisory="⚠️ Advisory: $reason"
    continue
  fi
  deny "$reason"
done < <(printf '%s' "$POLICY" | jq -c '.extra_banned_commands[]? // empty')

while IFS= read -r cat; do
  mode="$(printf '%s' "$cat" | jq -r '.mode')"
  reason="$(printf '%s' "$cat" | jq -r '.reason')"
  while IFS= read -r pattern; do
    printf '%s' "$NORM_STRIPPED" | grep -qiF "$pattern" || continue
    if [ "$mode" = "warn" ]; then
      [ -n "$advisory" ] || advisory="⚠️ Advisory: $reason"
      continue
    fi
    deny "$reason"
  done < <(printf '%s' "$cat" | jq -r '.blocked[]? // empty')
done < <(printf '%s' "$POLICY" | jq -c '.categories | to_entries[] | {mode:.value.mode,reason:.value.reason,blocked:.value.blocked}')

[ -n "$advisory" ] && printf '%s\n' "$advisory" >&2
exit 0
```

Run `chmod +x .github/hooks/scripts/pre-tool-guard.sh` after creating.

## `.github/hooks/scripts/pre-tool-guard.ps1`

```powershell
$ErrorActionPreference = 'Stop'
# Force UTF-8 output so non-ASCII characters survive ConvertTo-Json on all PS versions
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

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

# toolArgs is a JSON string — parse it a second time
$toolArgsRaw = [string]$payload.toolArgs
if ([string]::IsNullOrWhiteSpace($toolArgsRaw)) { exit 0 }
try { $toolArgs = $toolArgsRaw | ConvertFrom-Json } catch { exit 0 }

$command = Get-ToolCommand $toolArgs
if ([string]::IsNullOrWhiteSpace($command)) { exit 0 }
$norm = $command.ToLowerInvariant()
$normStripped = $norm -replace '"[^"]*"', '' -replace "'[^']*'", ''

$repoRoot   = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$policyPath = Join-Path $repoRoot 'hooks\tool-guard\policy.json'
if (-not (Test-Path $policyPath)) { exit 0 }
$policy = Get-Content $policyPath -Raw | ConvertFrom-Json

function Deny([string]$reason) {
    # -EscapeHandling EscapeNonAscii encodes emoji as \uXXXX in JSON output (PS 7.1+)
    @{ permissionDecision = 'deny'; permissionDecisionReason = $reason } | ConvertTo-Json -Compress -EscapeHandling EscapeNonAscii
    exit 0
}

# Use char codes for ⚠️ (U+26A0 U+FE0F) — avoids source-file encoding issues on Windows
$warn = "$([char]0x26A0)$([char]0xFE0F)"
$advisory = $null

foreach ($rule in $policy.extra_banned_commands) {
    $pattern = ([string]$rule.pattern).ToLowerInvariant()
    if (-not $normStripped.Contains($pattern)) { continue }
    if ([string]$rule.mode -eq 'warn') {
        if ([string]::IsNullOrWhiteSpace($advisory)) { $advisory = "$warn Advisory: $([string]$rule.reason)" }
        continue
    }
    Deny ([string]$rule.reason)
}

foreach ($prop in $policy.categories.PSObject.Properties) {
    $cat    = $prop.Value
    $mode   = [string]$cat.mode
    $reason = [string]$cat.reason
    foreach ($pattern in $cat.blocked) {
        if (-not $normStripped.Contains($pattern.ToLowerInvariant())) { continue }
        if ($mode -eq 'warn') {
            if ([string]::IsNullOrWhiteSpace($advisory)) { $advisory = "$warn Advisory: $reason" }
            continue
        }
        Deny $reason
    }
}

if (-not [string]::IsNullOrWhiteSpace($advisory)) { [Console]::Error.WriteLine($advisory) }
exit 0
```

## Test commands

```bash
# Should allow
echo '{"toolName":"bash","toolArgs":"{\"command\":\"git status\"}"}' \
  | .github/hooks/scripts/pre-tool-guard.sh

# Should warn only (non-blocking; advisory on stderr)
echo '{"toolName":"bash","toolArgs":"{\"command\":\"npm install\"}"}' \
  | .github/hooks/scripts/pre-tool-guard.sh

# Should allow (quoted text content is ignored for matching)
echo '{"toolName":"bash","toolArgs":"{\"command\":\"git commit -m \\\"contains npm run text only\\\"\"}"}' \
  | .github/hooks/scripts/pre-tool-guard.sh
```

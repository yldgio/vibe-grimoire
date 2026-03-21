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
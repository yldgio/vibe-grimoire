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
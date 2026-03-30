#!/usr/bin/env bash
# ==============================================================================
# install-immortals.sh
#
# Usage:
#   bash <(curl -fsSL https://raw.githubusercontent.com/yldgio/vibe-grimoire/main/install-immortals.sh)
#   # or, if you've cloned the repo:
#   bash install-immortals.sh
#
# Description:
#   Installs "The Immortals" agent skills and agent definition files into your
#   project. Skills land in .agents/skills/<name>/SKILL.md and agent definitions
#   land in .github/agents/<name>.agent.md, both relative to the directory you
#   run the script from.
#
#   If a target file already exists you will be prompted before it is
#   overwritten (default: No).
# ==============================================================================

set -euo pipefail

BASE_URL="https://raw.githubusercontent.com/yldgio/vibe-grimoire/main"

# ---------------------------------------------------------------------------
# Source → destination mapping
# Format: "src_path|dest_path|type"
# ---------------------------------------------------------------------------
SKILLS=(
  "skills/design-patterns/SKILL.md|.agents/skills/design-patterns/SKILL.md"
  "skills/clean-code/SKILL.md|.agents/skills/clean-code/SKILL.md"
  "skills/refactoring/SKILL.md|.agents/skills/refactoring/SKILL.md"
  "skills/domain-driven-design/SKILL.md|.agents/skills/domain-driven-design/SKILL.md"
  "skills/performance-review/SKILL.md|.agents/skills/performance-review/SKILL.md"
  "skills/the-immortals/SKILL.md|.agents/skills/the-immortals/SKILL.md"
)

AGENTS=(
  ".github/agents/fowler.agent.md|.github/agents/fowler.agent.md"
  ".github/agents/beck.agent.md|.github/agents/beck.agent.md"
  ".github/agents/uncle-bob.agent.md|.github/agents/uncle-bob.agent.md"
  ".github/agents/evans.agent.md|.github/agents/evans.agent.md"
  ".github/agents/linus.agent.md|.github/agents/linus.agent.md"
  ".github/agents/the-immortals.agent.md|.github/agents/the-immortals.agent.md"
)

# ---------------------------------------------------------------------------
# Counters
# ---------------------------------------------------------------------------
skills_installed=0
agents_installed=0
skipped=0

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
check_curl() {
  if ! command -v curl &>/dev/null; then
    echo "❌ curl is required but was not found. Please install curl and try again." >&2
    exit 1
  fi
}

# prompt_overwrite <path>  →  returns 0 (yes) or 1 (no)
prompt_overwrite() {
  local path="$1"
  printf "⚠️  Overwrite %s? [y/N] " "$path"
  local answer
  read -r answer
  case "$answer" in
    [Yy]*) return 0 ;;
    *)     return 1 ;;
  esac
}

# download_file <src_relative> <dest_path>  →  returns 0 on success, 1 on failure
download_file() {
  local src="$1"
  local dest="$2"
  local url="${BASE_URL}/${src}"

  mkdir -p "$(dirname "$dest")"

  if curl -fsSL -o "$dest" "$url"; then
    return 0
  else
    echo "  ❌ Download failed: $url" >&2
    return 1
  fi
}

# install_item <src> <dest> <type>
# type is "skill" or "agent"
install_item() {
  local src="$1"
  local dest="$2"
  local type="$3"

  if [[ -f "$dest" ]]; then
    if ! prompt_overwrite "$dest"; then
      echo "  ⏭  Skipped: $dest"
      (( skipped++ )) || true
      return
    fi
  fi

  printf "  ⬇  %s → %s\n" "$src" "$dest"
  if download_file "$src" "$dest"; then
    if [[ "$type" == "skill" ]]; then
      (( skills_installed++ )) || true
    else
      (( agents_installed++ )) || true
    fi
  else
    (( skipped++ )) || true
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
check_curl

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🧙 Installing The Immortals — Skills & Agents"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# --- Skills -----------------------------------------------------------------
echo "📚 Skills → .agents/skills/"
echo ""
for entry in "${SKILLS[@]}"; do
  IFS='|' read -r src dest <<< "$entry"
  install_item "$src" "$dest" "skill"
done

echo ""

# --- Agents -----------------------------------------------------------------
echo "🤖 Agents → .github/agents/"
echo ""
for entry in "${AGENTS[@]}"; do
  IFS='|' read -r src dest <<< "$entry"
  install_item "$src" "$dest" "agent"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ ${skills_installed} skills installed, ${agents_installed} agents installed, ${skipped} skipped."
echo ""
echo "For Claude Code & OpenCode, see docs/installing-agents.md"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

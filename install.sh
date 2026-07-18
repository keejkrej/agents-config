#!/usr/bin/env bash
# Install agent configs from this repo into user/global tool directories.
#
# Codex  -> ~/.codex
# opencode -> ~/.config/opencode
# Cursor -> ~/.cursor/rules/orchestration.mdc + ~/.cursor/agents/
# Grok   -> ~/.grok/AGENTS.md + ~/.grok/agents/ + ~/.grok/config.toml
#
# Usage:
#   ./install.sh              # install all four
#   ./install.sh codex opencode  # install only selected tools
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS=()

usage() {
  cat <<EOF
Usage: ./install.sh [codex] [opencode] [cursor] [grok]

Without arguments, installs all four to their user/global directories.
EOF
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage;;
    all) TOOLS=(codex opencode cursor grok); shift;;
    codex|opencode|cursor|grok) TOOLS+=("$1"); shift;;
    *) echo "Unknown option: $1" >&2; usage;;
  esac
done

if [[ ${#TOOLS[@]} -eq 0 ]]; then
  TOOLS=(codex opencode cursor grok)
fi

backup_and_copy() {
  local src="$1" dest="$2"
  local dest_dir
  dest_dir="$(dirname "$dest")"
  mkdir -p "$dest_dir"
  if [[ -e "$dest" ]]; then
    mv "$dest" "$dest.bak.$(date +%s)"
    echo "  backed up $(basename "$dest")"
  fi
  cp "$src" "$dest"
  echo "  copied $(basename "$src")"
}

install_codex() {
  local dest_dir="${CODEX_DIR:-$HOME/.codex}"
  echo "==> Installing Codex config to $dest_dir"
  mkdir -p "$dest_dir" "$dest_dir/agents"
  backup_and_copy "$HERE/codex/instructions.md" "$dest_dir/AGENTS.md"
  for f in "$HERE/codex/agents/"*.toml; do
    [[ -e "$f" ]] || continue
    backup_and_copy "$f" "$dest_dir/agents/$(basename "$f")"
  done
  if [[ ! -d "$HERE/codex/node_modules/smol-toml" ]]; then
    npm install --prefix "$HERE/codex" --omit=dev --no-fund --no-audit
  fi
  node "$HERE/codex/scripts/merge_config.mjs" "$HERE/codex/config.toml" "$dest_dir/config.toml"
}

install_opencode() {
  local dest_dir="${OPENCODE_DIR:-$HOME/.config/opencode}"
  echo "==> Installing opencode config to $dest_dir"
  mkdir -p "$dest_dir" "$dest_dir/agent"
  backup_and_copy "$HERE/opencode/instructions.md" "$dest_dir/AGENTS.md"
  for f in "$HERE/opencode/agent/"*.md; do
    [[ -e "$f" ]] || continue
    backup_and_copy "$f" "$dest_dir/agent/$(basename "$f")"
  done
  if ! command -v node >/dev/null 2>&1; then
    echo "!! node not found; skipping opencode.json merge" >&2
  else
    node "$HERE/opencode/scripts/merge-json.mjs" "$HERE/opencode/opencode.json" "$dest_dir/opencode.json"
  fi
}

install_cursor() {
  local cursor_dir="${CURSOR_DIR:-$HOME/.cursor}"
  echo "==> Installing Cursor global config to $cursor_dir"
  mkdir -p "$cursor_dir/rules" "$cursor_dir/agents"

  {
    cat <<'FRONTMATTER'
---
name: Orchestration
description: Global orchestration guidance for Cursor
globs: ["**/*"]
alwaysApply: true
---

FRONTMATTER
    cat "$HERE/cursor/instructions.md"
  } > "$cursor_dir/rules/orchestration.mdc"
  echo "  wrote orchestration.mdc"

  for f in "$HERE/cursor/agents/"*.md; do
    [[ -e "$f" ]] || continue
    backup_and_copy "$f" "$cursor_dir/agents/$(basename "$f")"
  done
}

ensure_grok_subagents() {
  local grok_dir="$1"
  local config="$grok_dir/config.toml"
  if [[ -e "$config" ]]; then
    if grep -q '^\s*\[subagents\]\s*$' "$config" 2>/dev/null; then
      echo "  $config already has a [subagents] section; leaving it unchanged"
    else
      cat >> "$config" <<'EOF'

[subagents]
enabled = true
EOF
      echo "  appended [subagents] enabled = true to $config"
    fi
  else
    cp "$HERE/grok/config.toml" "$config"
    echo "  copied config.toml (subagents enabled)"
  fi
}

install_grok() {
  local grok_dir="${GROK_DIR:-$HOME/.grok}"
  echo "==> Installing Grok global config to $grok_dir"
  mkdir -p "$grok_dir" "$grok_dir/agents"
  backup_and_copy "$HERE/grok/instructions.md" "$grok_dir/AGENTS.md"
  for f in "$HERE/grok/agents/"*.md; do
    [[ -e "$f" ]] || continue
    backup_and_copy "$f" "$grok_dir/agents/$(basename "$f")"
  done
  ensure_grok_subagents "$grok_dir"
}

for t in "${TOOLS[@]}"; do
  case "$t" in
    codex) install_codex;;
    opencode) install_opencode;;
    cursor) install_cursor;;
    grok) install_grok;;
  esac
done

echo
echo "==> Done."

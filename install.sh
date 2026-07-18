#!/usr/bin/env bash
# Install agent configs from this repo into the target tool directories.
#
# Codex and opencode always go to user config.
# Cursor and Grok are project-scoped by default; use --global to install them
# to the user-level directories (~/.cursor/rules/ and ~/.grok/AGENTS.md).
#
# Usage:
#   ./install.sh [codex] [opencode] [cursor] [grok]
#   ./install.sh --global [codex] [opencode] [cursor] [grok]
#   ./install.sh --global                    # installs all four
#   PROJECT_DIR=/path/to/project ./install.sh cursor grok
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-}"
GLOBAL=0
TOOLS=()

usage() {
  cat <<EOF
Usage: ./install.sh [options] [codex] [opencode] [cursor] [grok]

Options:
  -g, --global   Install cursor/grok to user/global dirs instead of PROJECT_DIR.
                 Without tools, -g installs all four.

Environment:
  PROJECT_DIR    Required for cursor/grok when not using --global.

Examples:
  ./install.sh                              # codex + opencode
  ./install.sh codex opencode               # same
  ./install.sh -g                           # all four to user/global dirs
  ./install.sh -g cursor grok               # cursor + grok globally
  PROJECT_DIR=/my/project ./install.sh cursor grok
EOF
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -g|--global) GLOBAL=1; shift;;
    -h|--help) usage;;
    all) TOOLS=(codex opencode cursor grok); shift;;
    codex|opencode|cursor|grok) TOOLS+=("$1"); shift;;
    *) echo "Unknown option: $1" >&2; usage;;
  esac
done

if [[ ${#TOOLS[@]} -eq 0 ]]; then
  if [[ $GLOBAL -eq 1 ]]; then
    TOOLS=(codex opencode cursor grok)
  else
    TOOLS=(codex opencode)
  fi
fi

for t in "${TOOLS[@]}"; do
  if [[ "$t" == "cursor" || "$t" == "grok" ]]; then
    if [[ $GLOBAL -eq 0 ]] && [[ -z "$PROJECT_DIR" ]]; then
      echo "Error: PROJECT_DIR is required for cursor/grok without --global" >&2
      usage
    fi
  fi
done

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

install_cursor_global() {
  local cursor_dir="${CURSOR_DIR:-$HOME/.cursor}"
  echo "==> Installing Cursor global config to $cursor_dir"
  mkdir -p "$cursor_dir/rules" "$cursor_dir/agents"

  # .mdc rules need YAML frontmatter; AGENTS.md is plain markdown.
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

install_cursor_project() {
  local dest_dir="$PROJECT_DIR"
  echo "==> Installing Cursor project config to $dest_dir"
  mkdir -p "$dest_dir"
  backup_and_copy "$HERE/cursor/instructions.md" "$dest_dir/AGENTS.md"
  if [[ -d "$HERE/cursor/agents" ]]; then
    mkdir -p "$dest_dir/.cursor/agents"
    for f in "$HERE/cursor/agents/"*.md; do
      [[ -e "$f" ]] || continue
      backup_and_copy "$f" "$dest_dir/.cursor/agents/$(basename "$f")"
    done
  fi
}

install_cursor() {
  if [[ $GLOBAL -eq 1 ]]; then
    install_cursor_global
  else
    install_cursor_project
  fi
}

install_grok_global() {
  local grok_dir="${GROK_DIR:-$HOME/.grok}"
  echo "==> Installing Grok global config to $grok_dir"
  mkdir -p "$grok_dir" "$grok_dir/agents"
  backup_and_copy "$HERE/grok/instructions.md" "$grok_dir/AGENTS.md"
  for f in "$HERE/grok/agents/"*.md; do
    [[ -e "$f" ]] || continue
    backup_and_copy "$f" "$grok_dir/agents/$(basename "$f")"
  done

  if [[ -e "$grok_dir/config.toml" ]]; then
    echo "  $grok_dir/config.toml already exists; not overwriting."
    echo "  Make sure it contains: [subagents] enabled = true"
  else
    cp "$HERE/grok/config.toml" "$grok_dir/config.toml"
    echo "  copied config.toml (subagents enabled)"
  fi
}

install_grok_project() {
  local dest_dir="$PROJECT_DIR"
  echo "==> Installing Grok project config to $dest_dir"
  mkdir -p "$dest_dir"
  backup_and_copy "$HERE/grok/instructions.md" "$dest_dir/AGENTS.md"
  if [[ -d "$HERE/grok/agents" ]]; then
    mkdir -p "$dest_dir/.grok/agents"
    for f in "$HERE/grok/agents/"*.md; do
      [[ -e "$f" ]] || continue
      backup_and_copy "$f" "$dest_dir/.grok/agents/$(basename "$f")"
    done
  fi
}

install_grok() {
  if [[ $GLOBAL -eq 1 ]]; then
    install_grok_global
  else
    install_grok_project
  fi
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

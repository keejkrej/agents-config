#!/usr/bin/env bash
# Install agent configs from this repo into the target tool directories.
#
# Codex and opencode go to user config by default.
# Cursor and Grok are project-scoped, so set PROJECT_DIR to the target project.
#
# Usage:
#   ./install.sh [codex] [opencode] [cursor] [grok]
#   PROJECT_DIR=/path/to/project ./install.sh cursor grok
#   ./install.sh
#
# Without arguments, codex and opencode are installed.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-}"
TOOLS=()

usage() {
  cat <<EOF
Usage: PROJECT_DIR=/path/to/project ./install.sh [codex] [opencode] [cursor] [grok]

Without arguments, installs codex and opencode into user config.

Examples:
  ./install.sh                    # codex + opencode
  ./install.sh codex opencode       # same
  PROJECT_DIR=/my/project ./install.sh cursor grok
  PROJECT_DIR=/my/project ./install.sh all
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
  TOOLS=(codex opencode)
fi

for t in "${TOOLS[@]}"; do
  if [[ "$t" == "cursor" || "$t" == "grok" ]] && [[ -z "$PROJECT_DIR" ]]; then
    echo "Error: PROJECT_DIR is required for cursor/grok" >&2
    usage
  fi
done

backup_and_copy() {
  local src="$1" dest="$2"
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
  local dest_dir="$PROJECT_DIR"
  echo "==> Installing Cursor config to $dest_dir"
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

install_grok() {
  local dest_dir="$PROJECT_DIR"
  echo "==> Installing Grok config to $dest_dir"
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

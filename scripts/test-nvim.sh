#!/usr/bin/env bash
set -euo pipefail

# Headless-load check for the Neovim config: install plugins, then confirm the
# config loads with no Lua/startup errors. The Neovim analog of the WezTerm
# `ls-fonts` check. Runs against an isolated copy of the repo's nvim/ so it never
# touches the user's live config or mutates the committed lazy-lock.json.
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v nvim >/dev/null 2>&1; then
  echo "test-nvim: neovim not found (brew install neovim)" >&2
  exit 1
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
export XDG_CONFIG_HOME="$work/config"
export XDG_DATA_HOME="$work/data"
export XDG_STATE_HOME="$work/state"
export XDG_CACHE_HOME="$work/cache"
mkdir -p "$XDG_CONFIG_HOME"
cp -R "$repo_root/nvim" "$XDG_CONFIG_HOME/nvim"

# Install plugins headlessly (network: clones from GitHub).
nvim --headless "+Lazy! sync" +qa >/dev/null 2>&1 || true

# Load once more, force-loading every lazy plugin (so event/cmd/keys-gated
# plugins like treesitter, telescope, gitsigns, diffview, lazygit, and
# mini.pairs actually run their setup) and opening a real .lua buffer (so the
# lua treesitter/highlight path is exercised), then fail on any error output.
# A clean config is silent.
out="$(nvim --headless +'Lazy! load all' +"edit $XDG_CONFIG_HOME/nvim/init.lua" +qa 2>&1 >/dev/null)" || true
if printf '%s' "$out" | grep -qiE 'error|E[0-9]+:|stack traceback'; then
  echo "test-nvim: startup produced errors:" >&2
  printf '%s\n' "$out" >&2
  exit 1
fi

echo "nvim config loads clean"

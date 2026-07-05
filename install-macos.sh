#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
timestamp="$(date +%Y%m%d-%H%M%S)"
mode="copy"

usage() {
  cat <<'EOF'
Usage: ./install-macos.sh [--copy|--link]

  --copy  Copy files into ~/.config/wezterm and ~/.tmux.conf. Best for another Mac.
  --link  Symlink live config to this dotfiles folder. Best while editing locally.
EOF
}

case "${1:---copy}" in
  --copy)
    mode="copy"
    ;;
  --link)
    mode="link"
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

backup_if_needed() {
  local source="$1"
  local target="$2"

  if [[ -e "$target" || -L "$target" ]]; then
    if cmp -s "$source" "$target"; then
      return
    fi

    cp -p "$target" "$target.backup-$timestamp"
    printf 'Backed up %s\n' "$target"
  fi
}

install_file() {
  local source="$1"
  local target="$2"
  local mode="${3:-0644}"

  backup_if_needed "$source" "$target"
  install -m "$mode" "$source" "$target"
  printf 'Installed %s\n' "$target"
}

link_path() {
  local source="$1"
  local target="$2"

  mkdir -p "$(dirname "$target")"

  if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$source" ]]; then
    printf 'Already linked %s\n' "$target"
    return
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    mv "$target" "$target.backup-$timestamp"
    printf 'Backed up %s\n' "$target"
  fi

  ln -s "$source" "$target"
  printf 'Linked %s -> %s\n' "$target" "$source"
}

mkdir -p "$HOME/.config/wezterm/modules"
mkdir -p "$HOME/.config/wezterm/assets"
mkdir -p "$HOME/.local/bin"

if [[ "$mode" == "link" ]]; then
  link_path "$root_dir/wezterm/.wezterm.lua" "$HOME/.wezterm.lua"
  link_path "$root_dir/wezterm" "$HOME/.config/wezterm"
  link_path "$root_dir/tmux/tmux.conf" "$HOME/.tmux.conf"
  link_path "$root_dir/tmux/tmux-llm-status" "$HOME/.local/bin/tmux-llm-status"

  printf '\nLinked WezTerm + tmux config for local editing.\n'
  printf 'Edit files in %s and reload WezTerm with Cmd-r if needed.\n' "$root_dir"
  printf 'Reload tmux with: Ctrl-a r\n'
  exit 0
fi

install_file "$root_dir/wezterm/.wezterm.lua" "$HOME/.wezterm.lua"
install_file "$root_dir/wezterm/wezterm.lua" "$HOME/.config/wezterm/wezterm.lua"

for module in "$root_dir"/wezterm/modules/*.lua; do
  install_file "$module" "$HOME/.config/wezterm/modules/$(basename "$module")"
done

while IFS= read -r asset; do
  relative_asset="${asset#"$root_dir"/wezterm/assets/}"
  target_asset="$HOME/.config/wezterm/assets/$relative_asset"
  mkdir -p "$(dirname "$target_asset")"
  install_file "$asset" "$target_asset"
done < <(find "$root_dir/wezterm/assets" -type f ! -name '.DS_Store' | sort)

install_file "$root_dir/tmux/tmux.conf" "$HOME/.tmux.conf"
install_file "$root_dir/tmux/tmux-llm-status" "$HOME/.local/bin/tmux-llm-status" 0755

printf '\nInstalled WezTerm + tmux config for macOS.\n'
printf 'Reload WezTerm, then reload tmux with: Ctrl-a r\n'

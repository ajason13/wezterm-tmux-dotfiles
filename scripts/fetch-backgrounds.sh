#!/usr/bin/env bash
set -euo pipefail

base_url="${BACKGROUNDS_BASE_URL:-https://github.com/ajason13/wezterm-tmux-dotfiles/releases/download/backgrounds}"

dest=""
refresh=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dest) dest="${2:?--dest requires a path}"; shift 2 ;;
    --refresh) refresh=true; shift ;;
    *) echo "fetch-backgrounds: unknown argument '$1'" >&2; exit 2 ;;
  esac
done

[[ -n "$dest" ]] || { echo "fetch-backgrounds: --dest is required" >&2; exit 2; }

warn() { echo "fetch-backgrounds: $*" >&2; }

marker="$(dirname "$dest")/.backgrounds-version"

remote_sha="$(curl -fsSL "$base_url/backgrounds.sha256" 2>/dev/null || true)"
if [[ -z "$remote_sha" ]]; then
  warn "could not fetch checksum from $base_url; leaving backgrounds unchanged"
  exit 0
fi

if [[ "$refresh" != true && -f "$marker" && "$(cat "$marker")" == "$remote_sha" ]]; then
  echo "backgrounds already up to date"
  exit 0
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

if ! curl -fsSL "$base_url/backgrounds.tar.gz" -o "$tmp/backgrounds.tar.gz"; then
  warn "could not download tarball from $base_url; leaving backgrounds unchanged"
  exit 0
fi

got="$(shasum -a 256 "$tmp/backgrounds.tar.gz" | awk '{print $1}')"
if [[ "$got" != "${remote_sha%% *}" ]]; then
  warn "checksum mismatch; leaving backgrounds unchanged"
  exit 0
fi

mkdir -p "$dest"
tar -xzf "$tmp/backgrounds.tar.gz" -C "$dest"
printf '%s\n' "$remote_sha" > "$marker"
echo "backgrounds updated"

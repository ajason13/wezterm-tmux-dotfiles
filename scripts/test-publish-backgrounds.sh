#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="$repo_root/scripts/publish-backgrounds.sh"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

fail() { echo "test failed: $*" >&2; exit 1; }

# Fixture asset tree
asset_dir="$tmp_dir/assets"
mkdir -p "$asset_dir/100-vehicles"
printf 'img-bytes' > "$asset_dir/100-vehicles/a.png"

out_dir="$tmp_dir/out"
mkdir -p "$out_dir"

BACKGROUND_ASSET_DIR="$asset_dir" "$script" --build-only "$out_dir" >/dev/null 2>&1 \
  || fail "build-only run failed"

[[ -f "$out_dir/backgrounds.tar.gz" ]] || fail "tarball not created"
[[ -f "$out_dir/backgrounds.sha256" ]] || fail "checksum not created"

# Checksum in the sidecar matches the tarball
recorded="$(awk '{print $1}' "$out_dir/backgrounds.sha256")"
actual="$(shasum -a 256 "$out_dir/backgrounds.tar.gz" | awk '{print $1}')"
[[ "$recorded" == "$actual" ]] || fail "recorded checksum does not match tarball"

# Tarball contains the fixture image at the expected relative path
tar -tzf "$out_dir/backgrounds.tar.gz" | grep -q '100-vehicles/a.png' \
  || fail "tarball missing expected entry"

echo "publish-backgrounds tests passed"

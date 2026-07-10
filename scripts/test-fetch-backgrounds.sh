#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="$repo_root/scripts/fetch-backgrounds.sh"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

fail() { echo "test failed: $*" >&2; exit 1; }

# Build a fixture "release" served over file://
release="$tmp_dir/release"
mkdir -p "$release/src/100-vehicles"
printf 'img-bytes' > "$release/src/100-vehicles/a.png"
tar -czf "$release/backgrounds.tar.gz" -C "$release/src" .
( cd "$release" && shasum -a 256 "backgrounds.tar.gz" > "backgrounds.sha256" )

dest="$tmp_dir/dest/backgrounds"
export BACKGROUNDS_BASE_URL="file://$release"

# First run extracts
"$script" --dest "$dest" >/dev/null 2>&1 || fail "first fetch failed"
[[ -f "$dest/100-vehicles/a.png" ]] || fail "asset not extracted"
[[ -f "$tmp_dir/dest/.backgrounds-version" ]] || fail "marker not written"

# Second run is a no-op (checksum matches) - remove asset, expect NOT re-created
rm -f "$dest/100-vehicles/a.png"
"$script" --dest "$dest" >/dev/null 2>&1 || fail "second fetch errored"
[[ ! -f "$dest/100-vehicles/a.png" ]] || fail "expected no re-download when checksum matches"

# --refresh forces re-extract
"$script" --dest "$dest" --refresh >/dev/null 2>&1 || fail "refresh fetch failed"
[[ -f "$dest/100-vehicles/a.png" ]] || fail "refresh did not re-extract"

# Missing release is non-fatal
export BACKGROUNDS_BASE_URL="file://$tmp_dir/does-not-exist"
"$script" --dest "$tmp_dir/dest2/backgrounds" >/dev/null 2>&1 \
  || fail "missing release should not exit non-zero"

echo "fetch-backgrounds tests passed"

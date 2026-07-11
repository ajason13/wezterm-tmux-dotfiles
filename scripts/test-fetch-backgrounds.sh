#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="$repo_root/scripts/fetch-backgrounds.sh"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

fail() { echo "test failed: $*" >&2; exit 1; }

# Build fixture "releases" served over file://
release="$tmp_dir/release"
mkdir -p "$release/backgrounds-vehicles/src/100-vehicles" "$release/backgrounds-anime/src/200-anime"
printf 'img-bytes' > "$release/backgrounds-vehicles/src/100-vehicles/a.png"
printf 'img-bytes-2' > "$release/backgrounds-anime/src/200-anime/b.png"
tar -czf "$release/backgrounds-vehicles/backgrounds.tar.gz" -C "$release/backgrounds-vehicles/src" 100-vehicles
( cd "$release/backgrounds-vehicles" && shasum -a 256 "backgrounds.tar.gz" > "backgrounds.sha256" )
tar -czf "$release/backgrounds-anime/backgrounds.tar.gz" -C "$release/backgrounds-anime/src" 200-anime
( cd "$release/backgrounds-anime" && shasum -a 256 "backgrounds.tar.gz" > "backgrounds.sha256" )

dest="$tmp_dir/dest/backgrounds"
export BACKGROUNDS_BASE_URL_PREFIX="file://$release"

# First run extracts
"$script" --dest "$dest" >/dev/null 2>&1 || fail "first fetch failed"
[[ -f "$dest/100-vehicles/a.png" ]] || fail "asset not extracted"
[[ -f "$dest/200-anime/b.png" ]] || fail "anime asset not extracted"
[[ -f "$tmp_dir/dest/.backgrounds-version-vehicles" ]] || fail "vehicle marker not written"
[[ -f "$tmp_dir/dest/.backgrounds-version-anime" ]] || fail "anime marker not written"

# Second run with a populated dest + matching checksum is a no-op (up to date)
out="$("$script" --dest "$dest" 2>&1)" || fail "second fetch errored"
[[ "$out" == *"background bundle 'vehicles' already up to date"* ]] || fail "expected vehicle no-op when populated and checksum matches"
[[ "$out" == *"background bundle 'anime' already up to date"* ]] || fail "expected anime no-op when populated and checksum matches"
[[ -f "$dest/100-vehicles/a.png" ]] || fail "no-op should leave the asset in place"

# Self-heal: if the local tree is missing/emptied, re-fetch even when the marker matches
rm -f "$dest/100-vehicles/a.png"
"$script" --dest "$dest" >/dev/null 2>&1 || fail "self-heal fetch errored"
[[ -f "$dest/100-vehicles/a.png" ]] || fail "expected self-heal re-extract when dest is empty"

# --refresh forces re-extract
"$script" --dest "$dest" --refresh >/dev/null 2>&1 || fail "refresh fetch failed"
[[ -f "$dest/100-vehicles/a.png" ]] || fail "refresh did not re-extract"

# Missing release is non-fatal
export BACKGROUNDS_BASE_URL_PREFIX="file://$tmp_dir/does-not-exist"
"$script" --dest "$tmp_dir/dest2/backgrounds" >/dev/null 2>&1 \
  || fail "missing release should not exit non-zero"

echo "fetch-backgrounds tests passed"

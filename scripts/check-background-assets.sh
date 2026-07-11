#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=scripts/background-bundles.sh
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
background_dir="$repo_root/wezterm/assets/backgrounds"
source "$repo_root/scripts/background-bundles.sh"
max_file_bytes=$((2560 * 1024))

fail() {
  echo "background asset check failed: $*" >&2
  exit 1
}

total_bytes=0
file_count=0
while IFS= read -r file; do
  file_count=$((file_count + 1))
  # wc -c is portable; `stat` size flags differ between macOS (-f%z) and Linux (-c%s).
  bytes=$(wc -c < "$file")
  total_bytes=$((total_bytes + bytes))
  if (( bytes > max_file_bytes )); then
    rel="${file#"$repo_root"/}"
    fail "$rel is ${bytes} bytes, above the ${max_file_bytes} byte limit"
  fi
done <<EOF
$(find "$background_dir" -type f \( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' \) | sort)
EOF

(( file_count > 0 )) || fail "no background assets found"

while IFS='|' read -r bundle_name _ bundle_path bundle_limit; do
  [[ -n "$bundle_name" ]] || continue
  bundle_dir="$background_dir/$bundle_path"
  [[ -d "$bundle_dir" ]] || continue

  bundle_bytes=0
  while IFS= read -r file; do
    [[ -n "$file" ]] || continue
    bundle_bytes=$((bundle_bytes + $(wc -c < "$file")))
  done <<EOF
$(find "$bundle_dir" -type f \( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' \) | sort)
EOF

  if (( bundle_bytes > bundle_limit )); then
    fail "${bundle_name} bundle total ${bundle_bytes} bytes, above the ${bundle_limit} byte limit"
  fi
done < <(background_bundles)

echo "background assets OK: ${file_count} files, ${total_bytes} bytes total"

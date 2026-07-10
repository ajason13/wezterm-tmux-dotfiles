# Backgrounds via GitHub Release + History Reclaim - Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver wallpaper assets from a GitHub Release tarball fetched at install time (instead of committing them to git), then reclaim the existing ~122 MB of history.

**Architecture:** Manifests (text) stay in git and define the wallpaper allowlist; the image bytes ship as a rolling `backgrounds` Release asset (`backgrounds.tar.gz` + `backgrounds.sha256`). A standalone `fetch-backgrounds.sh` (called by `install-macos.sh`) downloads and extracts them idempotently via checksum. A `publish-backgrounds.sh` builds and uploads the tarball. History reclaim is a sequenced, manual runbook done last.

**Tech Stack:** bash (matching existing repo scripts), `gh` CLI, `curl`, `tar`, `shasum`, `git filter-repo`, GitHub Actions.

## Global Constraints

- Bash scripts start with `#!/usr/bin/env bash` and `set -euo pipefail`; use the repo's `repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"` and `fail()` conventions - copied verbatim from existing scripts.
- All shell scripts must pass `shellcheck` (repo has a CI gate) and `bash -n`.
- Portability: run on both macOS (BSD tools) and the Linux CI runner. Prefer `wc -c`/`shasum -a 256` over BSD-only flags.
- New scripts must be `chmod +x` and added to the CI `bash -n`, `shellcheck`, and `test -x` lists.
- No em dashes in files (use `-`). No Jira/issue IDs in code comments.
- Repo is public: install downloads use unauthenticated `curl`; publishing uses `gh` as owner `ajason13`.
- Rolling Release tag is literally `backgrounds`; asset names are literally `backgrounds.tar.gz` and `backgrounds.sha256`.

---

### Task 1: Manifest path validator (CI-safe, no image files needed)

**Files:**
- Create: `scripts/check-manifest-paths.sh`
- Create: `scripts/test-check-manifest-paths.sh`

**Interfaces:**
- Produces: `scripts/check-manifest-paths.sh` - exits 0 when every quoted manifest entry ending in `.png`/`.jpg`/`.jpeg` is a relative path with no `..`; exits 1 otherwise. Honors `BACKGROUND_MANIFEST_DIR` env override (default `wezterm/modules/background_manifests`).

- [ ] **Step 1: Write the failing test**

Create `scripts/test-check-manifest-paths.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script="$repo_root/scripts/check-manifest-paths.sh"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

fail() { echo "test failed: $*" >&2; exit 1; }

make_manifest() {
  local name="$1" body="$2"
  local dir="$tmp_dir/$name"
  mkdir -p "$dir"
  printf '%s\n' "$body" > "$dir/general.lua"
  printf '%s' "$dir"
}

run_ok() {
  BACKGROUND_MANIFEST_DIR="$1" "$script" >/dev/null 2>&1 \
    || fail "expected pass for $1"
}

run_fail() {
  if BACKGROUND_MANIFEST_DIR="$1" "$script" >/dev/null 2>&1; then
    fail "expected failure for $1"
  fi
}

run_ok "$(make_manifest valid "return { '100-vehicles/a.png', '200-anime/b.jpg' }")"
run_fail "$(make_manifest absolute "return { '/etc/passwd.png' }")"
run_fail "$(make_manifest dotdot "return { '../secrets/a.png' }")"
run_fail "$(make_manifest empty "return { }")"

echo "check-manifest-paths tests passed"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash scripts/test-check-manifest-paths.sh`
Expected: FAIL - `check-manifest-paths.sh` does not exist yet (test errors on missing script / first `run_ok`).

- [ ] **Step 3: Write the script**

Create `scripts/check-manifest-paths.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
manifest_dir="${BACKGROUND_MANIFEST_DIR:-$repo_root/wezterm/modules/background_manifests}"

fail() {
  echo "manifest path check failed: $*" >&2
  exit 1
}

[[ -d "$manifest_dir" ]] || fail "missing manifest directory at $manifest_dir"

entry_count=0
while IFS= read -r entry; do
  [[ -n "$entry" ]] || continue
  entry_count=$((entry_count + 1))

  case "$entry" in
    /*) fail "entry '$entry' must be a relative path" ;;
  esac
  case "$entry" in
    *..*) fail "entry '$entry' must not contain '..'" ;;
  esac
done < <(
  grep -rhoE "'[^']*\.(png|jpg|jpeg)'" "$manifest_dir" 2>/dev/null \
    | sed "s/^'//; s/'\$//"
)

(( entry_count > 0 )) || fail "no manifest entries found in $manifest_dir"

echo "manifest paths OK: ${entry_count} entries"
```

- [ ] **Step 4: Make executable and run test to verify it passes**

Run: `chmod +x scripts/check-manifest-paths.sh scripts/test-check-manifest-paths.sh && bash scripts/test-check-manifest-paths.sh`
Expected: PASS - `check-manifest-paths tests passed`

- [ ] **Step 5: Verify it accepts the real manifests and passes shellcheck**

Run: `./scripts/check-manifest-paths.sh && shellcheck scripts/check-manifest-paths.sh scripts/test-check-manifest-paths.sh`
Expected: `manifest paths OK: N entries` and no shellcheck output.

- [ ] **Step 6: Commit**

```bash
git add scripts/check-manifest-paths.sh scripts/test-check-manifest-paths.sh
git commit -m "Add manifest path validator for CI"
```

---

### Task 2: Publish script (build tarball + checksum; upload via gh)

**Files:**
- Create: `scripts/publish-backgrounds.sh`
- Create: `scripts/test-publish-backgrounds.sh`

**Interfaces:**
- Consumes: `scripts/check-background-assets.sh` (existing size/manifest sanity check).
- Produces: `scripts/publish-backgrounds.sh`. With `--build-only <outdir>` it writes `<outdir>/backgrounds.tar.gz` and `<outdir>/backgrounds.sha256` from the working-tree images and exits 0 without touching GitHub. Without `--build-only` it also runs `gh release` upload to the rolling `backgrounds` tag. Honors `BACKGROUND_ASSET_DIR` (default `wezterm/assets/backgrounds`).

- [ ] **Step 1: Write the failing test**

Create `scripts/test-publish-backgrounds.sh`:

```bash
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash scripts/test-publish-backgrounds.sh`
Expected: FAIL - script does not exist.

- [ ] **Step 3: Write the script**

Create `scripts/publish-backgrounds.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
asset_dir="${BACKGROUND_ASSET_DIR:-$repo_root/wezterm/assets/backgrounds}"
release_tag="backgrounds"

fail() {
  echo "publish-backgrounds failed: $*" >&2
  exit 1
}

build_only=false
out_dir=""
if [[ "${1:-}" == "--build-only" ]]; then
  build_only=true
  out_dir="${2:?--build-only requires an output directory}"
  mkdir -p "$out_dir"
else
  out_dir="$(mktemp -d)"
  trap 'rm -rf "$out_dir"' EXIT
fi

[[ -d "$asset_dir" ]] || fail "missing asset directory at $asset_dir"
[[ -n "$(find "$asset_dir" -type f \( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' \) -print -quit)" ]] \
  || fail "no images found in $asset_dir"

# Validate against the real repo tree only (skipped for fixture/--build-only tests).
if [[ "$asset_dir" == "$repo_root/wezterm/assets/backgrounds" ]]; then
  [[ -x "$repo_root/scripts/check-background-assets.sh" ]] && "$repo_root/scripts/check-background-assets.sh"

  manifest_dir="$repo_root/wezterm/modules/background_manifests"
  if [[ -d "$manifest_dir" ]]; then
    entries="$(grep -rhoE "'[^']*\.(png|jpg|jpeg)'" "$manifest_dir" 2>/dev/null | sed "s/^'//; s/'\$//" | sort -u)"
    # Fail if a manifest references a file that is not present.
    while IFS= read -r entry; do
      [[ -n "$entry" ]] || continue
      [[ -f "$asset_dir/$entry" ]] || fail "manifest entry '$entry' has no file in $asset_dir"
    done < <(printf '%s\n' "$entries")
    # Warn (non-fatal) on image files not referenced by any manifest.
    while IFS= read -r file; do
      rel="${file#"$asset_dir"/}"
      printf '%s\n' "$entries" | grep -qxF "$rel" \
        || echo "note: $rel present but not listed in any manifest" >&2
    done < <(find "$asset_dir" -type f \( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' \) | sort)
  fi
fi

tarball="$out_dir/backgrounds.tar.gz"
checksum="$out_dir/backgrounds.sha256"

tar -czf "$tarball" -C "$asset_dir" .
( cd "$out_dir" && shasum -a 256 "backgrounds.tar.gz" > "backgrounds.sha256" )

echo "built $tarball ($(wc -c < "$tarball") bytes)"

if [[ "$build_only" == true ]]; then
  exit 0
fi

command -v gh >/dev/null 2>&1 || fail "gh CLI is required to publish"

if ! gh release view "$release_tag" >/dev/null 2>&1; then
  gh release create "$release_tag" \
    --title "Terminal backgrounds" \
    --notes "Rolling wallpaper bundle fetched by install-macos.sh."
fi

gh release upload "$release_tag" "$tarball" "$checksum" --clobber
echo "published to release '$release_tag'"
```

- [ ] **Step 4: Make executable and run test to verify it passes**

Run: `chmod +x scripts/publish-backgrounds.sh scripts/test-publish-backgrounds.sh && bash scripts/test-publish-backgrounds.sh`
Expected: PASS - `publish-backgrounds tests passed`

- [ ] **Step 5: shellcheck**

Run: `shellcheck scripts/publish-backgrounds.sh scripts/test-publish-backgrounds.sh`
Expected: no output.

- [ ] **Step 6: Commit**

```bash
git add scripts/publish-backgrounds.sh scripts/test-publish-backgrounds.sh
git commit -m "Add publish-backgrounds script (tarball + gh release)"
```

---

### Task 3: Fetch script (idempotent download + extract)

**Files:**
- Create: `scripts/fetch-backgrounds.sh`
- Create: `scripts/test-fetch-backgrounds.sh`

**Interfaces:**
- Consumes: a release base URL exposing `backgrounds.sha256` and `backgrounds.tar.gz`.
- Produces: `scripts/fetch-backgrounds.sh --dest <dir> [--refresh]`. Downloads the checksum; if it matches `<dir>/../.backgrounds-version` and `--refresh` is absent, no-ops. Otherwise downloads + verifies + extracts the tarball into `<dir>` and records the checksum in the marker. Never exits non-zero on network/download failure (warns and returns 0). Honors `BACKGROUNDS_BASE_URL` (default the GitHub releases download URL).

- [ ] **Step 1: Write the failing test**

Create `scripts/test-fetch-backgrounds.sh`:

```bash
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash scripts/test-fetch-backgrounds.sh`
Expected: FAIL - script does not exist.

- [ ] **Step 3: Write the script**

Create `scripts/fetch-backgrounds.sh`:

```bash
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
```

- [ ] **Step 4: Make executable and run test to verify it passes**

Run: `chmod +x scripts/fetch-backgrounds.sh scripts/test-fetch-backgrounds.sh && bash scripts/test-fetch-backgrounds.sh`
Expected: PASS - `fetch-backgrounds tests passed`

- [ ] **Step 5: shellcheck**

Run: `shellcheck scripts/fetch-backgrounds.sh scripts/test-fetch-backgrounds.sh`
Expected: no output.

- [ ] **Step 6: Commit**

```bash
git add scripts/fetch-backgrounds.sh scripts/test-fetch-backgrounds.sh
git commit -m "Add idempotent fetch-backgrounds script"
```

---

### Task 4: Wire fetch into installer, untrack assets, update CI + README

**Files:**
- Modify: `install-macos.sh` (add background-fetch step + flags)
- Modify: `.gitignore` (ignore images + marker)
- Modify: `.github/workflows/ci.yml` (drop in-tree asset-limit step; add new scripts to lint/test lists; add manifest-path check)
- Modify: `README.md` (document delivery model, flags, publish)
- Remove from tracking: `wezterm/assets/backgrounds/**` via `git rm -r --cached` (files stay on disk)

**Interfaces:**
- Consumes: `scripts/fetch-backgrounds.sh` from Task 3.

- [ ] **Step 1: Add background fetch to `install-macos.sh`**

`install-macos.sh` uses `mode` (`copy`/`link`), `dry_run` (string `"true"`/`"false"`), `root_dir`, and a `run()` dry-run wrapper. The link-mode block ends with `exit 0` (line 126); copy mode runs to the end. Make these exact edits:

**(a)** After the `dry_run="false"` line, add:
```bash
skip_backgrounds="false"
refresh_backgrounds="false"
```

**(b)** In `usage()`, add after the `--dry-run` description line:
```
  --skip-backgrounds     Do not download the wallpaper bundle.
  --refresh-backgrounds  Force re-download of the wallpaper bundle.
```

**(c)** In the arg-parsing `case`, add these arms before the `-h | --help)` arm:
```bash
    --skip-backgrounds)
      skip_backgrounds="true"
      ;;
    --refresh-backgrounds)
      refresh_backgrounds="true"
      ;;
```

**(d)** After the `link_path()` function definition, add this helper (uses `run` so `--dry-run` is honored automatically):
```bash
fetch_backgrounds() {
  local dest="$1"

  if [[ "$skip_backgrounds" == "true" ]]; then
    printf 'Skipping backgrounds fetch (--skip-backgrounds)\n'
    return
  fi

  local args=(--dest "$dest")
  if [[ "$refresh_backgrounds" == "true" ]]; then
    args+=(--refresh)
  fi

  run "$root_dir/scripts/fetch-backgrounds.sh" "${args[@]}"
}
```

**(e)** In the link-mode block, immediately before `exit 0`, add:
```bash
  fetch_backgrounds "$root_dir/wezterm/assets/backgrounds"
```

**(f)** At the very end of copy mode, before the final `printf '\nInstalled WezTerm + tmux config for macOS.\n'`, add:
```bash
fetch_backgrounds "$HOME/.config/wezterm/assets/backgrounds"
```

- [ ] **Step 2: Ignore assets and the marker in `.gitignore`**

Append:

```gitignore
# Wallpaper images are delivered via GitHub Release, not tracked in git.
wezterm/assets/backgrounds/
wezterm/assets/.backgrounds-version
```

- [ ] **Step 3: Update `.github/workflows/ci.yml`**

- Remove the `Check background asset limits` step (the images are no longer in the tree; size validation now happens in `publish-backgrounds.sh`).
- Add the three new scripts to the `bash -n`, `shellcheck`, and `test -x` lists.
- Add a step after the inbox check:

```yaml
      - name: Check manifest paths
        run: ./scripts/check-manifest-paths.sh
```

The `bash -n` and `shellcheck` lines should read (single line each):

```
install-macos.sh uninstall-macos.sh tmux/tmux-llm-status scripts/check-background-assets.sh scripts/check-background-inbox.sh scripts/test-check-background-inbox.sh scripts/check-manifest-paths.sh scripts/test-check-manifest-paths.sh scripts/publish-backgrounds.sh scripts/test-publish-backgrounds.sh scripts/fetch-backgrounds.sh scripts/test-fetch-backgrounds.sh
```

- [ ] **Step 4: Update `README.md`**

Under a "Backgrounds" section, replace any "add images under `wezterm/assets/backgrounds`" guidance with:

```markdown
Wallpapers are delivered as a GitHub Release asset, not committed to git.
`install-macos.sh` downloads `backgrounds.tar.gz` from the rolling `backgrounds`
release and extracts it (into the repo tree for `--link`, or `~/.config/wezterm`
for copy mode). Re-runs skip the download when the checksum is unchanged.

- Skip the fetch: `./install-macos.sh --skip-backgrounds`
- Force a re-download: `./install-macos.sh --refresh-backgrounds`

To publish a new set (repo owner): add/update images under
`wezterm/assets/backgrounds/`, list them in the manifests, then run
`./scripts/publish-backgrounds.sh`.
```

- [ ] **Step 5: Untrack the images (keep them on disk)**

Run:

```bash
git rm -r --cached --quiet wezterm/assets/backgrounds
git status --short | head
```

Expected: the background images show as staged deletions; the files remain in the working tree (`ls wezterm/assets/backgrounds` still lists them).

- [ ] **Step 6: Verify the config still loads and CI checks pass locally**

Run:

```bash
wezterm --config-file ~/.config/wezterm/wezterm.lua ls-fonts --text x 2>&1 | grep -iE "error|lua" || echo "config clean"
shellcheck install-macos.sh scripts/*.sh
bash scripts/test-check-manifest-paths.sh && bash scripts/test-publish-backgrounds.sh && bash scripts/test-fetch-backgrounds.sh && bash scripts/test-check-background-inbox.sh
./scripts/check-manifest-paths.sh
```

Expected: `config clean`, no shellcheck output, all test scripts pass, manifest check OK. (Wallpaper still renders locally because the on-disk files remain.)

- [ ] **Step 7: Commit**

```bash
git add install-macos.sh .gitignore .github/workflows/ci.yml README.md
git add -A wezterm/assets/backgrounds
git commit -m "Deliver backgrounds via Release; stop tracking image files"
```

---

### Task 5 (Runbook - manual, sequenced, partly irreversible): publish, verify, reclaim history

This task is operational, not TDD. Do the steps in order; do NOT start the rewrite until delivery is verified.

- [ ] **Step 1: Publish the first release (as `ajason13`)**

From the migration branch (assets still on disk), authenticated as the repo owner:

```bash
gh auth status   # confirm the active account can write to ajason13
./scripts/publish-backgrounds.sh
gh release view backgrounds
```

Expected: a `backgrounds` release exists with `backgrounds.tar.gz` and `backgrounds.sha256` assets.

- [ ] **Step 2: Open the migration PR and merge**

Push the branch to the `ajason14` fork and open a PR into `ajason13:main` (invoke the pr-description skill). Confirm CI is green (assets absent from the tree, checks pass), then merge as owner.

- [ ] **Step 3: Verify fetch on a clean checkout**

```bash
tmpclone="$(mktemp -d)"
git clone https://github.com/ajason13/wezterm-tmux-dotfiles "$tmpclone/repo"
cd "$tmpclone/repo"
./scripts/fetch-backgrounds.sh --dest "$PWD/wezterm/assets/backgrounds"
ls wezterm/assets/backgrounds
```

Expected: `backgrounds updated`, and the image tree is present. Re-run the same command and expect `backgrounds already up to date`.

- [ ] **Step 4: Back up before rewriting (non-negotiable)**

```bash
cd ~/Apps
git clone --mirror https://github.com/ajason13/wezterm-tmux-dotfiles wtd-backup.git
git -C wezterm-tmux-dotfiles bundle create ~/Apps/wtd-prewrite.bundle --all
```

- [ ] **Step 5: Rewrite history to drop wallpaper blobs**

```bash
cd ~/Apps/wezterm-tmux-dotfiles
git filter-repo --path wezterm/assets/backgrounds/ --invert-paths
du -sh .git   # expect a few MB, down from ~122 MB
```

(Install `git-filter-repo` first if needed: `brew install git-filter-repo`.)

- [ ] **Step 6: Force-push and re-sync fork + clones**

```bash
git remote add origin git@github.com:ajason13/wezterm-tmux-dotfiles.git   # filter-repo drops the remote
git push --force origin main
```

Then: delete and re-create the `ajason14` fork (its history is now divergent), and re-clone (or `git fetch && git reset --hard origin/main`) on every other machine.

- [ ] **Step 7: Confirm reclaim**

```bash
git count-objects -vH | grep size-pack   # expect a few MB
git log --oneline -- wezterm/assets/backgrounds   # expect no output
```

---

## Notes for the implementer

- Tasks 1-3 are independent and can be built in any order; Task 4 depends on Task 3; Task 5 depends on Tasks 1-4.
- Task 4 Step 1's edits target `install-macos.sh` as of 2026-07-09 (verified against the file). If it has since changed, re-locate the anchors (the `case` arg parser, `link_path()`, the link-mode `exit 0`, and the final copy-mode `printf`).
- `check-background-assets.sh` is intentionally kept (called by `publish-backgrounds.sh`); only its CI invocation is removed.

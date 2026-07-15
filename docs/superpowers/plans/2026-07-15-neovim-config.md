# Neovim Config Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a minimal, purpose-built Neovim config to the `wezterm-tmux-dotfiles` repo, installed like `wezterm/` and `tmux/`, for a navigate/open/git/edit/review loop.

**Architecture:** Hand-written config under `nvim/`, managed by `lazy.nvim`, one concern per file in `lua/plugins/`. Verified by a headless-load script wired into CI. No LSP or autocomplete.

**Tech Stack:** Neovim (Lua), lazy.nvim, telescope, oil, gitsigns, diffview, lazygit.nvim, treesitter, mini.pairs, mini.comment, which-key, lualine, tokyonight. Bash for the installer and test script.

## Global Constraints

- Minimal and focused: NO LSP, NO autocomplete, NO Mason. Every plugin maps to a stated need.
- Plugin manager is `lazy.nvim`; it auto-imports `lua/plugins/`.
- `nvim/lazy-lock.json` is committed (reproducible plugin versions); only `nvim/lua/local.lua` is gitignored.
- Leader is `<space>`; set in `init.lua` before lazy loads.
- Follow existing repo patterns: installer link/copy like `wezterm/`; a `scripts/test-*.sh` wired into `.github/workflows/ci.yml`.
- Prose/comments use a plain dash `-`, never an em dash.
- Ship via fork `ajason14` -> PR to `ajason13:main`. Branch `feat/neovim-config` already exists off `main`.
- Verification is headless-load plus manual smoke; there is no Lua unit-test harness.

---

### Task 1: Config foundation + headless test harness

**Files:**
- Create: `nvim/init.lua`
- Create: `nvim/lua/config/options.lua`
- Create: `nvim/lua/config/keymaps.lua`
- Create: `nvim/lua/plugins/ui.lua`
- Create: `scripts/test-nvim.sh`

**Interfaces:**
- Produces: a loadable Neovim config rooted at `nvim/init.lua` that bootstraps lazy.nvim, imports `lua/plugins/`, and loads `config.options` + `config.keymaps`; and `scripts/test-nvim.sh`, the headless-load gate every later task uses.

- [ ] **Step 1: Install Neovim**

```sh
brew install neovim
nvim --version | head -1   # expect: NVIM v0.10 or newer
```

- [ ] **Step 2: Write `nvim/lua/config/options.lua`**

```lua
local opt = vim.opt

opt.number = true
opt.relativenumber = true        -- counted motions like 5j become learnable
opt.mouse = 'a'                   -- mouse works as an escape hatch
opt.clipboard = 'unnamedplus'     -- yank/paste uses the system clipboard
opt.ignorecase = true
opt.smartcase = true
opt.termguicolors = true
opt.undofile = true               -- persistent undo across sessions
opt.signcolumn = 'yes'            -- stable gutter for gitsigns
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.splitright = true
opt.splitbelow = true
opt.scrolloff = 5
opt.wrap = false
```

- [ ] **Step 3: Write `nvim/lua/config/keymaps.lua`**

```lua
local map = vim.keymap.set

-- Split navigation (mirrors tmux hjkl muscle memory).
map('n', '<C-h>', '<C-w>h', { desc = 'Go to left split' })
map('n', '<C-j>', '<C-w>j', { desc = 'Go to lower split' })
map('n', '<C-k>', '<C-w>k', { desc = 'Go to upper split' })
map('n', '<C-l>', '<C-w>l', { desc = 'Go to right split' })

-- Write / quit.
map('n', '<leader>w', '<cmd>write<cr>', { desc = 'Write file' })
map('n', '<leader>q', '<cmd>quit<cr>', { desc = 'Quit window' })

-- Clear search highlight.
map('n', '<Esc>', '<cmd>nohlsearch<cr>', { desc = 'Clear search highlight' })
```

- [ ] **Step 4: Write `nvim/lua/plugins/ui.lua`**

```lua
return {
  {
    'folke/tokyonight.nvim',
    lazy = false,
    priority = 1000,       -- load the colorscheme before other UI
    config = function()
      require('tokyonight').setup({ style = 'storm' })
      vim.cmd.colorscheme('tokyonight-storm')
    end,
  },
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    event = 'VeryLazy',
    opts = {
      options = { theme = 'tokyonight', globalstatus = true },
    },
  },
}
```

- [ ] **Step 5: Write `nvim/init.lua`**

```lua
-- Leader must be set before lazy.nvim loads (plugin specs read it at setup).
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

require('config.options')
require('config.keymaps')

-- Bootstrap lazy.nvim.
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    'git', 'clone', '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup('plugins', {
  change_detection = { notify = false },
})

-- Machine-local overrides (gitignored), loaded last so a machine can tweak
-- options or add keymaps without editing tracked files.
pcall(require, 'local')
```

- [ ] **Step 6: Write `scripts/test-nvim.sh`**

```bash
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

# Load once more and fail on any error output. A clean config is silent.
out="$(nvim --headless +qa 2>&1 >/dev/null)" || true
if printf '%s' "$out" | grep -qiE 'error|E[0-9]+:|stack traceback'; then
  echo "test-nvim: startup produced errors:" >&2
  printf '%s\n' "$out" >&2
  exit 1
fi

echo "nvim config loads clean"
```

- [ ] **Step 7: Make the test script executable**

```sh
chmod +x scripts/test-nvim.sh
```

- [ ] **Step 8: Run the headless test**

Run: `./scripts/test-nvim.sh`
Expected: installs lazy.nvim + tokyonight + lualine, then prints `nvim config loads clean`. Exit 0.

- [ ] **Step 9: Manual smoke (optional but recommended)**

Run: `nvim` (with `~/.config/nvim` pointed at this repo, or `XDG_CONFIG_HOME` set as above)
Expected: opens with the TokyoNight Storm colorscheme and a lualine status bar showing the mode. `:q` to exit.

- [ ] **Step 10: Commit**

```bash
git add nvim/init.lua nvim/lua/config/options.lua nvim/lua/config/keymaps.lua \
  nvim/lua/plugins/ui.lua scripts/test-nvim.sh
git commit -m "feat: neovim config foundation (lazy bootstrap, options, theme) + headless test"
```

---

### Task 2: Navigate and open (telescope + oil)

**Files:**
- Create: `nvim/lua/plugins/telescope.lua`
- Create: `nvim/lua/plugins/oil.lua`

**Interfaces:**
- Consumes: the `lua/plugins/` import and leader from Task 1.
- Produces: `<leader>ff`/`<leader>fg`/`<leader>fb`/`<leader>fh` (telescope) and `-` (oil).

(`nvim/lazy-lock.json` for all plugins is generated and committed once in Task 5, after the config is linked live.)

- [ ] **Step 1: Write `nvim/lua/plugins/telescope.lua`**

```lua
return {
  'nvim-telescope/telescope.nvim',
  branch = '0.1.x',
  dependencies = { 'nvim-lua/plenary.nvim' },
  cmd = 'Telescope',
  keys = {
    { '<leader>ff', '<cmd>Telescope find_files<cr>', desc = 'Find files' },
    { '<leader>fg', '<cmd>Telescope live_grep<cr>', desc = 'Live grep' },
    { '<leader>fb', '<cmd>Telescope buffers<cr>', desc = 'Buffers' },
    { '<leader>fh', '<cmd>Telescope help_tags<cr>', desc = 'Help tags' },
  },
  opts = {},
}
```

- [ ] **Step 2: Write `nvim/lua/plugins/oil.lua`**

```lua
return {
  'stevearc/oil.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  lazy = false,          -- oil hijacks netrw, so it must load at startup
  keys = {
    { '-', '<cmd>Oil<cr>', desc = 'Open parent directory (oil)' },
  },
  opts = {
    view_options = { show_hidden = true },
  },
}
```

- [ ] **Step 3: Run the headless test (installs the new plugins)**

Run: `./scripts/test-nvim.sh`
Expected: `nvim config loads clean`. Exit 0. A missing or broken plugin surfaces here as a sync/load error, so this is the gate.

- [ ] **Step 4: Commit**

```bash
git add nvim/lua/plugins/telescope.lua nvim/lua/plugins/oil.lua
git commit -m "feat: neovim file navigation and opening (telescope + oil)"
```

---

### Task 3: Git (gitsigns + diffview + lazygit)

**Files:**
- Create: `nvim/lua/plugins/git.lua`

**Interfaces:**
- Consumes: leader + `lua/plugins/` import from Task 1.
- Produces: `<leader>gg` (lazygit), `<leader>gd` (diffview branch review), `<leader>gh` (file history), `]c`/`[c` (hunk nav), `<leader>gs`/`<leader>gr`/`<leader>gb` (stage/reset/blame).

- [ ] **Step 1: Write `nvim/lua/plugins/git.lua`**

```lua
return {
  {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {
      on_attach = function(bufnr)
        local gs = require('gitsigns')
        local function map(l, r, desc)
          vim.keymap.set('n', l, r, { buffer = bufnr, desc = desc })
        end
        map(']c', function() gs.nav_hunk('next') end, 'Next git hunk')
        map('[c', function() gs.nav_hunk('prev') end, 'Previous git hunk')
        map('<leader>gs', gs.stage_hunk, 'Stage hunk')
        map('<leader>gr', gs.reset_hunk, 'Reset hunk')
        map('<leader>gb', function() gs.blame_line({ full = true }) end, 'Blame line')
      end,
    },
  },
  {
    'sindrets/diffview.nvim',
    cmd = { 'DiffviewOpen', 'DiffviewFileHistory' },
    keys = {
      { '<leader>gd', '<cmd>DiffviewOpen main...HEAD<cr>', desc = 'Review branch vs main' },
      { '<leader>gh', '<cmd>DiffviewFileHistory %<cr>', desc = 'File history (current file)' },
    },
  },
  {
    'kdheepak/lazygit.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    cmd = { 'LazyGit' },
    keys = {
      { '<leader>gg', '<cmd>LazyGit<cr>', desc = 'Open lazygit' },
    },
  },
}
```

- [ ] **Step 2: Run the headless test**

Run: `./scripts/test-nvim.sh`
Expected: `nvim config loads clean`. Exit 0.

- [ ] **Step 3: Commit**

```bash
git add nvim/lua/plugins/git.lua
git commit -m "feat: neovim git (gitsigns inline, diffview review, lazygit float)"
```

---

### Task 4: Editing quality-of-life + discovery (treesitter, mini, which-key)

**Files:**
- Create: `nvim/lua/plugins/treesitter.lua`
- Create: `nvim/lua/plugins/editing.lua`
- Create: `nvim/lua/plugins/which-key.lua`

**Interfaces:**
- Consumes: the `<leader>f` and `<leader>g` keymaps from Tasks 2-3 (which-key labels those groups).
- Produces: syntax highlighting, `gcc` comment toggle, autopairs, and the which-key discovery popup.

- [ ] **Step 1: Write `nvim/lua/plugins/treesitter.lua`**

```lua
return {
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  event = { 'BufReadPost', 'BufNewFile' },
  main = 'nvim-treesitter.configs',
  opts = {
    ensure_installed = { 'lua', 'bash', 'json', 'yaml', 'markdown', 'gitcommit', 'diff' },
    highlight = { enable = true },
    indent = { enable = true },
  },
}
```

- [ ] **Step 2: Write `nvim/lua/plugins/editing.lua`**

```lua
return {
  {
    'echasnovski/mini.pairs',
    event = 'InsertEnter',
    opts = {},
  },
  {
    'echasnovski/mini.comment',
    event = 'VeryLazy',
    opts = {},
  },
}
```

- [ ] **Step 3: Write `nvim/lua/plugins/which-key.lua`**

```lua
return {
  'folke/which-key.nvim',
  event = 'VeryLazy',
  opts = {
    spec = {
      { '<leader>f', group = 'find' },
      { '<leader>g', group = 'git' },
    },
  },
}
```

- [ ] **Step 4: Run the headless test**

Run: `./scripts/test-nvim.sh`
Expected: `nvim config loads clean`. Exit 0.

- [ ] **Step 5: Commit**

```bash
git add nvim/lua/plugins/treesitter.lua nvim/lua/plugins/editing.lua \
  nvim/lua/plugins/which-key.lua
git commit -m "feat: neovim treesitter, editing QoL (mini), and which-key discovery"
```

---

### Task 5: Delivery (installer, uninstaller, gitignore)

**Files:**
- Modify: `install-macos.sh`
- Modify: `uninstall-macos.sh`
- Modify: `.gitignore`
- Create: `nvim/lazy-lock.json` (generated by syncing the linked config)

**Interfaces:**
- Consumes: the `nvim/` tree from Tasks 1-4.
- Produces: `~/.config/nvim` symlinked (link mode) or copied (copy mode); `nvim/lua/local.lua` ignored by git; a committed `nvim/lazy-lock.json` pinning every plugin.

- [ ] **Step 1: Add the link-mode line to `install-macos.sh`**

In the `if [[ "$mode" == "link" ]]` block (currently the `link_path ...` lines around 143-147), add, after the tmux line:

```bash
link_path "$root_dir/nvim" "$HOME/.config/nvim"
```

- [ ] **Step 2: Add copy-mode handling to `install-macos.sh`**

In the copy-mode branch (the `prepare_copy_dir` / `install_file` section), copy the `nvim/` tree to `~/.config/nvim`. Match the file's existing helper style; a directory copy is:

```bash
prepare_copy_dir "$HOME/.config/nvim"
cp -R "$root_dir/nvim/." "$HOME/.config/nvim/"
```

Place it alongside the other copy-mode installs. Preserve any existing `--dry-run` (`run ...`) wrapping the file already uses for copy operations.

- [ ] **Step 3: Add `~/.config/nvim` to `uninstall-macos.sh`**

Find the list of managed target paths the uninstaller removes/restores (the same set as `~/.wezterm.lua`, `~/.config/wezterm`, `~/.tmux.conf`, `~/.local/bin/tmux-llm-status`) and add `~/.config/nvim`, mirroring the exact per-path handling already there (removal, and backup restore under `--restore-latest`).

- [ ] **Step 4: Ignore machine-local nvim config in `.gitignore`**

Add:

```gitignore
nvim/lua/local.lua
```

- [ ] **Step 5: Verify install dry-run shows the nvim link**

Run: `./install-macos.sh --link --dry-run`
Expected: output includes creating a symlink `~/.config/nvim -> <repo>/nvim` (and no errors).

- [ ] **Step 6: Verify shell scripts still lint**

Run: `bash -n install-macos.sh uninstall-macos.sh && shellcheck install-macos.sh uninstall-macos.sh`
Expected: no output / exit 0.

- [ ] **Step 7: Link for real and confirm**

Run: `./install-macos.sh --link` then `readlink ~/.config/nvim`
Expected: prints the repo's `nvim` path. `nvim` opens the repo config.

- [ ] **Step 8: Generate the committed lockfile**

Now that `~/.config/nvim` points at the repo, sync the live config so `lazy.nvim`
writes `nvim/lazy-lock.json` into the repo (pinning every plugin from Tasks 1-4):

```sh
nvim --headless "+Lazy! sync" +qa
test -f nvim/lazy-lock.json && echo "lockfile written"
```
Expected: `nvim/lazy-lock.json` exists and lists all plugins.

- [ ] **Step 9: Commit**

```bash
git add install-macos.sh uninstall-macos.sh .gitignore nvim/lazy-lock.json
git commit -m "feat: install/uninstall the nvim config; pin plugins; ignore local.lua"
```

---

### Task 6: CI (headless-load gate)

**Files:**
- Modify: `.github/workflows/ci.yml`

**Interfaces:**
- Consumes: `scripts/test-nvim.sh` from Task 1.
- Produces: a CI step that installs Neovim and runs the headless-load check; the script added to the lint/executable checks.

- [ ] **Step 1: Add `scripts/test-nvim.sh` to the `bash -n` list** (the `Check shell syntax` step) by appending it to that command's file list.

- [ ] **Step 2: Add `scripts/test-nvim.sh` to the `shellcheck` list** (the `Lint shell scripts` step) by appending it.

- [ ] **Step 3: Add `test -x scripts/test-nvim.sh`** to the `Check executable scripts` step's block.

- [ ] **Step 4: Add the install + run steps** after the existing `Run script test suites` step:

```yaml
      - name: Install Neovim (for config headless-load test)
        run: sudo apt-get update && sudo apt-get install -y neovim

      - name: Neovim config loads clean
        run: ./scripts/test-nvim.sh
```

- [ ] **Step 5: Validate the workflow file**

Run: `bash -n scripts/test-nvim.sh && shellcheck scripts/test-nvim.sh`
Expected: clean. (YAML itself is validated by CI on push; confirm indentation matches surrounding steps.)

- [ ] **Step 6: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "ci: install neovim and run the nvim headless-load test"
```

---

### Task 7: Docs (cheat sheet + README updates)

**Files:**
- Create: `nvim/README.md`
- Modify: `README.md`

**Interfaces:**
- Consumes: the keymaps from Tasks 1-4 and the install flow from Task 5.
- Produces: the config's cheat sheet and updated top-level docs.

- [ ] **Step 1: Write `nvim/README.md`** with these sections (plain dashes only, no em dashes):
  - Intro: what this config is and its scope (navigate/open/git/edit/review; no LSP).
  - **Keymaps** table (grouped find / git / windows), copied from the specs:
    `<leader>ff|fg|fb|fh`, `-` (oil), `<leader>gg|gd|gh`, `]c`/`[c`, `<leader>gs|gr|gb`, `<C-h/j/k/l>`, `<leader>w|q`.
  - **Common workflows**: open/grep a file; navigate and do file ops in oil (edit the buffer, `:w` to apply); the branch-review loop `gh pr checkout <n>` -> `wt` -> `nvim` -> `:DiffviewOpen main...HEAD` (or `<leader>gd`); open lazygit with `<leader>gg`.
  - **Learning vim**: run `:Tutor`; press `<space>` and wait for the which-key popup to discover keys.
  - **Machine-local overrides**: create `nvim/lua/local.lua` (gitignored) to tweak options or add keymaps; it is `require`d last.

- [ ] **Step 2: Update `README.md` Requirements** to add Neovim:

```sh
brew install neovim
```

- [ ] **Step 3: Update `README.md` Layout** tree to include the `nvim/` directory.

- [ ] **Step 4: Update the `README.md` Neovim note** (in the Recommended Tools section, currently "Later: Neovim"): change it from "later" to "included," point at `nvim/README.md`, and state the now-live review loop `gh pr checkout <n>` -> `wt` -> `nvim` -> `:DiffviewOpen`.

- [ ] **Step 5: Update `README.md` Local Editing / link list** to mention `~/.config/nvim -> nvim` alongside the other symlinks.

- [ ] **Step 6: Review the rendered docs**

Run: skim `nvim/README.md` and `README.md`.
Expected: no em dashes; keymaps match the plugin files; the review loop reads correctly.

- [ ] **Step 7: Commit**

```bash
git add nvim/README.md README.md
git commit -m "docs: neovim cheat sheet and README updates (requirements, layout, review loop)"
```

---

## Notes for the implementer

- Neovim 0.10+ is assumed (Homebrew installs current). `vim.uv` is used with a `vim.loop` fallback in `init.lua`.
- The `main...HEAD` base in `<leader>gd` and the cheat sheet assumes branches cut from `main`. If a repo uses a different base, run `:DiffviewOpen <base>...HEAD` directly.
- If `test-nvim.sh` is flaky on a plugin that prints non-fatal warnings to stderr, tighten the `grep` in the script to the specific error signature rather than the broad `error` match; do not silence real errors.
- Follow-ups (out of scope): `vim-tmux-navigator` (+ tmux `Ctrl-hjkl` rebind), `octo.nvim`, LSP/autocomplete.

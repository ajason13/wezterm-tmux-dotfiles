# Neovim Config Design

**Status:** Approved (design), pending implementation plan.

## Goal

Add a minimal, comprehensible Neovim config to the `wezterm-tmux-dotfiles` repo,
built for one person's actual terminal loop: navigating, opening files, running
git, editing (including files an AI agent can't touch, like `.env*`), and
reviewing branch diffs locally instead of in the browser. It ships as part of the
portable cross-machine setup, installed the same way as `wezterm/` and `tmux/`.

## Context and constraints

- **User is rusty at vim but willing to learn.** The config must aid discovery
  (which-key), keep sensible escape hatches (arrow keys stay enabled), and be
  small enough to read end to end. User is already comfortable with `hjkl` from
  tmux pane switching.
- **Minimal and focused, not an IDE.** No LSP, no autocomplete. The user felt
  overwhelmed by large tool sets; every plugin must map to a stated need.
- **Purpose-built, not a distribution.** Hand-written config (Approach A), not
  LazyVim or an adapted kickstart.nvim - so the user owns and understands every
  line, and there is nothing extraneous to strip.
- **Lives in the repo** at `nvim/`, delivered by the existing installer.

## Non-goals (deliberately deferred)

- LSP, autocomplete, Mason.
- `fugitive` (git commands are covered by lazygit + gitsigns + diffview).
- `octo.nvim` (in-editor PR comment/approve) - a natural phase 2 once local diff
  review lands.
- `vim-tmux-navigator` - high value given the user's tmux `hjkl` habit, but it
  also requires a change on the tmux side (panes are bound to *prefix*+`hjkl`;
  the navigator wants bare `Ctrl`+`hjkl`), so it is its own small change touching
  the shared `tmux.conf`. Tracked as a follow-up.

## Plugins

Plugin manager: **`lazy.nvim`** (self-bootstrapping, lazy-loads, imports the
`lua/plugins/` directory). `lazy-lock.json` is committed so every machine
resolves identical plugin versions.

| Need | Plugin | Role |
|---|---|---|
| Open | `telescope.nvim` (+ `plenary.nvim`) | Fuzzy find files, live-grep (via ripgrep), list buffers/help. |
| Navigate | `oil.nvim` | Edit a directory as a buffer; navigate with vim motions; `-` opens the parent dir. Reinforces the motions the user is learning and doubles as bulk file ops. |
| Git (inline) | `gitsigns.nvim` | Gutter change signs, stage/reset hunk, inline blame, hunk navigation. |
| Git (review) | `diffview.nvim` | `:DiffviewOpen main...HEAD` branch review ("Files changed" view) and file history. |
| Git (commands) | `lazygit.nvim` | `<leader>gg` opens the already-installed `lazygit` in a float. |
| Edit | `nvim-treesitter` | Accurate syntax highlighting and smarter selections. |
| Edit (QoL) | `mini.pairs`, `mini.comment` | Auto-close brackets; `gcc` to toggle comments. |
| Learn | `which-key.nvim` | Popup of available keybindings after a prefix. Primary learning aid. |
| UI | `lualine.nvim` | Status line with a mode indicator (helpful while rusty) and git branch. |
| UI | `tokyonight.nvim` | `storm` variant, matching WezTerm's `TokyoNightStorm (Gogh)` for visual consistency. |

`nvim-web-devicons` comes in as a dependency of telescope/oil/lualine and relies
on the Nerd Font already recommended in the README.

## File layout

Mirrors the one-concern-per-file style of `wezterm/`:

```
nvim/
├── init.lua                 # bootstrap lazy.nvim, load config + plugins
├── lazy-lock.json           # committed: pins plugin versions
├── README.md                # cheat sheet
└── lua/
    ├── config/
    │   ├── options.lua       # editor settings
    │   └── keymaps.lua       # non-plugin keymaps
    ├── plugins/              # one file per concern (lazy auto-imports)
    │   ├── oil.lua
    │   ├── telescope.lua
    │   ├── git.lua           # gitsigns + diffview + lazygit
    │   ├── treesitter.lua
    │   ├── editing.lua       # mini.pairs + mini.comment
    │   ├── which-key.lua
    │   └── ui.lua            # tokyonight + lualine
    └── local.lua             # gitignored machine-local tweaks (mirrors wezterm/local.lua)
```

`init.lua` loads `config.options` and `config.keymaps`, bootstraps lazy.nvim,
calls `require("lazy").setup("plugins")`, then `pcall(require, "local")` so a
machine can tweak options/keymaps without editing tracked files.

## Editor defaults (`options.lua`)

Tuned for a learner:

- Leader = `<space>`.
- `number` + `relativenumber` (makes counted motions like `5j` learnable).
- `clipboard = "unnamedplus"` (yank/paste uses the system clipboard).
- `mouse = "a"` (mouse works as an escape hatch).
- `ignorecase` + `smartcase` search.
- `termguicolors` (true color, matching the terminal setup).
- `undofile` (persistent undo).
- `signcolumn = "yes"` (stable gutter for gitsigns).
- `expandtab`, `shiftwidth = 2`, `tabstop = 2` as a neutral default.
- `splitright`, `splitbelow`, modest `scrolloff`.
- Arrow keys stay enabled.

## Keymaps (`keymaps.lua` + plugin specs)

Small and memorable; all discoverable via which-key. Which-key group labels:
`f` = find, `g` = git.

| Keys | Action |
|---|---|
| `<leader>ff` / `<leader>fg` / `<leader>fb` | find files / live-grep / buffers (telescope) |
| `<leader>fh` | search help tags |
| `-` | open oil in the current file's directory |
| `<leader>gg` | open lazygit (float) |
| `<leader>gd` | diffview: review current branch vs `main` (`:DiffviewOpen main...HEAD`) |
| `<leader>gh` | file history (`:DiffviewFileHistory`) |
| `]c` / `[c` | next / previous git hunk |
| `<leader>gs` / `<leader>gr` | stage / reset hunk |
| `<leader>gb` | toggle inline blame |
| `<C-h/j/k/l>` | move between splits |
| `<leader>w` / `<leader>q` | write / quit |

## Delivery

- **Location:** `nvim/` at the repo root.
- **Installer:** `install-macos.sh --link` symlinks `nvim/` → `~/.config/nvim`
  (like `wezterm/` → `~/.config/wezterm`); copy mode copies the tree.
  `uninstall-macos.sh` removes/restores `~/.config/nvim` too.
- **New requirement:** `brew install neovim`. Ripgrep and a Nerd Font are already
  in the README's tool list.
- **Git ignore:** only `nvim/lua/local.lua` is ignored; `lazy-lock.json` is
  committed for reproducible plugin versions.
- **README:** the "Later: Neovim" note becomes real, pointing at `nvim/README.md`
  and the now-live `gh pr checkout → wt → nvim → :DiffviewOpen` review loop.

## Verification

- **`scripts/test-nvim.sh`:** headless load that fails on any Lua/startup error -
  the Neovim analog of the `wezterm ... ls-fonts` check. Runs
  `nvim --headless "+Lazy! sync" +qa` (installs/updates plugins, then quits),
  asserting a clean exit and no error output.
- **CI:** a `ci.yml` step installs Neovim and runs `scripts/test-nvim.sh`. The
  script is added to the shell lint/executable checks like the other
  `scripts/*.sh`.
- Neovim has no unit-test harness here; verification is headless-load plus manual
  smoke of the keymaps, matching how the WezTerm config is verified.

## Cheat sheet (`nvim/README.md`)

The config's own reference, for a learner:

- The keymap table above, grouped by purpose.
- Common workflows: open/grep a file; navigate and do file ops in oil; the
  branch-review loop (`gh pr checkout` → `wt` → `nvim` → `:DiffviewOpen`); open
  lazygit.
- A "learning vim" pointer: `:Tutor`, and a note that which-key shows available
  keys after `<space>`.

## Follow-ups (out of scope here, tracked for later)

- `vim-tmux-navigator` + the tmux-side `Ctrl`+`hjkl` rebind, for seamless
  navigation across tmux panes and nvim splits.
- `octo.nvim` for in-editor PR comment/approve.
- LSP/autocomplete, if the user later misses it.

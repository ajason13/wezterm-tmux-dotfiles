# WezTerm + tmux Dotfiles

Portable macOS configuration for a WezTerm + tmux workflow focused on LLM
sessions, fast pane/window management, Quick Select file opening, and rotating
terminal backgrounds.

## What This Includes

- WezTerm starts or attaches to tmux session `main`.
- tmux owns windows and panes; WezTerm tabs are hidden.
- tmux status bar shows aggregate LLM activity markers.
- `Ctrl-a` is the tmux prefix.
- `Ctrl-a \` splits horizontally and `Ctrl-a -` splits vertically.
- `Ctrl-a h/j/k/l` moves between panes.
- `Ctrl-Shift-Space` opens selected paths in VS Code and web targets in the
  browser.
- WezTerm backgrounds rotate every two hours.

## Layout

```text
.
├── install-macos.sh
├── tmux
│   ├── tmux.conf
│   └── tmux-llm-status
└── wezterm
    ├── .wezterm.lua
    ├── wezterm.lua
    ├── modules
    │   ├── appearance.lua
    │   ├── backgrounds.lua
    │   ├── general.lua
    │   ├── links.lua
    │   └── macos.lua
    └── assets/backgrounds
```

## Install On A Mac

Clone this repo, then run:

```sh
./install-macos.sh
```

Copy mode installs files into:

```text
~/.wezterm.lua
~/.config/wezterm
~/.tmux.conf
~/.local/bin/tmux-llm-status
```

Existing files are backed up before replacement when contents differ.

## Local Editing Mode

Use link mode on a machine where you want this repo to be the live config:

```sh
./install-macos.sh --link
```

This symlinks:

```text
~/.wezterm.lua -> wezterm/.wezterm.lua
~/.config/wezterm -> wezterm
~/.tmux.conf -> tmux/tmux.conf
~/.local/bin/tmux-llm-status -> tmux/tmux-llm-status
```

WezTerm has automatic reload enabled, but module edits through symlinks may not
always reload immediately. Press `Cmd-r` in WezTerm if needed. Reload tmux with
`Ctrl-a r`.

## Backgrounds

Background rotation is configured in:

```text
wezterm/modules/backgrounds.lua
```

To change brightness:

```lua
local background_hsb = {
  brightness = 0.16,
  saturation = 0.90,
}
```

To change the interval:

```lua
local rotation_seconds = 2 * 60 * 60
```

Add image files under `wezterm/assets/backgrounds` and list them in
`background_files`.

## Requirements

- macOS
- WezTerm
- tmux
- VS Code with the `vscode://file` URI handler enabled
- Optional: JetBrains Mono font

## Notes

The LLM activity marker relies on pane titles and foreground command names. It
works best with CLIs that expose active/waiting state in terminal titles, such
as Codex. Other LLM CLIs may only show a generic detected marker.

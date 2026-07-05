local home = os.getenv('HOME')

if not home or home == '' then
  error('HOME is not set; cannot load ~/.config/wezterm/wezterm.lua')
end

_G.WEZTERM_PORTABLE_CONFIG_DIR = home .. '/.config/wezterm'

return dofile(home .. '/.config/wezterm/wezterm.lua')

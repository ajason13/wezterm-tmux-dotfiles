local wezterm = require 'wezterm'
local config = wezterm.config_builder()

local home = os.getenv('HOME')
local config_dir = _G.WEZTERM_PORTABLE_CONFIG_DIR or wezterm.config_dir or (home .. '/.config/wezterm')
local modules_dir = config_dir .. '/modules'
local env = {
  config_dir = config_dir,
  home = home,
}

dofile(modules_dir .. '/links.lua').apply(config, wezterm, env)
dofile(modules_dir .. '/general.lua').apply(config, wezterm, env)
dofile(modules_dir .. '/appearance.lua').apply(config, wezterm, env)
dofile(modules_dir .. '/backgrounds.lua').apply(config, wezterm, env)
dofile(modules_dir .. '/macos.lua').apply(config, wezterm, env)

return config

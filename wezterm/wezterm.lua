local wezterm = require 'wezterm'
local config = wezterm.config_builder()

local home = os.getenv('HOME')
local config_dir = _G.WEZTERM_PORTABLE_CONFIG_DIR or wezterm.config_dir or (home .. '/.config/wezterm')
local modules_dir = config_dir .. '/modules'
local env = {
  config_dir = config_dir,
  home = home,
}

local function file_exists(path)
  local file = io.open(path, 'r')
  if file then
    file:close()
    return true
  end

  return false
end

local local_config_path = config_dir .. '/local.lua'
if file_exists(local_config_path) then
  local local_config = dofile(local_config_path)
  if type(local_config) == 'table' then
    env.local_config = local_config
  elseif type(local_config) == 'function' then
    env.local_config = {
      apply = local_config,
    }
  end
end

dofile(modules_dir .. '/links.lua').apply(config, wezterm, env)
dofile(modules_dir .. '/general.lua').apply(config, wezterm, env)
dofile(modules_dir .. '/appearance.lua').apply(config, wezterm, env)
dofile(modules_dir .. '/backgrounds.lua').apply(config, wezterm, env)
dofile(modules_dir .. '/macos.lua').apply(config, wezterm, env)

if env.local_config and type(env.local_config.apply) == 'function' then
  env.local_config.apply(config, wezterm, env)
end

return config

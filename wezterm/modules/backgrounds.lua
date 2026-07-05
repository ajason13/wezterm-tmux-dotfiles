local M = {}

local rotation_seconds = 2 * 60 * 60
local refresh_interval_ms = 60 * 1000

local background_files = {
  '00-mountain-night-lights.jpg',
  '10-ae86-rainy-mountain-pass.png',
  '20-rx7-fd-foggy-mountain-pass.png',
  '30-rx7-fc-clear-night-pass.png',
  '40-g35-rainy-mountain-pass.png',
  '50-gr-corolla-foggy-mountain-pass.png',
  '60-wrx-rainy-mountain-pass.png',
  '70-mini-cooper-s-foggy-mountain-pass.png',
  '80-1955-chevy-gasser-night-drag.png',
}

local background_hsb = {
  brightness = 0.10,
  saturation = 0.90,
}

local last_background_by_window = {}

local function file_exists(path)
  local file = io.open(path, 'r')
  if file then
    file:close()
    return true
  end

  return false
end

local function collect_backgrounds(env)
  local backgrounds = {}
  local dir = env.config_dir .. '/assets/backgrounds'

  for _, file in ipairs(background_files) do
    local path = dir .. '/' .. file
    if file_exists(path) then
      table.insert(backgrounds, path)
    end
  end

  return backgrounds
end

local function current_background(backgrounds)
  if #backgrounds == 0 then
    return nil
  end

  local slot = math.floor(os.time() / rotation_seconds)
  local index = (slot % #backgrounds) + 1
  return backgrounds[index]
end

local function apply_window_background(window, background)
  local id = tostring(window:window_id())
  if last_background_by_window[id] == background then
    return
  end

  local overrides = window:get_config_overrides() or {}
  overrides.window_background_image = background
  overrides.window_background_image_hsb = background_hsb
  window:set_config_overrides(overrides)
  last_background_by_window[id] = background
end

function M.apply(config, wezterm, env)
  local backgrounds = collect_backgrounds(env)
  local initial_background = current_background(backgrounds)

  if initial_background then
    config.window_background_image = initial_background
    config.window_background_image_hsb = background_hsb
  end

  config.status_update_interval = refresh_interval_ms

  wezterm.on('update-status', function(window)
    local background = current_background(backgrounds)
    if background then
      apply_window_background(window, background)
    end
  end)
end

return M

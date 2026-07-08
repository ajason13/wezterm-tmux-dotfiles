local M = {}

local rotation_seconds = 15 * 60
local refresh_interval_ms = 60 * 1000

local background_hsb = {
  brightness = 0.40,
  saturation = 0.90,
}

-- Opacity is only lowered when a background image is active, so an image-less
-- setup stays fully opaque. window_background_opacity affects cells using the
-- default background (shell output, empty regions); text_background_opacity
-- affects cells with an explicit background color (full-screen TUIs, styled
-- tmux status segments). Both must be below 1.0 or the wallpaper is hidden
-- behind opaque cell backgrounds.
local window_background_opacity = 0.90
local text_background_opacity = 0.55

local last_background_by_window = {}

local function file_exists(path)
  local file = io.open(path, 'r')
  if file then
    file:close()
    return true
  end

  return false
end

local function extend(list, values)
  for _, value in ipairs(values) do
    table.insert(list, value)
  end
end

local function exclude_set(values)
  local set = {}
  for _, value in ipairs(values or {}) do
    set[value] = true
  end

  return set
end

local function listed_background_groups(env)
  local manifest_dir = env.config_dir .. '/modules/background_manifests'

  -- Backgrounds stay on an explicit allowlist for predictability. Small
  -- manifest files scale better than one large flat table.
  return {
    dofile(manifest_dir .. '/general.lua'),
    dofile(manifest_dir .. '/vehicles.lua'),
    dofile(manifest_dir .. '/anime.lua'),
  }
end

local function all_background_files(env, local_config)
  local files = {}
  local excludes = exclude_set(local_config.background_excludes)

  for _, group in ipairs(listed_background_groups(env)) do
    for _, file in ipairs(group) do
      if not excludes[file] then
        table.insert(files, file)
      end
    end
  end

  return files
end

local function collect_backgrounds(env)
  local backgrounds = {}
  local dir = env.config_dir .. '/assets/backgrounds'
  local local_config = env.local_config or {}
  local background_files = all_background_files(env, local_config)

  for _, file in ipairs(background_files) do
    local path = dir .. '/' .. file
    if file_exists(path) then
      table.insert(backgrounds, path)
    end
  end

  return backgrounds
end

local function current_background(backgrounds, interval)
  if #backgrounds == 0 then
    return nil
  end

  local slot = math.floor(os.time() / interval)
  local index = (slot % #backgrounds) + 1
  return backgrounds[index]
end

local function apply_window_background(window, background, hsb, window_opacity, text_opacity)
  local id = tostring(window:window_id())
  if last_background_by_window[id] == background then
    return
  end

  local overrides = window:get_config_overrides() or {}
  overrides.window_background_image = background
  overrides.window_background_image_hsb = hsb
  overrides.window_background_opacity = window_opacity
  overrides.text_background_opacity = text_opacity
  window:set_config_overrides(overrides)
  last_background_by_window[id] = background
end

function M.apply(config, wezterm, env)
  local backgrounds = collect_backgrounds(env)
  local local_config = env.local_config or {}
  local hsb = local_config.background_hsb or background_hsb
  local interval = local_config.background_rotation_seconds or rotation_seconds
  local window_opacity = local_config.window_background_opacity or window_background_opacity
  local text_opacity = local_config.text_background_opacity or text_background_opacity
  local initial_background = current_background(backgrounds, interval)

  if initial_background then
    config.window_background_image = initial_background
    config.window_background_image_hsb = hsb
    config.window_background_opacity = window_opacity
    config.text_background_opacity = text_opacity
  end

  config.status_update_interval = refresh_interval_ms

  wezterm.on('update-status', function(window)
    local background = current_background(backgrounds, interval)
    if background then
      apply_window_background(window, background, hsb, window_opacity, text_opacity)
    end
  end)
end

return M

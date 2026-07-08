local M = {}

local rotation_seconds = 60 * 60
local refresh_interval_ms = 60 * 1000

-- Background paths are an explicit allowlist. This keeps rotation stable and
-- prevents archive, experiment, or sensitive folders from showing by accident.
-- Prefer grouped allowlists over an exclude model. Excludes are harder to audit
-- and can accidentally pull in archive, NSFW, or experiment assets.
local background_groups = {
  general = {
    '000-general/000-mountain-night-lights.jpg',
  },
  vehicles = {
    '100-vehicles/110-ae86-rainy-mountain-pass.png',
    '100-vehicles/120-rx7-fd-foggy-mountain-pass.png',
    '100-vehicles/130-rx7-fc-clear-night-pass.png',
    '100-vehicles/140-g35-rainy-mountain-pass.png',
    '100-vehicles/150-gr-corolla-foggy-mountain-pass.png',
    '100-vehicles/160-wrx-rainy-mountain-pass.png',
    '100-vehicles/170-mini-cooper-s-foggy-mountain-pass.png',
    '100-vehicles/180-1955-chevy-gasser-night-drag.png',
    '100-vehicles/190-honda-odyssey-elite-costco-night.png',
  },
  anime = {
    attack_on_titan = {
      '200-anime/attack-on-titan/001-colossal-face-wall.png',
      '200-anime/attack-on-titan/002-forest-maneuver-gear.png',
    },
    one_punch_man = {
      '200-anime/one-punch-man/001-canyon-moon.png',
    },
    haikyuu = {
      '200-anime/haikyuu/001-minus-tempo-quick.png',
      '200-anime/haikyuu/002-tsukishima-block.png',
      '200-anime/haikyuu/003-nishinoya-hard-dig.png',
      '200-anime/haikyuu/004-nishinoya-pancake-save.png',
      '200-anime/haikyuu/005-diving-dig.png',
      '200-anime/haikyuu/006-tsukishima-celebration.png',
      '200-anime/haikyuu/007-coach-ukai-look-up.png',
      '200-anime/haikyuu/008-tanaka-mountain-stairs.png',
      '200-anime/haikyuu/009-tanaka-stupid-look.png',
      '200-anime/haikyuu/010-good-luck-banner.png',
      '200-anime/haikyuu/011-meat-celebration.png',
      '200-anime/haikyuu/012-jump-block.png',
      '200-anime/haikyuu/013-ball-action.png',
      '200-anime/haikyuu/014-pointing-black.png',
      '200-anime/haikyuu/015-floor-slide.png',
    },
  },
}

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

local function all_background_files()
  local files = {}
  extend(files, background_groups.general)
  extend(files, background_groups.vehicles)
  extend(files, background_groups.anime.attack_on_titan)
  extend(files, background_groups.anime.one_punch_man)
  extend(files, background_groups.anime.haikyuu)

  return files
end

local function collect_backgrounds(env)
  local backgrounds = {}
  local dir = env.config_dir .. '/assets/backgrounds'
  local background_files = all_background_files()

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

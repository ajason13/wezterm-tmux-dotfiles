local M = {}

function M.apply(config, wezterm, env)
  config.font = wezterm.font_with_fallback({
    'JetBrains Mono',
    'SF Mono',
    'Menlo',
    'Noto Color Emoji',
  })
  config.font_size = 13.0
  config.line_height = 1.05
  config.harfbuzz_features = { 'calt=0', 'liga=0' }

  config.color_scheme = 'TokyoNightStorm (Gogh)'

  config.window_padding = {
    left = 10,
    right = 10,
    top = 8,
    bottom = 8,
  }
  config.window_background_opacity = 1.0
end

return M

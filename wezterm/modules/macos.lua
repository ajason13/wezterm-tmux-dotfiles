local M = {}

function M.apply(config, wezterm)
  if not wezterm.target_triple:find('darwin') then
    return
  end

  config.native_macos_fullscreen_mode = true
  config.integrated_title_button_style = 'MacOsNative'
end

return M

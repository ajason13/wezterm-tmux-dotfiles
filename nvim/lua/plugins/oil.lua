return {
  'stevearc/oil.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  lazy = false,          -- oil hijacks netrw, so it must load at startup
  keys = {
    { '-', '<cmd>Oil<cr>', desc = 'Open parent directory (oil)' },
  },
  opts = {
    view_options = { show_hidden = true },
  },
}

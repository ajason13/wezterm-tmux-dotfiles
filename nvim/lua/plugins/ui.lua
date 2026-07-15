return {
  {
    'folke/tokyonight.nvim',
    lazy = false,
    priority = 1000,       -- load the colorscheme before other UI
    config = function()
      require('tokyonight').setup({ style = 'storm' })
      vim.cmd.colorscheme('tokyonight-storm')
    end,
  },
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    event = 'VeryLazy',
    opts = {
      options = { theme = 'tokyonight', globalstatus = true },
    },
  },
}

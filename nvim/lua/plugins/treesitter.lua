return {
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  event = { 'BufReadPost', 'BufNewFile' },
  main = 'nvim-treesitter.configs',
  opts = {
    ensure_installed = { 'lua', 'bash', 'json', 'yaml', 'markdown', 'gitcommit', 'diff' },
    highlight = { enable = true },
    indent = { enable = true },
  },
}

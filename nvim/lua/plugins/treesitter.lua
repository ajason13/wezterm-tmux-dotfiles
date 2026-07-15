return {
  'nvim-treesitter/nvim-treesitter',
  -- The `main` branch is the current, actively-developed nvim-treesitter, built
  -- for modern Neovim (0.11+). The frozen `master` branch's query predicates
  -- call treesitter node APIs that no longer exist in Neovim 0.12, which breaks
  -- injected-language parsing (e.g. markdown code blocks).
  branch = 'main',
  lazy = false,
  build = ':TSUpdate',
  config = function()
    -- Install the parsers this config uses (async on first run). Guarded so the
    -- headless test harness can pre-install them synchronously without a second
    -- concurrent installer racing it. Keep this list in sync with the one in
    -- scripts/test-nvim.sh.
    if not vim.env.NVIM_TEST_SKIP_TS_INSTALL then
      require('nvim-treesitter').install({
        'lua',
        'bash',
        'json',
        'yaml',
        'markdown',
        'markdown_inline',
        'gitcommit',
        'diff',
        'vim',
        'query',
      })
    end

    -- On the `main` branch, highlighting is Neovim core (vim.treesitter.start),
    -- not a plugin option, so enable it per buffer on FileType. pcall keeps it
    -- quiet for filetypes whose parser is not installed.
    --
    -- Treesitter-based indentation is intentionally not enabled: it is
    -- experimental on the main branch and needs an explicit indentexpr, and this
    -- read-mostly config relies on Neovim's built-in filetype indentation.
    vim.api.nvim_create_autocmd('FileType', {
      callback = function(args)
        pcall(vim.treesitter.start, args.buf)
      end,
    })
  end,
}

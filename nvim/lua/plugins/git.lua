return {
  {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {
      on_attach = function(bufnr)
        local gs = require('gitsigns')
        local function map(l, r, desc)
          vim.keymap.set('n', l, r, { buffer = bufnr, desc = desc })
        end
        vim.keymap.set('n', ']c', function()
          if vim.wo.diff then return ']c' end
          vim.schedule(function() gs.nav_hunk('next') end)
          return '<Ignore>'
        end, { buffer = bufnr, expr = true, desc = 'Next git hunk' })
        vim.keymap.set('n', '[c', function()
          if vim.wo.diff then return '[c' end
          vim.schedule(function() gs.nav_hunk('prev') end)
          return '<Ignore>'
        end, { buffer = bufnr, expr = true, desc = 'Previous git hunk' })
        map('<leader>gs', gs.stage_hunk, 'Stage hunk')
        map('<leader>gr', gs.reset_hunk, 'Reset hunk')
        map('<leader>gb', function() gs.blame_line({ full = true }) end, 'Blame line')
      end,
    },
  },
  {
    'sindrets/diffview.nvim',
    cmd = { 'DiffviewOpen', 'DiffviewFileHistory' },
    keys = {
      { '<leader>gd', '<cmd>DiffviewOpen main...HEAD<cr>', desc = 'Review branch vs main' },
      { '<leader>gh', '<cmd>DiffviewFileHistory %<cr>', desc = 'File history (current file)' },
    },
  },
  {
    'kdheepak/lazygit.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    cmd = { 'LazyGit' },
    keys = {
      { '<leader>gg', '<cmd>LazyGit<cr>', desc = 'Open lazygit' },
    },
  },
}

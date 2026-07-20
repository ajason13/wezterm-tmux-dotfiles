local map = vim.keymap.set

-- Split navigation (mirrors tmux hjkl muscle memory).
map('n', '<C-h>', '<C-w>h', { desc = 'Go to left split' })
map('n', '<C-j>', '<C-w>j', { desc = 'Go to lower split' })
map('n', '<C-k>', '<C-w>k', { desc = 'Go to upper split' })
map('n', '<C-l>', '<C-w>l', { desc = 'Go to right split' })

-- Write / quit.
map('n', '<leader>w', '<cmd>write<cr>', { desc = 'Write file' })
map('n', '<leader>q', '<cmd>quit<cr>', { desc = 'Quit window' })

-- Clear search highlight.
map('n', '<Esc>', '<cmd>nohlsearch<cr>', { desc = 'Clear search highlight' })

-- Toggle soft-wrap for the current window. Prose wraps by default (see
-- config.autocmds); flip it off to read a wide Markdown table correctly
-- (render-markdown draws it and you scroll right), then flip back for prose.
map('n', '<leader>tw', function()
  vim.wo.wrap = not vim.wo.wrap
  vim.notify('wrap ' .. (vim.wo.wrap and 'on' or 'off'))
end, { desc = 'Toggle line wrap' })

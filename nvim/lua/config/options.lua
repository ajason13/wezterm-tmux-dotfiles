local opt = vim.opt

opt.number = true
opt.relativenumber = true        -- counted motions like 5j become learnable
opt.mouse = 'a'                   -- mouse works as an escape hatch
opt.clipboard = 'unnamedplus'     -- yank/paste uses the system clipboard
opt.ignorecase = true
opt.smartcase = true
opt.termguicolors = true
opt.undofile = true               -- persistent undo across sessions
opt.signcolumn = 'yes'            -- stable gutter for gitsigns
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.splitright = true
opt.splitbelow = true
opt.scrolloff = 5
opt.wrap = false

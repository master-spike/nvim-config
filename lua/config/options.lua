-- Core options. Leader must be set before plugins load (keymaps).
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.termguicolors = true
opt.mouse = "a"

opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true
opt.shiftround = true

opt.ignorecase = true
opt.smartcase = true
opt.inccommand = "nosplit"

opt.splitright = true
opt.splitbelow = true
opt.splitkeep = "screen"

opt.wrap = false
opt.linebreak = true
opt.scrolloff = 4
opt.sidescrolloff = 8

opt.undofile = true
opt.undolevels = 10000
opt.swapfile = false
opt.updatetime = 200
opt.timeoutlen = 300
opt.confirm = true

opt.completeopt = "menu,menuone,noselect"
opt.pumheight = 10
opt.winminwidth = 5

opt.list = true
opt.fillchars = { eob = " ", diff = "╱" }

-- Ported from previous config
vim.g.snacks_animate = false
opt.spell = false
opt.smoothscroll = false

-- Yank to / paste from the system clipboard by default
opt.clipboard = "unnamedplus"

-- Use ripgrep when available
if vim.fn.executable("rg") == 1 then
  opt.grepprg = "rg --vimgrep"
  opt.grepformat = "%f:%l:%c:%m"
end

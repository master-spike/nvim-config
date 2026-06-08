-- vim-tmux-navigator: keymaps for seamless tmux/nvim window navigation
local map = vim.keymap.set
map("n", "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>", { desc = "Navigate left" })
map("n", "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>", { desc = "Navigate down" })
map("n", "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>", { desc = "Navigate up" })
map("n", "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>", { desc = "Navigate right" })
map("n", "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>", { desc = "Navigate previous" })

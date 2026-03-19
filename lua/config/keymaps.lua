-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n", "<Esc>", "<cmd>noh<cr>", { desc = "Clear highlights" })
vim.keymap.set("i", "<M-k>", vim.lsp.buf.signature_help, { desc = "Signature Help" })

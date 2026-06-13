-- Keymaps (native; LazyVim-equivalent essentials + ported custom)
local map = vim.keymap.set

-- Ported from previous config
map("n", "<Esc>", "<cmd>noh<cr>", { desc = "Clear highlights" })
map("i", "<M-k>", vim.lsp.buf.signature_help, { desc = "Signature Help" })

-- Better up/down on wrapped lines
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

-- Window navigation handled by vim-tmux-navigator (<C-h/j/k/l>)
-- Window management
map("n", "<leader>wd", "<C-W>c", { desc = "Delete window" })
map("n", "<leader>w-", "<C-W>s", { desc = "Split window below" })
map("n", "<leader>w|", "<C-W>v", { desc = "Split window right" })

-- Resize with arrows
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase width" })

-- Buffers
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete buffer" })

-- Move lines
map("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move line down" })
map("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move line up" })
map("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move down" })
map("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move up" })

-- Save / quit
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file" })
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit all" })

-- UI toggles (<leader>u prefix)
map("n", "<leader>uh", function()
  local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
  vim.lsp.inlay_hint.enable(not enabled, { bufnr = 0 })
end, { desc = "Toggle inlay hints" })
map("n", "<leader>uw", "<cmd>set wrap!<CR>", { desc = "Toggle line wrap" })
map("n", "<leader>uf", function()
  local bufnr = vim.api.nvim_get_current_buf()
  local state = _G.conform_format_state
  state.buffer_overrides[bufnr] = not (state.buffer_overrides[bufnr] or state.enabled)
  vim.notify("Buffer formatter " .. (state.buffer_overrides[bufnr] and "enabled" or "disabled"))
end, { desc = "Toggle formatter (buffer)" })
map("n", "<leader>uF", function()
  local state = _G.conform_format_state
  state.enabled = not state.enabled
  vim.notify("Global formatter " .. (state.enabled and "enabled" or "disabled"))
end, { desc = "Toggle formatter (global)" })

-- Diagnostics
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line diagnostics" })
map("n", "]d", function()
  vim.diagnostic.jump({ count = 1 })
end, { desc = "Next diagnostic" })
map("n", "[d", function()
  vim.diagnostic.jump({ count = -1 })
end, { desc = "Prev diagnostic" })

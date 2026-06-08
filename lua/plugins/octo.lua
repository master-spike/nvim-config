require("octo").setup({
  picker = "telescope",
  enable_builtin = true,
})

local map = vim.keymap.set
map("n", "<leader>oi", "<CMD>Octo issue list<CR>", { desc = "List GitHub Issues" })
map("n", "<leader>op", "<CMD>Octo pr list<CR>", { desc = "List GitHub PullRequests" })
map("n", "<leader>od", "<CMD>Octo discussion list<CR>", { desc = "List GitHub Discussions" })
map("n", "<leader>on", "<CMD>Octo notification list<CR>", { desc = "List GitHub Notifications" })
map("n", "<leader>os", function()
  require("octo.utils").create_base_search_command({ include_current_repo = true })
end, { desc = "Search GitHub" })

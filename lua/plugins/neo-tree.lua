require("neo-tree").setup({
  filesystem = {
    filtered_items = {
      visible = false, -- Hide the items matched below
      hide_gitignored = true, -- Yes, hide things in your .gitignore
      hide_dotfiles = false, -- No, DO NOT hide dotfiles globally
      hide_by_name = {
        ".git",
      },
    },
  },
})

-- Toggle the file explorer; when opening, jump to the current buffer's file.
vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle reveal<cr>", { desc = "Explorer (reveal current file)" })

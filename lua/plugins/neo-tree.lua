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
    components = {
      icon = function(config, node, state)
        if node.type == "file" and node.link_to then
          return {
            text = "→ ",
            highlight = "NeoTreeSymbolicLinkTarget",
          }
        end
        return require("neo-tree.sources.filesystem.components").icon(config, node, state)
      end,
    },
  },
})

-- Toggle the file explorer; when opening, jump to the current buffer's file.
vim.keymap.set("n", "<leader>e", "<cmd>Neotree toggle reveal<cr>", { desc = "Explorer (reveal current file)" })

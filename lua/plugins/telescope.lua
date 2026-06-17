-- Telescope + fzf-native
local telescope = require("telescope")
local path_util = require("util.path")

telescope.setup({
  defaults = {
    layout_strategy = "horizontal",
    layout_config = { prompt_position = "top" },
    sorting_strategy = "ascending",
    winblend = 0,
    -- Minify paths in every picker that displays a filepath (find_files,
    -- live_grep, oldfiles, lsp, quickfix, ...) using the same collapsing rule
    -- as the lualine statusline. path_display receives the path telescope is
    -- about to show and returns the string to render.
    path_display = function(_, path)
      return path_util.collapse(path)
    end,
  },
  pickers = {
    find_files = {
      find_command = {
        "git",
        "ls-files",
        "--cached",
        "--others",
        "--exclude-standard",
      },
    },
  },
  extensions = {
    fzf = {},
    ["ui-select"] = {
      require("telescope.themes").get_dropdown({}),
    },
  },
})

pcall(telescope.load_extension, "fzf")
pcall(telescope.load_extension, "ui-select")

local builtin = require("telescope.builtin")
local map = vim.keymap.set
map("n", "<leader><space>", builtin.find_files, { desc = "Find files" })
map("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
map("n", "<leader>f/", builtin.live_grep, { desc = "Grep" })
map("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })
map("n", "<leader>fh", builtin.help_tags, { desc = "Help" })
map("n", "<leader>fr", builtin.oldfiles, { desc = "Recent files" })
map("n", "<leader>sg", builtin.live_grep, { desc = "Grep" })
map("n", "<leader>sk", builtin.keymaps, { desc = "Keymaps" })

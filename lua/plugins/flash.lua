-- flash.nvim: jump anywhere with labelled search motions.
require("flash").setup()

local flash = require("flash")

-- Remap flash from 's' to 'gs' to avoid conflict with surround plugin
vim.keymap.set({ "n", "x", "o" }, "gs", function()
  flash.jump()
end, { desc = "Flash" })

vim.keymap.set({ "n", "x", "o" }, "S", function()
  flash.treesitter()
end, { desc = "Flash Treesitter" })

vim.keymap.set("o", "r", function()
  flash.remote()
end, { desc = "Remote Flash" })

vim.keymap.set({ "o", "x" }, "R", function()
  flash.treesitter_search()
end, { desc = "Treesitter Search" })

vim.keymap.set("c", "<c-s>", function()
  flash.toggle()
end, { desc = "Toggle Flash Search" })

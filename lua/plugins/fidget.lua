-- fidget.nvim: lightweight progress notifications in the bottom-right corner.
-- Used here as the "little spinner" indicator for codecompanion requests
-- (wired up in plugins/codecompanion.lua) and for LSP progress generally.
require("fidget").setup({
  notification = {
    window = {
      winblend = 0,
    },
  },
})

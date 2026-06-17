-- fidget.nvim: lightweight progress notifications in the bottom-right corner.
-- Used for LSP progress and other async operations.
require("fidget").setup({
  notification = {
    window = {
      winblend = 0,
    },
  },
})

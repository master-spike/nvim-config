-- Colorscheme: gruvbox (with previous overrides) + nightfox available.
require("gruvbox").setup({
  overrides = {
    LspInlayHint = { bg = "#504945" },
    GitSignsAdd = { fg = "#76CD30" },
    GitSignsAddLn = { fg = "#76CD30" },
    GitSignsChange = { fg = "#64B0C3" },
    GitSignsChangeLn = { fg = "#64B0C3" },
  },
})

vim.cmd.colorscheme("gruvbox")

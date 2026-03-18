return {
  { "EdenEast/nightfox.nvim" },
  {
    "ellisonleao/gruvbox.nvim",
    opts = {
      overrides = {
        LspInlayHint = { bg = "#504945" },
        GitSignsAdd = { fg = "#76CD30" },
        GitSignsAddLn = { fg = "#76CD30" },
        GitSignsChange = { fg = "#64B0C3" },
        GitSignsChangeLn = { fg = "#64B0C3" },
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox",
    },
  },
}

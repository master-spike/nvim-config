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

require("kanagawa").setup({
  overrides = function(colors)
    return {
      LspInlayHint = { bg = "#403935" },
      GitSignsAdd = { fg = "#46BD30" },
      GitSignsAddLn = { fg = "#4BCD30" },
      GitSignsChange = { fg = "#3490C3" },
      GitSignsChangeLn = { fg = "#3490C3" },
    }
  end,
})

require("material").setup({

  contrast = {
    terminal = false, -- Enable contrast for the built-in terminal
    sidebars = false, -- Enable contrast for sidebar-like windows ( for example Nvim-Tree )
    floating_windows = false, -- Enable contrast for floating windows
    cursor_line = false, -- Enable darker background for the cursor line
    lsp_virtual_text = false, -- Enable contrasted background for lsp virtual text
    non_current_windows = false, -- Enable contrasted background for non-current windows
    filetypes = {}, -- Specify which filetypes get the contrasted (darker) background
  },

  styles = { -- Give comments style such as bold, italic, underline etc.
    comments = { italic = true },
    strings = {},
    keywords = {},
    functions = {},
    variables = {},
    operators = {},
    types = {},
  },

  plugins = { -- Uncomment the plugins that you use to highlight them
    -- Available plugins:
    "blink",
    -- "coc",
    -- "colorful-winsep",
    -- "dap",
    -- "dashboard",
    -- "eyeliner",
    "fidget",
    "flash",
    "gitsigns",
    -- "harpoon",
    -- "hop",
    -- "illuminate",
    -- "indent-blankline",
    -- "lspsaga",
    "mini",
    "neo-tree",
    -- "neogit",
    -- "neorg",
    -- "neotest",
    -- "noice",
    -- "nvim-cmp",
    -- "nvim-navic",
    -- "nvim-notify",
    -- "nvim-tree",
    "nvim-web-devicons",
    -- "rainbow-delimiters",
    -- "sneak",
    "telescope",
    "trouble",
    "which-key",
  },

  disable = {
    colored_cursor = false, -- Disable the colored cursor
    borders = false, -- Disable borders between vertically split windows
    background = false, -- Prevent the theme from setting the background (NeoVim then uses your terminal background)
    term_colors = false, -- Prevent the theme from setting terminal colors
    eob_lines = false, -- Hide the end-of-buffer lines
  },

  high_visibility = {
    lighter = false, -- Enable higher contrast text for lighter style
    darker = false, -- Enable higher contrast text for darker style
  },

  lualine_style = "default", -- Lualine style ( can be 'stealth' or 'default' )

  async_loading = true, -- Load parts of the theme asynchronously for faster startup (turned on by default)

  custom_colors = nil, -- If you want to override the default colors, set this to a function

  custom_highlights = {}, -- Overwrite highlights with your own
})

vim.g.material_style = "darker"
vim.cmd.colorscheme("material")

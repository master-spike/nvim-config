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

vim.g.material_style = "darker"
local material = require("material")
local material_colors = require("material.colors")

material.setup({

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
    strings = { italic = true },
    keywords = {},
    functions = {},
    variables = {},
    operators = {},
    types = { bold = true },
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

  async_loading = false, -- Load parts of the theme asynchronously for faster startup (turned on by default)

  custom_colors = nil, -- If you want to override the default colors, set this to a function

  custom_highlights = {
    LspInlayHint = { bg = "#323232", fg = "#D0D8E0", italic = true },

    -- Syntax highlighting colors
    Keyword = { fg = material_colors.main.orange },
    ["@keyword"] = { fg = material_colors.main.orange },
    ["@keyword.builtin"] = { fg = material_colors.main.orange },
    ["@type.qualifier"] = { fg = material_colors.main.orange },
    ["@attribute"] = { fg = material_colors.main.purple }, -- Annotations without background
    ["@attribute.builtin"] = { fg = material_colors.main.purple },
    ["@property"] = { fg = material_colors.editor.fg },
    ["@lsp.type.interface"] = { link = "@type" }, -- material links interface to identifier by default

    -- Completion menu background (blink.cmp and similar)
    Pmenu = { bg = material_colors.editor.bg_alt },
    PmenuSel = { bg = material_colors.editor.active },
    BlinkCmpMenu = { bg = material_colors.editor.bg_alt },
    BlinkCmpMenuBorder = { fg = material_colors.editor.border, bg = material_colors.editor.bg_alt },
    BlinkCmpMenuSelection = { bg = material_colors.editor.active },
  },
})

vim.cmd.colorscheme("material")

require("colorizer").setup({
  filetypes = {
    "css",
    "javascript",
    "typescript",
    "tsx",
    "jsx",
    "html",
    "lua",
    "json",
    "yaml",
    "markdown",
    "*",
  },
  user_default_options = {
    RGB = true, -- #RGB hex codes
    RRGGBB = true, -- #RRGGBB hex codes
    names = false, -- "Name" codes like Blue, green, etc
    RRGGBBAA = true, -- #RRGGBBAA hex codes
    AARRGGBB = false, -- 0xAARRGGBB hex codes
    rgb_fn = true, -- CSS rgb() and rgba() functions
    hsl_fn = true, -- CSS hsl() and hsla() functions
    css = true, -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
    css_fn = true, -- Enable all CSS *functions*: rgb_fn, hsl_fn
    mode = "background", -- Set the display mode
    tailwind = true, -- Enable tailwind colors
    sass = { enable = true, parsers = { "css" } }, -- Enable sass colors
    virtualtext = "■", -- Change the virtualtext character
    always_update = false,
  },
})

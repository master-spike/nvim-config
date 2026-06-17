---
name: nvim-colorscheme
description: >-
  Material.nvim colorscheme wiring for this hand-rolled Neovim config. Use when
  changing the theme, editing highlight groups, debugging WhichKey/Blink/Pmenu
  colors, touching lualine theme coupling, or checking load order for
  g:material_style, material.setup(), :colorscheme, and manual nvim_set_hl
  overrides.
covers:
  - lua/plugins/colorscheme.lua
---

# Colorscheme

Material.nvim is the only active colorscheme. It is configured in
`lua/plugins/colorscheme.lua`, installed at
`~/.local/share/nvim/site/pack/core/opt/material.nvim/`, and pinned in
`nvim-pack-lock.json` at rev `92f7366a93`. Upstream:
https://github.com/marko-cerovac/material.nvim.

## Role

Keep color work grounded in Material's installed API. Do not guess highlight
names, setup keys, or theme-switching steps. Read `:help material.nvim`,
`doc/material.nvim.txt`, and the installed Lua before editing.

## What's configured

Real load order in `lua/plugins/colorscheme.lua`:

```lua
vim.g.material_style = "darker"
local material = require("material")
local material_colors = require("material.colors")

material.setup({
  contrast = {
    terminal = false,
    sidebars = false,
    floating_windows = false,
    cursor_line = false,
    lsp_virtual_text = false,
    non_current_windows = false,
    filetypes = {},
  },
  styles = {
    comments = { italic = true },
    strings = { italic = true },
    keywords = {},
    functions = {},
    variables = {},
    operators = {},
    types = { bold = true },
  },
  plugins = {
    "blink",
    "fidget",
    "flash",
    "gitsigns",
    "mini",
    "neo-tree",
    "nvim-web-devicons",
    "telescope",
    "trouble",
    "which-key",
  },
  disable = {
    colored_cursor = false,
    borders = false,
    background = false,
    term_colors = false,
    eob_lines = false,
  },
  high_visibility = {
    lighter = false,
    darker = false,
  },
  lualine_style = "default",
  async_loading = false,
  custom_colors = nil,
  custom_highlights = {
    LspInlayHint = {
      bg = "#323232",
      fg = "#D0D8E0",
      italic = true,
    },
    Keyword = { fg = material_colors.main.orange },
    ["@keyword"] = { fg = material_colors.main.orange },
    ["@keyword.builtin"] = { fg = material_colors.main.orange },
    ["@type.qualifier"] = { fg = material_colors.main.orange },
    ["@attribute"] = { fg = material_colors.main.purple },
    ["@attribute.builtin"] = { fg = material_colors.main.purple },
    ["@property"] = { fg = material_colors.editor.fg },
    ["@lsp.type.interface"] = { link = "@type" },
    Pmenu = { bg = material_colors.editor.bg_alt },
    PmenuSel = { bg = material_colors.editor.active },
    BlinkCmpMenu = { bg = material_colors.editor.bg_alt },
    BlinkCmpMenuBorder = {
      fg = material_colors.editor.border,
      bg = material_colors.editor.bg_alt,
    },
    BlinkCmpMenuSelection = { bg = material_colors.editor.active },
    WhichKeyFloat = { bg = material_colors.editor.bg_alt },
    WhichKeyBorder = {
      fg = material_colors.editor.border,
      bg = material_colors.editor.bg_alt,
    },
    TelescopeResultsFileName = { fg = material_colors.main.orange },
  },
})

vim.cmd.colorscheme("material")

vim.api.nvim_set_hl(0, "WhichKeyFloat", {
  bg = material_colors.editor.bg_alt,
})
vim.api.nvim_set_hl(0, "WhichKeyBorder", {
  fg = material_colors.editor.border,
  bg = material_colors.editor.bg_alt,
})
vim.api.nvim_set_hl(0, "WhichKeyNormal", {
  bg = material_colors.editor.bg_alt,
})
```

## Load-order rules

1. Set `vim.g.material_style = "darker"` before `material.setup()` and before
   `vim.cmd.colorscheme("material")`. Material docs say style settings must be
   placed before applying the colorscheme.
2. Put Material-owned overrides in `custom_highlights` inside
   `material.setup()`.
   Installed docs show `custom_highlights` as a setup key.
3. Run `vim.cmd.colorscheme("material")` after setup. This applies the theme.
4. Put manual `vim.api.nvim_set_hl()` overrides after `:colorscheme`. A
   colorscheme application clears/replaces highlight groups, so post-theme
   overrides must be re-applied after it.

Correct post-colorscheme override pattern:

```lua
vim.cmd.colorscheme("material")
vim.api.nvim_set_hl(0, "FloatBorder", {
  fg = require("material.colors").editor.border,
  bg = require("material.colors").editor.bg_alt,
})
```

## Capabilities + examples

- Change the style by editing only line 1 of `lua/plugins/colorscheme.lua`:
  `vim.g.material_style = "darker"`. Valid installed styles include `oceanic`,
  `deep ocean`, `palenight`, `lighter`, and `darker`.
- Add plugin integration by adding a real name to the `plugins` allowlist.
  Verify the name in `doc/material.nvim.txt` first.
- Override Treesitter or LSP groups inside `custom_highlights` if the
  override is part of the theme.
- Override volatile float groups after `vim.cmd.colorscheme("material")` if the
  group is being reset by the colorscheme.

## Cross-plugin coupling

`lua/config/pack.lua` installs Material before UI plugins and loads the
`colorscheme` module before `lualine`, `bufferline`, `whichkey`, and most other
plugin modules. Keep this order.

`lua/plugins/whichkey.lua` requires `material.colors` directly. Keep Material
installed before `whichkey` loads. `lua/plugins/lualine.lua` sets
`options.theme = "material"`; the theme file comes from Material's installed
`lua/lualine/themes/material.lua` and reads Material settings.

## Gotchas/version notes

- `nvim-pack-lock.json` also lists `catppuccin`, `gruvbox.nvim`, `kanagawa`, and
  `nightfox.nvim`. These are lockfile leftovers: they are not in
  `vim.pack.add()` and are not active.
- To switch themes, add the new plugin to `vim.pack.add()` in
  `lua/config/pack.lua`, change `vim.cmd.colorscheme(...)`, and update any
  modules that require `material.colors` or use `theme = "material"`.
- Do not move the final WhichKey `nvim_set_hl()` calls above
  `vim.cmd.colorscheme("material")`; they are intentionally post-theme.

## Docs / ground truth

- Config: `lua/plugins/colorscheme.lua`.
- Pack load order: `lua/config/pack.lua`, modules list lines for `colorscheme`,
  `lualine`, and `whichkey`.
- Installed source/docs:
  `~/.local/share/nvim/site/pack/core/opt/material.nvim/`.
- Help tags: `:help material.nvim`, `:help material-configuration`,
  `:help material-examples`.
- Color table: installed `lua/material/colors/init.lua`.
- Lualine theme: installed `lua/lualine/themes/material.lua`.
- Upstream: https://github.com/marko-cerovac/material.nvim.
- Pin: `nvim-pack-lock.json`, `material.nvim` rev `92f7366a93`.

## Verify your change

Run from `~/.config/nvim`:

```bash
luac -p lua/plugins/colorscheme.lua
nvim --headless -u init.lua -c 'lua
  assert(vim.g.material_style == "darker")
  assert(vim.g.colors_name == "material")
  local colors = require("material.colors")
  assert(type(colors.editor.bg_alt) == "string")
  local wk = vim.api.nvim_get_hl(0, { name = "WhichKeyNormal" })
  assert(wk.bg, "WhichKeyNormal bg missing")
  print("PASS colorscheme")
' -c 'qa!' 2>&1 | grep -v tbl_flatten
```

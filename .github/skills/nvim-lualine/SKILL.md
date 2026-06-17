---
name: nvim-lualine
description: >-
  lualine.nvim statusline setup and the repo-wide path shortening helper. Use
  when changing statusline sections, the custom filename component, material
  theme, globalstatus, separators, or util.path.collapse behavior.
covers:
  - lua/plugins/lualine.lua
  - lua/util/path.lua
---

# Lualine

## Role

Statusline. This config keeps lualine small and makes `lua/util/path.lua` the
single source of truth for path shortening across lualine, Telescope, and the
custom gitsigns hunk picker.

Ground truth:
- Config: `lua/plugins/lualine.lua`.
- Shared helper: `lua/util/path.lua`.
- Install root: `~/.local/share/nvim/site/pack/core/opt/`.
- Install dir: `lualine.nvim/`.
- Pinned rev: `221ce6b2d999187044529f49da6554a92f740a96`.
- Upstream: https://github.com/nvim-lualine/lualine.nvim
- Help: `:help lualine`.
- Docs: `lualine.nvim/doc/lualine.txt`.

## What's configured

The real setup in `lua/plugins/lualine.lua`:

```lua
local path_util = require("util.path")

local function custom_filename()
  local filepath = vim.api.nvim_buf_get_name(0)
  if filepath == "" then
    return "[No Name]"
  end

  local buftype = vim.bo.buftype
  if buftype ~= "" then
    return vim.fn.fnamemodify(filepath, ":t")
  end

  local result = path_util.collapse(filepath)

  if vim.bo.modified then
    result = result .. " [+]"
  end
  if vim.bo.readonly or not vim.bo.modifiable then
    result = result .. " [RO]"
  end

  return result
end

require("lualine").setup({
  options = {
    theme = "material",
    globalstatus = true,
    section_separators = "",
    component_separators = "",
  },
  sections = {
    lualine_c = { custom_filename },
  },
})
```

## The custom filename component

Rules in order:

```text
empty buffer name             -> [No Name]
special buftype               -> tail only, via fnamemodify(filepath, ":t")
normal file                   -> util.path.collapse(filepath)
modified buffer               -> append " [+]"
readonly or unmodifiable      -> append " [RO]"
```

Do not replace this with lualine's built-in `filename` component unless asked.
The custom behavior is in `lua/plugins/lualine.lua`.

## Shared path shortening

`lua/util/path.lua` is shared by:

```text
lua/plugins/lualine.lua       statusline filename
lua/plugins/telescope.lua     defaults.path_display
lua/plugins/gitsigns.lua      custom <leader>fg entry display
```

`collapse(filepath)` accepts an absolute or cwd-relative path. For paths under
`vim.uv.cwd()`, it splits the relative path and walks parent directories. Each
directory segment whose parent has exactly one subdirectory becomes `...`. Then
consecutive `...` segments are deduped. The final path component is always kept.
Paths outside cwd return `vim.fn.fnamemodify(filepath, ":~:.")`.

`is_only_directory(parent)` uses `vim.uv.fs_scandir(parent)` and caches the
boolean result in `single_subdir_cache`. Use `M.clear_cache()` to force a
rescan. Stale cache entries affect display only, not navigation.

## Capabilities + examples

```text
file in normal buffer       .../reporting/file.lua
modified file               .../reporting/file.lua [+]
readonly file               .../reporting/file.lua [RO]
terminal or quickfix buffer  tail-name-only
unnamed buffer              [No Name]
```

If you change path shortening, update `lua/util/path.lua` instead of copying
logic into lualine. See `nvim-telescope` and `nvim-gitsigns` for the other call
sites.

## Gotchas / version notes

- `theme = "material"` is configured. The theme name is listed in
  `lualine.nvim/THEMES.md` at this pinned rev.
- `globalstatus = true` requests a single global statusline. The option is
  documented in `lualine.nvim/doc/lualine.txt` and used in
  `lualine.nvim/lua/lualine/config.lua`.
- Empty string separators are documented as a no-separator style in
  `lualine.nvim/doc/lualine.txt`. `get_config()` normalizes them to tables
  with empty `left` and `right` fields.
- `sections.lualine_c = { custom_filename }` is the only section override here.

## Docs / ground truth

Verify lualine options and util behavior before editing:

```bash
P=~/.local/share/nvim/site/pack/core/opt/lualine.nvim
rg -n 'globalstatus|section_separators' "$P"/doc/lualine.txt
rg -n 'component_separators|lualine_c' "$P"/doc/lualine.txt
rg -n 'material' "$P"/THEMES.md
cd ~/.config/nvim
rg -n 'function M.collapse|fs_scandir|clear_cache' lua/util/path.lua
```

## Verify your change

Run from `~/.config/nvim`:

```bash
luac -p lua/plugins/lualine.lua lua/util/path.lua
nvim --headless -u init.lua -c 'lua
  local cfg = require("lualine").get_config()
  assert(cfg.options.theme == "material")
  assert(cfg.options.globalstatus == true)
  assert(cfg.options.section_separators.left == "")
  assert(cfg.options.section_separators.right == "")
  assert(cfg.options.component_separators.left == "")
  assert(cfg.options.component_separators.right == "")
  assert(type(cfg.sections.lualine_c[1]) == "function")
  assert(type(require("util.path").collapse("a/b.lua")) == "string")
  print("PASS lualine")
' -c 'qa!' 2>&1 | grep -v tbl_flatten
```

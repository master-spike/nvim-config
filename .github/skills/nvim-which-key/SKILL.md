---
name: nvim-which-key
description: >-
  Which-key popup and key description registration in this repo. Use when
  editing lua/plugins/whichkey.lua, group labels, mini.ai text-object labels,
  <leader>u labels, keymap descriptions, or the material colorscheme dependency.
covers:
  - lua/plugins/whichkey.lua
---

# Which-key

Key hint popup. Configured in `lua/plugins/whichkey.lua`. Installed source is
`~/.local/share/nvim/site/pack/core/opt/which-key.nvim/`, upstream is
https://github.com/folke/which-key.nvim, and `nvim-pack-lock.json` pins rev
`3aab2147e7`.

## Role
Use which-key to show existing keymap descriptions and to add group labels for
prefixes that are not normal mappings. It reads `desc` from keymaps by default;
use `wk.add()` for group labels or virtual mappings only.

## What's configured
Faithful excerpt from `lua/plugins/whichkey.lua`:

```lua
local wk = require("which-key")
local material_colors = require("material.colors")

wk.setup({
  delay = 0,
  win = {
    no_overlap = false,
    padding = { 1, 2 },
    title_pos = "center",
    wo = { winblend = 0 },
  },
})

wk.add({
  { "<leader>u", group = "ui" },
  { "<leader>uf", desc = "Toggle formatter (buffer)" },
  { "<leader>uF", desc = "Toggle formatter (global)" },
  { "<leader>ut", desc = "Toggle translations" },
})
```

The file then programmatically registers descriptions for mini.ai text objects.
It reads real prefixes from `require("mini.ai").config.mappings` and builds
around, inside, next, and last labels for operator-pending and visual modes.
The approach is adapted from LazyVim, but this repo is not LazyVim.

## Capabilities + examples
- Add a group label: `wk.add({ { "<leader>x", group = "diagnostics" } })`.
- Add a description for a virtual mapping:
  `wk.add({ { "<leader>ux", desc = "Toggle x" } })`.
- mini.ai labels cover objects such as `a` argument, `f` function, `c` class,
  quote/string objects, block objects, and tag objects.

## Gotchas / version notes
- `whichkey.lua` has a hard dependency on `require("material.colors")`. Keep
  `material.nvim` installed or update this require. See `nvim-colorscheme`.
- Do not hard-code mini.ai prefixes. The file reads them from
  `require("mini.ai").config.mappings` so remaps stay in sync.
- `wk.add()` is the v3 mapping API documented in `doc/which-key.nvim.txt`.
- Other files may add groups too; `codecompanion` adds `<leader>a = "AI"`.

## Docs / ground truth
- Config: `lua/plugins/whichkey.lua`; pack entry: `lua/config/pack.lua`.
- Installed docs/source:
  `~/.local/share/nvim/site/pack/core/opt/which-key.nvim/doc/` and
  `~/.local/share/nvim/site/pack/core/opt/which-key.nvim/lua/`.
- Help tag: `:help which-key`.
- mini.ai config source: installed `mini.nvim` and `lua/plugins/mini.lua`.
- Lockfile: `nvim-pack-lock.json`, rev `3aab2147e7`.

## Verify your change
Run from `~/.config/nvim`:

```bash
luac -p lua/plugins/whichkey.lua
nvim --headless -u init.lua \
  -c 'lua assert(require("which-key"))' \
  -c 'lua assert(require("mini.ai").config.mappings)' \
  -c 'qa!' 2>&1 | grep -v tbl_flatten
nvim --headless -u init.lua \
  -c 'lua assert(vim.wait(1000, function()
  return vim.fn.maparg("<leader>uf", "n") ~= ""
end))' \
  -c 'qa!' 2>&1 | grep -v tbl_flatten
```

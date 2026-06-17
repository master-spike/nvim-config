---
name: nvim-flash
description: >-
  flash.nvim jump/search setup. Use when changing Flash keymaps, jump behavior,
  Treesitter search, remote operator mode, command-line search toggle, or the gs
  remap that avoids the surround-plugin conflict.
covers:
  - lua/plugins/flash.lua
---

# Flash

## Role

Jump to visible text with labels, jump by Treesitter nodes, and enhance search.
Configured in `lua/plugins/flash.lua`.

Ground truth:
- Config: `lua/plugins/flash.lua`.
- Install root: `~/.local/share/nvim/site/pack/core/opt/`.
- Install dir: `flash.nvim/`.
- Pinned rev: `fcea7ff883235d9024dc41e638f164a450c14ca2`.
- Upstream: https://github.com/folke/flash.nvim
- Help: `:help flash`.
- Docs: `flash.nvim/doc/flash.nvim.txt`.

## What's configured

The real setup uses defaults:

```lua
require("flash").setup()
```

The real keymaps in `lua/plugins/flash.lua`:

```lua
local flash = require("flash")

-- Remap flash from 's' to 'gs' to avoid conflict with surround plugin
vim.keymap.set({ "n", "x", "o" }, "gs", function()
  flash.jump()
end, { desc = "Flash" })

vim.keymap.set({ "n", "x", "o" }, "S", function()
  flash.treesitter()
end, { desc = "Flash Treesitter" })

vim.keymap.set("o", "r", function()
  flash.remote()
end, { desc = "Remote Flash" })

vim.keymap.set({ "o", "x" }, "R", function()
  flash.treesitter_search()
end, { desc = "Treesitter Search" })

vim.keymap.set("c", "<c-s>", function()
  flash.toggle()
end, { desc = "Toggle Flash Search" })
```

## Capabilities + examples

```text
gs        normal, visual, operator-pending: flash.jump()
S         normal, visual, operator-pending: flash.treesitter()
r         operator-pending only: flash.remote()
R         visual and operator-pending: flash.treesitter_search()
<c-s>     command-line mode: flash.toggle()
```

Use `gs`, not `s`, for the main Flash jump. The config comment is the source of
truth for why: `Remap flash from 's' to 'gs' to avoid conflict with surround
plugin`. Do not reintroduce an `s` Flash map unless you also check the surround
setup in `nvim-mini`.

## Gotchas / version notes

- `flash.setup()` is called with no options. Defaults come from the pinned
  plugin source in `flash.nvim/lua/flash/config.lua`.
- The upstream docs show default examples with `s`, `S`, `r`, `R`, and `<c-s>`.
  This config changes only the main `s` jump to `gs`.
- Flash command functions exist in `flash.nvim/lua/flash/commands.lua`:
  `jump`, `treesitter`, `treesitter_search`, `remote`, and `toggle`.
- `r` is mapped only in operator-pending mode. Do not add normal-mode `r`.

## Docs / ground truth

Verify before changing a Flash API or keymap:

```bash
P=~/.local/share/nvim/site/pack/core/opt/flash.nvim
rg -n 'function M.jump|function M.remote' "$P"/lua/flash/commands.lua
rg -n 'treesitter_search|function M.toggle' "$P"/lua/flash/commands.lua
rg -n 'flash.jump|treesitter_search|<c-s>' "$P"/doc/flash.nvim.txt
cd ~/.config/nvim
rg -n 'Remap flash|vim.keymap.set' lua/plugins/flash.lua
```

## Verify your change

Run from `~/.config/nvim`:

```bash
luac -p lua/plugins/flash.lua
nvim --headless -u init.lua -c 'lua
  local flash = require("flash")
  assert(type(flash.jump) == "function")
  assert(type(flash.treesitter) == "function")
  assert(type(flash.remote) == "function")
  assert(type(flash.treesitter_search) == "function")
  assert(type(flash.toggle) == "function")
  assert(vim.fn.maparg("gs", "n") ~= "")
  assert(vim.fn.maparg("<c-s>", "c") ~= "")
  print("PASS flash")
' -c 'qa!' 2>&1 | grep -v tbl_flatten
```

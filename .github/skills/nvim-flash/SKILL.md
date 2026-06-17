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

The setup uses Flash's defaults. No custom keymaps are set because `gs` is now
used by mini.surround for surround operators:

```lua
require("flash").setup()
```

Flash's other features remain available via default keymaps.

## Capabilities + examples

Flash is available via the following default keymaps (consult `:help flash`):
- `f`/`F`/`t`/`T`: Char mode (enhanced f/F/t/T with labels)
- `S`: Flash Treesitter search

## Gotchas / version notes

- `flash.setup()` is called with defaults. Char mode (f/F/t/T) is enabled.
- The `gs` keybinding (formerly used for `flash.jump`) is now used by
  mini.surround for surround operators. Flash's main jump is unavailable.
- Flash command functions exist in `flash.nvim/lua/flash/commands.lua`:
  `jump`, `treesitter`, `treesitter_search`, `remote`, and `toggle`.

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
  -- gs is no longer mapped (used by surround)
  assert(vim.fn.maparg("gs", "n") == "", "gs should not be mapped (surround uses it)")
  print("PASS flash")
' -c 'qa!' 2>&1 | grep -v tbl_flatten
```

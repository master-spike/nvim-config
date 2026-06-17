---
name: nvim-trouble
description: >-
  Trouble.nvim diagnostics, symbols, LSP, loclist, and qflist keymaps in this
  repo. Use when editing lua/plugins/trouble.lua, <leader>x diagnostics maps,
  <leader>c symbols/LSP maps, or :Trouble command options.
covers:
  - lua/plugins/trouble.lua
---

# Trouble

Diagnostics and list UI. Configured in `lua/plugins/trouble.lua`. Installed
source is `~/.local/share/nvim/site/pack/core/opt/trouble.nvim/`, upstream is
https://github.com/folke/trouble.nvim, and `nvim-pack-lock.json` pins rev
`bd67efe408`.

## Role
Use Trouble for diagnostics, buffer diagnostics, document symbols, LSP result
lists, location lists, and quickfix lists. This config uses the `:Trouble
<mode> toggle` command form documented in `doc/trouble.nvim.txt`.

## What's configured
Faithful excerpt from `lua/plugins/trouble.lua`:

```lua
require("trouble").setup({})

map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>",
  { desc = "Diagnostics (Trouble)" })
map("n", "<leader>xX",
  "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
  { desc = "Buffer Diagnostics (Trouble)" })
map("n", "<leader>cs",
  "<cmd>Trouble symbols toggle focus=false<cr>",
  { desc = "Symbols (Trouble)" })
map("n", "<leader>cS",
  "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
  { desc = "LSP references/definitions (Trouble)" })
map("n", "<leader>xL", "<cmd>Trouble loclist toggle<cr>",
  { desc = "Location List (Trouble)" })
map("n", "<leader>xQ", "<cmd>Trouble qflist toggle<cr>",
  { desc = "Quickfix List (Trouble)" })
```

## Capabilities + examples
- `<leader>xx`: all diagnostics.
- `<leader>xX`: current-buffer diagnostics via `filter.buf=0`.
- `<leader>cs`: symbols, with `focus=false`.
- `<leader>cS`: LSP list, with `focus=false win.position=right`.
- `<leader>xL`: location list.
- `<leader>xQ`: quickfix list.

## Gotchas / version notes
- Keep the command syntax as `Trouble [mode] [action] [options]` unless the
  installed docs say otherwise.
- `filter.buf=0`, `focus=false`, and `win.position=right` are documented command
  options in `doc/trouble.nvim.txt`.
- This file does not create diagnostics itself; it displays Neovim diagnostics
  configured elsewhere, mainly `lua/config/lsp.lua`. See `nvim-lsp`.

## Docs / ground truth
- Config: `lua/plugins/trouble.lua`; pack entry: `lua/config/pack.lua`.
- Installed docs/source:
  `~/.local/share/nvim/site/pack/core/opt/trouble.nvim/doc/trouble.nvim.txt`
  and `~/.local/share/nvim/site/pack/core/opt/trouble.nvim/lua/`.
- Help tags: `:help trouble`, `:help trouble.nvim`.
- Lockfile: `nvim-pack-lock.json`, rev `bd67efe408`.

## Verify your change
Run from `~/.config/nvim`:

```bash
luac -p lua/plugins/trouble.lua
nvim --headless -u init.lua \
  -c 'lua assert(vim.fn.maparg("<leader>xx", "n") ~= "")' \
  -c 'lua assert(vim.fn.maparg("<leader>cS", "n") ~= "")' \
  -c 'qa!' 2>&1 | grep -v tbl_flatten
nvim --headless -u init.lua \
  -c 'lua assert(vim.fn.exists(":Trouble") == 2)' \
  -c 'qa!' 2>&1 | grep -v tbl_flatten
```

---
name: nvim-core-options-keymaps-autocmds
description: >-
  How core editor behaviour is configured in this Neovim config: options
  (lua/config/options.lua), global keymaps (lua/config/keymaps.lua), and
  autocommands (lua/config/autocmds.lua). Use when changing vim options,
  adding/editing a global keymap, or adding an autocommand. Covers the leader
  setup, the map+desc convention, and the augroup() helper.
covers:
  - lua/config/options.lua
  - lua/config/keymaps.lua
  - lua/config/autocmds.lua
---

# Core: options, keymaps, autocmds

These three files in `lua/config/` define editor behaviour independent of any
plugin. They are required by `init.lua` in order: `options` → `keymaps` →
`autocmds` (then `pack`, then `lsp`). See `nvim-config-overview` for load order.

## options.lua — `vim.opt` + leader
`lua/config/options.lua`. **Leader is set here and must stay first** because
`keymaps.lua` (loaded next) defines `<leader>` mappings:
```lua
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
```
Everything else is plain `vim.opt.<name> = <value>`. Read the file for the live
settings rather than assuming — the durable points are: leader is set before any
keymap; indentation/search/UI/file behaviour are set via `vim.opt`; the system
clipboard is used; and `grepprg` switches to `rg` when `rg` is on `PATH`.

To change an option: edit this file, keep the `opt.<name> = <value>` style.

## keymaps.lua — global `vim.keymap.set`
`lua/config/keymaps.lua`. The durable conventions (not the specific keys — read
the file for those):
- `local map = vim.keymap.set`, and **every mapping gets a `desc`** so which-key
  can show it.
- Use a Lua function (not a string) for anything non-trivial; keep `desc`.
- Leader **prefix groups** are organised by purpose (window / buffer / UI toggles
  / code-diagnostics / quit, etc.); the group *labels* are declared in which-key
  (see `nvim-which-key`). Follow the existing grouping when adding a map.
- An `expr` map example to copy for count-aware motions:
  ```lua
  map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
  ```

Scope rules (these are the load-bearing part):
- `<C-h/j/k/l>` are **not** defined here — they belong to vim-tmux-navigator
  (`nvim-misc-plugins`). Don't redefine them.
- **Plugin-specific keymaps live in that plugin's `lua/plugins/<x>.lua`**, not
  here. Only global/editor maps go in `keymaps.lua`. LSP maps live in
  `config/lsp.lua` (buffer-local, on `LspAttach`).

## autocmds.lua — `vim.api.nvim_create_autocmd`
`lua/config/autocmds.lua`. Uses a local helper so every group is namespaced and
cleared on reload:
```lua
local function augroup(name)
  return vim.api.nvim_create_augroup("config_" .. name, { clear = true })
end
```
Always pass `group = augroup("something")` when adding an autocmd here, matching
the existing entries (highlight-on-yank, restore last cursor location, close
certain filetypes with `q`, enable Treesitter-based C/C++ indentation,
auto-create missing parent dirs on save).

Pattern to add a new autocmd:
```lua
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup("my_feature"),
  callback = function(event)
    -- event.buf, event.match, etc.
  end,
})
```
Note other files create their own augroups directly with the same `config_`
prefix (e.g. `config_lint`, `config_jdtls`, `config_lsp_attach`) — that's the
house style for autocmds owned by a specific module.

## Verify your change
```bash
cd ~/.config/nvim
luac -p lua/config/options.lua   # (and keymaps.lua / autocmds.lua)
nvim --headless -u init.lua -c 'qa!'                       # loads clean?
# Option took effect (substitute the option you changed):
nvim --headless -u init.lua -c 'lua print(vim.o.shiftwidth)' -c 'qa!'
# A keymap is defined (substitute the lhs you added; non-empty == defined):
nvim --headless -u init.lua -c 'lua print(vim.fn.maparg("<leader>w","n"))' -c 'qa!'
# An autocmd group exists (substitute the augroup name you used):
nvim --headless -u init.lua \
  -c 'lua print(#vim.api.nvim_get_autocmds({ group = "config_highlight_yank" }))' \
  -c 'qa!'
```

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
Everything else is plain `vim.opt`. Current notable settings (read the file for
the full list — don't assume):
- Indent: `expandtab`, `shiftwidth=2`, `tabstop=2`, `softtabstop=2`,
  `smartindent`, `shiftround`.
- Search: `ignorecase`, `smartcase`, `inccommand="nosplit"`.
- UI: `number`, `relativenumber`, `signcolumn="yes"`, `cursorline`,
  `termguicolors`, `list` with custom `fillchars`.
- Files: `undofile`, `swapfile=false`, `updatetime=200`, `timeoutlen=300`.
- `clipboard="unnamedplus"` (yank/paste use the system clipboard).
- Uses `rg` for `grepprg` when `rg` is on PATH.

To change an option: edit this file, keep the `opt.<name> = <value>` style.

## keymaps.lua — global `vim.keymap.set`
`lua/config/keymaps.lua`. Convention: `local map = vim.keymap.set`, and **every
mapping gets a `desc`** (which-key shows it). Examples already present:
```lua
map("n", "<leader>wd", "<C-W>c", { desc = "Delete window" })
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map("n", "<leader>uh", function() ... end, { desc = "Toggle inlay hints" })
```
Notes / conventions:
- Prefix groups: `<leader>w` window, `<leader>b` buffer, `<leader>u` UI toggles,
  `<leader>c` code/diagnostics, `<leader>q` quit. Group labels are declared in
  which-key (see `nvim-which-key`).
- `<C-h/j/k/l>` are NOT defined here — they belong to vim-tmux-navigator
  (`nvim-misc-plugins`). Don't redefine them.
- **Plugin-specific keymaps live in that plugin's `lua/plugins/<x>.lua`**, not
  here. Only global/editor maps go in `keymaps.lua`. LSP maps live in
  `config/lsp.lua` (buffer-local, on `LspAttach`).
- Use a Lua function (not a string) for anything non-trivial; keep `desc`.

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
certain filetypes with `q`, auto-create missing parent dirs on save).

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
# Option took effect:
nvim --headless -u init.lua -c 'lua print(vim.o.shiftwidth)' -c 'qa!'
# Keymap is defined (non-empty rhs/callback):
nvim --headless -u init.lua -c 'lua print(vim.fn.maparg("<leader>wd","n"))' -c 'qa!'
# Autocmd group exists:
nvim --headless -u init.lua \
  -c 'lua print(#vim.api.nvim_get_autocmds({ group = "config_highlight_yank" }))' \
  -c 'qa!'
```

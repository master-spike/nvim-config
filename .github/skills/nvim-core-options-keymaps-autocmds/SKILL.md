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
  - lua/util/fold.lua
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

### Folding
Treesitter-based folds are enabled here and start fully open:
```lua
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldtext = "v:lua.require'util.fold'.foldtext()"  -- custom closed-fold line
opt.foldlevel = 99       -- open all folds on buffer open
opt.foldlevelstart = 99
opt.foldnestmax = 4
```
Parsers/highlight come from tree-sitter-manager (`nvim-tree-sitter-manager`);
`vim.treesitter.foldexpr()` returns `0` (no folds) for buffers without a parser,
so this is safe globally. Folds are driven by the built-in `z*` mappings
(`za`, `zR`, `zM`, …) — no custom fold keymaps are defined.

The fold gutter is NOT the native `foldcolumn` (which collapses nested depth into
digits). It is `opt.foldcolumn = "0"` plus a custom `opt.statuscolumn` built in
`lua/util/fold.lua`.

> **Performance/stability invariant (do not break):** the `statuscolumn`
> callbacks (`M.marker` / `M.number`) MUST be pure cache lookups and must NEVER
> call `vim.treesitter.foldexpr()`. An earlier version called `foldexpr` per
> visible line during redraw; doing that re-entrantly with the fold engine
> **intermittently hangs the UI on the main thread** (frozen pane, no input,
> needs `kill -9`, and crucially logs *no* error — it is a hang, not a crash, and
> is NOT limited to large files). Fold starts and marks are now precomputed
> **off the redraw path** by `M.refresh()` and cached per buffer.

- Caches: `M._foldstarts[buf] = { tick, set }` (lines where a Treesitter fold
  starts) and `M._marks[buf] = { [lnum] = letter }`. `M.refresh(buf)` (only ever
  for the current buffer) rescans fold starts when the buffer `changedtick`
  changed and always recomputes marks, then issues a targeted
  `vim.api.nvim__redraw({ buf, statuscolumn = true })`.
- `M.marker()` is a lookup: a **mark letter takes priority** (`%#FoldMark#…%*`,
  `main.purple`), else a fold chevron on a cached fold-start line, else a blank.
  Fold starts are detected (in `compute_foldstarts`, off-redraw) from the raw
  `vim.treesitter.foldexpr(l)` value beginning with `>` (NOT a
  `foldlevel(l) > foldlevel(l-1)` increase — that misses sibling folds at the
  same level, e.g. two `if` blocks in one function body): `0xf0140`
  (chevron-down) when open, `0xf0142` (chevron-right, reads like `>`) when
  closed. So no depth numbers ever appear. It is placed first in `statuscolumn`
  so it sits in the leftmost gutter column, before signs and numbers.
- Marks shown: buffer-local lowercase `a`–`z` (`getmarklist(buf)`) plus global
  uppercase `A`–`Z` whose `file` resolves to this buffer (`getmarklist()`).
  `compute_foldstarts` is skipped above `MAX_SCAN_LINES` (4000) — big files just
  omit chevrons rather than risk a slow synchronous scan.
- `M.number()` reproduces `number` / `relativenumber` (blank on wrapped/virtual
  lines) since a `statuscolumn` replaces the whole gutter.
- The glyphs use `vim.fn.nr2char(...)`; do NOT paste nerd-font glyphs literally
  (that previously tripped `E1511: Wrong number of characters` in `fillchars`).
- `fillchars.fold = "╌"` fills the fold line past the `M.foldtext()` label with the
  same double-dash (rendered in the `Folded` highlight) so the dashed texture
  runs to the window edge.
- Active-fold illumination: the chevron of the innermost fold *containing the
  cursor* is highlighted with the `FoldActive` group (see `nvim-colorscheme`).
  `active_fold_start()` finds it by walking UP from the cursor and returning the
  nearest fold-start line whose `foldlevel` equals the cursor's depth — the
  `foldlevel(s) == level` guard is essential, otherwise deeper sibling folds
  sitting above the cursor (but not containing it) get wrongly picked. The walk
  is bounded by the parent fold (`foldlevel(s-1) < level`) and reads the cached
  fold-start set (not `foldexpr`).
- Two `config_fold` autocmds: one (`BufWinEnter` / `BufReadPost` / `TextChanged`
  / `InsertLeave` / `CursorHold`) `vim.schedule`s `M.refresh` to repopulate the
  caches off-redraw — `CursorHold` (after `updatetime`) is what makes a freshly
  set `ma` appear without a manual redraw; the other (`CursorMoved` /
  `CursorMovedI` / `BufEnter` / `WinEnter`) runs `M.update_active` and caches the
  result in `M._active = { buf, line }`. `relativenumber` forces a statuscolumn
  redraw on every cursor move so the highlighted chevron tracks the cursor.
- `M.marker()` wraps the active chevron / mark in `%#…#…%*`. Because of that,
  the marker segment in `statuscolumn` uses the `%{%…%}` form (which interprets
  embedded highlight items), while `M.number()` stays in the plain `%{…}` form.

Closed folds show a `'foldtext'` rendered by `M.foldtext()` (wired via
`opt.foldtext = "v:lua.require'util.fold'.foldtext()"`):
- The fold's first line is split into chunks: each whitespace character that is
  NOT directly adjacent to a code character becomes a double-dash `╌` in the
  muted `Folded` highlight, while whitespace touching code stays blank (so single
  inter-token spaces and the space before the first token are kept). Code runs
  stay in `FoldLine` (golden yellow, matching `MatchParen`). A ` ╌╌ ` separator
  (two dashes flanked by spaces) then a `N lines` label in `FoldCount` (blue
  italic), then a one-space gap before the trailing dash fill, follow.
  `N = v:foldend - v:foldstart + 1`. All three groups are in `nvim-colorscheme`.
- This uses `'foldtext'` rather than decoration-provider virtual text on purpose:
  ephemeral `virt_text` from `nvim_set_decoration_provider`/`on_line` is NOT
  rendered on a closed fold's first line (it shows fine on a normal line), and a
  decoration provider may only mutate the buffer via *ephemeral* marks, so that
  route is a dead end for fold labels. `'foldtext'` is always drawn for folds.
- Tabs in the line are expanded to spaces via `vim.bo.tabstop` so they become
  dashes too and the label lines up.

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

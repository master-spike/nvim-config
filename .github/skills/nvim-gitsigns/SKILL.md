---
name: nvim-gitsigns
description: >-
  gitsigns.nvim integration. Use when changing git hunk navigation, staging,
  blame, diff, quickfix, toggles, or the custom Telescope git-hunks picker on
  <leader>fg. Grounded in lua/plugins/gitsigns.lua.
covers:
  - lua/plugins/gitsigns.lua
  - lua/util/path.lua
---

# Gitsigns

## Role

Git hunk signs, hunk actions, blame, diffs, quickfix export, and a custom
Telescope picker for all git hunks. Everything is configured in
`lua/plugins/gitsigns.lua`.

Ground truth:
- Config: `lua/plugins/gitsigns.lua`.
- Shared path helper: `lua/util/path.lua`.
- Install root: `~/.local/share/nvim/site/pack/core/opt/`.
- Install dir: `gitsigns.nvim/`.
- Pinned rev: `25050e4ed39e628282831d4cbecb1850454ce915`.
- Upstream: https://github.com/lewis6991/gitsigns.nvim
- Help: `:help gitsigns`, `:help gitsigns.setup()`.
- Docs: `gitsigns.nvim/doc/gitsigns.txt`.

## What's configured

`gitsigns.setup({ on_attach = function(bufnr) ... end })`. Almost everything is
wired in the `on_attach` callback, so the gitsigns action maps are **buffer-local
and only exist after gitsigns attaches** to a git-backed buffer. Read
`lua/plugins/gitsigns.lua` for the current key list — the durable conventions are:

- Hunk navigation on `]h` / `[h`.
- A `<leader>g…` family for git actions: `<leader>gh…` for per-hunk
  stage/reset/preview (these also take a visual range when called from visual
  mode), buffer-wide stage/reset, blame, diff, quickfix export, and `<leader>gt…`
  for the blame/word-diff toggles.

Navigation has a deliberate fallback: when `vim.wo.diff` is true it runs the
built-in `]h`/`[h` via `vim.cmd.normal(...)`; otherwise it calls
`gitsigns.nav_hunk("next"|"prev")`. Keep that branch if you touch hunk nav.

## Custom Telescope hunk picker

`<leader>fg` (global, desc `Find git hunks (Telescope)`) is **not** a gitsigns
default — it's a custom picker implemented in `lua/plugins/gitsigns.lua` after
`gitsigns.setup(...)`. Understand the mechanism rather than the exact code:

- It calls `gitsigns.setqflist("all", { open = false }, cb)` to enumerate every
  hunk in the repo, then builds a Telescope picker (`pickers.new` +
  `finders.new_table`) from the quickfix items.
- **Why a custom previewer:** `setqflist` entries carry location (file/line/text)
  but **no diff body**. So the previewer re-runs `git --no-pager -c
  color.ui=never diff -U0` for the selected file, parses the `@@` hunks, and shows
  the hunk covering `lnum` (or the nearest) in a `diff`-filetype buffer.
- Entry display reuses `require("util.path").collapse(...)` so paths shorten the
  same way as Telescope defaults and lualine. See `nvim-telescope` and
  `nvim-lualine`.

This is the worked example to copy when you need a custom Telescope picker over
ad-hoc data — see `nvim-telescope` for the general pattern.

## Capabilities + examples

Read the `on_attach` map list in `lua/plugins/gitsigns.lua` for current keys.
The shape: `]h`/`[h` navigate; `<leader>gh{s,r,p}` act on the hunk under the
cursor (or the visual selection); buffer-wide stage/reset, blame, diff, and
quickfix export live under `<leader>g…`; `<leader>gt…` toggles blame/word-diff;
`<leader>fg` opens the custom git-hunks picker.

## Gotchas / version notes

- `setqflist("all")` fills quickfix entries, but those entries do not include
  diff bodies. The custom previewer reparses `git diff -U0` for the selected
  file and hunk.
- The picker depends on Telescope APIs verified in `telescope.nvim/lua`:
  `pickers.new`, `finders.new_table`, `previewers.new_buffer_previewer`, and
  `require("telescope.config").values.generic_sorter`.
- Buffer-local gitsigns maps only exist after gitsigns attaches to a git-backed
  buffer. `<leader>fg` is global and should exist after startup.

## Docs / ground truth

Verify every gitsigns action in installed source/docs before using it:

```bash
P=~/.local/share/nvim/site/pack/core/opt/gitsigns.nvim
rg -n 'nav_hunk|stage_hunk|reset_hunk|setqflist' "$P"/lua
rg -n 'preview_hunk_inline|blame_line|diffthis' "$P"/doc
rg -n 'toggle_current_line_blame|toggle_word_diff' "$P"/doc
```

Verify the picker APIs in Telescope source/docs:

```bash
P=~/.local/share/nvim/site/pack/core/opt/telescope.nvim
rg -n 'finders.new_table|pickers.new' "$P"/lua
rg -n 'previewers.new_buffer_previewer|generic_sorter' "$P"/doc
```

## Verify your change

Run from `~/.config/nvim`:

```bash
luac -p lua/plugins/gitsigns.lua lua/util/path.lua
nvim --headless -u init.lua -c 'lua
  local gs = require("gitsigns")
  assert(type(gs.setqflist) == "function")
  assert(type(gs.nav_hunk) == "function")
  assert(type(vim.fn.maparg("<leader>fg", "n")) == "string")
  assert(vim.fn.maparg("<leader>fg", "n") ~= "")
  print("PASS gitsigns")
' -c 'qa!' 2>&1 | grep -v tbl_flatten
```

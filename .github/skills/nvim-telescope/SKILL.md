---
name: nvim-telescope
description: >-
  How telescope.nvim is configured and used in this config: defaults (including
  the path_display function that minifies paths via util.path.collapse),
  fzf-native + ui-select extensions, the find/grep keymaps, and the pattern for
  customizing entry display across ALL pickers. Use to add a picker keymap,
  change how results are displayed, build a custom picker, or adjust telescope
  defaults/extensions.
covers:
  - lua/plugins/telescope.lua
  - lua/util/path.lua
---

# Telescope

Fuzzy finder. Configured in `lua/plugins/telescope.lua`, with two extensions:
`telescope-fzf-native` (compiled sorter — build step in `pack.lua`) and
`telescope-ui-select` (routes `vim.ui.select` through telescope). Shared path
shortening lives in `lua/util/path.lua` (see `nvim-config-overview`).

## What's configured
```lua
telescope.setup({
  defaults = {
    layout_strategy = "horizontal",
    layout_config = { prompt_position = "top" },
    sorting_strategy = "ascending",
    winblend = 0,
    path_display = function(_, path)
      return require("util.path").collapse(path)   -- minify path globally
    end,
  },
  extensions = {
    fzf = {},
    ["ui-select"] = { require("telescope.themes").get_dropdown({}) },
  },
})
pcall(telescope.load_extension, "fzf")
pcall(telescope.load_extension, "ui-select")
```
Extensions are loaded under `pcall` so a missing/unbuilt extension doesn't break
startup. fzf-native needs its C lib built — `pack.lua` runs `make` if
`build/libfzf.so` is absent.

## The path_display pattern (IMPORTANT — reuse, don't reinvent)
`path_display` is a **documented telescope default** that can be a function
`(opts, path) -> string`. Setting it once in `defaults` rewrites the displayed
path for **every** picker that shows a file (find_files, live_grep, oldfiles,
LSP pickers, quickfix, ...). This is the one-size-fits-all hook — prefer it over
wrapping individual pickers with a custom `entry_maker`.

This was a real lesson in this repo: an earlier attempt used a non-existent
`telescope.finders.entry_from_file` as a custom `entry_maker`, which returned
`nil` and made all results vanish. The correct, simple solution was the built-in
`path_display` function. **Confirm the API in the installed source before
writing a custom maker** (see `nvim-testing-and-verification`). The real entry
makers, if you ever need them, are in `telescope.make_entry`
(`gen_from_file`, `gen_from_vimgrep`), and `utils.transform_path` is what calls
`path_display`.

## Keymaps (defined in telescope.lua)
```
<leader><space> / <leader>ff  find_files
<leader>f/ , <leader>sg        live_grep
<leader>fb                     buffers
<leader>fh                     help_tags
<leader>fr                     oldfiles
<leader>sk                     keymaps
```
Add a picker keymap: `map("n", "<leader>fX", builtin.<picker>, {desc=...})`.
List real builtin pickers:
```bash
nvim --headless -u init.lua \
  -c 'lua print(vim.inspect(vim.tbl_keys(require("telescope.builtin"))))' -c 'qa!'
```

## Building a custom picker
See `lua/plugins/gitsigns.lua` for a worked example (the git-hunks picker:
`pickers.new`, `finders.new_table`, a custom `entry_maker`, a
`previewers.new_buffer_previewer`, `conf.generic_sorter`). Pattern:
```lua
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
pickers.new({}, {
  prompt_title = "...",
  finder = finders.new_table({ results = items, entry_maker = function(item)
    return { value = item, display = ..., ordinal = ..., filename = ..., lnum = ... }
  end }),
  sorter = conf.generic_sorter({}),
  previewer = ...,
}):find()
```
An entry's `display`/`ordinal` may be strings or functions; `filename`+`lnum`
make it openable and previewable.

## Docs / ground truth
- `:help telescope`, `:help telescope.defaults.path_display`,
  `:help telescope.builtin`.
- Source/docs:
  `~/.local/share/nvim/site/pack/core/opt/telescope.nvim/` (`lua/` + `doc/`).
  Key files: `lua/telescope/make_entry.lua`, `lua/telescope/utils.lua`
  (`transform_path`).
- Upstream: https://github.com/nvim-telescope/telescope.nvim (pinned rev in
  `nvim-pack-lock.json`).

## Verify your change
Drive a picker headlessly and inspect REAL results (this is how the path_display
work was validated):
```bash
cd /some/dir && nvim --headless -u ~/.config/nvim/init.lua -c 'lua
  require("telescope.builtin").find_files()
  vim.wait(1500, function() return false end)
  local p = require("telescope.actions.state")
    .get_current_picker(vim.api.nvim_get_current_buf())
  local n = 0
  for e in p.manager:iter() do
    n = n + 1
    print("ENTRY: "..(type(e.display)=="function" and e:display() or e.display))
  end
  print("COUNT: "..n)
' -c 'qa!' 2>&1 | grep -E "ENTRY|COUNT"
```
For `live_grep`, pass `{ default_text = "..." }`. Async finders require the
`vim.wait`. See `nvim-testing-and-verification` for the full recipe and
pitfalls.

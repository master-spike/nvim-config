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
      -- returns (string, style); style colours the filename component
      local collapsed = require("util.path").collapse(path)
      local filename = collapsed:match("[^/]+$") or collapsed
      local start = #collapsed - #filename
      return collapsed, { { { start, #collapsed }, "TelescopeResultsFileName" } }
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
`(opts, path) -> string, style?`. Setting it once in `defaults` rewrites the
displayed path for **every** picker that shows a file (find_files, live_grep,
oldfiles, LSP pickers, quickfix, ...). This is the one-size-fits-all hook —
prefer it over wrapping individual pickers with a custom `entry_maker`.

### Colouring part of the path (the filename)
`path_display` may return a **second value**: a `path_style` highlights table of
the form `{ { { byte_start, byte_end }, "HlGroup" }, ... }` (0-based,
end-exclusive byte columns). `utils.transform_path` forwards this style, and
`utils.merge_styles` offsets it past any devicon, so the colour lands on the
right characters in every picker. This config uses it to colour just the final
filename component with `TelescopeResultsFileName` — a dedicated group defined in
`lua/plugins/colorscheme.lua`'s `custom_highlights` as orange
(`material_colors.main.orange`) — leaving the directory prefix in the default
colour. A dedicated group (not the built-in `TelescopeResultsIdentifier`) is
used so git/branch pickers that share `TelescopeResultsIdentifier` keep their
colour:
```lua
path_display = function(_, path)
  local collapsed = require("util.path").collapse(path)
  local filename = collapsed:match("[^/]+$") or collapsed
  local start = #collapsed - #filename
  return collapsed, { { { start, #collapsed }, "TelescopeResultsFileName" } }
end,
```
Ground truth for the style mechanism: `utils.transform_path` (returns
`custom_transformed_path, custom_path_style`) and `path_filename_first`
(builds the same `{ {start,end}, hl }` shape) in `lua/telescope/utils.lua`;
the highlight format is documented in `lua/telescope/make_entry.lua` as
`{ { start_col, end_col }, hl_group }`.

This was a real lesson in this repo: an earlier attempt used a non-existent
`telescope.finders.entry_from_file` as a custom `entry_maker`, which returned
`nil` and made all results vanish. A later attempt split the path with
`entry_display.create` + a custom `entry_maker` and dropped the `/` between
directory and filename. The correct, simple solution is the built-in
`path_display` function returning `(string, style)` — no per-picker
`entry_maker`. **Confirm the API in the installed source before writing a custom
maker** (see `nvim-testing-and-verification`). The real entry makers, if you
ever need them, are in `telescope.make_entry` (`gen_from_file`,
`gen_from_vimgrep`), and `utils.transform_path` is what calls `path_display`.

## Keymaps (defined in telescope.lua)
```
<leader><space> / <leader>ff  find_files (custom wrapper)
<leader>f/ , <leader>sg        live_grep  (custom wrapper)
<leader>fb                     buffers
<leader>fh                     help_tags
<leader>fr                     oldfiles
<leader>sk                     keymaps
```
`<leader>ff` and `<leader>f/` are bound to **local wrapper functions**
(`find_files` / `live_grep` in telescope.lua), NOT `builtin.*`, because they add
the `<C-y>` toggle below. The other maps still use `builtin.*`.
Add a plain picker keymap: `map("n", "<leader>fX", builtin.<picker>, {desc=...})`.
List real builtin pickers:
```bash
nvim --headless -u init.lua \
  -c 'lua print(vim.inspect(vim.tbl_keys(require("telescope.builtin"))))' -c 'qa!'
```

## In-picker toggle: include-ignored (`<C-y>`)
`<leader>ff`/`<leader>f/` are bound to local wrapper functions (`find_files` /
`live_grep` in telescope.lua) — they delegate to `builtin.find_files` /
`builtin.live_grep` but add a shared module-level boolean `include_ignored`
(default `false`) and one mapping (insert + normal):

- **`<C-y>` (both pickers) — toggle gitignored files.** Flips `include_ignored`,
  then `actions.close` + reopen the same picker with `default_text` = current
  prompt. find_files drops/adds `--exclude-standard` on `git ls-files`;
  live_grep adds/removes `--no-ignore` via `opts.additional_args`. Title shows
  `(+ignored)` when on. (`<C-y>` is used instead of `<C-i>` because `<C-i>` ==
  `<Tab>` in most terminals and would shadow Telescope's multi-select.)
- **No `<C-h>`.** Dotfiles are ALWAYS searched: `git ls-files` lists them and
  live_grep's rg args always include `--hidden` (plus `--glob !**/.git/**` so it
  never descends into `.git`). They are intentionally never treated differently.

find_files no longer sets `pickers.find_files.find_command` in `telescope.setup`
— the wrapper builds the command per call from `include_ignored`.

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

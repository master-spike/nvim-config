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

`gitsigns.setup({ on_attach = function(bufnr) ... end })` defines buffer-local
maps for buffers that gitsigns attaches to:

```lua
map("n", "]h", nav_next_hunk, { desc = "Next hunk" })
map("n", "[h", nav_prev_hunk, { desc = "Prev hunk" })

map("n", "<leader>ghs", gitsigns.stage_hunk)
map("n", "<leader>ghr", gitsigns.reset_hunk)
map("v", "<leader>ghs", function()
  gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
end)
map("v", "<leader>ghr", function()
  gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
end)

map("n", "<leader>gS", gitsigns.stage_buffer)
map("n", "<leader>gR", gitsigns.reset_buffer)
map("n", "<leader>ghp", gitsigns.preview_hunk_inline)
map("n", "<leader>gb", function()
  gitsigns.blame_line({ full = true })
end)
map("n", "<leader>gd", gitsigns.diffthis)
map("n", "<leader>gD", function()
  gitsigns.diffthis("~")
end)
map("n", "<leader>gQ", function()
  gitsigns.setqflist("all")
end)
map("n", "<leader>gq", gitsigns.setqflist)
map("n", "<leader>gtb", gitsigns.toggle_current_line_blame)
map("n", "<leader>gtw", gitsigns.toggle_word_diff)
```

Navigation falls back to built-in `]h` or `[h` with `vim.cmd.normal(...)` when
`vim.wo.diff` is true. Otherwise it calls `gitsigns.nav_hunk("next")` or
`gitsigns.nav_hunk("prev")`.

## Custom Telescope hunk picker

`<leader>fg` is a global map with desc `Find git hunks (Telescope)`. It is not
a gitsigns default. It is implemented in `lua/plugins/gitsigns.lua` after
`gitsigns.setup(...)`.

Flow:

```lua
require("gitsigns").setqflist("all", { open = false }, function()
  vim.schedule(function()
    local items = vim.fn.getqflist({ items = 0 }).items
    -- build entries from bufnr / filename / lnum / text
    local previewer = previewers.new_buffer_previewer({
      title = "Hunk Diff",
      define_preview = function(self, entry)
        local lines = hunk_diff_lines(entry.filename, entry.lnum)
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
        vim.bo[self.state.bufnr].filetype = "diff"
      end,
    })
    pickers.new({}, {
      prompt_title = "Git Hunks",
      finder = finders.new_table({
        results = entries,
        entry_maker = function(item)
          local rel = vim.fn.fnamemodify(item.filename, ":.")
          local minified = path_util.collapse(rel)
          return {
            ordinal = rel .. " " .. item.text,
            display = minified .. " │ " .. item.text,
            filename = item.filename,
            lnum = item.lnum,
            col = 1,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      previewer = previewer,
    }):find()
  end)
end)
```

`hunk_diff_lines(filename, lnum)` runs `git -C <dir> --no-pager -c
color.ui=never diff -U0` and parses `@@` hunks. It returns the diff hunk that
covers `lnum`, or the nearest hunk. The preview buffer filetype is `diff`.

Path display uses `require("util.path").collapse(rel)`. This is the same helper
used by Telescope defaults and lualine. See `nvim-telescope` and `nvim-lualine`.

## Capabilities + examples

```text
]h / [h          next / previous hunk
<leader>ghs      stage hunk, visual range in visual mode
<leader>ghr      reset hunk, visual range in visual mode
<leader>gS       stage buffer
<leader>gR       reset buffer
<leader>ghp      preview hunk inline
<leader>gb       blame current line, full=true
<leader>gd       diffthis
<leader>gD       diffthis("~")
<leader>gQ       send all hunks to quickfix
<leader>gq       send attached-buffer hunks to quickfix
<leader>gtb      toggle current line blame
<leader>gtw      toggle word diff
<leader>fg       open the custom Telescope git-hunks picker
```

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

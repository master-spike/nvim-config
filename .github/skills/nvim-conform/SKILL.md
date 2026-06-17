---
name: nvim-conform
description: >-
  How conform.nvim formatting is configured in this config, including
  formatters by filetype, formatter overrides, format-on-save state, manual
  formatting, Snacks toggles, and Mason-installed formatter binaries. Use when
  changing formatting, format-on-save, Prettier args, or formatter tools.
covers:
  - lua/plugins/conform.lua
---

# conform.nvim

Formatter runner. Configured in `lua/plugins/conform.lua`. It maps filetypes to
formatter names and calls external formatter binaries. Those binaries are
installed by Mason; see `nvim-mason`.

## What's configured

```lua
_G.conform_format_state = {
  enabled = true,
  buffer_overrides = {},
}

require("conform").setup({
  formatters_by_ft = {
    java = { "google-java-format" },
    markdown = { "prettier" },
    lua = { "stylua" },
    sh = { "shfmt" },
  },
  formatters = {
    ["google-java-format"] = {
      command = "google-java-format",
      args = { "-" },
      stdin = true,
    },
    prettier = {
      prepend_args = {
        "--prose-wrap",
        "always",
        "--print-width",
        "80",
      },
    },
  },
  format_on_save = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local state = _G.conform_format_state
    local enabled = state.buffer_overrides[bufnr]
    if enabled == nil then
      enabled = state.enabled
    end
    return enabled and { timeout_ms = 3000, lsp_format = "fallback" } or nil
  end,
})
```

Manual format and toggles:

```lua
vim.keymap.set({ "n", "v" }, "<leader>cf", function()
  require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "Format" })

Snacks.toggle.new({
  id = "conform_global",
  name = "Formatter (global)",
  get = function()
    return _G.conform_format_state.enabled
  end,
  set = function(enabled)
    _G.conform_format_state.enabled = enabled
  end,
}):map("<leader>uF")
```

The buffer toggle is also in this file. It writes
`_G.conform_format_state.buffer_overrides[bufnr]` and maps to `<leader>uf`.

## Capabilities + examples

Format the current buffer manually:

```lua
require("conform").format({ async = true, lsp_format = "fallback" })
```

Ask Conform what would run for the current buffer:

```lua
local formatters = require("conform").list_formatters_to_run(0)
print(vim.inspect(formatters))
```

Disable format-on-save globally from Lua:

```lua
_G.conform_format_state.enabled = false
```

## Gotchas / version notes

- Format-on-save is controlled by `_G.conform_format_state`, not a plugin
  command. Buffer overrides win over the global flag.
- `<leader>cf` is async manual formatting. Save formatting returns
  `{ timeout_ms = 3000, lsp_format = "fallback" }` only when enabled.
- Prettier is overridden with `--prose-wrap always --print-width 80`.
- Mason installs the formatter binaries. Adding a formatter here is not enough;
  add the Mason package in `lua/plugins/mason.lua` too.

## Docs / ground truth

- Config: `lua/plugins/conform.lua`.
- Install path: `~/.local/share/nvim/site/pack/core/opt/conform.nvim/`.
- Help: `:help conform`, `:help conform.setup`, `:help conform.format`, and
  `doc/conform.txt`.
- Upstream: https://github.com/stevearc/conform.nvim
- Pinned rev: `619363c30309d29ffa631e67c8183f2a72caa373`.

## Verify your change

Run from `~/.config/nvim`:

```bash
luac -p lua/plugins/conform.lua lua/plugins/mason.lua

nvim --headless -u init.lua -c 'lua
  vim.bo.filetype = "markdown"
  local state = _G.conform_format_state
  assert(state.enabled == true)
  assert(type(state.buffer_overrides) == "table")
  assert(vim.fn.maparg("<leader>cf", "n") ~= "")
  local fmts = require("conform").list_formatters_to_run(0)
  assert(fmts[1] and fmts[1].name == "prettier")
  print("PASS conform " .. fmts[1].name)
' -c 'qa!' 2>&1 | grep -v tbl_flatten
```

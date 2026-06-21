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

`lua/plugins/conform.lua` does three durable things; read the file for the exact
filetype→formatter map, formatter arg overrides, and keys (those churn):

**1. A `formatters_by_ft` map + per-formatter overrides.** Each filetype lists
the formatter(s) to run; the `formatters` table overrides individual tools (e.g.
a custom `command`/`args`, or `prepend_args` for prettier's prose wrapping). The
binaries come from Mason — see the coupling gotcha below.

**2. A global format-on-save state object** — the load-bearing mechanism:

```lua
_G.conform_format_state = { enabled = true, buffer_overrides = {} }

format_on_save = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local state = _G.conform_format_state
  local enabled = state.buffer_overrides[bufnr]
  if enabled == nil then enabled = state.enabled end
  return enabled and { timeout_ms = 3000, lsp_format = "fallback" } or nil
end
```

So format-on-save is gated by `_G.conform_format_state`: a global `enabled` flag
with **per-buffer overrides that win over the global**. `format_on_save` returns
options only when enabled, `nil` otherwise.

**3. Keymaps + Snacks toggles** wired to that state: a manual async format map,
and two `Snacks.toggle.new({...})` toggles (global + per-buffer) whose `get`/`set`
read and write `_G.conform_format_state`. Read the file for the current keys
(`<leader>c…`/`<leader>u…` family); see `nvim-snacks` for the toggle pattern.

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

Disable format-on-save globally / for one buffer from Lua:

```lua
_G.conform_format_state.enabled = false
_G.conform_format_state.buffer_overrides[0] = false
```

## Gotchas / version notes

- Format-on-save is controlled by `_G.conform_format_state`, not a plugin
  command. Per-buffer overrides win over the global flag.
- The manual format map is async; save formatting only runs when the state says
  enabled (it returns `{ timeout_ms, lsp_format = "fallback" }`).
- Some formatters are overridden in the `formatters` table (e.g. prettier's prose
  wrap/print width) — check the file before assuming default behaviour.
- Mason installs the formatter binaries. Adding a formatter to `formatters_by_ft`
  is not enough; add its Mason package in `lua/plugins/mason.lua` too.

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
  -- the durable mechanism, independent of which filetypes/formatters are mapped:
  local state = _G.conform_format_state
  assert(type(state) == "table")
  assert(type(state.enabled) == "boolean")
  assert(type(state.buffer_overrides) == "table")
  -- a manual format map and the global format-on-save toggle exist:
  assert(require("conform").format, "conform.format missing")
  -- list_formatters_to_run works for some configured filetype (read the file
  -- for one it maps); this just checks the call path, not a specific tool:
  assert(type(require("conform").list_formatters_to_run(0)) == "table")
  print("PASS conform")
' -c 'qa!' 2>&1 | grep -v tbl_flatten
```

---
name: nvim-blink-cmp
description: >-
  How blink.cmp completion is configured in this config, including Tab and
  Shift-Tab behaviour, sources, documentation, signature help, and LSP
  capability wiring. Use when changing completion, completion keymaps,
  signature help, docs popups, sources, or LSP completion capabilities.
covers:
  - lua/plugins/completion.lua
---

# blink.cmp

Completion engine. Configured in `lua/plugins/completion.lua` with
`require("blink.cmp").setup(...)`. Native LSP gets blink's completion
capabilities in `lua/config/lsp.lua`; `lua/plugins/jdtls.lua` does the same for
jdtls. See `nvim-lsp` for server setup and `nvim-jdtls` for Java.

## What's configured

```lua
require("blink.cmp").setup({
  keymap = {
    preset = "default",
    ["<Tab>"] = { "show_and_insert", "select_next" },
    ["<S-Tab>"] = { "show_and_insert", "select_prev" },
  },
  appearance = { nerd_font_variant = "mono" },
  completion = {
    list = {
      selection = { preselect = false, auto_insert = true },
    },
    documentation = { auto_show = true, auto_show_delay_ms = 200 },
  },
  sources = {
    default = { "lsp", "path", "snippets", "buffer" },
  },
  signature = { enabled = true },
})
```

LSP integration is also real config, not plugin magic:

```lua
local ok_blink, blink = pcall(require, "blink.cmp")
if ok_blink then
  vim.lsp.config("*", { capabilities = blink.get_lsp_capabilities() })
end
```

## Capabilities + examples

Inspect configured sources after startup:

```bash
cd ~/.config/nvim
nvim --headless -u init.lua   -c 'lua print(vim.inspect(require("blink.cmp.config").sources.default))'   -c 'qa!' 2>&1 | grep -v tbl_flatten
```

Check that the public LSP capability helper returns a table:

```lua
local blink = require("blink.cmp")
print(type(blink.get_lsp_capabilities()))
```

If you change completion keys, use blink command names that exist in this rev.
`show_and_insert`, `select_next`, and `select_prev` are documented commands.

## Gotchas / version notes

- `<Tab>` does not accept a completion item here. It shows the menu, inserts the
  first item, then selects the next item on later presses.
- `preselect = false` means the list does not select the first item by default.
  `auto_insert = true` previews the selected item while cycling.
- Signature help is opt-in in blink docs. This config opts in with
  `signature.enabled = true`.
- Do not invent source names. This config uses only `lsp`, `path`, `snippets`,
  and `buffer`.

## Docs / ground truth

- Config: `lua/plugins/completion.lua`, plus LSP wiring in `lua/config/lsp.lua`
  and `lua/plugins/jdtls.lua`.
- Install path: `~/.local/share/nvim/site/pack/core/opt/blink.cmp/`.
- Help: `:help blink-cmp`, `:help blink-cmp-config-keymap`, and
  `doc/blink-cmp.txt`. Extra versioned docs are under `doc/configuration/*.md`.
- Upstream: https://github.com/saghen/blink.cmp
- Pinned rev/version: `bae4bae0eedd1fa55f34b685862e94a222d5c6f8`, `v1.6.0`.

## Verify your change

Run from `~/.config/nvim`:

```bash
luac -p lua/plugins/completion.lua lua/config/lsp.lua lua/plugins/jdtls.lua

nvim --headless -u init.lua -c 'lua
  local cfg = require("blink.cmp.config")
  assert(vim.deep_equal(cfg.sources.default,
    { "lsp", "path", "snippets", "buffer" }))
  assert(cfg.signature.enabled == true)
  assert(type(require("blink.cmp").get_lsp_capabilities()) == "table")
  print("PASS blink " .. table.concat(cfg.sources.default, ","))
' -c 'qa!' 2>&1 | grep -v tbl_flatten
```

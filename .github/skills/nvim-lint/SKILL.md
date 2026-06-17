---
name: nvim-lint
description: >-
  How nvim-lint is configured in this config, including the shellcheck-only
  linter map, lint autocmds, Mason-provided shellcheck binary, and the split
  from JavaScript/TypeScript eslint LSP linting. Use when changing non-LSP
  linting, shell linting, or lint-on-save/read/insert-leave behaviour.
covers:
  - lua/plugins/lint.lua
---

# nvim-lint

Non-LSP linter runner. Configured in `lua/plugins/lint.lua`. This config only
uses it for shell files with `shellcheck`; the `shellcheck` binary is installed
by Mason. See `nvim-mason`.

## What's configured

```lua
local lint = require("lint")

lint.linters_by_ft = {
  sh = { "shellcheck" },
}

local group = vim.api.nvim_create_augroup("config_lint", { clear = true })
vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
  group = group,
  callback = function()
    if vim.bo.modifiable then
      lint.try_lint()
    end
  end,
})
```

## Capabilities + examples

Run the configured linter for the current buffer:

```lua
require("lint").try_lint()
```

Run shellcheck explicitly:

```lua
require("lint").try_lint("shellcheck")
```

Inspect the configured filetype map:

```lua
print(vim.inspect(require("lint").linters_by_ft))
```

## Gotchas / version notes

- `linters_by_ft` is exactly `{ sh = { "shellcheck" } }` in this config.
- The autocmd group is `config_lint`. It runs on `BufWritePost`, `BufReadPost`,
  and `InsertLeave`, but only when `vim.bo.modifiable` is true.
- JavaScript and TypeScript linting are not configured here. They use the eslint
  LSP in `lua/config/lsp.lua`, including fix-on-save via `LspEslintFixAll`.
- Mason installs the `shellcheck` binary. Add binary packages in
  `lua/plugins/mason.lua`, not in this file.

## Docs / ground truth

- Config: `lua/plugins/lint.lua`; eslint LSP split is in `lua/config/lsp.lua`.
- Install path: `~/.local/share/nvim/site/pack/core/opt/nvim-lint/`.
- Help: `:help lint`, `:help lint.linters_by_ft`, `:help lint.try_lint`, and
  `doc/lint.txt`.
- Upstream: https://github.com/mfussenegger/nvim-lint
- Pinned rev: `99cbc3ca8a76845fca50e496be7212bebf907dd3`.

## Verify your change

Run from `~/.config/nvim`:

```bash
luac -p lua/plugins/lint.lua lua/config/lsp.lua

nvim --headless -u init.lua -c 'lua
  local lint = require("lint")
  assert(vim.deep_equal(lint.linters_by_ft, { sh = { "shellcheck" } }))
  local a = vim.api.nvim_get_autocmds({ group = "config_lint" })
  assert(#a == 3)
  print("PASS lint " .. lint.linters_by_ft.sh[1] .. " autocmds=" .. #a)
' -c 'qa!' 2>&1 | grep -v tbl_flatten
```

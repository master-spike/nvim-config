---
name: nvim-mason
description: >-
  How mason.nvim and mason-tool-installer.nvim are configured in this config,
  including installed LSP servers, formatters, linters, package-name gotchas,
  and the split between tool installation, native LSP, Conform, and nvim-lint.
  Use when adding, removing, or verifying external editor tools.
covers:
  - lua/plugins/mason.lua
---

# Mason

External tool installer. Configured in `lua/plugins/mason.lua`. Mason installs
binaries into Neovim's data directory and adds Mason's `bin/` directory to the
Neovim session `PATH`. It does not configure LSP, formatting, or linting by
itself.

## What's configured

```lua
require("mason").setup()

require("mason-tool-installer").setup({
  ensure_installed = {
    -- LSP servers
    "lua-language-server",
    "json-lsp",
    "yaml-language-server",
    "vacuum",
    -- Formatters
    "stylua",
    "prettier",
    "google-java-format",
    "shfmt",
    -- Linters
    "eslint_d",
    "shellcheck",
  },
  run_on_start = true,
})
```

## Capabilities + examples

Install a package manually from inside Neovim:

```vim
:MasonInstall stylua
```

Check that a package name exists in Mason's registry:

```lua
local registry = require("mason-registry")
print(registry.has_package("lua-language-server"))
```

Add a tool by adding its Mason package name to `ensure_installed`:

```lua
require("mason-tool-installer").setup({
  ensure_installed = { "stylua", "shellcheck" },
  run_on_start = true,
})
```

## Gotchas / version notes

- Mason installs binaries. Native LSP config lives in `lua/config/lsp.lua`; see
  `nvim-lsp`.
- Formatters are selected by Conform in `lua/plugins/conform.lua`; see
  `nvim-conform`.
- Non-LSP linters are selected by nvim-lint in `lua/plugins/lint.lua`; see
  `nvim-lint`.
- Mason package names can differ from LSP server names. Example: Mason installs
  `lua-language-server`, but native LSP enables `lua_ls`.
- `eslint_d` is installed here, but JS/TS linting in this config is the eslint
  LSP in `lua/config/lsp.lua`, not nvim-lint.
- `mason-tool-installer.nvim` has no installed `doc/*.txt` helpfile in this rev;
  its setup fields are documented in source annotations.

## Docs / ground truth

- Config: `lua/plugins/mason.lua`.
- mason.nvim install path:
  `~/.local/share/nvim/site/pack/core/opt/mason.nvim/`.
- mason-tool-installer.nvim install path:
  `~/.local/share/nvim/site/pack/core/opt/mason-tool-installer.nvim/`.
- Help: `:help mason`, `:help mason.setup()`, `:help :MasonInstall`, and
  `mason.nvim/doc/mason.txt`.
- mason-tool-installer source:
  `mason-tool-installer.nvim/lua/mason-tool-installer/init.lua`.
- Upstream: https://github.com/mason-org/mason.nvim
- Upstream: https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim
- Pinned mason.nvim rev: `2a6940af80375532e5e9e7c1f2fc6319a1b7a69d`.
- Pinned mason-tool-installer.nvim rev:
  `443f1ef8b5e6bf47045cb2217b6f748a223cf7dc`.

## Verify your change

Run from `~/.config/nvim`:

```bash
luac -p lua/plugins/mason.lua

nvim --headless -u init.lua -c 'lua
  local mr = require("mason-registry")
  local tools = {
    "lua-language-server", "json-lsp", "yaml-language-server", "vacuum",
    "stylua", "prettier", "google-java-format", "shfmt", "eslint_d",
    "shellcheck",
  }
  for _, name in ipairs(tools) do
    assert(mr.has_package(name), name)
  end
  assert(vim.fn.exists(":MasonInstall") == 2)
  print("PASS mason packages=" .. #tools)
' -c 'qa!' 2>&1 | grep -v tbl_flatten
```

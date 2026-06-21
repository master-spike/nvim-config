---
name: nvim-tree-sitter-manager
description: >-
  How tree-sitter-manager.nvim is wired in this config for parser installation,
  query management, and automatic highlighting. Use it when you want to add a
  new grammar, tweak auto-install behavior, or inspect the manager commands.
covers:
  - lua/plugins/tree-sitter-manager.lua
  - lua/config/pack.lua
---

# tree-sitter-manager.nvim

Parser manager for Neovim's built-in Tree-sitter integration. This config uses
`tree-sitter-manager.nvim` in `lua/plugins/tree-sitter-manager.lua` to install
parsers for the languages I work with most often, opt into automatic highlight
startup, and expose the manager commands `:TSManager`, `:TSInstall`,
`:TSUninstall`, and `:TSUpdate`.

## What's configured
```lua
require("tree-sitter-manager").setup({
  ensure_installed = {
    "bash",
    "c",
    "cmake",
    "cpp",
    "diff",
    "dockerfile",
    "git_config",
    "gitcommit",
    "gitignore",
    "haskell",
    "hocon",
    "html",
    "java",
    "javascript",
    "json",
    "json5",
    "kotlin",
    "lua",
    "luadoc",
    "luap",
    "markdown",
    "markdown_inline",
    "python",
    "query",
    "regex",
    "rust",
    "terraform",
    "toml",
    "tsx",
    "typescript",
    "vim",
    "vimdoc",
    "yaml",
  },
  auto_install = true,
  highlight = true,
})

vim.filetype.add({ extension = { conf = "hocon" } })
```

The setup call is wired through `lua/config/pack.lua` by adding the plugin to
`vim.pack.add(...)` and loading `"tree-sitter-manager"` from the module list.

## Commands
- `:TSManager` — open the parser manager TUI
- `:TSInstall <lang>...` — install one or more parsers
- `:TSUninstall <lang>...` — remove one or more parsers
- `:TSUpdate <lang>...` — reinstall/refresh a parser

## Notes / gotchas
- The plugin expects the `tree-sitter` CLI to be available on `PATH`.
- It writes parsers into `stdpath("data")/site/parser` and queries into
  `stdpath("data")/site/queries` by default.
- It bundles `highlights/folds/indents/injections/locals` queries but **NO
  `textobjects.scm`**. Textobjects come from `nvim-treesitter-textobjects` (query
  files only) plus the make-range resolver — see `nvim-treesitter`. The
  `after/queries/` overrides in this repo still apply on top.
- This is now the **sole parser + highlight source** (`nvim-treesitter` was
  removed). It does NOT provide treesitter indentation.

## Docs / ground truth
- Source: `~/.local/share/nvim/site/pack/core/opt/tree-sitter-manager.nvim/`
- Help/docs: `:help tree-sitter-manager` (if installed)
- Upstream: https://github.com/romus204/tree-sitter-manager.nvim
- Current lockfile entry: `nvim-pack-lock.json`

## Verify your change
```bash
cd ~/.config/nvim
luac -p lua/plugins/tree-sitter-manager.lua
nvim --headless -u init.lua -c 'lua print(pcall(require, "tree-sitter-manager"))' -c 'qa!'
```

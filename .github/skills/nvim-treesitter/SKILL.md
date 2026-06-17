---
name: nvim-treesitter
description: >-
  How Treesitter is configured in this config (nvim-treesitter pinned to the
  master branch = classic setup API, stable on Neovim 0.12), plus the
  treesitter-textobjects integration and the after/queries/*.scm overrides. Use
  to add a parser/language, change highlight/indent, edit textobject queries, or
  understand why the master branch (not main) is used.
covers:
  - lua/plugins/treesitter.lua
  - after/queries/**/*.scm
---

# Treesitter

Configured in `lua/plugins/treesitter.lua`. This config pins
**nvim-treesitter to the `master` branch** (in `vim.pack.add`, `version =
"master"`), which uses the **classic `require("nvim-treesitter.configs").setup`
API**. The newer `main` branch has a different, incompatible API. On Neovim
0.12 the master/classic API is the stable choice here — do not "upgrade" the
config to the `main`-branch API.

## What's configured
```lua
require("nvim-treesitter.configs").setup({
  ensure_installed = { "bash", "c", "cpp", "lua", "java", "typescript", ... },
  auto_install = true,           -- install missing parsers on the fly
  highlight = { enable = true },
  indent = { enable = true },
})
vim.filetype.add({ extension = { conf = "hocon" } })  -- .conf -> hocon
```
`ensure_installed` is an explicit parser list (read the file for the full set).
`auto_install = true` means opening a new filetype pulls its parser
automatically (requires a network + a C compiler).

## Add a language/parser
Append the parser name to `ensure_installed` in `treesitter.lua`. Parser names
are the treesitter language ids (e.g. `python`, `rust`, `go`), not filetypes.
Confirm the exact id against the installed parser list:
```bash
ls ~/.local/share/nvim/site/pack/core/opt/nvim-treesitter/parser/   # installed
# or inside nvim:
nvim --headless -u init.lua -c 'TSInstallInfo' -c 'qa!'
```

## Textobjects (nvim-treesitter-textobjects)
The textobjects plugin (also pinned `master`) provides the queries consumed by
**mini.ai** for `af/if` (function), `ac/ic` (class), `ao/io`
(block/conditional/loop) and the custom `aa/ia` argument object. The wiring is
in `lua/plugins/mini.lua` + `lua/util/ai_argument.lua` — see `nvim-mini`. This
config does NOT use the textobjects plugin's own keymap module; mini.ai is the
front-end.

## Query overrides: after/queries/<lang>/*.scm
`after/queries/{c,cpp,java}/textobjects.scm` override/extend the textobject
captures for those languages. Files in `after/` are loaded after the plugin's
own queries, so they augment them. Edit these to change what `@function.inner`,
`@parameter.inner`, etc. capture for a language.

Important gotcha (documented in `util/ai_argument.lua`): `@parameter.outer` in
these grammars uses the `#make-range!` directive, which nvim-treesitter on
master on 0.12 fails to resolve via native `vim.treesitter` — that's why the
argument textobject is built on the plain `@parameter.inner` capture instead.
Keep this in mind when editing argument queries.

## Docs / ground truth
- `:help nvim-treesitter` and the plugin's `doc/`:
  `~/.local/share/nvim/site/pack/core/opt/nvim-treesitter/doc/`.
- Textobjects:
  `~/.local/share/nvim/site/pack/core/opt/nvim-treesitter-textobjects/`.
- Inspect live captures with `:Inspect` (highlight) and `:InspectTree`
  (syntax tree) on a buffer.

## Verify your change
```bash
cd ~/.config/nvim
luac -p lua/plugins/treesitter.lua
nvim --headless -u init.lua -c 'qa!'
# Parser present for a language:
nvim --headless -u init.lua \
  -c 'lua print(pcall(vim.treesitter.language.inspect, "lua"))' -c 'qa!'
# A textobjects query parses for a language (after/ overrides applied):
nvim --headless -u init.lua some.java \
  -c 'lua print(vim.treesitter.query.get("java","textobjects") ~= nil)' -c 'qa!'
```
Editing a `.scm` query? A malformed query throws when
`vim.treesitter.query.get` is called — the second check above surfaces it.

---
name: nvim-treesitter
description: >-
  How Treesitter works in this config AFTER nvim-treesitter was removed: parsers
  and highlight come from tree-sitter-manager, textobject queries come from
  nvim-treesitter-textobjects (query files only, never loaded), a make-range!
  directive handler + util.ai_treesitter resolver make mini.ai work, and
  after/queries/*.scm add only what upstream omits. Use to add a parser, edit
  textobject queries/captures, or understand the make-range gotcha.
covers:
  - lua/plugins/treesitter-textobjects.lua
  - lua/util/ai_treesitter.lua
  - lua/util/treesitter_indent.lua
  - after/queries/**/*.scm
---

# Treesitter

**`nvim-treesitter` was removed** (its sole maintainer archived it). This config
now uses Neovim's **native `vim.treesitter`** plus two narrowly-scoped helpers.
Do NOT re-add `nvim-treesitter` or its classic
`require("nvim-treesitter.configs").setup` API.

## Architecture (who provides what)

| Concern | Source | Skill |
| --- | --- | --- |
| Parsers + highlight + folds/indents/injections/locals queries | `tree-sitter-manager.nvim` | `nvim-tree-sitter-manager` |
| `textobjects.scm` query files | `nvim-treesitter-textobjects` (query data only) | this skill |
| make-range! handler + textobjects rtp wiring | `lua/plugins/treesitter-textobjects.lua` | this skill |
| mini.ai resolver (reads plain + make-range captures) | `lua/util/ai_treesitter.lua` | this skill |
| per-language capture overrides | `after/queries/<lang>/textobjects.scm` | this skill |
| consuming the textobjects in mini.ai | `lua/plugins/mini.lua`, `lua/util/ai_argument.lua` | `nvim-mini` |

tree-sitter-manager bundles `highlights/folds/indents/injections/locals` but
**NO `textobjects.scm`** for any language — that is why the textobjects plugin is
still needed as a query-only data source. This repo now uses a small local
adapter, `lua/util/treesitter_indent.lua`, that reads the installed `indents.scm`
queries from tree-sitter-manager and exposes an `indentexpr` for C/C++ buffers.

## nvim-treesitter-textobjects as a query-only data source

It is installed and pinned by `vim.pack.add` but its Lua runtime is **never
loaded** — its `plugin/*.vim` hard-requires the removed `nvim-treesitter` and
would error on startup. See `lua/config/pack.lua`:

```lua
vim.pack.add({
  { src = ".../nvim-treesitter-textobjects", version = "master" },
}, { load = function() end })   -- install + pin only, never source
```

`lua/plugins/treesitter-textobjects.lua` then does the two things needed to use
its query files natively:

1. **Registers a `make-range!` directive handler.** The textobjects queries
   define many objects (e.g. `function.inner`, `loop.inner`, `parameter.outer`)
   via `#make-range!`. `nvim-treesitter` used to register this directive; without
   a handler, `vim.treesitter` throws `No handler for make-range!` while
   iterating the query, breaking ALL textobjects. The handler stores the
   directive's range in `metadata[name].range`.
2. **Prepends the repo to `runtimepath` on `VimEnter`** (deferred past startup's
   plugin-sourcing pass, so the broken `plugin/*.vim` is never sourced).
   Prepended so the upstream base queries come before the `after/queries`
   overrides (which use `; extends`).

## The make-range invisibility gotcha (READ THIS before editing queries)

mini.ai's *builtin* treesitter resolver only inspects captures listed in
`query.captures` (the static capture list). `#make-range!` range NAMES are not in
that list, so directive-produced ranges are invisible to it. This is why this
config does NOT use `ai.gen_spec.treesitter`; it uses
`lua/util/ai_treesitter.lua`, a resolver that reads **both** plain `@capture`
nodes **and** `make-range!` metadata ranges. Result: `function.inner`,
`class.inner`, `loop.inner`, `conditional.inner` resolve in **every language**
straight from the upstream queries — **no per-language override needed** for them.

## Query overrides: after/queries/<lang>/textobjects.scm

`after/` files augment (not replace) the upstream query for a language. With the
make-range-aware resolver, the ONLY overrides still needed are objects upstream
never defines at all:

- `after/queries/c/textobjects.scm` and `cpp` — add `@block.inner` for
  `compound_statement` (upstream gives `@block.outer` but no inner), so mini.ai's
  `io` works.
- `after/queries/java/textobjects.scm` — add `@block.inner` for `(block)`, and
  capture `record`/`interface`/`enum` declarations as `@class` (upstream only
  captures plain `class_declaration`).

Do not re-add `function.inner`/`class.inner` overrides — they are redundant now
(upstream make-range + the resolver handle them). Keep the user-approved
`"{" (_)+ @block.inner "}"` form for block captures; do not rewrite it using
`#make-range!`.

## Add a language/parser

Parsers are managed by tree-sitter-manager, not here. Add the language id to
`ensure_installed` in `lua/plugins/tree-sitter-manager.lua` (see
`nvim-tree-sitter-manager`). Textobjects for a new language work automatically if
`nvim-treesitter-textobjects` ships a `queries/<lang>/textobjects.scm`; only add
an `after/queries` override if a specific object is missing upstream.

## Docs / ground truth

- Textobjects query files (the data source):
  `~/.local/share/nvim/site/pack/core/opt/nvim-treesitter-textobjects/queries/<lang>/textobjects.scm`
- make-range handler contract: `$VIMRUNTIME/lua/vim/treesitter/query.lua`
  (`add_directive`, `_apply_directives`).
- mini.ai builtin resolver (why make-range is invisible):
  `~/.local/share/nvim/site/pack/core/opt/mini.nvim/lua/mini/ai.lua`
  (`H.append_ranges`, `H.get_matched_ranges_builtin`).
- Inspect live captures with `:Inspect` and `:InspectTree` on a buffer.

## Verify your change

```bash
cd ~/.config/nvim
luac -p lua/plugins/treesitter-textobjects.lua lua/util/ai_treesitter.lua lua/util/treesitter_indent.lua
nvim --headless -u init.lua -c 'qa!'   # loads clean, no "No handler for make-range!"

# make-range! handler registered:
nvim --headless -u init.lua \
  -c 'lua print(vim.tbl_contains(vim.treesitter.query.list_directives(), "make-range!"))' \
  -c 'qa!' 2>&1 | grep -v 'tbl_flatten\|js-i18n\|npm install'

# treesitter-based indentation for C/C++:
printf 'namespace foo {\nint x = 1;\n}\n' > /tmp/v.cpp
nvim --headless -u init.lua -c 'lua
  vim.cmd("doautocmd VimEnter")
  vim.cmd("edit! /tmp/v.cpp")
  local b = vim.api.nvim_get_current_buf()
  vim.bo[b].filetype = "cpp"
  vim.cmd("doautocmd FileType")
  local indent = vim.fn.eval("indent(2)")
  print("indent_line2=" .. indent)
' -c 'qa!' 2>&1 | grep -E 'indent_line2'
rm -f /tmp/v.cpp
```

A malformed `.scm` query throws when `vim.treesitter.query.get` is first called
for that language; the cpp check above surfaces it.

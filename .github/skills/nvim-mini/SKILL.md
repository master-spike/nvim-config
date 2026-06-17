---
name: nvim-mini
description: >-
  mini.nvim modules in this config. Use when changing mini.ai textobjects,
  mini.surround, mini.icons, argument selection, surround conflicts, or when a
  model suggests mini.pairs. Grounded in lua/plugins/mini.lua and
  lua/util/ai_argument.lua.
covers:
  - lua/plugins/mini.lua
  - lua/util/ai_argument.lua
---

# mini.nvim

## Role

Small editing primitives from `mini.nvim`: textobjects, surround edits, and
icons. This config enables exactly three modules in `lua/plugins/mini.lua`:
`mini.ai`, `mini.surround`, and `mini.icons`. `mini.pairs` is intentionally
omitted; line 1 says it was disabled in the old config.

Ground truth:
- Config: `lua/plugins/mini.lua` and `lua/util/ai_argument.lua`.
- Install root: `~/.local/share/nvim/site/pack/core/opt/`.
- Install dir: `mini.nvim/`.
- Pinned rev: `a59a9b7fb0a42cbcf022938ee5f0724320b66f63`.
- Upstream: https://github.com/echasnovski/mini.nvim
- Help: `:help mini.ai`, `:help mini.surround`, `:help mini.icons`.
- Docs: `mini.nvim/doc/mini-ai.txt`, `mini-surround.txt`, `mini-icons.txt`.

## What's configured

This is the real setup in `lua/plugins/mini.lua`:

```lua
local ai = require("mini.ai")
local argument = require("util.ai_argument").spec

ai.setup({
  n_lines = 500,
  custom_textobjects = {
    a = argument,
    f = ai.gen_spec.treesitter({
      a = "@function.outer",
      i = "@function.inner",
    }),
    c = ai.gen_spec.treesitter({
      a = "@class.outer",
      i = "@class.inner",
    }),
    o = ai.gen_spec.treesitter({
      a = { "@block.outer", "@conditional.outer", "@loop.outer" },
      i = { "@block.inner", "@conditional.inner", "@loop.inner" },
    }),
  },
})

require("mini.surround").setup()
require("mini.icons").setup()
```

`mini.ai` uses default mappings plus these custom object ids:

```text
aa / ia  argument or parameter, from util.ai_argument.spec
af / if  function, from @function.outer and @function.inner
ac / ic  class, from @class.outer and @class.inner
ao / io  block, conditional, or loop captures
```

`lua/plugins/whichkey.lua` adds descriptions for these ids so which-key can
show them after `a`, `i`, `an`, `in`, `al`, and `il`. See `nvim-which-key`.

## Capabilities + examples

Use the normal `mini.ai` operator/visual grammar:

```text
daf  delete around function
yif  yank inside function
vac  visually select around class
daa  delete around argument
cia  change inside argument
```

Use `mini.surround` defaults. Verify mappings in `mini-surround.txt` before
changing them. Do not assume a surround mapping from another plugin.

Use `mini.icons` defaults. It is set up only by
`require("mini.icons").setup()` in `lua/plugins/mini.lua`.

## Argument textobject gotcha

`lua/util/ai_argument.lua` implements the `a` object. It collects
`@parameter.inner` captures from the `textobjects` query with
`vim.treesitter.query.get(...)`, chooses the smallest node containing the
cursor, and expands the around form to include one adjacent comma.

Do not switch it to `@parameter.outer` without testing. The file documents the
real reason: `@parameter.outer` is defined through `#make-range!` in these
queries, and nvim-treesitter master on Neovim 0.12 fails to resolve it with the
native `vim.treesitter` API. `@parameter.inner` is a plain capture and works.
Read `nvim-treesitter` before editing parser queries or captures.

## Gotchas / version notes

- Only three mini modules are enabled. Do not add `mini.pairs` unless asked.
- `n_lines = 500` is configured for `mini.ai`; the upstream default in
  `mini.nvim/lua/mini/ai.lua` is `50` at this pinned rev.
- `ai.gen_spec.treesitter(...)` exists in `mini.nvim/lua/mini/ai.lua` and is
  documented as `MiniAi.gen_spec.treesitter()`.
- The custom argument object returns a `mini.ai` region with 1-based line and
  column positions. Keep that convention if editing `util.ai_argument`.

## Docs / ground truth

Before using an API, verify it in installed source/docs:

```bash
P=~/.local/share/nvim/site/pack/core/opt/mini.nvim
rg -n 'MiniAi.gen_spec.treesitter|custom_textobjects|n_lines' "$P"/lua
rg -n 'mini.ai|MiniAi.gen_spec.treesitter' "$P"/doc
rg -n 'mini.surround|mini.icons' "$P"/doc
```

For the argument object, also inspect:

```bash
cd ~/.config/nvim
rg -n 'parameter.inner|parameter.outer|make-range' lua/util/ai_argument.lua
```

## Verify your change

Run from `~/.config/nvim`:

```bash
luac -p lua/plugins/mini.lua lua/util/ai_argument.lua
nvim --headless -u init.lua -c 'lua
  local ai = require("mini.ai")
  assert(ai.config.n_lines == 500)
  assert(type(ai.config.custom_textobjects.a) == "function")
  assert(type(ai.config.custom_textobjects.f) == "function")
  assert(type(require("mini.surround").config) == "table")
  assert(type(require("mini.icons")) == "table")
  print("PASS mini")
' -c 'qa!' 2>&1 | grep -v tbl_flatten
```

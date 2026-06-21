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
  - lua/util/ai_treesitter.lua
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

`lua/plugins/mini.lua` sets up the three modules. Read the file for the exact
custom-textobject id → capture map and the surround keys; the durable structure:

**`mini.ai`** — default textobjects plus a set of custom ids in
`custom_textobjects`, each built from a resolver rather than inline logic:

```lua
local ai = require("mini.ai")
local argument = require("util.ai_argument").spec
local treesitter = require("util.ai_treesitter").spec  -- make-range-aware (NOT ai.gen_spec.treesitter)

ai.setup({
  n_lines = 500,
  custom_textobjects = {
    a = argument,                                                  -- argument/parameter
    f = treesitter({ a = "@function.outer", i = "@function.inner" }),
    -- c/d/m/o similarly map an id to treesitter captures; read the file for the set
  },
})
```

The pattern that matters: custom ids are produced by `util.ai_argument.spec`
(the argument object) and `util.ai_treesitter.spec` (function/class/statement/
call/block-style objects from treesitter captures). To add or change an object,
edit the `custom_textobjects` map — don't write bespoke selection logic.

**`mini.surround`** — remapped to a **`gs` prefix** (`gsa`/`gsd`/`gsr`/`gsf`/
`gsF`/`gsh`) instead of the default `s` prefix. This is deliberate: it avoids
clashing with Flash and Vim's `s` substitute. Keep the `gs` prefix.

**`mini.icons`** — `require("mini.icons").setup()`, defaults only.

### Why util.ai_treesitter (not ai.gen_spec.treesitter)

The treesitter-backed ids are resolved by `lua/util/ai_treesitter.lua`, a
**make-range-aware** resolver, NOT mini.ai's `ai.gen_spec.treesitter`. Most
`*.inner` objects are defined upstream via the `#make-range!` directive, whose
range names mini.ai's builtin resolver cannot see; the custom resolver reads both
plain captures and make-range metadata, so inner objects work in every language
with no per-language override. See `nvim-treesitter` for the full story.

`lua/plugins/whichkey.lua` adds descriptions for the custom ids so which-key can
surface them after `a`/`i`/`an`/`in`/`al`/`il`. See `nvim-which-key`.

## Capabilities + examples

Use the normal `mini.ai` operator/visual grammar:

```text
daf  delete around function
yif  yank inside function
vac  visually select around class
daa  delete around argument
cia  change inside argument
dad  delete around statement/declaration
mam  delete around method/function call
```

Use `mini.surround` with the `gs` prefix (to avoid conflicts with Flash and other plugins):

```text
gsa{char}  add surrounding with {char}
gsd{char}  delete surrounding {char}
gsr{char1}{char2}  replace {char1} surrounding with {char2}
gsf{char}  find surrounding {char}
gsF{char}  find left surrounding {char}
gsh{char}  highlight surrounding {char}
```

Extend these with suffixes for search method:
- `n` or `l` for "next" / "last" (e.g., `gsan` adds next surrounding)

Use `mini.icons` defaults. It is set up only by
`require("mini.icons").setup()` in `lua/plugins/mini.lua`.

## Argument textobject gotcha

`lua/util/ai_argument.lua` implements the `a` object. It collects
`@parameter.inner` captures from the `textobjects` query with
`vim.treesitter.query.get(...)`, chooses the smallest node containing the
cursor, and expands the around form to include one adjacent comma.

Do not switch it to `@parameter.outer` without testing. The file documents the
real reason: `@parameter.outer` is defined through `#make-range!` in these
queries, whose range name is not in the static capture list, so the native
`vim.treesitter` query API cannot expose it as a capture. `@parameter.inner` is a
plain capture and works. Read `nvim-treesitter` before editing parser queries or
captures.

## Gotchas / version notes

- Only three mini modules are enabled. Do not add `mini.pairs` unless asked.
- `n_lines = 500` is configured for `mini.ai`; the upstream default in
  `mini.nvim/lua/mini/ai.lua` is `50` at this pinned rev.
- `mini.surround` mappings use the `gs` prefix instead of the default `s` prefix
  to avoid conflicts with Flash and Vim's default substitute command. The mappings
  are customized in the `setup()` call in `lua/plugins/mini.lua`.
- `lua/util/ai_treesitter.lua` provides the `f`/`c`/`o` specs via
  `require("util.ai_treesitter").spec(...)`, replacing `ai.gen_spec.treesitter`.
  It reads make-range metadata that gen_spec ignores. Do not revert to
  `ai.gen_spec.treesitter` — inner objects would break in most languages.
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
luac -p lua/plugins/mini.lua lua/util/ai_argument.lua lua/util/ai_treesitter.lua
nvim --headless -u init.lua -c 'lua
  local ai = require("mini.ai")
  assert(type(ai.config.n_lines) == "number")
  -- the custom-object PATTERN: ids resolve to resolver functions. Check the two
  -- stable ones (argument + function); the rest of the set may change.
  assert(type(ai.config.custom_textobjects.a) == "function", "argument object missing")
  assert(type(ai.config.custom_textobjects.f) == "function", "function object missing")
  assert(type(require("mini.surround").config) == "table")
  assert(type(require("mini.icons")) == "table")
  -- surround uses the gs prefix (the deliberate, durable choice):
  assert(vim.fn.maparg("gsa", "n") ~= "", "gsa should be mapped")
  assert(vim.fn.maparg("gsd", "n") ~= "", "gsd should be mapped")
  print("PASS mini")
' -c 'qa!' 2>&1 | grep -v tbl_flatten
```

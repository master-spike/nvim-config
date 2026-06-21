---
name: nvim-treesitter-context
description: >-
  treesitter-context.nvim sticky-scope header setup. Use when changing the
  context window (max_lines, multiline_threshold), the `[c` jump-to-context
  keymap, the `<leader>uc` Snacks toggle, the Java `@context.start` query
  override that pins the signature line instead of the annotations above it, or
  debugging the sticky header that shows the enclosing function/class/loop.
covers:
  - lua/plugins/treesitter-context.lua
---

# Treesitter Context

## Role

Shows a sticky header at the top of the window with the line(s) of the
enclosing scope (function, class, conditional, loop) so you always see the
context of the code you're looking at, even when it scrolls off-screen.
Configured in `lua/plugins/treesitter-context.lua`.

Ground truth:
- Config: `lua/plugins/treesitter-context.lua`.
- Install root: `~/.local/share/nvim/site/pack/core/opt/`.
- Install dir: `nvim-treesitter-context/`.
- Pinned rev: `b311b30818951d01f7b4bf650521b868b3fece16`.
- Upstream: https://github.com/nvim-treesitter/nvim-treesitter-context
- Help: `:help treesitter-context`.
- Docs: `nvim-treesitter-context/doc/treesitter-context.txt`.

Loaded from `pack.lua`: the `vim.pack.add` entry is unpinned (tracks default
branch). The module is ordered **after `snacks`** in the `modules` list because
the toggle below depends on the `Snacks` global being set first.

## What's configured

```lua
require("treesitter-context").setup({
  max_lines = 3,
  multiline_threshold = 1,
})

-- Re-anchor Java context to the signature line, not the annotations above it.
pcall(vim.treesitter.query.set, "java", "context", [[
  ...
  (method_declaration
    type: (_) @context.start
    body: (_) @context.end) @context
  (constructor_declaration
    name: (_) @context.start
    body: (_) @context.end) @context
  (class_declaration
    name: (_) @context.start
    body: (_) @context.end) @context
  (record_declaration
    name: (_) @context.start
    body: (_) @context.end) @context
  (interface_declaration
    name: (_) @context.start
    body: (_) @context.end) @context
  (enum_declaration
    name: (_) @context.start
    body: (_) @context.end) @context
  ...
]])

-- Jump to the top of the current context (upwards to the enclosing scope).
vim.keymap.set("n", "[c", function()
  require("treesitter-context").go_to_context(vim.v.count1)
end, { silent = true, desc = "Jump to context (upwards)" })

-- Toggle the context window via Snacks (<leader>u toggle convention).
Snacks.toggle
  .new({
    id = "treesitter_context",
    name = "Treesitter Context",
    get = function() return require("treesitter-context").enabled() end,
    set = function(state) require("treesitter-context").toggle() end,
  })
  :map("<leader>uc")
```

- `max_lines = 3`: at most 3 context lines shown at the top.
- `multiline_threshold = 1`: collapse a multi-line scope opener to a single line.
- The `<leader>uc` label is registered in `lua/plugins/whichkey.lua`.

### Java signature anchoring (the `@context.start` override)

In `tree-sitter-java` a declaration node (`method_declaration`,
`constructor_declaration`, `class_declaration`, `record_declaration`,
`interface_declaration`, `enum_declaration`) *starts* at its `modifiers` child,
which includes the annotations (`@Override`, `@Service`, ...). The plugin pins a
context node's **start row**, so by default Java context pins the annotation
lines instead of the signature.

**Why not show both annotation and signature?** The plugin trims header lines
from the **bottom up** (`get_text_for_range` strips from the last line while
`#lines > multiline_threshold`). So when a declaration has more annotations than
fit, the line that gets dropped is the *signature*, leaving only annotations —
the worst outcome. There is no "keep the signature, drop excess annotations"
mode. So we deliberately leave the annotations out and always show the
signature.

The plugin honours a `@context.start` capture that overrides the start row, so
the config re-anchors it to the signature line:
- methods → the `type` field (the return type, e.g. `void`),
- constructors / classes / records / interfaces / enums → the `name` field.

The displayed text always starts at column 0 (`get_text_for_range` forces
`start_col = 0`), so modifiers on the signature line (`public static`) are still
shown in full — only the annotation lines above are dropped.

**Why replace the whole query instead of `after/queries/java/context.scm`?**
`vim.treesitter.query.get` merges every `queries/java/context.scm` on the
runtimepath additively, and `context_range` returns the FIRST pattern whose
`@context` capture matches the node. The plugin's own `method_declaration` /
`class_declaration` patterns have a lower pattern index than an appended
`after/` one, so they always win — an `after/` override of those is silently
ignored. `vim.treesitter.query.set` replaces the query outright, so it must
carry ALL the original patterns plus the re-anchored ones AND the extra type
declarations (`constructor`/`record`/`interface`/`enum`) the bundled query does
not pin. If the plugin updates its bundled `queries/java/context.scm`, re-sync
this inlined copy.

## Capabilities + examples

- Sticky header updates automatically as you scroll/move.
- `[c`: jump upwards to the start of the current context (accepts a count).
- `<leader>uc`: toggle the context window on/off (shows enabled/disabled icon
  via Snacks).
- `:TSContextToggle`, `:TSContextEnable`, `:TSContextDisable` user commands also
  exist (provided by the plugin).

## Gotchas / version notes

- The plugin emits a `vim.tbl_flatten is deprecated` notice on load on Neovim
  0.12. This is upstream, not a config error; the verify recipes filter it out.
- The module MUST load after `snacks` (it uses `Snacks.toggle`). Keep
  `"treesitter-context"` after `"snacks"` in the `pack.lua` `modules` list.
- Public API (in `nvim-treesitter-context/lua/treesitter-context.lua`):
  `enable`, `disable`, `toggle`, `enabled`, `setup`, `go_to_context`.

## Docs / ground truth

Verify before changing an API, option, or keymap:

```bash
P=~/.local/share/nvim/site/pack/core/opt/nvim-treesitter-context
grep -nE '^function M\.' "$P"/lua/treesitter-context.lua
# The bundled java context query this override is kept in sync with:
cat "$P"/queries/java/context.scm
# How the start row / @context.start capture is applied:
grep -nE "context.start|range\[1\]" "$P"/lua/treesitter-context/context.lua
cd ~/.config/nvim
grep -nE 'go_to_context|Snacks.toggle|max_lines|query.set' lua/plugins/treesitter-context.lua
```

## Verify your change

Run from `~/.config/nvim`:

```bash
luac -p lua/plugins/treesitter-context.lua
nvim --headless -u init.lua -c 'lua
  local tc = require("treesitter-context")
  assert(type(tc.go_to_context) == "function")
  assert(type(tc.toggle) == "function")
  assert(type(tc.enabled) == "function")
  assert(vim.fn.maparg("[c", "n") ~= "", "[c should be mapped")
  print("PASS treesitter-context")
' -c 'qa!' 2>&1 | grep -v tbl_flatten

# Java signature anchoring: the method context.start must skip annotations.
printf "class F {\n  @Override\n  public void bar() {\n    x();\n  }\n}\n" > /tmp/_tc.java
nvim --headless -u init.lua /tmp/_tc.java -c 'lua
  local q = vim.treesitter.query.get("java", "context")
  local root = vim.treesitter.get_parser(0, "java"):parse()[1]:root()
  local function find(n,t) if n:type()==t then return n end
    for c in n:iter_children() do local r=find(c,t); if r then return r end end end
  local m = find(root, "method_declaration")
  for _, match in q:iter_matches(m, 0, 0, -1, {max_start_depth=0}) do
    for id, nodes in pairs(match) do
      local n0 = type(nodes)=="table" and nodes[#nodes] or nodes
      if q.captures[id] == "context.start" then
        local sr = n0:range()
        assert(sr == 2, "expected signature row 2, got "..sr)
        print("PASS java context.start anchors signature")
      end
    end
  end
' -c "qa!" 2>&1 | grep -v tbl_flatten
rm -f /tmp/_tc.java
```

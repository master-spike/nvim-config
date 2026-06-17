---
name: nvim-testing-and-verification
description: >-
  How to verify Neovim config changes rigorously and avoid hallucinating APIs.
  Read this before editing any Lua in this repo. Covers the syntax + headless
  load loop, driving plugins/pickers headlessly to inspect real output, locating
  installed plugin source and doc/*.txt helpfiles, confirming an API exists
  BEFORE using it, and the pinned-version lockfile. Use for any "verify",
  "test", "does this API exist", or "how do I check this works" request.
covers: []
---

# Testing & verification (anti-hallucination workflow)

The #1 failure mode when editing this config is **using an API that doesn't
exist or behaves differently in the installed version**. The #2 is **claiming a
change works without running it**. This skill exists to stop both. Follow it.

## Core principle: verify, then write, then test
1. **Confirm the API exists** in the *installed* source before you use it.
2. **Write** the smallest change that uses a documented option.
3. **Test** it with `luac -p` (syntax) and headless Neovim (behaviour).

Never skip step 1 or step 3.

## Where everything lives on disk
- **Config (this repo):** `~/.config/nvim`
- **Installed plugins (source + docs):**
  `~/.local/share/nvim/site/pack/core/opt/<plugin>/`
  - Lua source: `.../<plugin>/lua/...`
  - Help docs: `.../<plugin>/doc/*.txt`  (open in nvim with `:help <tag>`)
- **Pinned versions:** `~/.config/nvim/nvim-pack-lock.json` (exact git `rev` +
  optional `version` per plugin).

Plugin directory names match the repo name, e.g. `telescope.nvim`,
`blink.cmp`, `mini.nvim`, `nvim-treesitter`. List them:
```bash
ls ~/.local/share/nvim/site/pack/core/opt/
```

## Step 1 — Confirm an API exists BEFORE using it
Pick whichever is fastest; do at least one. Replace `<plugin>` with the dir.

```bash
P=~/.local/share/nvim/site/pack/core/opt/<plugin>

# (a) Search the plugin's own help docs for the option/function.
rg -n 'path_display' "$P"/doc/*.txt

# (b) Search the plugin's Lua source for the function/field.
rg -n 'function M.collapse|path_display' "$P"/lua

# (c) Read the setup options table / module exports directly.
rg -n 'gen_from_|function make_entry' "$P"/lua/telescope/make_entry.lua
```

Inside Neovim you can also:
```vim
:help telescope.defaults.path_display   " jump to the documented option
:lua print(vim.inspect(require('telescope.builtin')))  " list real functions
```

If grep across `doc/` and `lua/` finds nothing, **the API probably does not
exist** — do not invent it. Find the real one or ask.

## Step 2 — Syntax check (always, instantly)
```bash
cd ~/.config/nvim
luac -p lua/plugins/telescope.lua && echo OK   # one file
# or several:
for f in lua/util/path.lua lua/plugins/telescope.lua; do luac -p "$f" && echo "OK $f"; done
```
`luac -p` parses without executing — catches typos, bad concat, unbalanced
blocks. It does NOT catch runtime/logic errors; that's step 3.

## Step 3 — Headless load + behaviour test
The canonical pattern: start Neovim headless with real config, run Lua, quit.

```bash
cd ~/.config/nvim

# 3a. Does the whole config load cleanly?
nvim --headless -u init.lua -c 'qa!'
# No output (besides the known vim.tbl_flatten deprecation) == clean load.

# 3b. Run arbitrary Lua against the loaded config.
nvim --headless -u init.lua \
  -c 'lua print(require("util.path").collapse("a/b/c/reporting/file.txt"))' \
  -c 'qa!' 2>&1 | grep -v 'tbl_flatten'

# 3c. Assert and signal failure (useful in scripts).
nvim --headless -u init.lua -c 'lua
  local got = require("util.path").collapse("a/b/c/file.txt")
  assert(type(got) == "string", "expected string, got "..type(got))
  print("PASS: "..got)
' -c 'qa!' 2>&1 | grep -E 'PASS|Error|assert'
```

### Driving a Telescope picker headlessly (inspect real results)
This is how to *prove* a picker change works (results appear AND display is
correct) instead of guessing:

```bash
cd <some test dir> && nvim --headless -u ~/.config/nvim/init.lua -c 'lua
  require("telescope.builtin").find_files()
  vim.wait(1500, function() return false end)   -- let the async finder populate
  local picker = require("telescope.actions.state")
    .get_current_picker(vim.api.nvim_get_current_buf())
  if not picker then print("NO_PICKER") return end
  local n = 0
  for entry in picker.manager:iter() do
    n = n + 1
    local d = type(entry.display) == "function" and entry:display() or entry.display
    print("ENTRY: "..tostring(d))
  end
  print("COUNT: "..n)
' -c 'qa!' 2>&1 | grep -E 'ENTRY|COUNT|NO_PICKER'
```
Key points: `vim.wait(...)` is required because finders are async; iterate
`picker.manager:iter()`; an entry's `display` may be a **function** (call it as
`entry:display()`) or a string. For `live_grep`, pass `{default_text="..."}`.

### Inspecting other runtime state
```bash
# Which LSP servers are enabled / attached?
nvim --headless -u init.lua -c 'lua print(vim.inspect(vim.lsp.get_clients()))' -c 'qa!'
# A keymap's effect:
nvim --headless -u init.lua -c 'lua print(vim.fn.maparg("<leader>ff", "n"))' -c 'qa!'
# An option value:
nvim --headless -u init.lua -c 'lua print(vim.o.shiftwidth)' -c 'qa!'
```

## Formatting
The repo uses **stylua** (`stylua.toml`: 2-space, width 120). The `stylua`
CLI may not be on `PATH` in every environment. Options, in order of preference:
```bash
stylua --check lua/plugins/telescope.lua   # if the CLI is installed
```
If the CLI is missing, format inside Neovim via conform (it's configured for
`lua` → stylua, installed through Mason):
```bash
nvim --headless -u init.lua path/to/file.lua \
  -c 'lua require("conform").format({ bufnr = 0 })' -c 'wq'
```
Match surrounding style by hand if neither is available: 2-space indent, double
quotes, trailing commas in multiline tables.

## Common pitfalls (seen in this repo)
- **String concatenation is `..`, not `,`.** `return "/.../" .. rest` (a comma
  makes it return two values and usually a syntax error before `..`).
- **Async finders need `vim.wait`** before results exist (see picker recipe).
- **`entry.display` can be a function** — call it, don't print the function.
- **Wrong plugin API:** `telescope.finders` has no `entry_from_file`; the real
  entry makers are in `telescope.make_entry` (`gen_from_file`,
  `gen_from_vimgrep`). Always grep the installed source (Step 1) rather than
  guessing the module path.
- **`vim.tbl_flatten is deprecated`** in headless output is pre-existing plugin
  noise — filter it with `grep -v tbl_flatten`, don't "fix" it.
- **Don't add new tooling** (test frameworks, linters) to verify — `luac -p` +
  headless nvim is the supported baseline and is always available.

## Definition of done
A change is complete only when:
1. Every touched file passes `luac -p`.
2. `nvim --headless -u init.lua -c 'qa!'` loads with no new errors.
3. The specific behaviour is demonstrated (picker results, option value, keymap,
   function output) via a headless Lua snippet — not asserted from memory.

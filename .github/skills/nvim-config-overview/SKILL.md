---
name: nvim-config-overview
description: >-
  Architecture and conventions of this Neovim config (vim.pack + native LSP, no
  LazyVim/lazy.nvim). Read this FIRST before changing anything. Covers load
  order, directory layout, the per-plugin module pattern, how to add/remove a
  plugin, coding conventions, and links to the other skills. Use whenever you
  are orienting yourself in this repo or asked "how does my config work".
covers:
  - init.lua
  - lua/config/pack.lua
---

# Neovim config overview

This is a **from-scratch Neovim 0.12 config**. It does **not** use LazyVim or
lazy.nvim. Plugins are managed by the built-in `vim.pack`, and LSP is wired with
native `vim.lsp.config` / `vim.lsp.enable`. The `README.md` still says "LazyVim"
— that is a stale leftover; ignore it.

Repo root: `~/.config/nvim` (this is also the git root).

## Golden rules for working here
1. **Read before you write.** Match the existing pattern in the file you are
   editing. This config is deliberately small and hand-rolled — do not introduce
   frameworks, abstractions, or plugin managers.
2. **Prefer a built-in config option over bespoke Lua.** Many requests are a
   single documented option (e.g. telescope's `path_display`). Check the
   plugin's `doc/*.txt` before writing a custom function. See
   `nvim-testing-and-verification`.
3. **Never trust an API from memory — verify it exists in installed source.**
   See `nvim-testing-and-verification` for the exact workflow.
4. **Always verify your change actually loads and behaves**, with `luac -p` and
   headless Neovim. A change is not done until tested.
5. **Formatting:** stylua, 2-space indent, column width 120 (`stylua.toml`).
6. **Keep the skills current.** When you change a config file, update the skill
   that documents it in the SAME change. `nvim-skill-maintenance` has the
   file -> skill index and the rules for stale skills and new plugins.

## Load order (init.lua)
`init.lua` requires five modules **in this exact order**:

```lua
require("config.options")   -- 1. vim.g.mapleader + all vim.opt settings
require("config.keymaps")   -- 2. global keymaps (need leader already set)
require("config.autocmds")  -- 3. autocommands
require("config.pack")      -- 4. vim.pack.add(...) + load every plugins/* module
require("config.lsp")       -- 5. native LSP config/enable
```

Order matters: `options` sets `mapleader` before `keymaps` defines `<leader>`
mappings; `pack` installs/loads plugins before `lsp` (which references
`blink.cmp` for capabilities and `telescope.builtin` for LSP keymaps).

## Directory layout
```
init.lua                 -- entry point, just 5 requires
lua/config/              -- core editor config (no plugin setup except pack loader)
  options.lua            -- vim.opt + leader
  keymaps.lua            -- global vim.keymap.set
  autocmds.lua           -- vim.api.nvim_create_autocmd, grouped via augroup()
  pack.lua               -- vim.pack.add{...} + the plugin module loader loop
  lsp.lua                -- vim.lsp.config / vim.lsp.enable, diagnostics, LspAttach
lua/plugins/<name>.lua   -- ONE file per plugin; does its own require(...).setup()
lua/util/<name>.lua      -- shared helper modules (return a table)
after/queries/<lang>/    -- treesitter query overrides (*.scm)
nvim-pack-lock.json      -- vim.pack lockfile (pinned revs/versions)
stylua.toml              -- formatter config
.github/skills/          -- THESE skills
```

## The plugin module pattern (most important convention)
Plugins are wired in **two places**, both in `lua/config/pack.lua`:

1. **Install** — add an entry to `vim.pack.add({ ... })`:
   ```lua
   { src = "https://github.com/owner/repo" },
   -- optionally: version = "v1.2.3"  or  version = vim.version.range("3")
   ```
2. **Configure** — add the module name to the `modules` list, which is looped:
   ```lua
   for _, m in ipairs(modules) do
     local ok, err = pcall(require, "plugins." .. m)
     if not ok then
       vim.notify("Failed to load plugin module '" .. m .. "': " .. err, vim.log.levels.ERROR)
     end
   end
   ```
   So `modules = { ..., "telescope" }` requires `lua/plugins/telescope.lua`.

Each `lua/plugins/<name>.lua` is self-contained: it `require`s the plugin and
calls its `.setup()` (plus any keymaps for that plugin). The `pcall` wrapper
means one broken module won't break the whole config — it just notifies.

### How to ADD a plugin
1. Add `{ src = "https://github.com/owner/repo" }` to `vim.pack.add` (pack.lua).
2. Create `lua/plugins/<name>.lua` that does `require("<module>").setup({...})`.
3. Add `"<name>"` to the `modules` list in `pack.lua`.
4. Restart Neovim (or `:lua vim.pack.add` is run at startup); run the verify
   recipe below.

### How to REMOVE a plugin
Reverse the above: delete the `vim.pack.add` entry, delete
`lua/plugins/<name>.lua`, remove it from `modules`. Optionally prune from
`nvim-pack-lock.json`.

## util/ helpers (shared code lives here, not inline)
- `util/path.lua` — `collapse(filepath)` shortens a path by replacing each
  directory whose parent has exactly one subdirectory with `...` (deduped). Used
  by `lualine`, `telescope` (`path_display`), and the `gitsigns` hunks picker so
  all three shorten paths identically. Memoized via `vim.uv.fs_scandir`.
- `util/lsp_definition.lua` — `goto_definition` used by the `gd` LSP keymap.
- `util/ai_argument.lua` — treesitter `@parameter.inner` argument textobject for
  mini.ai (the `aa`/`ia` object). See `nvim-mini`.
- `util/ai_treesitter.lua` — make-range-aware treesitter resolver for mini.ai's
  `f`/`c`/`o` textobjects (replaces `ai.gen_spec.treesitter`). See
  `nvim-treesitter`.

When logic is needed in more than one place, add it to `util/` and `require` it;
don't duplicate.

## Where to go next (other skills)
- `nvim-testing-and-verification` — **read this before making changes.** How to
  verify APIs and test changes (luac, headless nvim, finding plugin docs).
- `nvim-skill-maintenance` — **read when you change config.** Which skill to
  update for a given file, how to handle stale skills, and adding new ones.
- `nvim-core-options-keymaps-autocmds` — editing options/keymaps/autocmds.
- `nvim-pack-management` — vim.pack, the lockfile, versions, build steps.
- `nvim-lsp` — native LSP, mason, adding servers.
- `nvim-treesitter` — native treesitter, textobject queries, the make-range
  resolver, and `after/queries` overrides (nvim-treesitter itself was removed).
- One skill per plugin: `nvim-telescope`, `nvim-blink-cmp`, `nvim-conform`,
  `nvim-lint`, `nvim-mini`, `nvim-gitsigns`, `nvim-lualine`, `nvim-neo-tree`,
  `nvim-snacks`, `nvim-trouble`, `nvim-which-key`, `nvim-flash`, `nvim-octo`,
  `nvim-jdtls`, `nvim-render-markdown`, `nvim-mason`,
  `nvim-tree-sitter-manager`, `nvim-99`, `nvim-colorscheme`, and
  `nvim-misc-plugins` (the small ones).

## Verify your change
Run from the repo root (`~/.config/nvim`):

```bash
# 1. Syntax-check every Lua file you touched.
luac -p lua/config/pack.lua

# 2. Confirm the whole config loads with no errors (headless, then quit).
nvim --headless -u init.lua -c 'qa!'
# Any require/setup error prints a `Failed to load plugin module ...` notify
# line or a stack trace. Clean exit with no error output == config loads.

# 3. If you added a plugin, confirm its module loaded:
nvim --headless -u init.lua -c 'lua print(pcall(require, "plugins.<name>"))' -c 'qa!'
```
A `vim.tbl_flatten is deprecated` warning from a plugin is pre-existing noise,
not your error.

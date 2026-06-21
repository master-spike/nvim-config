---
name: nvim-pack-management
description: >-
  How plugins are installed and loaded in this config using Neovim 0.12's
  built-in vim.pack (no lazy.nvim). Covers lua/config/pack.lua, the
  vim.pack.add list, version pinning, the nvim-pack-lock.json lockfile, build
  steps, and the per-plugin module loader loop. Use to add, remove, pin, or
  update a plugin, or to debug why a plugin module failed to load.
covers:
  - lua/config/pack.lua
  - nvim-pack-lock.json
---

# Plugin management (vim.pack)

This config uses **Neovim 0.12's built-in `vim.pack`** — not lazy.nvim or
packer. Everything lives in `lua/config/pack.lua`. Plugins are cloned to
`~/.local/share/nvim/site/pack/core/opt/<plugin>/` and added to the runtimepath.

## The two-part pattern (install + configure)
`pack.lua` does two things, in order:

1. **Install** via `vim.pack.add({ ... })` — a list of `{ src = "<git url>" }`
   specs (these are illustrative; read `pack.lua` for the live list):
   ```lua
   vim.pack.add({
     { src = "https://github.com/owner/repo" },                      -- default branch
     { src = "https://github.com/owner/repo", version = "v1.6.0" },  -- pinned tag
     { src = "https://github.com/owner/repo", version = vim.version.range("3") },
   })
   ```

   A second `vim.pack.add` call installs `nvim-treesitter-textobjects` with a
   no-op `load` so it is **installed and pinned but never sourced** (used only as
   a query data source — see `nvim-treesitter`):
   ```lua
   vim.pack.add({
     { src = ".../nvim-treesitter-textobjects", version = "master" },
   }, { load = function() end })
   ```
2. **Configure** via the module loader loop — a `modules` table of plugin module
   names, each `require`d under `pcall`:
   ```lua
   local modules = { "colorscheme", "tree-sitter-manager", "treesitter-textobjects", "telescope", ... }
   for _, m in ipairs(modules) do
     local ok, err = pcall(require, "plugins." .. m)
     if not ok then
       vim.notify("Failed to load plugin module '" .. m .. "': " .. err,
         vim.log.levels.ERROR)
     end
   end
   ```
   `"telescope"` → loads `lua/plugins/telescope.lua`. The `pcall` isolates
   failures: a broken module notifies but doesn't abort the rest.

## Version pinning (the `version` field)
`version` accepts:
- a tag/branch string: `version = "v1.6.0"`, `version = "master"`, `"dev"`
- a semver range: `version = vim.version.range("3")` (neo-tree uses `3` →
  resolves to `3.0.0 - 4.0.0`).
- omitted → tracks the default branch.

Pin a plugin that needs a specific branch/API. `nvim-treesitter-textobjects` is
pinned to `master` and loaded via a no-op `load` callback so vim.pack installs +
pins it without sourcing its (broken) runtime — see `nvim-treesitter`. To remove
a plugin's dir AND lockfile entry, use `vim.pack.del({ "<name>" })`; deleting the
dir or editing the lockfile by hand is not enough (vim.pack re-clones from the
lockfile on the next start).

## The lockfile: nvim-pack-lock.json
`~/.config/nvim/nvim-pack-lock.json` records the exact `rev` (commit) + `src`
(+ `version`) each plugin is locked to. `vim.pack` reads/writes it so installs
are reproducible. To know exactly what's installed, read this file — it is the
source of truth for versions.

Note: the lockfile may contain plugins **not** in the current `vim.pack.add`
list (e.g. extra colorschemes `catppuccin`, `gruvbox`, `kanagawa`, `nightfox`).
Those are previously-installed leftovers, not active — only entries in
`vim.pack.add` are loaded.

## Self-heal guard: stray non-git dirs crash startup
The top of `lua/config/pack.lua` (before `vim.pack.add`) prunes any directory in
`site/pack/core/opt/` that lacks a `.git`. This is mandatory, not cosmetic:
`vim.pack`'s `lock_sync()` traverses **every** entry in `opt/` on each startup and,
for a directory with no git metadata, calls `lock_repair()` which runs `git`
inside it and **aborts init** with a fatal `E5113 ... not a git repository`.
Every real plugin is a git clone (has `.git`); tree-sitter-manager parsers live
under `site/parser`, never `opt/`. So a non-git dir in `opt/` is always stray
junk (historically a leftover `nvim-treesitter/parser` recreated after the plugin
was removed) and is safe to delete. Do not remove this guard.

## Build steps (compiled plugins)
Some plugins need a build. `pack.lua` handles telescope-fzf-native inline after
`vim.pack.add`: if its `build/libfzf.so` is missing and `make` exists, it runs
`make -C <dir>`. Mirror this pattern for any other plugin needing compilation —
guard on the artifact existing and the tool being available.

## Add / remove / update — exact steps
**Add:**
1. Append `{ src = "https://github.com/owner/repo" }` to `vim.pack.add`.
2. Create `lua/plugins/<name>.lua` doing `require("<module>").setup({...})`.
3. Add `"<name>"` to the `modules` list.
4. Restart Neovim; verify (below).
5. **Author its skill.** A substantial plugin gets a new
   `.github/skills/nvim-<name>/SKILL.md`; a tiny library/game gets an entry in
   `nvim-misc-plugins`. This is part of done — see `nvim-skill-maintenance`.

**Remove:** delete the `vim.pack.add` entry, delete `lua/plugins/<name>.lua`,
remove `"<name>"` from `modules`. Optionally remove its lockfile entry. Also
delete/trim its skill and regenerate the index (see `nvim-skill-maintenance`).

**Update:** `vim.pack` provides update commands at runtime (`:h vim.pack`).
updating, the lockfile `rev` changes — commit it.

## Anti-hallucination
`vim.pack` is the Neovim 0.12 native API. If unsure of a field or command, read
`:help vim.pack` inside Neovim rather than assuming lazy.nvim-style spec keys
(`opts`, `event`, `dependencies`, `config` — **none of those exist here**).
Dependencies are handled by listing both plugins in `vim.pack.add` and ordering
the `modules` list.

## Verify your change
```bash
cd ~/.config/nvim
luac -p lua/config/pack.lua
# Whole config still loads:
nvim --headless -u init.lua -c 'qa!'
# A specific plugin module loaded without error:
nvim --headless -u init.lua \
  -c 'lua print(pcall(require, "plugins.telescope"))' -c 'qa!'
# The plugin's runtime is on the rtp / requirable:
nvim --headless -u init.lua \
  -c 'lua print(pcall(require, "telescope"))' -c 'qa!'
```
A `Failed to load plugin module '<name>'` notify line means the module errored —
read the appended error; usually a typo or a missing `.setup()` dependency.

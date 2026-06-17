---
name: nvim-neo-tree
description: >-
  Neo-tree file explorer in this repo: current-window explorer, reveal-current
  keymap, filesystem filters, symlink icon component, dependencies, and verify
  steps. Use when changing lua/plugins/neo-tree.lua, <leader>e, :Neotree,
  hidden-file behavior, explorer icons, or neo-tree/sidebar integration.
covers:
  - lua/plugins/neo-tree.lua
---

# Neo-tree

File explorer. Configured in `lua/plugins/neo-tree.lua`. Installed source is
`~/.local/share/nvim/site/pack/core/opt/neo-tree.nvim/`, upstream is
https://github.com/nvim-neo-tree/neo-tree.nvim, and the lockfile pins rev
`83e7a2982f` with version range `3.0.0 - 4.0.0` from
`vim.version.range("3")` in `lua/config/pack.lua`.

## Role
Use neo-tree as the file browser for the current window, not as a left sidebar.
The docs list `current` as a valid `position`; see `:help neo-tree` and
`doc/neo-tree.txt` in the installed plugin.

## What's configured
Faithful excerpt from `lua/plugins/neo-tree.lua`:

```lua
require("neo-tree").setup({
  window = { position = "current" },
  filesystem = {
    filtered_items = {
      visible = false,
      hide_gitignored = true,
      hide_dotfiles = false,
      hide_by_name = { ".git" },
    },
    components = {
      icon = function(config, node, state)
        if node.type == "file" and node.link_to then
          return { text = "→ ", highlight = "NeoTreeSymbolicLinkTarget" }
        end
        return require("neo-tree.sources.filesystem.components")
          .icon(config, node, state)
      end,
    },
  },
})

vim.keymap.set(
  "n",
  "<leader>e",
  "<cmd>Neotree toggle reveal<cr>",
  { desc = "Explorer (reveal current file)" }
)
```

`reveal` is a documented `:Neotree` flag in `doc/neo-tree.txt`; it focuses the
current file when the explorer opens.

## Capabilities + examples
- Toggle the explorer and reveal the current buffer: press `<leader>e`.
- Command form used by the keymap: `:Neotree toggle reveal`.
- Dotfiles are shown, gitignored files are hidden, and `.git` is hidden.
- File symlinks use `→ ` with `NeoTreeSymbolicLinkTarget`.

## Gotchas / version notes
- Do not document a left sidebar here: `window.position` is `"current"`.
- `bufferline.lua` still has an offset for filetype `neo-tree`; if neo-tree is
  later moved back to a sidebar, cross-check `bufferline.lua` behavior (see
  `nvim-misc-plugins`).
- Dependencies are installed in `lua/config/pack.lua`: `nui.nvim`,
  `plenary.nvim`, and `nvim-web-devicons`. See `nvim-misc-plugins`.
- Verify any new option in installed `lua/` or `doc/` before using it.

## Docs / ground truth
- Config: `lua/plugins/neo-tree.lua`; pack entry: `lua/config/pack.lua`.
- Installed docs/source:
  `~/.local/share/nvim/site/pack/core/opt/neo-tree.nvim/doc/neo-tree.txt` and
  `~/.local/share/nvim/site/pack/core/opt/neo-tree.nvim/lua/`.
- Help tags: `:help neo-tree`, `:help neo-tree-commands`,
  `:help neo-tree-filtered-items`.
- Lockfile: `nvim-pack-lock.json`, rev `83e7a2982f`.

## Verify your change
Run from `~/.config/nvim`:

```bash
luac -p lua/plugins/neo-tree.lua
nvim --headless -u init.lua \
  -c 'lua assert(vim.fn.maparg("<leader>e", "n") ~= "")' \
  -c 'qa!' 2>&1 | grep -v tbl_flatten
nvim --headless -u init.lua \
  -c 'lua vim.cmd("Neotree toggle reveal")' \
  -c 'qa!' 2>&1 | grep -v tbl_flatten
```

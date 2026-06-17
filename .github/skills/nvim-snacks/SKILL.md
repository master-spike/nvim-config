---
name: nvim-snacks
description: >-
  Snacks.nvim image configuration and global Snacks.toggle usage in this repo.
  Use when changing lua/plugins/snacks.lua, image rendering, doc.conceal,
  formatter/translation toggles, <leader>uf, <leader>uF, <leader>ut, or the
  lua_ls Snacks global.
covers:
  - lua/plugins/snacks.lua
---

# Snacks

QoL plugin collection. This repo configures only Snacks image support in
`lua/plugins/snacks.lua`. Installed source is
`~/.local/share/nvim/site/pack/core/opt/snacks.nvim/`, upstream is
https://github.com/folke/snacks.nvim, and `nvim-pack-lock.json` pins rev
`882c996cf2`.

## Role
Use Snacks here for image rendering and for the global `Snacks.toggle` helper
used by other plugin files. Do not assume other Snacks modules are configured in
`snacks.lua`.

## What's configured
Faithful excerpt from `lua/plugins/snacks.lua`:

```lua
require("snacks").setup({
  image = {
    enabled = true,
    doc = {
      conceal = false,
      enabled = true,
      inline = true,
      float = true,
    },
  },
})

if Snacks and Snacks.image and Snacks.image.config then
  Snacks.image.config.doc.conceal = false
end
```

The second block is a direct patch: image document conceal is forced off after
setup. The installed image docs define `doc.enabled`, `doc.inline`, `doc.float`,
and `doc.conceal`; see `doc/snacks.nvim-image.txt`.

## Capabilities + examples
- Image module: render document images inline when supported, otherwise float.
- Reusable toggle pattern from installed `lua/snacks/toggle.lua`:

```lua
Snacks.toggle.new({
  id = "my_toggle",
  name = "My Toggle",
  get = function()
    return true
  end,
  set = function(enabled)
    vim.g.my_toggle = enabled
  end,
}):map("<leader>ux")
```

Real uses in this repo:
- `lua/plugins/conform.lua`: `<leader>uf` and `<leader>uF` formatter toggles.
- `lua/plugins/js-i18n.lua`: `<leader>ut` translation virtual-text toggle.

## Gotchas / version notes
- `snacks.lua` does not configure picker, explorer, dashboard, notifier, or
  indent. Verify before using any Snacks module API.
- The global `Snacks` name is allowed for lua_ls in `lua/config/lsp.lua`:
  `diagnostics.globals = { "vim", "Snacks" }`. See `nvim-lsp`.
- The which-key group labels for `<leader>uf`, `<leader>uF`, and `<leader>ut`
  live in `lua/plugins/whichkey.lua`. See `nvim-which-key`.
- Cross-reference `nvim-conform` before changing formatter toggles.

## Docs / ground truth
- Config: `lua/plugins/snacks.lua`; pack entry: `lua/config/pack.lua`.
- Installed docs/source:
  `~/.local/share/nvim/site/pack/core/opt/snacks.nvim/doc/` and
  `~/.local/share/nvim/site/pack/core/opt/snacks.nvim/lua/snacks/`.
- Help tags: `:help snacks.nvim`, `:help snacks.nvim-image`.
- Toggle source: `lua/snacks/toggle.lua`, `M.new(...)`, `Toggle:map(...)`.
- Lockfile: `nvim-pack-lock.json`, rev `882c996cf2`.

## Verify your change
Run from `~/.config/nvim`:

```bash
luac -p lua/plugins/snacks.lua lua/plugins/conform.lua lua/plugins/js-i18n.lua
nvim --headless -u init.lua \
  -c 'lua assert(Snacks and Snacks.image and Snacks.toggle)' \
  -c 'lua assert(Snacks.image.config.doc.conceal == false)' \
  -c 'qa!' 2>&1 | grep -v tbl_flatten
nvim --headless -u init.lua \
  -c 'lua assert(vim.wait(1000, function()
  return vim.fn.maparg("<leader>uf", "n") ~= ""
end))
assert(vim.fn.maparg("<leader>ut", "n") ~= "")' \
  -c 'qa!' 2>&1 | grep -v tbl_flatten
```

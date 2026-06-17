---
name: nvim-octo
description: >-
  How octo.nvim is configured for GitHub issues, PRs, discussions,
  notifications, and repo-scoped search. Use when editing Octo setup,
  adding GitHub keymaps, debugging :Octo commands, checking gh auth,
  or integrating Octo with Telescope or render-markdown.
covers:
  - lua/plugins/octo.lua
---

# Octo

GitHub issue, pull request, discussion, notification, and search UI inside
Neovim. The local config is `lua/plugins/octo.lua`. The installed plugin is
`~/.local/share/nvim/site/pack/core/opt/octo.nvim/`, pinned in
`nvim-pack-lock.json` at rev `7fed87415c401954f73401bbed0fd736b9611e7c`.
Upstream is https://github.com/pwntester/octo.nvim.

## Role

Use Octo for GitHub objects through the documented `:Octo <object> <action>`
command interface. It depends on an authenticated `gh` CLI; Octo's help lists
`gh CLI binary` as a dependency in `doc/octo.txt`.

## What's configured

Faithful excerpt from `lua/plugins/octo.lua`:

```lua
require("octo").setup({
  picker = "telescope",
  enable_builtin = true,
})

local map = vim.keymap.set
map("n", "<leader>oi", "<CMD>Octo issue list<CR>")
map("n", "<leader>op", "<CMD>Octo pr list<CR>")
map("n", "<leader>od", "<CMD>Octo discussion list<CR>")
map("n", "<leader>on", "<CMD>Octo notification list<CR>")
map("n", "<leader>os", function()
  require("octo.utils").create_base_search_command({
    include_current_repo = true,
  })
end)
```

Do not add guessed keymaps. Check `lua/plugins/octo.lua` first.

## Capabilities + examples

Use the configured mappings:

- `<leader>oi` runs `:Octo issue list`.
- `<leader>op` runs `:Octo pr list`.
- `<leader>od` runs `:Octo discussion list`.
- `<leader>on` runs `:Octo notification list`.
- `<leader>os` starts Octo search with `include_current_repo = true`.

Use documented commands from `:help octo-commands`:

```vim
:Octo issue list
:Octo pr list
:Octo discussion list
:Octo search is:pr author:@me
```

The picker backend is Telescope, configured by `picker = "telescope"`; see
`nvim-telescope` before changing picker behavior. Octo buffers are rendered as
markdown because `lua/plugins/render-markdown.lua` includes `"octo"` in
`file_types`; see `nvim-render-markdown`.

## Gotchas / version notes

- `enable_builtin = true` is real Octo config. The installed source validates
  `enable_builtin` as a boolean in `lua/octo/config.lua`.
- Valid picker names in this rev include `"telescope"`, `"fzf-lua"`,
  `"snacks"`, and `"default"` in `lua/octo/config.lua`.
- Search uses `require("octo.utils").create_base_search_command(...)`; grep
  that symbol in the installed `octo.nvim/lua/` before changing it.
- GitHub API failures usually mean `gh auth status` is not clean, not that the
  keymap is wrong.

## Docs / ground truth

- Config: `lua/plugins/octo.lua`.
- Installed source/docs:
  `~/.local/share/nvim/site/pack/core/opt/octo.nvim/`.
- Help tags: `:help octo`, `:help octo-commands`,
  `:help octo-commands-issue`, `:help octo-commands-pr`,
  `:help octo-commands-discussion`, `:help octo-commands-search`.
- Source checked: `lua/octo/config.lua`, `lua/octo/commands.lua`,
  `lua/octo/utils.lua`, and `doc/octo.txt`.
- Upstream: https://github.com/pwntester/octo.nvim.

## Verify your change

Run syntax and a headless keymap/setup check:

```bash
cd ~/.config/nvim
luac -p lua/plugins/octo.lua && echo OK
nvim --headless -u init.lua \
  -c 'lua local c=require("octo.config").values; print(c.picker)' \
  -c 'lua print(vim.fn.maparg("<leader>oi", "n"))' \
  -c 'qa!' 2>&1 | grep -v tbl_flatten
```

Expected output includes `telescope` and `Octo issue list`. For live GitHub
checks, run `gh auth status` before opening Neovim.

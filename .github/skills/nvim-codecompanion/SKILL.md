---
name: nvim-codecompanion
description: >-
  How codecompanion.nvim is configured with the Copilot adapter for chat,
  inline, and cmd strategies. Use when editing AI keymaps under <leader>a,
  debugging CodeCompanion commands/events, checking Copilot auth, or changing
  the fidget spinner integration. Distinct from nvim-99.
covers:
  - lua/plugins/codecompanion.lua
---

# CodeCompanion

AI chat and inline-edit plugin. The local config is
`lua/plugins/codecompanion.lua`. The installed plugin is
`~/.local/share/nvim/site/pack/core/opt/codecompanion.nvim/`, pinned in
`nvim-pack-lock.json` at rev `123d8b3428b321ade9a8c1b749a65e4021a14dd0`.
Upstream is https://github.com/olimorris/codecompanion.nvim.

## Role

Use CodeCompanion for explicit chat, action-palette, visual-selection, and
inline-edit flows. It is a separate AI plugin from `99`; see `nvim-99` before
assuming a `<leader>9` mapping belongs here.

## What's configured

Faithful excerpt from `lua/plugins/codecompanion.lua`:

```lua
require("codecompanion").setup({
  strategies = {
    chat = { adapter = "copilot" },
    inline = { adapter = "copilot" },
    cmd = { adapter = "copilot" },
  },
})

map({ "n", "x" }, "<leader>aa", "<cmd>CodeCompanionActions<cr>")
map({ "n", "x" }, "<leader>ac", "<cmd>CodeCompanionChat Toggle<cr>")
map("x", "<leader>ax", "<cmd>CodeCompanionChat Add<cr>")
map({ "n", "x" }, "<leader>ai", ":CodeCompanion ")
```

The same file adds a which-key group:

```lua
wk.add({ { "<leader>a", group = "AI" } })
```

It also creates `CodeCompanionFidget` `User` autocmds for
`CodeCompanionRequestStarted` and `CodeCompanionRequestFinished`. The started
handler calls `require("fidget.progress").handle.create(...)`; see
`nvim-misc-plugins` for fidget.

## Capabilities + examples

Use the configured mappings:

- `<leader>aa` opens `:CodeCompanionActions` in normal or visual mode.
- `<leader>ac` toggles `:CodeCompanionChat Toggle`.
- `<leader>ax` adds the visual selection with `:CodeCompanionChat Add`.
- `<leader>ai` leaves `:CodeCompanion ` on the command line for an inline edit.

Use documented commands from `:help codecompanion`:

```vim
:CodeCompanionActions
:CodeCompanionChat Toggle
:'<,'>CodeCompanionChat Add
:CodeCompanion rewrite this function to be smaller
```

The configured adapter is `"copilot"` for `strategies.chat`,
`strategies.inline`, and `strategies.cmd`. CodeCompanion's Copilot HTTP
adapter reads token files under `stdpath("config") .. "/github-copilot/"`
in `lua/codecompanion/adapters/http/copilot/token.lua`.

## Gotchas / version notes

- Do not replace the adapter name from memory. Verify adapter names in
  `doc/codecompanion.txt` and `lua/codecompanion/adapters/` first.
- This config uses the HTTP Copilot adapter name `"copilot"`, not the ACP
  adapter file `lua/codecompanion/adapters/acp/copilot_acp.lua`.
- Fidget events are real: `doc/codecompanion.txt` lists
  `CodeCompanionRequestStarted` and `CodeCompanionRequestFinished`.
- Fidget's handle API is real: `:help fidget.progress.handle.create`.
- Copilot auth comes from `~/.config/github-copilot/` token files for the HTTP
  adapter, not from a key hard-coded in this repo.

## Docs / ground truth

- Config: `lua/plugins/codecompanion.lua`.
- Installed source/docs:
  `~/.local/share/nvim/site/pack/core/opt/codecompanion.nvim/`.
- Help tags: `:help codecompanion`, `:help codecompanion-commands`,
  and the events section in `doc/codecompanion.txt`.
- Source checked: `lua/codecompanion/config.lua`,
  `lua/codecompanion/commands/init.lua`,
  `lua/codecompanion/adapters/http/copilot/token.lua`, and
  `doc/codecompanion.txt`.
- Upstream: https://github.com/olimorris/codecompanion.nvim.

## Verify your change

Run syntax and a headless command/keymap check:

```bash
cd ~/.config/nvim
luac -p lua/plugins/codecompanion.lua && echo OK
nvim --headless -u init.lua \
  -c 'lua print(vim.fn.exists(":CodeCompanionChat"))' \
  -c 'lua print(vim.fn.maparg("<leader>ac", "n"))' \
  -c 'qa!' 2>&1 | grep -v tbl_flatten
```

Expected output includes `2` for the command and `CodeCompanionChat Toggle`.
If requests fail, inspect Copilot auth under `~/.config/github-copilot/`.

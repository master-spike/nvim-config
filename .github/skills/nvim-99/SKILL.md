---
name: nvim-99
description: >-
  How the local 99 AI plugin is configured with CopilotProvider, native
  #rules/@files completion, AGENT.md auto-context, debug logging, and
  <leader>9 keymaps. Use when editing 99 setup, model selection, prompt
  history, visual/search workflows, or distinguishing 99 from CodeCompanion.
covers:
  - lua/plugins/99.lua
---

# 99

User-owned AI plugin. The local config is `lua/plugins/99.lua`. The installed
plugin is `~/.local/share/nvim/site/pack/core/opt/99/`, pinned in
`nvim-pack-lock.json` at rev `773768aa313219107d8cb2e2f4f6562266d2803a` with
version `'dev'`. Upstream is https://github.com/master-spike/99.

## Role

Use 99 for the user's custom AI workflows: visual replacement, project search,
prompt history, request cancellation, and model picking. It is distinct from
CodeCompanion; see `nvim-codecompanion` for `<leader>a` mappings.

## What's configured

Faithful excerpt from `lua/plugins/99.lua`:

```lua
local _99 = require("99")
local cwd = vim.uv.cwd()
local basename = vim.fs.basename(cwd)

_99.setup({
  provider = _99.Providers.CopilotProvider,
  logger = {
    level = _99.DEBUG,
    path = "/tmp/" .. basename .. ".99.debug",
    print_on_error = true,
  },
  tmp_dir = "./tmp",
  completion = {
    custom_rules = { "scratch/custom_rules/" },
    files = { exclude = { ".env", ".env.*", "node_modules", ".git" } },
    source = "native",
  },
  md_files = { "AGENT.md" },
})
```

Configured keymaps:

```lua
vim.keymap.set("v", "<leader>9v", function() _99.visual() end)
vim.keymap.set("n", "<leader>9x", function() _99.stop_all_requests() end)
vim.keymap.set("n", "<leader>9s", function() _99.search() end)
vim.keymap.set("n", "<leader>9h", function() _99.prompt_history() end)
vim.keymap.set("n", "<leader>9m", function()
  require("99.extensions.telescope").select_model()
end)
```

## Capabilities + examples

Use the configured mappings:

- `<leader>9v` in visual mode calls `_99.visual()`.
- `<leader>9x` calls `_99.stop_all_requests()`.
- `<leader>9s` calls `_99.search()`.
- `<leader>9h` calls `_99.prompt_history()`.
- `<leader>9m` opens a Telescope-backed model picker.

The selected provider is `_99.Providers.CopilotProvider`. Installed source
`lua/99/init.lua` shows the default provider would be `OpenCodeProvider` when no
provider is set. `lua/99/providers.lua` also exports `ClaudeCodeProvider`.

Native prompt-buffer completion is configured with `source = "native"`.
Installed source `lua/99/extensions/init.lua` loads
`99.extensions.native` for that source. Native completion registers `#` rules
from `scratch/custom_rules/*/SKILL.md` and `@` files from project discovery.
File discovery uses `git ls-files --cached --others --exclude-standard` in git
repos and applies the configured `files.exclude` list.

`md_files = { "AGENT.md" }` makes 99 look for `AGENT.md` context files while
building prompts. The config comment in `lua/plugins/99.lua` warns this is tied
to the current working directory.

## Gotchas / version notes

- The plugin is pinned to the `dev` branch. APIs may move. Always read the
  installed source under `~/.local/share/nvim/site/pack/core/opt/99/` before
  relying on any function or option.
- The debug logger path is configured as `/tmp/<cwd-basename>.99.debug` in
  `lua/plugins/99.lua`; do not commit logs or secrets.
- `tmp_dir = "./tmp"` is intentionally inside the current working directory, per
  the config comments about external-directory permissions.
- `<leader>9m` requires Telescope. See `nvim-telescope` before changing that
  picker integration.
- Do not confuse 99's Copilot CLI provider with CodeCompanion's Copilot HTTP
  adapter. Both AI tools coexist in this config.

## Docs / ground truth

- Config: `lua/plugins/99.lua`.
- Installed source/docs:
  `~/.local/share/nvim/site/pack/core/opt/99/`.
- Source checked: `lua/99/init.lua`, `lua/99/providers.lua`,
  `lua/99/extensions/init.lua`, `lua/99/extensions/native.lua`,
  `lua/99/extensions/agents/init.lua`, `lua/99/extensions/files/init.lua`, and
  `lua/99/extensions/telescope.lua`.
- Upstream: https://github.com/master-spike/99.
- Lockfile: `nvim-pack-lock.json` shows version `'dev'` and the pinned rev.

## Verify your change

Run syntax and a headless provider/keymap check:

```bash
cd ~/.config/nvim
luac -p lua/plugins/99.lua && echo OK
nvim --headless -u init.lua \
  -c 'lua local p=require("99").get_provider(); print(p._get_provider_name())' \
  -c 'lua print(vim.fn.maparg("<leader>9s", "n"))' \
  -c 'qa!' 2>&1 | grep -v tbl_flatten
```

Expected output includes `CopilotProvider` and a Lua mapping reference for
`<leader>9s`.

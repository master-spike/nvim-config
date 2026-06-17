---
name: nvim-misc-plugins
description: >-
  Grouped reference for small/simple plugins in this Neovim config. Use when
  changing bufferline, colorizer, fidget, js-i18n, vim-tmux-navigator,
  minesweeper, or library-only dependencies such as nvim-web-devicons,
  nui.nvim, and plenary.nvim. Includes real config paths, keymaps, pins,
  installed docs, gotchas, and verification commands.
covers:
  - lua/plugins/bufferline.lua
  - lua/plugins/colorizer.lua
  - lua/plugins/fidget.lua
  - lua/plugins/js-i18n.lua
  - lua/plugins/tmux-navigator.lua
  - lua/plugins/minesweeper.lua
---

# Misc plugins

Use this for small plugin modules that do not need a full dedicated skill. Every
claim below is grounded in `lua/plugins/*.lua`, `lua/config/pack.lua`, installed
source under `~/.local/share/nvim/site/pack/core/opt/`, and
`nvim-pack-lock.json`.

## Role

Make small UI/plugin changes without hallucinating commands or setup keys. Read
the local config and installed docs before editing. Cross-reference
`nvim-testing-and-verification`, `nvim-snacks`, `nvim-codecompanion`, and
`nvim-core-options-keymaps-autocmds` when a change crosses plugin boundaries.

## What's configured

### bufferline.nvim

Role: buffer tabs, LSP diagnostic markers, and bufferline-specific operations.

Config: `lua/plugins/bufferline.lua`. Install path:
`~/.local/share/nvim/site/pack/core/opt/bufferline.nvim/`. Pin:
`655133c3b4`. Upstream: https://github.com/akinsho/bufferline.nvim.

```lua
require("bufferline").setup({
  options = {
    diagnostics = "nvim_lsp",
    always_show_bufferline = false,
    offsets = {
      {
        filetype = "neo-tree",
        text = "Neo-tree",
        highlight = "Directory",
        text_align = "left",
      },
    },
  },
})

map("n", "[b", "<cmd>BufferLineCyclePrev<cr>")
map("n", "]b", "<cmd>BufferLineCycleNext<cr>")
map("n", "[B", "<cmd>BufferLineMovePrev<cr>")
map("n", "]B", "<cmd>BufferLineMoveNext<cr>")
map("n", "<leader>bp", "<cmd>BufferLineTogglePin<cr>")
map("n", "<leader>bP", "<cmd>BufferLineGroupClose ungrouped<cr>")
map("n", "<leader>br", "<cmd>BufferLineCloseRight<cr>")
map("n", "<leader>bl", "<cmd>BufferLineCloseLeft<cr>")
map("n", "<leader>bo", "<cmd>BufferLineCloseOthers<cr>")
```

Plain buffer navigation is not here: `<S-h>`, `<S-l>`, and `<leader>bd` live in
`lua/config/keymaps.lua`.

Docs: `:help bufferline`, `:help bufferline-commands`,
`:help bufferline-offset`. Verify commands in installed `doc/bufferline.txt`.

### nvim-colorizer.lua

Role: highlight color literals inline.

Config: `lua/plugins/colorizer.lua`. Install path:
`~/.local/share/nvim/site/pack/core/opt/nvim-colorizer.lua/`. Pin:
`a065833f35`. Upstream: https://github.com/norcalli/nvim-colorizer.lua.

```lua
require("colorizer").setup({
  filetypes = {
    "css",
    "javascript",
    "typescript",
    "tsx",
    "jsx",
    "html",
    "lua",
    "json",
    "yaml",
    "markdown",
    "*",
  },
  user_default_options = {
    RGB = true,
    RRGGBB = true,
    names = false,
    RRGGBBAA = true,
    AARRGGBB = false,
    rgb_fn = true,
    hsl_fn = true,
    css = true,
    css_fn = true,
    mode = "background",
    tailwind = true,
    sass = { enable = true, parsers = { "css" } },
    virtualtext = "■",
    always_update = false,
  },
})
```

Gotcha: this installed plugin is the norcalli original, not the newer
`catgoose/nvim-colorizer.lua` API. Its real source exports
`setup(filetypes, user_default_options)`. Installed docs/source document
`RGB`, `RRGGBB`, `names`, `RRGGBBAA`, `rgb_fn`, `hsl_fn`, `css`, `css_fn`, and
`mode`. They do not document `tailwind`, `sass`, `virtualtext`,
`always_update`, or table-form `user_default_options`; do not add more options
from memory without grepping the installed source.

Docs: `:help colorizer-lua`, installed `lua/colorizer.lua` lines around
`local function setup(filetypes, user_default_options)`.

### fidget.nvim

Role: LSP progress and notification UI in the bottom-right.

Config: `lua/plugins/fidget.lua`. Install path:
`~/.local/share/nvim/site/pack/core/opt/fidget.nvim/`. Pin:
`82404b196e`. Upstream: https://github.com/j-hui/fidget.nvim.

```lua
require("fidget").setup({
  notification = {
    window = {
      winblend = 0,
    },
  },
})
```

Cross-plugin coupling: `lua/plugins/codecompanion.lua` uses
`require("fidget.progress")` and `progress.handle.create(...)` for the
CodeCompanion spinner. See `nvim-codecompanion` before changing Fidget setup.

Docs: `:help fidget`, `:help fidget.setup`,
`:help fidget.option.notification.window.winblend`, `:help fidget.progress`.

### js-i18n.nvim

Role: show JavaScript/TypeScript i18n translations as virtual text.

Config: `lua/plugins/js-i18n.lua`. Install path:
`~/.local/share/nvim/site/pack/core/opt/js-i18n.nvim/`. Pin:
`178732fe80`. Upstream: https://github.com/nabekou29/js-i18n.nvim.

```lua
require("js-i18n").setup({
  virt_text = {
    enabled = true,
    format = function(text, opts)
      text = text:sub(1, 60)
      return text
    end,
    conceal_key = false,
    max_length = 0,
    max_width = 60,
  },
  server = {
    cmd = { "js-i18n-language-server" },
    translation_files = {
      file_pattern = "**/i18n/messages/**/*.json",
    },
    key_separator = ".",
    namespace_separator = nil,
    default_namespace = "common",
    primary_languages = nil,
    required_languages = nil,
    optional_languages = nil,
    diagnostics = { unused_keys = false },
  },
})

vim.api.nvim_set_hl(0, "@i18n.translation", {
  link = "LspInlayHint",
})
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("I18nTranslationHl", {
    clear = true,
  }),
  callback = set_i18n_hl,
})

Snacks.toggle.new({
  id = "i18n_virt_text",
  name = "Translations",
  get = function()
    return require("js-i18n.config").config.virt_text.enabled
  end,
  set = function(state)
    vim.cmd(state and "I18nVirtualTextEnable" or "I18nVirtualTextDisable")
  end,
}):map("<leader>ut")
```

Commands verified in installed source/docs: `:I18nVirtualTextEnable` and
`:I18nVirtualTextDisable`. The virtual-text highlight group is
`@i18n.translation`; this config links it to `LspInlayHint` and re-applies the
link on `ColorScheme`.

Cross-plugin coupling: `<leader>ut` is a `Snacks.toggle` mapping. See
`nvim-snacks` before changing toggle behavior.

Docs: `:help js-i18n`, installed `lua/js-i18n/init.lua`,
`lua/js-i18n/config.lua`, and `lua/js-i18n/virt_text.lua`.

### vim-tmux-navigator

Role: move between Neovim splits and tmux panes with one set of keys.

Config: `lua/plugins/tmux-navigator.lua`. Install path:
`~/.local/share/nvim/site/pack/core/opt/vim-tmux-navigator/`. Pin:
`e41c431a0c`. Upstream: https://github.com/christoomey/vim-tmux-navigator.

```lua
map("n", "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>")
map("n", "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>")
map("n", "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>")
map("n", "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>")
map("n", "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>")
```

This module owns `<C-h>`, `<C-j>`, `<C-k>`, `<C-l>`, and `<C-\>`. Do not
redefine them elsewhere. Cross-reference `nvim-core-options-keymaps-autocmds`.

Docs: `:help tmux-navigator`, installed `plugin/tmux_navigator.vim`, and
`doc/tmux-navigator.txt`.

### minesweeper-nvim

Role: a small floating-window Minesweeper game, from the user's own plugin.

Config: `lua/plugins/minesweeper.lua`. Install path:
`~/.local/share/nvim/site/pack/core/opt/minesweeper-nvim/`. Pin:
`047c5ac8c2`. Upstream: https://github.com/master-spike/minesweeper-nvim.

```lua
require("minesweeper").setup()
```

Installed README documents `:Minesweeper` and `:Minesweeper reset`. There is no
`doc/*.txt` help file in the installed plugin; use its README and source.

## Library dependencies with no setup module

These are listed in `vim.pack.add()` in `lua/config/pack.lua`, pinned in
`nvim-pack-lock.json`, and have no `lua/plugins/<name>.lua` setup file here.

- `nvim-web-devicons`: icons for UI plugins. Install path
  `~/.local/share/nvim/site/pack/core/opt/nvim-web-devicons/`. Pin
  `dfbfaa967a`. Upstream: https://github.com/nvim-tree/nvim-web-devicons.
- `nui.nvim`: UI primitives used by plugins such as Neo-tree. Install path
  `~/.local/share/nvim/site/pack/core/opt/nui.nvim/`. Pin `de740991c1`.
  Upstream: https://github.com/MunifTanjim/nui.nvim.
- `plenary.nvim`: Lua utility library used by plugins such as Telescope, Octo,
  and Gitsigns. Install path
  `~/.local/share/nvim/site/pack/core/opt/plenary.nvim/`. Pin `74b06c6c75`.
  Upstream: https://github.com/nvim-lua/plenary.nvim.

## Capabilities + examples

- Add a bufferline action by mapping a real `BufferLine*` command in
  `lua/plugins/bufferline.lua` after verifying it in `doc/bufferline.txt`.
- Change i18n virtual text by editing `virt_text.format`, `max_width`, or the
  server `translation_files` pattern in `lua/plugins/js-i18n.lua`.
- Change notification opacity by editing Fidget's documented
  `notification.window.winblend` option.
- Do not move `<C-hjkl>` mappings out of `tmux-navigator.lua`; that module owns
  pane navigation.

## Gotchas/version notes

- `nvim-colorizer.lua` is the norcalli original. Its source does not document
  newer colorizer options such as `tailwind` or `virtualtext`. Verify behavior
  before relying on those fields.
- `js-i18n.nvim` requires the external `js-i18n-language-server` command. The
  config uses `cmd = { "js-i18n-language-server" }`.
- `minesweeper-nvim` has no help tags in `doc/`; use README/source as ground
  truth.
- Plain buffer close/navigation keymaps are in `lua/config/keymaps.lua`, not in
  `bufferline.lua`.

## Docs / ground truth

- Config files: `lua/plugins/bufferline.lua`, `lua/plugins/colorizer.lua`,
  `lua/plugins/fidget.lua`, `lua/plugins/js-i18n.lua`,
  `lua/plugins/tmux-navigator.lua`, and `lua/plugins/minesweeper.lua`.
- Pack list: `lua/config/pack.lua`.
- Pins: `nvim-pack-lock.json`.
- Installed docs/source under
  `~/.local/share/nvim/site/pack/core/opt/<plugin>/`.
- Help tags: `:help bufferline`, `:help colorizer-lua`, `:help fidget`,
  `:help js-i18n`, `:help tmux-navigator`, `:help plenary`.

## Verify your change

Run from `~/.config/nvim`:

```bash
luac -p lua/plugins/bufferline.lua lua/plugins/colorizer.lua \
  lua/plugins/fidget.lua lua/plugins/js-i18n.lua \
  lua/plugins/tmux-navigator.lua lua/plugins/minesweeper.lua
nvim --headless -u init.lua -c 'lua
  assert(vim.fn.exists(":BufferLineCycleNext") == 2)
  assert(vim.fn.exists(":TmuxNavigateLeft") == 2)
  assert(vim.fn.exists(":I18nVirtualTextEnable") == 2)
  assert(package.loaded["fidget"] ~= nil)
  assert(package.loaded["bufferline"] ~= nil)
  assert(package.loaded["js-i18n"] ~= nil)
  print("PASS misc plugins")
' -c 'qa!' 2>&1 | grep -v tbl_flatten
```

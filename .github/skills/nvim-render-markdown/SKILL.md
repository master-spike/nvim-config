---
name: nvim-render-markdown
description: >-
  Render-markdown.nvim configuration in this repo, including markdown, Avante,
  and octo filetypes plus heading/code/bullet/checkbox/quote/table/callout
  styling. Use when editing lua/plugins/render-markdown.lua or markdown render
  behavior in normal, AI, or GitHub buffers.
covers:
  - lua/plugins/render-markdown.lua
---

# Render Markdown

Markdown renderer. Configured in `lua/plugins/render-markdown.lua`. Installed
source is `~/.local/share/nvim/site/pack/core/opt/render-markdown.nvim/`,
upstream is https://github.com/MeanderingProgrammer/render-markdown.nvim, and
`nvim-pack-lock.json` pins rev `5adf089531`.

## Role
Render markdown syntax with virtual icons/highlights in normal markdown buffers,
Avante buffers, and octo GitHub buffers. The plugin docs list markdown headings,
code blocks, bullets, checkboxes, quotes, callouts, and tables as renderable
components.

## What's configured
Faithful excerpt from `lua/plugins/render-markdown.lua`:

```lua
require("render-markdown").setup({
  file_types = { "markdown", "Avante", "octo" },
  heading = {
    enabled = true,
    sign = true,
    icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
    backgrounds = {
      "RenderMarkdownH1Bg",
      "RenderMarkdownH2Bg",
      "RenderMarkdownH3Bg",
      "RenderMarkdownH4Bg",
      "RenderMarkdownH5Bg",
      "RenderMarkdownH6Bg",
    },
    foregrounds = {
      "RenderMarkdownH1",
      "RenderMarkdownH2",
      "RenderMarkdownH3",
      "RenderMarkdownH4",
      "RenderMarkdownH5",
      "RenderMarkdownH6",
    },
  },
  code = {
    enabled = true,
    sign = true,
    style = "full",
    width = "block",
    border = "thin",
    highlight = "RenderMarkdownCode",
    highlight_inline = "RenderMarkdownCodeInline",
  },
})
```

The real file also configures:
- `bullet.icons = { "●", "○", "◆", "◇" }` and `RenderMarkdownBullet`.
- Checkbox icons for unchecked, checked, and custom `[-]` todo states.
- Quote icon `▋` with `RenderMarkdownQuote`.
- Pipe-table style `"full"` with `RenderMarkdownTableHead` and
  `RenderMarkdownTableRow`.
- Callouts for note, tip, important, warning, and caution.

## Capabilities + examples
- Open a markdown file and run `:RenderMarkdown toggle` to toggle rendering.
- Open an octo buffer; filetype `octo` is included in `file_types`.
- Highlight groups use the `RenderMarkdown*` naming pattern.

## Gotchas / version notes
- Keep `file_types = { "markdown", "Avante", "octo" }` if GitHub/octo buffers
  should render. Removing `octo` disables that integration.
- Do not invent highlight group names. Use the installed docs/source and the
  existing `RenderMarkdown*` names in `lua/plugins/render-markdown.lua`.
- This plugin depends on markdown Treesitter parsers for normal markdown
  parsing; see installed `doc/render-markdown.txt` requirements and
  `nvim-treesitter`.

## Docs / ground truth
- Config: `lua/plugins/render-markdown.lua`; pack entry: `lua/config/pack.lua`.
- Installed docs/source:
  `~/.local/share/nvim/site/pack/core/opt/render-markdown.nvim/doc/` and
  `~/.local/share/nvim/site/pack/core/opt/render-markdown.nvim/lua/`.
- Help tags: `:help render-markdown`, `:help render-markdown-setup`.
- Lockfile: `nvim-pack-lock.json`, rev `5adf089531`.

## Verify your change
Run from `~/.config/nvim`:

```bash
luac -p lua/plugins/render-markdown.lua
nvim --headless -u init.lua \
  -c 'lua local c=require("render-markdown.state").config
assert(vim.tbl_contains(c.file_types, "octo"))' \
  -c 'qa!' 2>&1 | grep -v tbl_flatten
nvim --headless -u init.lua \
  -c 'set ft=markdown' \
  -c 'RenderMarkdown toggle' \
  -c 'qa!' 2>&1 | grep -v tbl_flatten
```

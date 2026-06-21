---
name: nvim-which-key
description: >-
  Which-key is a popup helper for discovering and documenting keymaps as you
  type. Use it when you need to register key descriptions, create group labels,
  or add virtual mappings that should appear in the popup even when no real
  mapping exists.
covers:
  - lua/plugins/whichkey.lua
---

# Which-key

Which-key is a Neovim plugin that shows a popup of available keymaps as you type
prefixes. It is especially useful for leader-based mappings, nested prefixes,
and operator/visual text-object workflows.

## Core role

Use which-key to:

- show existing keymaps and their descriptions,
- add group labels for prefix keys such as `<leader>g` or `<leader>u`,
- create virtual mappings that have no real command behind them, and
- expose discoverable descriptions for multi-key workflows such as text objects.

## Fundamental model

Which-key works by building a tree of mappings from the current buffer/mode,
then matching the keys you type against that tree. It does not simply read the
current mode and show everything; it needs the mapping tree and the typed prefix
to decide what to display.

Key points:

- It uses a mapping tree and a current buffer/mode context.
- It can surface both real keymaps and virtual mappings added with `wk.add()`.
- It is most useful for prefixes: one key that leads to a second or third key.
- It can be used for operator-pending and visual workflows, but those are more
  subtle because which-key must decide whether the first key is a complete
  command or a prefix that should wait for another key.

## Typical API

```lua
local wk = require("which-key")

wk.setup({})

wk.add({
  { "<leader>g", group = "git" },
  { "<leader>gc", desc = "Commit" },
})
```

## Important gotchas

- `wk.add()` is the main API for adding labels and virtual mappings.
- `wk.add()` uses the v3 spec style, where each entry is a mapping descriptor.
- The popup is driven by the mapping tree, so it is not enough to have a
  keypress buffer state; which-key needs the relevant mappings to exist in the
  tree.
- For workflows like `dai`/`vif`/`yaf`, which-key may defer or suppress the
  popup if it detects that the current keypress is already part of a pending
  sequence, because it must avoid interrupting fast typed input.
- In practice, this means that as-you-type popup behavior for operator/visual
  text objects can be inconsistent for very fast typing, even when the
  underlying mappings exist. If you need deterministic discoverability, an
  explicit on-demand entry point (for example, a dedicated keymap that opens the
  popup) is often better than relying purely on the live popup.

## Practical guidance

- Prefer `wk.add()` when you want labels for prefixes or virtual mappings.
- `lua/plugins/whichkey.lua` also registers virtual labels for mini.ai's custom
  textobject ids (e.g. statement/method-call objects) so the around/inside
  prefixes surface them in the popup — read that file for the current set and see
  `nvim-mini`.
- Use real mappings and descriptions when possible; which-key can display those
  automatically.
- If you need discoverability for a custom workflow, consider a dedicated keymap
  that opens which-key explicitly instead of relying on the live as-you-type
  popup.
- Keep the popup behavior simple unless you have a strong reason to model a
  custom multi-step workflow.

## Docs / ground truth

- Plugin source/docs: the installed which-key.nvim plugin under your Neovim data
  directory.
- Help tag: `:help which-key`.
- For plugin-specific behavior, inspect the plugin source and its docs rather
  than relying on memory or configuration heuristics.

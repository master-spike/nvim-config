---
name: nvim-lsp
description: >-
  How LSP is configured in this Neovim 0.12 config using the NATIVE
  vim.lsp.config / vim.lsp.enable API (not the old lspconfig.setup). Covers
  lua/config/lsp.lua, blink.cmp capabilities, the LspAttach keymaps, diagnostics
  UI, per-server settings, adding a server, custom servers (vacuum), and how
  Mason supplies the binaries. Use for anything LSP: adding/configuring a
  language server, changing diagnostics, or LSP keymaps.
covers:
  - lua/config/lsp.lua
  - lua/util/lsp_definition.lua
---

# LSP (native vim.lsp on Neovim 0.12)

LSP is wired in `lua/config/lsp.lua` using Neovim 0.12's **native** API:
`vim.lsp.config(name, opts)` to configure and `vim.lsp.enable({...})` to turn
servers on. `nvim-lspconfig` is installed only to ship the per-server default
definitions (`lsp/<server>.lua` on the runtimepath) that `vim.lsp.enable` picks
up. **Do not call `require("lspconfig").<server>.setup{}`** — that's the old API
and is not how this config works.

Server binaries are installed by **Mason** (see `nvim-mason`). Config = native
API; binaries = Mason. They are separate concerns.

## File structure of config/lsp.lua (read it before editing)
1. **Global capabilities** — attaches blink.cmp completion capabilities to every
   server via the `"*"` wildcard:
   ```lua
   local ok_blink, blink = pcall(require, "blink.cmp")
   if ok_blink then
     vim.lsp.config("*", { capabilities = blink.get_lsp_capabilities() })
   end
   ```
2. **Diagnostics UI** — `vim.diagnostic.config({...})` (severity sort, sign text
   icons, virtual_text). Change diagnostic appearance here.
3. **LspAttach autocmd** — buffer-local keymaps + inlay hints, set when any
   server attaches (details below).
4. **Per-server overrides** — `vim.lsp.config("<name>", {...})` blocks that
   override only what's needed for specific servers (read the file for which).
5. **Enable list** — `vim.lsp.enable({...})` names every active server.

## LspAttach: keymaps + inlay hints
On attach (`config_lsp_attach` augroup) it enables inlay hints for servers that
support them, then sets buffer-local `n`-mode LSP maps. Read `config/lsp.lua` for
the current keys; the durable conventions:

- Navigation (definition/references/implementations/type-defs) goes through
  **Telescope pickers** so results land in the picker (and `<C-q>` → quickfix),
  rather than the raw `vim.lsp.buf.*` jumps. Hover/rename/code-action use
  `vim.lsp.buf.*` directly.
- `gd` is special: it goes through `util/lsp_definition.lua`, which nudges the
  cursor for Java `method_reference` nodes (a jdtls SelectionEngine quirk) before
  delegating to the Telescope definition picker. Keep that indirection.

Toggle inlay hints with `<leader>uh` (`config/keymaps.lua`). Diagnostics nav
(`]d`/`[d`, `<leader>cd`) lives in `keymaps.lua`, not here.

## Add a new language server
1. Install the binary: add it to `mason-tool-installer`'s `ensure_installed`
   in `lua/plugins/mason.lua` (use Mason's package name, e.g.
   `lua-language-server`).
2. Enable it: add the **lspconfig server name** (e.g. `lua_ls`) to the
   `vim.lsp.enable({...})` list in `config/lsp.lua`.
3. Only if you need overrides, add a `vim.lsp.config("<name>", {...})` block.
   lspconfig already ships sane defaults (cmd, filetypes, root_markers).

Find the server name + defaults by reading the installed lspconfig definition:
```bash
ls ~/.local/share/nvim/site/pack/core/opt/nvim-lspconfig/lsp/        # all servers
cat ~/.local/share/nvim/site/pack/core/opt/nvim-lspconfig/lsp/lua_ls.lua
```

## Per-server settings (patterns to copy)
The file holds a handful of `vim.lsp.config("<name>", {...})` override blocks —
read it for the current set. The reusable patterns they demonstrate:

- **Declaring globals / runtime** for a server (e.g. lua_ls gets `vim` + `Snacks`
  globals and LuaJIT runtime so it stops warning about them).
- **Enabling inlay hints** via a server's settings.
- **Wrapping lspconfig's `on_attach`** to add behaviour — e.g. a `BufWritePre`
  fix-on-save for eslint. (JS/TS linting is the eslint LSP's job, NOT nvim-lint —
  see `nvim-lint`.)
- **Schema associations** (e.g. yamlls for OpenAPI/Swagger).
- **A fully custom server** with no lspconfig default, defined inline with
  explicit `cmd`/`filetypes`/`root_markers` — this is the template for adding a
  server lspconfig doesn't know:

```lua
vim.lsp.config("myserver", {
  cmd = { "myserver", "--stdio" },
  filetypes = { "myft" },
  root_markers = { ".git" },
})
vim.lsp.enable("myserver")  -- (or add to the enable list)
```

## Java note
Java does NOT go through `vim.lsp.enable`. jdtls is started per-project by
`lua/plugins/jdtls.lua` via `nvim-jdtls` on a `FileType java` autocmd. See
`nvim-jdtls`.

## Docs / ground truth
- Native API: `:help vim.lsp.config`, `:help vim.lsp.enable`,
  `:help vim.diagnostic.config`.
- lspconfig server list/defaults:
  `~/.local/share/nvim/site/pack/core/opt/nvim-lspconfig/lsp/*.lua` and its
  `doc/`. Upstream: https://github.com/neovim/nvim-lspconfig (pinned rev in
  `nvim-pack-lock.json`).

## Verify your change
```bash
cd ~/.config/nvim
luac -p lua/config/lsp.lua
nvim --headless -u init.lua -c 'qa!'   # loads clean?
# Open a real file of the target filetype and check the server attaches:
nvim --headless -u init.lua some.lua \
  -c 'lua vim.defer_fn(function()
        print(vim.inspect(vim.tbl_map(function(c) return c.name end,
          vim.lsp.get_clients({ bufnr = 0 }))))
        vim.cmd("qa!")
      end, 2000)'
```
Server attach is async — use `vim.defer_fn`/`vim.wait` before asserting clients,
and open an actual file of the right filetype (an empty headless buffer attaches
nothing).

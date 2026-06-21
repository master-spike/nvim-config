# Copilot instructions for this repository

## Repository overview

- This is a hand-rolled Neovim 0.12 configuration, not a LazyVim or lazy.nvim
  setup.
- The entry point is `init.lua`, which loads modules in this exact order:
  1. `config.options`
  2. `config.keymaps`
  3. `config.autocmds`
  4. `config.pack`
  5. `config.lsp`
- `lua/config/pack.lua` is the central plugin loader: it installs plugins with
  `vim.pack.add(...)`, then loads each plugin setup module from `lua/plugins/`.

## Build, test, and lint commands

- There is no dedicated build script or test suite configured for this
  repository.
- For Lua syntax checks, run:
  - `luac -p lua/config/pack.lua`
  - `luac -p lua/plugins/<name>.lua`
- To verify the config loads cleanly in a headless Neovim session:
  - `nvim --headless -u init.lua -c 'qa!'`
- To verify a specific plugin/module loads:
  - `nvim --headless -u init.lua -c 'lua print(pcall(require, "plugins.<name>"))' -c 'qa!'`
- Formatting is handled by Stylua. If the CLI is available, check one file with:
  - `stylua --check lua/plugins/<name>.lua`
- If Stylua is not installed, format through the configured conform setup inside
  Neovim:
  - `nvim --headless -u init.lua path/to/file.lua -c 'lua require("conform").format({ bufnr = 0 })' -c 'wq'`

## High-level architecture

- `lua/config/` holds core editor bootstrapping and should be treated as the
  startup layer:
  - `options.lua`: leader, `vim.opt` settings, clipboard, grep defaults
  - `keymaps.lua`: global keymaps and leader-based UI/diagnostic shortcuts
  - `autocmds.lua`: grouped autocommands for yank highlight, last-location jump,
    close-with-q, and auto-creating directories
  - `pack.lua`: plugin installation, build step for `telescope-fzf-native`, and
    module loader
  - `lsp.lua`: native `vim.lsp.config` / `vim.lsp.enable`, diagnostics defaults,
    LSP attach keymaps, and custom server overrides
- `lua/plugins/` contains one self-contained module per plugin. Each file
  usually requires the plugin and calls `.setup(...)`, then registers keymaps.
- `lua/util/` holds shared helpers used by multiple places (for example path
  collapsing and LSP definition handling). Reuse helpers rather than duplicating
  logic.
- LSP servers, formatters, and linters are installed via Mason in
  `lua/plugins/mason.lua` and enabled through native LSP configuration.
- The repo also has `.github/skills/<plugin>/SKILL.md` docs; treat them as part
  of the repository’s working knowledge and keep them current when changing the
  related config.

## Key conventions

- Follow the existing pattern in the file you edit; this config is intentionally
  small and hand-rolled.
- For any modification, you must consult the relevant skills before editing.
  This is mandatory, not optional:
  - `nvim-config-overview` for architecture and load order
  - `nvim-testing-and-verification` before using any API or claiming a change
    works
  - `nvim-skill-maintenance` for any config change, plugin change, or skill/doc
    update so the skill docs stay in sync with the real implementation
- For any modification, also use any additional relevant skills for the touched
  subsystem (for example `nvim-lsp`, `nvim-treesitter`, `nvim-telescope`,
  `nvim-pack-management`, `nvim-conform`, `nvim-lint`, `nvim-mini`,
  `nvim-gitsigns`, `nvim-lualine`, `nvim-neo-tree`, `nvim-snacks`,
  `nvim-trouble`, `nvim-which-key`, `nvim-flash`, `nvim-octo`, `nvim-jdtls`,
  `nvim-render-markdown`, `nvim-mason`, `nvim-99`, or `nvim-colorscheme`).
- If a change affects a plugin, behavior, or API quirk that is not already
  documented, treat that as a signal to update the related skill docs in the
  same change.
- Prefer documented plugin options over inventing custom Lua. Verify the API
  exists in the installed plugin’s source/docs before using it.
- Keep formatting consistent with `stylua.toml`: 2-space indentation, 120-column
  width, double quotes, trailing commas in multiline tables.
- When adding a plugin, make all three changes in the same change:
  1. add it to `vim.pack.add(...)` in `lua/config/pack.lua`
  2. create or update `lua/plugins/<name>.lua`
  3. add the module name to the `modules` list in `lua/config/pack.lua`
- When removing a plugin, reverse those steps and prune any stale lockfile entry
  if needed.
- The README currently claims this is a LazyVim config, but the code does not
  use LazyVim. Ignore that stale README guidance and follow the actual
  implementation.
- Keep `nvim-pack-lock.json` aligned with plugin changes when versions or pins
  are involved.

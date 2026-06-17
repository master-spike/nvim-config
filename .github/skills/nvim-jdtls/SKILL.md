---
name: nvim-jdtls
description: >-
  How Java LSP is started with nvim-jdtls instead of vim.lsp.enable. Use when
  editing Java LSP startup, root/workspace detection, jdtls Mason paths,
  Java-only keymaps, the Akka/Maven classpath fix, or the Java gd
  method-reference workaround.
covers:
  - lua/plugins/jdtls.lua
  - lua/util/lsp_definition.lua
---

# nvim-jdtls

Java LSP integration for Eclipse JDT LS. The local config is
`lua/plugins/jdtls.lua`, with a related `gd` workaround in
`lua/util/lsp_definition.lua`. The installed plugin is
`~/.local/share/nvim/site/pack/core/opt/nvim-jdtls/`, pinned in
`nvim-pack-lock.json` at rev `6e9d953f0b82bccdb834cfde0e893f3119c22592`.
Upstream is https://github.com/mfussenegger/nvim-jdtls.

## Role

Use this file for Java only. Java LSP is not started by `vim.lsp.enable` in
`lua/config/lsp.lua`; that server list does not include `jdtls`. Instead,
`lua/plugins/jdtls.lua` starts JDT LS from a `FileType=java` autocmd.

## What's configured

Faithful excerpt from `lua/plugins/jdtls.lua`:

```lua
local jdtls_bin = vim.fn.stdpath("data") .. "/mason/bin/jdtls"

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("config_jdtls", { clear = true }),
  pattern = "java",
  callback = start_jdtls,
})
```

`start_jdtls()` does this:

```lua
local root_dir = vim.fs.root(0, root_markers)
local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
local workspace_dir = vim.fn.stdpath("cache")
  .. "/jdtls/workspace/" .. project_name
local capabilities = require("blink.cmp").get_lsp_capabilities()

jdtls.start_or_attach({
  cmd = { jdtls_bin, "-data", workspace_dir },
  root_dir = root_dir,
  capabilities = capabilities,
  on_attach = on_attach,
  settings = {
    java = {
      configuration = { updateBuildConfiguration = "interactive" },
      inlayHints = { parameterNames = { enabled = "all" } },
      signatureHelp = { enabled = true, description = { enabled = true } },
    },
  },
})
```

Root markers are `.git`, `mvnw`, `gradlew`, `pom.xml`, `build.gradle`,
`build.gradle.kts`, `settings.gradle`, and `settings.gradle.kts`.

`on_attach()` adds Java-only mappings:

```lua
map("<leader>jo", jdtls.organize_imports, "Organize Imports")
map("<leader>jv", jdtls.extract_variable, "Extract Variable")
map("<leader>jc", jdtls.extract_constant, "Extract Constant")
```

It also runs `fix_jdtls_project_settings(client.root_dir)` after 5 seconds.

## Capabilities + examples

Use the configured Java mappings in a Java buffer after JDT LS attaches:

- `<leader>jo` calls `jdtls.organize_imports`.
- `<leader>jv` calls `jdtls.extract_variable`.
- `<leader>jc` calls `jdtls.extract_constant`.

The helper `fix_jdtls_project_settings()` edits generated Eclipse project files
under each subproject. It redirects `target/classes` to
`target/jdtls-classes`, redirects `target/test-classes` to
`target/jdtls-test-classes`, and enables annotation processing in Eclipse prefs.
This avoids clobbering Akka-generated `META-INF` files in Maven output.

`lua/util/lsp_definition.lua` wraps `gd`. For Java `method_reference` nodes such
as `Type::method`, it nudges the cursor one column into the method name before
calling `require("telescope.builtin").lsp_definitions()`.

Java textobjects are extended in `after/queries/java/textobjects.scm`; see
`nvim-treesitter` before changing Java Treesitter captures.

## Gotchas / version notes

- Do not add `jdtls` to `vim.lsp.enable` unless you intentionally replace this
  autocmd-based setup. `nvim-jdtls` documents `jdtls.start_or_attach`.
- `jdtls_bin` is `stdpath("data") .. "/mason/bin/jdtls"`; install or repair the
  `jdtls` Mason package if startup fails with an executable error.
- `blink.cmp` capabilities are optional in the code path. If
  `require("blink.cmp")` fails, `capabilities` stays nil and JDT LS can still
  start.
- The Akka/Maven fix writes project `.classpath` and `.settings` files. Do not
  run it on non-Java roots by hand.

## Docs / ground truth

- Config: `lua/plugins/jdtls.lua`.
- Related helper: `lua/util/lsp_definition.lua`.
- Java queries: `after/queries/java/textobjects.scm`.
- Native LSP contrast: `lua/config/lsp.lua`.
- Installed source/docs:
  `~/.local/share/nvim/site/pack/core/opt/nvim-jdtls/`.
- Help tags: `:help jdtls`, `:help jdtls.start_or_attach`,
  `:help jdtls.organize_imports`, `:help jdtls.extract_variable`,
  `:help jdtls.extract_constant`.
- Upstream: https://github.com/mfussenegger/nvim-jdtls.

## Verify your change

Run syntax and a headless Java autocmd/keymap check:

```bash
cd ~/.config/nvim
luac -p lua/plugins/jdtls.lua lua/util/lsp_definition.lua && echo OK
nvim --headless -u init.lua \
  -c 'set ft=java' \
  -c 'lua print(vim.fn.exists("#config_jdtls#FileType#java"))' \
  -c 'lua vim.g.jdtls_bin=vim.fn.stdpath("data").."/mason/bin/jdtls"' \
  -c 'lua print(vim.fn.executable(vim.g.jdtls_bin))' \
  -c 'qa!' 2>&1 | grep -v tbl_flatten
```

Expected output includes `1` for the autocmd. The executable check should print
`1` when Mason has installed JDT LS.

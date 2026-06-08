-- Native LSP (Neovim 0.12: vim.lsp.config / vim.lsp.enable).
-- nvim-lspconfig ships lsp/<server>.lua definitions on the runtimepath;
-- vim.lsp.enable() picks them up. We only override what we need.

-- Global defaults: attach blink.cmp completion capabilities to every server.
local ok_blink, blink = pcall(require, "blink.cmp")
if ok_blink then
  vim.lsp.config("*", { capabilities = blink.get_lsp_capabilities() })
end

-- Diagnostics UI
vim.diagnostic.config({
  severity_sort = true,
  underline = { severity = vim.diagnostic.severity.ERROR },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "",
      [vim.diagnostic.severity.WARN] = "",
      [vim.diagnostic.severity.HINT] = "",
      [vim.diagnostic.severity.INFO] = "",
    },
  },
  virtual_text = { spacing = 4, source = "if_many" },
})

-- Buffer-local LSP keymaps on attach
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("config_lsp_attach", { clear = true }),
  callback = function(event)
    local buf = event.buf
    local function map(keys, fn, desc)
      vim.keymap.set("n", keys, fn, { buffer = buf, desc = "LSP: " .. desc })
    end

    -- Use Telescope pickers for LSP navigation so results open in the picker
    -- (and <C-q> sends them to the quickfix list). Fall back to vim.lsp.buf.
    local tb = require("telescope.builtin")
    map("gd", tb.lsp_definitions, "Goto Definition")
    map("gr", tb.lsp_references, "References")
    map("gI", tb.lsp_implementations, "Goto Implementation")
    map("gy", tb.lsp_type_definitions, "Goto Type Definition")

    map("gD", vim.lsp.buf.declaration, "Goto Declaration")
    map("K", vim.lsp.buf.hover, "Hover")
    map("<leader>ca", vim.lsp.buf.code_action, "Code Action")
    map("<leader>cr", vim.lsp.buf.rename, "Rename")
  end,
})

----------------------------------------------------------------------
-- Custom OpenAPI tooling (ported from previous openapi-lsp.lua)
----------------------------------------------------------------------
local vacuum_ruleset_content = [=[
extends: [[vacuum:oas, recommended]]
rules:
  oas3-missing-example: false
  component-description: false
  operation-description: false
  oas3-parameter-description: false
  oas2-parameter-description: false
]=]

local global_ruleset_path = vim.fn.stdpath("cache") .. "/vacuum-embedded-rules.yaml"
local file = io.open(global_ruleset_path, "w")
if file then
  file:write(vacuum_ruleset_content)
  file:close()
end

-- vacuum has no lspconfig default; define it directly.
vim.lsp.config("vacuum", {
  cmd = { "vacuum", "language-server", "--ruleset", global_ruleset_path },
  filetypes = { "yaml", "json" },
  root_markers = { ".git" },
})

-- yamlls schema overrides (OpenAPI / Swagger / Arazzo)
vim.lsp.config("yamlls", {
  filetypes = { "yaml" },
  settings = {
    yaml = {
      validate = true,
      completion = true,
      schemas = {
        ["https://www.schemastore.org/openapi-3.X.json"] = {
          "openapi.json",
          "openapi.yml",
          "openapi.yaml",
          "*openapi*.yaml",
          "*openapi*.yml",
        },
        ["https://spec.openapis.org/oas/2.0/schema/2017-08-27"] = {
          "swagger.json",
          "swagger.yml",
          "swagger.yaml",
          "*swagger*.yaml",
          "*swagger*.yml",
        },
        ["https://www.schemastore.org/openapi-arazzo-1.X.json"] = {
          "arazzo.json",
          "arazzo.yml",
          "arazzo.yaml",
        },
      },
    },
  },
})

-- lua_ls: make it aware of the Neovim runtime/vim global.
vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = { checkThirdParty = false },
      diagnostics = { globals = { "vim", "Snacks" } },
    },
  },
})

-- Enable servers (binaries installed via Mason).
vim.lsp.enable({
  "lua_ls",
  "jsonls",
  "yamlls",
  "vacuum",
  "bashls",
  "clangd",
  "neocmake",
  "dockerls",
  "docker_compose_language_service",
  "kotlin_language_server",
  "marksman",
  "terraformls",
  "vtsls",
})

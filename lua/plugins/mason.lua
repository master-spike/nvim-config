-- Mason: install LSP servers, formatters, linters.
require("mason").setup()

require("mason-tool-installer").setup({
  ensure_installed = {
    -- LSP servers
    "lua-language-server",
    "json-lsp",
    "yaml-language-server",
    "vacuum",
    -- Formatters
    "stylua",
    "prettier",
    "google-java-format",
    "shfmt",
    -- Linters
    "eslint_d",
    "shellcheck",
  },
  run_on_start = true,
})

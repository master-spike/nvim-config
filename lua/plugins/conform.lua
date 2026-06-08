-- Formatting via conform.nvim (ported java + markdown/prettier config)
require("conform").setup({
  formatters_by_ft = {
    java = { "google-java-format" },
    markdown = { "prettier" },
    lua = { "stylua" },
    sh = { "shfmt" },
  },
  formatters = {
    ["google-java-format"] = {
      command = "google-java-format",
      args = { "-" },
      stdin = true,
    },
    prettier = {
      prepend_args = {
        "--prose-wrap",
        "always",
        "--print-width",
        "80",
      },
    },
  },
  format_on_save = {
    timeout_ms = 3000,
    lsp_format = "fallback",
  },
})

vim.keymap.set({ "n", "v" }, "<leader>cf", function()
  require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "Format" })

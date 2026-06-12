-- Formatting via conform.nvim (ported java + markdown/prettier config)
local format_enabled = true
local format_enabled_buffer = {} -- per-buffer overrides

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
  format_on_save = function()
    local bufnr = vim.api.nvim_get_current_buf()
    if format_enabled_buffer[bufnr] ~= nil then
      return format_enabled_buffer[bufnr] and { timeout_ms = 3000, lsp_format = "fallback" } or nil
    end
    return format_enabled and { timeout_ms = 3000, lsp_format = "fallback" } or nil
  end,
})

vim.keymap.set({ "n", "v" }, "<leader>cf", function()
  require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "Format" })

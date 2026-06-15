-- Formatting via conform.nvim (ported java + markdown/prettier config)
_G.conform_format_state = {
  enabled = true,
  buffer_overrides = {},
}

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
    local state = _G.conform_format_state
    -- Check buffer-specific override first, then fall back to global
    local enabled = state.buffer_overrides[bufnr]
    if enabled == nil then
      enabled = state.enabled
    end
    return enabled and { timeout_ms = 3000, lsp_format = "fallback" } or nil
  end,
})

-- Register Snacks toggles for formatter state after Snacks is loaded
vim.schedule(function()
  -- These will show with which-key switch indicators after they're mapped
  Snacks.toggle.new({
    id = "conform_buffer",
    name = "Formatter (buffer)",
    get = function()
      local bufnr = vim.api.nvim_get_current_buf()
      local state = _G.conform_format_state
      local enabled = state.buffer_overrides[bufnr]
      if enabled == nil then
        enabled = state.enabled
      end
      return enabled
    end,
    set = function(enabled)
      local bufnr = vim.api.nvim_get_current_buf()
      _G.conform_format_state.buffer_overrides[bufnr] = enabled
    end,
  }):map("<leader>uf")

  Snacks.toggle.new({
    id = "conform_global",
    name = "Formatter (global)",
    get = function()
      return _G.conform_format_state.enabled
    end,
    set = function(enabled)
      _G.conform_format_state.enabled = enabled
    end,
  }):map("<leader>uF")
end)

vim.keymap.set({ "n", "v" }, "<leader>cf", function()
  require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "Format" })

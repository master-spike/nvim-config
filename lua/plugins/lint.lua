-- Linting via nvim-lint (non-LSP linters only).
-- JS/TS linting is handled by the eslint LSP (see config/lsp.lua), matching the
-- previous LazyVim eslint extra (diagnostics + fix-on-save via LspEslintFixAll).
local lint = require("lint")

lint.linters_by_ft = {
  sh = { "shellcheck" },
}

local group = vim.api.nvim_create_augroup("config_lint", { clear = true })
vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
  group = group,
  callback = function()
    if vim.bo.modifiable then
      lint.try_lint()
    end
  end,
})

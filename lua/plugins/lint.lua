-- Linting via nvim-lint (eslint extra)
local lint = require("lint")

lint.linters_by_ft = {
  javascript = { "eslint_d" },
  typescript = { "eslint_d" },
  javascriptreact = { "eslint_d" },
  typescriptreact = { "eslint_d" },
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

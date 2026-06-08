-- avante.nvim with GitHub Copilot as the provider.
-- Auth token is read from ~/.config/github-copilot (shared with copilot.lua).
require("avante").setup({
  provider = "copilot",
  providers = {
    copilot = {
      model = "gpt-4o-2024-08-06",
    },
  },
})

-- copilot.lua — used here only as the auth/token provider for avante's copilot
-- provider. Inline suggestions and the panel are disabled so it doesn't compete
-- with blink.cmp completion.
require("copilot").setup({
  suggestion = { enabled = false },
  panel = { enabled = false },
})

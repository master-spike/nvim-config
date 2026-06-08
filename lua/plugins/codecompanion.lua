-- codecompanion.nvim with GitHub Copilot as the adapter.
--
-- Replaces avante: inline edits stream directly into the buffer and run
-- asynchronously, so you can fire an edit and keep working. Progress is shown
-- as a little spinner in the bottom-right via fidget (wired up below), so you
-- always have a visual indication of what's happening even after you move away.
--
-- The copilot adapter reads its auth token from ~/.config/github-copilot.

require("codecompanion").setup({
  strategies = {
    chat = { adapter = "copilot" },
    inline = { adapter = "copilot" },
    cmd = { adapter = "copilot" },
  },
})

-- Keymaps (under <leader>a = AI).
local map = vim.keymap.set
map({ "n", "x" }, "<leader>aa", "<cmd>CodeCompanionActions<cr>", { desc = "AI: actions" })
map({ "n", "x" }, "<leader>ac", "<cmd>CodeCompanionChat Toggle<cr>", { desc = "AI: toggle chat" })
map("x", "<leader>ax", "<cmd>CodeCompanionChat Add<cr>", { desc = "AI: add selection to chat" })
-- Inline edit: type your instruction after the prompt and hit <cr>. Fire and
-- walk away — it streams the edit in asynchronously with a spinner.
map({ "n", "x" }, "<leader>ai", ":CodeCompanion ", { desc = "AI: inline edit" })

local ok_wk, wk = pcall(require, "which-key")
if ok_wk then
  wk.add({ { "<leader>a", group = "AI" } })
end

-- Progress indicator: drive a fidget spinner from codecompanion request events
-- so there's a persistent visual cue while a request is in flight.
local progress_handles = {}
local group = vim.api.nvim_create_augroup("CodeCompanionFidget", { clear = true })

vim.api.nvim_create_autocmd("User", {
  group = group,
  pattern = "CodeCompanionRequestStarted",
  callback = function(args)
    local ok, progress = pcall(require, "fidget.progress")
    if not ok then
      return
    end
    local data = args.data or {}
    local id = data.id
    if not id then
      return
    end
    local adapter = type(data.adapter) == "table" and (data.adapter.formatted_name or data.adapter.name) or "Copilot"
    progress_handles[id] = progress.handle.create({
      title = "CodeCompanion",
      message = "Thinking...",
      lsp_client = { name = adapter },
    })
  end,
})

vim.api.nvim_create_autocmd("User", {
  group = group,
  pattern = "CodeCompanionRequestFinished",
  callback = function(args)
    local data = args.data or {}
    local handle = data.id and progress_handles[data.id]
    if handle then
      handle.message = (data.status == "success") and "Done" or "Cancelled"
      handle:finish()
      progress_handles[data.id] = nil
    end
  end,
})

require("gitsigns").setup({
  on_attach = function(bufnr)
    local gitsigns = require("gitsigns")

    local function map(mode, l, r, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, l, r, opts)
    end

    -- Navigation
    map("n", "]c", function()
      if vim.wo.diff then
        vim.cmd.normal({ "]c", bang = true })
      else
        gitsigns.nav_hunk("next")
      end
    end)

    map("n", "[c", function()
      if vim.wo.diff then
        vim.cmd.normal({ "[c", bang = true })
      else
        gitsigns.nav_hunk("prev")
      end
    end)

    -- Actions
    map("n", "<leader>ghs", gitsigns.stage_hunk)
    map("n", "<leader>ghr", gitsigns.reset_hunk)

    map("v", "<leader>ghs", function()
      gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
    end)

    map("v", "<leader>ghr", function()
      gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
    end)

    map("n", "<leader>gS", gitsigns.stage_buffer)
    map("n", "<leader>gR", gitsigns.reset_buffer)
    map("n", "<leader>ghp", gitsigns.preview_hunk_inline)

    map("n", "<leader>gb", function()
      gitsigns.blame_line({ full = true })
    end)

    map("n", "<leader>gd", gitsigns.diffthis)

    map("n", "<leader>gD", function()
      gitsigns.diffthis("~")
    end)

    map("n", "<leader>gQ", function()
      gitsigns.setqflist("all")
    end)
    map("n", "<leader>gq", gitsigns.setqflist)

    -- Toggles
    map("n", "<leader>gtb", gitsigns.toggle_current_line_blame)
    map("n", "<leader>gtw", gitsigns.toggle_word_diff)
  end,
})

-- Send all git hunks to a Telescope picker.
-- setqflist populates the quickfix list asynchronously; we suppress the native
-- quickfix window (open = false) and open Telescope's quickfix picker from the
-- completion callback (scheduled onto the main loop).
vim.keymap.set("n", "<leader>fg", function()
  require("gitsigns").setqflist("all", { open = false }, function()
    vim.schedule(function()
      require("telescope.builtin").quickfix({ prompt_title = "Git Hunks" })
    end)
  end)
end, { desc = "Find git hunks (Telescope)" })

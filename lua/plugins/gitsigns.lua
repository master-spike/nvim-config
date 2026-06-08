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

-- Send all git hunks to a Telescope picker with an inline diff preview.
--
-- gitsigns.setqflist('all') gathers every hunk in the repo into the quickfix
-- list, but those entries only carry filename/lnum/text (no diff body), so the
-- default Telescope quickfix previewer can only show the file, not the change.
-- Instead we build our own picker from the hunk locations and attach a previewer
-- that renders the specific hunk's diff (parsed out of `git diff`) so the preview
-- pane shows the actual added/removed lines with diff highlighting.

-- Return the unified-diff lines for the hunk in `filename` that covers `lnum`.
local function hunk_diff_lines(filename, lnum)
  local dir = vim.fn.fnamemodify(filename, ":h")
  local out = vim.fn.systemlist({
    "git",
    "-C",
    dir,
    "--no-pager",
    "-c",
    "color.ui=never",
    "diff",
    "-U3",
    "--",
    filename,
  })
  if vim.v.shell_error ~= 0 or vim.tbl_isempty(out) then
    return { "(no diff available)" }
  end

  local hunks, cur = {}, nil
  for _, line in ipairs(out) do
    if line:match("^diff %-%-git") then
      cur = nil
    elseif line:match("^@@") then
      local newstart = tonumber(line:match("%+(%d+)")) or 0
      local newcount = tonumber(line:match("%+%d+,(%d+)")) or 1
      cur = {
        lines = { line },
        newstart = newstart,
        newend = newstart + math.max(newcount, 1) - 1,
      }
      hunks[#hunks + 1] = cur
    elseif cur and line:match("^[ +\\-]") then
      cur.lines[#cur.lines + 1] = line
    end
  end

  if vim.tbl_isempty(hunks) then
    return out
  end

  -- Prefer the hunk whose new-line range contains lnum; else the nearest.
  local best, best_dist
  for _, h in ipairs(hunks) do
    if lnum >= h.newstart and lnum <= h.newend then
      return h.lines
    end
    local dist = math.abs(h.newstart - lnum)
    if not best_dist or dist < best_dist then
      best, best_dist = h, dist
    end
  end
  return best and best.lines or out
end

vim.keymap.set("n", "<leader>fg", function()
  require("gitsigns").setqflist("all", { open = false }, function()
    vim.schedule(function()
      local items = vim.fn.getqflist({ items = 0 }).items
      local entries = {}
      for _, it in ipairs(items) do
        local fname = it.bufnr and it.bufnr > 0 and vim.api.nvim_buf_get_name(it.bufnr) or nil
        if (not fname or fname == "") and it.filename then
          fname = it.filename
        end
        if fname and fname ~= "" then
          entries[#entries + 1] = { filename = fname, lnum = it.lnum, text = it.text }
        end
      end

      if vim.tbl_isempty(entries) then
        vim.notify("No git hunks found", vim.log.levels.INFO)
        return
      end

      local pickers = require("telescope.pickers")
      local finders = require("telescope.finders")
      local conf = require("telescope.config").values
      local previewers = require("telescope.previewers")

      local previewer = previewers.new_buffer_previewer({
        title = "Hunk Diff",
        define_preview = function(self, entry)
          local lines = hunk_diff_lines(entry.filename, entry.lnum)
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
          vim.bo[self.state.bufnr].filetype = "diff"
        end,
      })

      pickers
        .new({}, {
          prompt_title = "Git Hunks",
          finder = finders.new_table({
            results = entries,
            entry_maker = function(item)
              local rel = vim.fn.fnamemodify(item.filename, ":.")
              return {
                value = item,
                ordinal = rel .. " " .. item.text,
                display = rel .. " │ " .. item.text,
                filename = item.filename,
                path = item.filename,
                lnum = item.lnum,
                col = 1,
              }
            end,
          }),
          sorter = conf.generic_sorter({}),
          previewer = previewer,
        })
        :find()
    end)
  end)
end, { desc = "Find git hunks (Telescope)" })

-- Custom fold + mark gutter rendered through 'statuscolumn'. The native
-- 'foldcolumn' collapses nested fold depth into digits; this instead shows a
-- single chevron only on the line where a fold starts (open or closed), and the
-- letter of any |mark| set on the line. Signs and (relative) line numbers are
-- preserved; the gutter never shows fold-depth numbers.
--
-- The chevron of the innermost ("youngest") fold enclosing the cursor is drawn
-- in the `FoldActive` highlight; mark letters are drawn in `FoldMark`.
--
-- CRITICAL: the statuscolumn callbacks (`M.marker` / `M.number`) are pure table
-- lookups and must NEVER call `vim.treesitter.foldexpr()`. Calling foldexpr per
-- visible line, during a redraw, re-entrant with the fold engine, intermittently
-- HANGS the UI on the main thread (no error is logged -- it is a hang, not a
-- crash, and it is not limited to large files). Fold starts and marks are
-- instead precomputed OFF the redraw path by `M.refresh()` (driven by the
-- autocmds at the bottom) and cached per buffer.

local M = {}

local OPEN = vim.fn.nr2char(0xf0140) -- nf-md-chevron_down
local CLOSED = vim.fn.nr2char(0xf0142) -- nf-md-chevron_right (reads like ">")

-- Above this line count the (whole-buffer) fold-start scan is skipped: the
-- gutter simply omits chevrons rather than risk a slow synchronous scan.
local MAX_SCAN_LINES = 4000

-- Per-buffer caches, all populated by `M.refresh()` outside of redraw.
M._foldstarts = {} -- [buf] = { tick = <changedtick>, set = { [lnum] = true } }
M._marks = {} -- [buf] = { [lnum] = "<letter>" }
M._active = nil -- innermost fold-start line under the cursor: { buf, line }

-- True when `lnum` is cached as a fold-start for `buf`.
local function is_fold_start(buf, lnum)
  local fs = M._foldstarts[buf]
  return (fs and fs.set[lnum]) == true
end

-- Letters of all marks per line of `buf`: buffer-local lowercase marks plus
-- global uppercase marks that point at this buffer's file.
local function compute_marks(buf)
  local res = {}
  for _, m in ipairs(vim.fn.getmarklist(buf)) do
    local name = m.mark:sub(2) -- strip the leading "'"
    if name:match("^%l$") then
      res[m.pos[2]] = name
    end
  end
  local bufname = vim.api.nvim_buf_get_name(buf)
  if bufname ~= "" then
    for _, m in ipairs(vim.fn.getmarklist()) do
      local name = m.mark:sub(2)
      if name:match("^%u$") and vim.fn.fnamemodify(m.file, ":p") == bufname then
        res[m.pos[2]] = name
      end
    end
  end
  return res
end

-- Set of lines where a Treesitter fold starts, detected from the raw foldexpr
-- value (a leading ">"), which -- unlike a foldlevel increase versus the
-- previous line -- also catches sibling folds at the same level (e.g. two `if`
-- blocks in one function body). Runs only for the current buffer and never
-- during a redraw (see the file header).
local function compute_foldstarts(buf)
  local set = {}
  if not vim.api.nvim_buf_is_loaded(buf) then
    return set
  end
  local lcount = vim.api.nvim_buf_line_count(buf)
  if lcount > MAX_SCAN_LINES then
    return set
  end
  for lnum = 1, lcount do
    local ok, fe = pcall(vim.treesitter.foldexpr, lnum)
    if ok then
      fe = type(fe) == "string" and fe or tostring(fe)
      if fe:sub(1, 1) == ">" then
        set[lnum] = true
      end
    end
  end
  return set
end

-- Recompute the fold-start and mark caches for `buf` (defaults to the current
-- buffer) and trigger a targeted statuscolumn redraw. Must run OUTSIDE redraw
-- (the autocmds below `vim.schedule` it). Fold starts are only rescanned when
-- the buffer changed; marks are cheap and always refreshed.
function M.refresh(buf)
  if not buf or buf == 0 then
    buf = vim.api.nvim_get_current_buf()
  end
  if not vim.api.nvim_buf_is_valid(buf) or buf ~= vim.api.nvim_get_current_buf() then
    return
  end
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local fs = M._foldstarts[buf]
  if not fs or fs.tick ~= tick then
    M._foldstarts[buf] = { tick = tick, set = compute_foldstarts(buf) }
  end
  M._marks[buf] = compute_marks(buf)
  pcall(vim.api.nvim__redraw, { buf = buf, statuscolumn = true })
end

-- Line number segment honouring 'number' / 'relativenumber', blank on wrapped
-- (virtual) lines.
function M.number()
  if vim.v.virtnum ~= 0 then
    return ""
  end
  if not (vim.wo.number or vim.wo.relativenumber) then
    return ""
  end
  if vim.wo.relativenumber and vim.v.relnum > 0 then
    return tostring(vim.v.relnum)
  end
  return tostring(vim.v.lnum)
end

-- Leftmost gutter cell for the line being drawn: a mark letter takes priority
-- (`FoldMark`), else a fold chevron on a fold-start line (the innermost fold
-- under the cursor in `FoldActive`), else a blank. Pure cache lookups only.
function M.marker(lnum)
  lnum = lnum or vim.v.lnum
  if vim.v.virtnum and vim.v.virtnum ~= 0 then
    return " "
  end
  local buf = vim.api.nvim_get_current_buf()
  local marks = M._marks[buf]
  local letter = marks and marks[lnum]
  if letter then
    return "%#FoldMark#" .. letter .. "%*"
  end
  if not is_fold_start(buf, lnum) then
    return " "
  end
  local glyph = vim.fn.foldclosed(lnum) == -1 and OPEN or CLOSED
  local a = M._active
  if a and a.line == lnum and a.buf == buf then
    return "%#FoldActive#" .. glyph .. "%*"
  end
  return glyph
end

-- Line of the innermost fold start that contains the cursor, or nil when the
-- cursor is not inside any fold. Walks up from the cursor looking for a
-- fold-start line whose fold level equals the cursor's depth (so deeper sibling
-- folds sitting above the cursor are skipped), bounded by the parent fold. Uses
-- the cached fold-start set and the (cheap) fold-engine `foldlevel`.
local function active_fold_start()
  local buf = vim.api.nvim_get_current_buf()
  local cur = vim.fn.line(".")
  local level = vim.fn.foldlevel(cur)
  if level == 0 then
    return nil
  end
  local s = cur
  while s >= 1 do
    if vim.fn.foldlevel(s) == level and is_fold_start(buf, s) then
      return s
    end
    if s == 1 or vim.fn.foldlevel(s - 1) < level then
      return s
    end
    s = s - 1
  end
  return s
end

-- Recomputes and caches the active fold-start line for the current window.
function M.update_active()
  M._active = { buf = vim.api.nvim_get_current_buf(), line = active_fold_start() }
end

-- 'foldtext' for a closed fold: the fold's first line where each whitespace
-- character that is NOT directly adjacent to a code (non-whitespace) character
-- becomes a double-dash "╌" (muted `Folded` colour), while whitespace touching
-- code stays blank to keep it readable. Code runs are golden `FoldLine`, and a
-- blue " N lines" label follows. Used instead of decoration-provider virtual
-- text because ephemeral virt_text from a decoration provider is NOT rendered on
-- a closed fold line (a non-fold line shows it fine), whereas 'foldtext' always
-- is. The trailing area past the label is filled with the same dash via
-- `fillchars.fold`.
function M.foldtext()
  local first = vim.v.foldstart
  local line = vim.api.nvim_buf_get_lines(0, first - 1, first, false)[1] or ""
  line = line:gsub("\t", string.rep(" ", vim.bo.tabstop > 0 and vim.bo.tabstop or 8))
  local DASH = "╌"
  local n = #line
  local function is_code(idx)
    local c = line:sub(idx, idx)
    return c ~= "" and c ~= " "
  end
  local chunks = {}
  local i = 1
  while i <= n do
    if line:sub(i, i) == " " then
      local j = i
      while j <= n and line:sub(j, j) == " " do
        j = j + 1
      end
      local run = {}
      for k = i, j - 1 do
        run[#run + 1] = (is_code(k - 1) or is_code(k + 1)) and " " or DASH
      end
      chunks[#chunks + 1] = { table.concat(run), "Folded" }
      i = j
    else
      local j = i
      while j <= n and line:sub(j, j) ~= " " do
        j = j + 1
      end
      chunks[#chunks + 1] = { line:sub(i, j - 1), "FoldLine" }
      i = j
    end
  end
  local count = vim.v.foldend - vim.v.foldstart + 1
  chunks[#chunks + 1] = { " " .. DASH:rep(2) .. " ", "Folded" }
  chunks[#chunks + 1] = { count .. " lines", "FoldCount" }
  chunks[#chunks + 1] = { " ", "Folded" }
  return chunks
end

M.statuscolumn = table.concat({
  "%{%v:lua.require'util.fold'.marker()%}", -- mark letter / fold chevron, leftmost
  "%s", -- signs (gitsigns, diagnostics)
  "%=", -- right-align the number
  "%{v:lua.require'util.fold'.number()} ",
})

local group = vim.api.nvim_create_augroup("config_fold", { clear = true })

-- Recompute the fold-start + mark caches OFF the redraw path. `CursorHold`
-- (after 'updatetime') is what makes a freshly set `ma` appear without a manual
-- redraw; `TextChanged` / `InsertLeave` keep marks aligned after edits.
vim.api.nvim_create_autocmd({ "BufWinEnter", "BufReadPost", "TextChanged", "InsertLeave", "CursorHold" }, {
  group = group,
  callback = function(ev)
    vim.schedule(function()
      M.refresh(ev.buf)
    end)
  end,
})

-- Track the active (cursor-enclosing) fold start for the `FoldActive` highlight.
vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufEnter", "WinEnter" }, {
  group = group,
  callback = M.update_active,
})

return M

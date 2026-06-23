-- Custom fold gutter rendered through 'statuscolumn'. The native 'foldcolumn'
-- collapses nested fold depth into digits; this instead shows a single chevron
-- only on the line where a fold starts (open or closed) and nothing else, so the
-- gutter never shows numbers. Signs and (relative) line numbers are preserved.
--
-- The chevron of the innermost ("youngest") fold enclosing the cursor is drawn
-- in the `FoldActive` highlight, giving a visual indicator of which fold the
-- cursor is currently in. The active line is recomputed on cursor movement and
-- cached so `marker()` stays cheap per redraw.

local M = {}

local OPEN = vim.fn.nr2char(0xf0140) -- nf-md-chevron_down
local CLOSED = vim.fn.nr2char(0xf0142) -- nf-md-chevron_right (reads like ">")

-- Cached innermost-fold-start line under the cursor: { buf = ..., line = ... }.
M._active = nil

-- True when a fold starts on `lnum`, detected from the raw Treesitter foldexpr
-- value (a leading ">").
local function is_fold_start(lnum)
  local ok, fe = pcall(vim.treesitter.foldexpr, lnum)
  if not ok then
    return false
  end
  fe = type(fe) == "string" and fe or tostring(fe)
  return fe:sub(1, 1) == ">"
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

-- Fold chevron for the given line (defaults to the line being drawn). A chevron
-- is shown only where a fold *starts*. Fold starts are detected from the raw
-- Treesitter foldexpr value (a leading ">"), not from a fold-level increase
-- versus the previous line -- the latter misses sibling folds at the same level
-- (e.g. two `if` blocks in one function body). The chevron of the innermost
-- fold enclosing the cursor is wrapped in the `FoldActive` highlight.
function M.marker(lnum)
  lnum = lnum or vim.v.lnum
  if vim.v.virtnum and vim.v.virtnum ~= 0 then
    return " "
  end
  if not is_fold_start(lnum) then
    return " "
  end
  local glyph = vim.fn.foldclosed(lnum) == -1 and OPEN or CLOSED
  local a = M._active
  if a and a.line == lnum and a.buf == vim.api.nvim_get_current_buf() then
    return "%#FoldActive#" .. glyph .. "%*"
  end
  return glyph
end

-- Line of the innermost fold start that contains the cursor, or nil when the
-- cursor is not inside any fold. Walks up from the cursor looking for a
-- fold-start line whose fold level equals the cursor's depth (so deeper sibling
-- folds sitting above the cursor are skipped), bounded by the parent fold.
local function active_fold_start()
  local cur = vim.fn.line(".")
  local level = vim.fn.foldlevel(cur)
  if level == 0 then
    return nil
  end
  local s = cur
  while s >= 1 do
    if vim.fn.foldlevel(s) == level and is_fold_start(s) then
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
  "%{%v:lua.require'util.fold'.marker()%}", -- fold chevron (with highlight), leftmost
  "%s", -- signs (gitsigns, diagnostics)
  "%=", -- right-align the number
  "%{v:lua.require'util.fold'.number()} ",
})

vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufEnter", "WinEnter" }, {
  group = vim.api.nvim_create_augroup("config_fold", { clear = true }),
  callback = M.update_active,
})

return M

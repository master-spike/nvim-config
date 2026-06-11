-- Go-to-definition wrapper that works around a JDT `SelectionEngine` quirk.
--
-- For a Java method reference (`Qualifier::name`), jdtls mis-resolves
-- `textDocument/definition` when the request position sits on the `::` operator
-- or on the *first* character of the method name: it returns the functional
-- interface (e.g. `Supplier`) or the enclosing call instead of the referenced
-- method. Requesting one column further into the name resolves correctly.
--
-- Since `gd` naturally leaves the cursor on that first character, we detect the
-- situation with treesitter and nudge the request position into the interior of
-- the name before delegating to the normal (Telescope-backed) definition picker.

local M = {}

-- If the cursor is on the `::`/name-start boundary of a Java `method_reference`,
-- return the 0-based column just inside the method name; otherwise nil.
local function java_method_ref_snap()
  if not pcall(vim.treesitter.get_parser, 0, "java") then
    return nil
  end

  local pos = vim.api.nvim_win_get_cursor(0)
  local row, col = pos[1] - 1, pos[2]

  local ok, node = pcall(vim.treesitter.get_node, { pos = { row, col } })
  if not ok or not node then
    return nil
  end

  local mref = node
  while mref and mref:type() ~= "method_reference" do
    mref = mref:parent()
  end
  if not mref then
    return nil
  end

  -- The method name is the child immediately following the `::` token.
  local op, name
  for i = 0, mref:child_count() - 1 do
    local child = mref:child(i)
    if child:type() == "::" then
      op = child
    elseif op and not name then
      name = child
    end
  end
  if not op or not name then
    return nil
  end

  local _, op_col = op:range()
  local nsr, nsc, ner, nec = name:range()

  -- Only nudge when the cursor is on the `::` or the name's first character, and
  -- only when the name has an interior column to move to.
  local has_interior = ner > nsr or nec - nsc > 1
  if row == nsr and col >= op_col and col <= nsc and has_interior then
    return nsc + 1
  end
  return nil
end

-- Go to definition via the Telescope picker, applying the Java method-reference
-- position fix when applicable.
function M.goto_definition()
  local definitions = require("telescope.builtin").lsp_definitions

  local snap = vim.bo.filetype == "java" and java_method_ref_snap() or nil
  if not snap then
    return definitions()
  end

  local win = vim.api.nvim_get_current_win()
  local original = vim.api.nvim_win_get_cursor(win)
  vim.api.nvim_win_set_cursor(win, { original[1], snap })
  definitions()
  -- The position params are read synchronously above; restore the cursor so a
  -- multi-result picker or "not found" leaves it where the user actually was.
  -- On a successful single jump, Telescope's async handler moves it to the target.
  vim.schedule(function()
    if vim.api.nvim_win_is_valid(win) then
      pcall(vim.api.nvim_win_set_cursor, win, original)
    end
  end)
end

return M

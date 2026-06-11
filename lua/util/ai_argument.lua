-- Treesitter-based "argument" text object for mini.ai (mapped to `a`, used as
-- `aa`/`ia`/`daa`/`dia`/...).
--
-- It is fully query-driven: the argument node comes from the grammar's
-- `@parameter.inner` capture, so nesting, multi-line calls, strings, comments
-- and constructs like `Map<K, V>` are handled by the parser rather than by
-- text scanning. With the cursor on `bar` in
--     foo(
--     bar(a,b),
--     baz(c,d));
-- the smallest `@parameter.inner` node containing the cursor is `bar(a,b)`, so
-- `dia` affects `bar(a,b)` (not `a`).
--
-- `i` is the parameter node itself. `a` extends it to include one adjacent
-- comma (and the whitespace up to the neighbouring argument) using the node's
-- siblings in the syntax tree, chosen so deleting the first/middle/last
-- argument always leaves a well-formed list.
--
-- NOTE: `@parameter.outer` is intentionally not used. In these grammars it is
-- defined via the `#make-range!` directive, which nvim-treesitter (master) on
-- Neovim 0.12 fails to resolve; `@parameter.inner` is a plain capture and works
-- with the native `vim.treesitter` API.

local M = {}

-- Collect every `@parameter.inner` node in the language tree at the cursor.
local function parameter_nodes(bufnr, row, col)
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, nil, { error = false })
  if not ok or not parser then
    return {}
  end
  parser:parse()

  local ltree = parser:language_for_range({ row, col, row, col })
  local query = vim.treesitter.query.get(ltree:lang(), "textobjects")
  if not query then
    return {}
  end

  local nodes = {}
  for _, tree in ipairs(ltree:trees()) do
    for id, node in query:iter_captures(tree:root(), bufnr, 0, -1) do
      if query.captures[id] == "parameter.inner" then
        nodes[#nodes + 1] = node
      end
    end
  end
  return nodes
end

-- Is (row, col) (0-based) within node's range? End is exclusive.
local function node_contains(node, row, col)
  local sr, sc, er, ec = node:range()
  local after_start = row > sr or (row == sr and col >= sc)
  local before_end = row < er or (row == er and col < ec)
  return after_start and before_end
end

local function node_byte_len(node)
  local _, _, sb = node:start()
  local _, _, eb = node:end_()
  return eb - sb
end

-- Smallest @parameter.inner node containing the cursor.
local function arg_at_cursor(bufnr, row, col)
  local best
  for _, node in ipairs(parameter_nodes(bufnr, row, col)) do
    if node_contains(node, row, col) then
      if not best or node_byte_len(node) < node_byte_len(best) then
        best = node
      end
    end
  end
  return best
end

local function is_comma(node)
  return node ~= nil and node:type() == ","
end

-- mini.ai uses 1-based lines and 1-based, end-inclusive columns.
local function start_pos(node)
  local sr, sc = node:start()
  return { line = sr + 1, col = sc + 1 }
end

-- Convert a 0-based, end-exclusive (row, col) edge into a 1-based, inclusive
-- mini.ai position (mirrors mini.ai's own handling of column-0 edges).
local function exclusive_to_inclusive(row, col)
  local line, c = row + 1, col
  if c == 0 then
    line = line - 1
    c = math.max(vim.fn.col({ line, "$" }) - 1, 1)
  end
  return { line = line, col = c }
end

local function end_pos(node)
  local er, ec = node:end_()
  return exclusive_to_inclusive(er, ec)
end

-- A node's exclusive end position, interpreted as the START of a region
-- (0-based, end-exclusive -> 1-based start column).
local function end_as_start(node)
  local er, ec = node:end_()
  return { line = er + 1, col = ec + 1 }
end

--- mini.ai custom text object specification (use as a `custom_textobjects` value).
---@param ai_type string '"a"' or '"i"'
---@return table|nil region `{ from = {line, col}, to = {line, col} }`
function M.spec(ai_type)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]

  local node = arg_at_cursor(0, row, col)
  if not node then
    return nil
  end

  local from = start_pos(node)
  local to = end_pos(node)

  if ai_type == "a" then
    local nxt, prev = node:next_sibling(), node:prev_sibling()
    if is_comma(nxt) then
      -- Not the last argument: include the comma and the whitespace up to the
      -- next argument (so the remaining list stays well-formed).
      local after = nxt:next_sibling()
      if after then
        local ar, ac = after:start()
        to = exclusive_to_inclusive(ar, ac)
      else
        to = end_pos(nxt)
      end
    elseif is_comma(prev) then
      -- Last argument: include the preceding comma (and any whitespace before
      -- it that separates it from the previous argument).
      local before = prev:prev_sibling()
      if before then
        from = end_as_start(before)
      else
        from = start_pos(prev)
      end
    end
    -- Single argument (no comma siblings): fall through with `a` == `i`.
  end

  return { from = from, to = to }
end

return M

-- Treesitter textobject resolver for mini.ai.
--
-- This is a drop-in replacement for `MiniAi.gen_spec.treesitter()` that, in
-- addition to plain `@capture` nodes, also resolves ranges produced by the
-- `#make-range!` directive (see lua/plugins/treesitter-textobjects.lua).
--
-- Why this exists: nvim-treesitter-textobjects defines most `*.inner` objects
-- (and some `*.outer`) only via `#make-range!`. mini.ai's builtin resolver
-- (`H.get_matched_ranges_builtin`) only inspects captures listed in
-- `query.captures`, so directive-produced ranges are invisible to it and
-- `dif`/`yic`/... silently do nothing. By reading the directive's metadata too,
-- this resolver makes function/class/loop/conditional inner objects work in
-- every language straight from the upstream queries, with no per-language
-- override files. The only objects still needing an `after/queries` override are
-- ones upstream never defines at all (e.g. `block.inner` for C/C++/Java).

local M = {}

-- Convert a treesitter range (4- or 6-element, 0-based) to a mini.ai region
-- (1-based, `to.col` inclusive). Mirrors the conversion in MiniAi.gen_spec.
local function range_to_region(r)
  local offset = #r == 4 and -1 or 0
  local res = {
    from = { line = r[1] + 1, col = r[2] + 1 },
    to = { line = r[4 + offset] + 1, col = r[5 + offset] },
  }
  if res.to.col == 0 then
    res.to.line = res.to.line - 1
    res.to.col = vim.fn.col({ res.to.line, "$" })
  end
  return res
end

-- Span several quantified-capture nodes as one range (leftmost start to
-- rightmost end), matching mini.ai's "quantified captures" behaviour.
local function nodes_range(nodes, buf_id, metadata)
  nodes = type(nodes) == "table" and nodes or { nodes }
  local left, right
  for _, node in ipairs(nodes) do
    local range = vim.treesitter.get_range(node, buf_id, metadata)
    if left == nil or range[3] < left[3] then
      left = range
    end
    if right == nil or range[6] > right[6] then
      right = range
    end
  end
  return { left[1], left[2], left[3], right[4], right[5], right[6] }
end

local function append_ranges(res, buf_id, query, wanted, lang_tree)
  local capture_is_wanted = {}
  for i, name in ipairs(query.captures) do
    capture_is_wanted[i] = wanted["@" .. name] == true
  end

  for _, tree in ipairs(lang_tree:trees()) do
    for _, match, metadata in query:iter_matches(tree:root(), buf_id, nil, nil, { all = true }) do
      for capture_id, nodes in pairs(match) do
        if capture_is_wanted[capture_id] then
          res[#res + 1] = nodes_range(nodes, buf_id, metadata[capture_id])
        end
      end
      -- Ranges produced by `#make-range!` are stored in metadata under the
      -- (string) range name rather than as a capture node.
      for key, value in pairs(metadata) do
        if type(key) == "string" and wanted["@" .. key] and type(value) == "table" and value.range then
          res[#res + 1] = value.range
        end
      end
    end
  end
end

local function matched_ranges(wanted)
  local buf_id = vim.api.nvim_get_current_buf()
  local has_parser, parser = pcall(vim.treesitter.get_parser, buf_id, nil, { error = false })
  if not has_parser or parser == nil then
    return {}
  end

  local pos = vim.api.nvim_win_get_cursor(0)
  local lang_tree = parser:language_for_range({ pos[1] - 1, pos[2], pos[1] - 1, pos[2] })
  local init_lang_tree = lang_tree

  local res = {}
  -- Walk up parent trees (handles injected languages).
  while vim.tbl_isempty(res) and lang_tree ~= nil do
    local query = vim.treesitter.query.get(lang_tree:lang(), "textobjects")
    if query ~= nil then
      append_ranges(res, buf_id, query, wanted, lang_tree)
    end
    lang_tree = lang_tree:parent()
  end

  -- Fall back to child trees (injected languages inside the cursor's tree).
  if vim.tbl_isempty(res) then
    local function check_children(l_tree)
      for _, child in pairs(l_tree:children()) do
        local query = vim.treesitter.query.get(child:lang(), "textobjects")
        if query ~= nil then
          append_ranges(res, buf_id, query, wanted, child)
        end
        check_children(child)
      end
    end
    check_children(init_lang_tree)
  end

  return res
end

-- Build a mini.ai custom textobject spec. `ai_captures` maps the `a`/`i` types
-- to one or more capture names, e.g. `{ a = "@function.outer", i = "@function.inner" }`.
function M.spec(ai_captures)
  local prepared = {}
  for ai_type, caps in pairs(ai_captures) do
    prepared[ai_type] = type(caps) == "table" and caps or { caps }
  end

  return function(ai_type)
    local wanted = {}
    for _, cap in ipairs(prepared[ai_type] or {}) do
      wanted[cap] = true
    end
    return vim.tbl_map(range_to_region, matched_ranges(wanted))
  end
end

return M

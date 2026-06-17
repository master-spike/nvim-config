-- Path display helpers shared by lualine, telescope and gitsigns so every
-- place that shortens a filepath collapses it the exact same way.

local M = {}

-- Cache of "does this directory contain exactly one subdirectory?" keyed by
-- directory path. collapse() runs per-entry on every telescope redraw, so we
-- memoize the scandir syscalls to keep large lists snappy. Stale entries only
-- affect display, never navigation. Call clear_cache() to force a re-scan.
local single_subdir_cache = {}

local function is_only_directory(parent)
  local cached = single_subdir_cache[parent]
  if cached ~= nil then
    return cached
  end

  local handle = vim.uv.fs_scandir(parent)
  if not handle then
    single_subdir_cache[parent] = false
    return false
  end

  local dir_count = 0
  while true do
    local name, type = vim.uv.fs_scandir_next(handle)
    if not name then
      break
    end
    if type == "directory" then
      dir_count = dir_count + 1
    end
  end

  local result = dir_count == 1
  single_subdir_cache[parent] = result
  return result
end

function M.clear_cache()
  single_subdir_cache = {}
end

-- Collapse a filepath by replacing each directory segment whose parent holds
-- exactly one subdirectory with "...", then deduping consecutive "...". The
-- final component is always kept. Paths outside cwd fall back to a "~"-relative
-- form without collapsing. Accepts absolute or cwd-relative input.
--
-- Example: tech/dojo/avalanche/reporting/file.txt -> .../reporting/file.txt
function M.collapse(filepath)
  if type(filepath) ~= "string" or filepath == "" then
    return filepath
  end

  local cwd = vim.uv.cwd()
  local rel
  if filepath:sub(1, 1) == "/" then
    if filepath:sub(1, #cwd) == cwd then
      rel = filepath:sub(#cwd + 2)
    else
      return vim.fn.fnamemodify(filepath, ":~:.")
    end
  else
    rel = filepath
  end

  local parts = {}
  for part in string.gmatch(rel, "[^/]+") do
    table.insert(parts, part)
  end

  if #parts <= 1 then
    return rel
  end

  local current_path = cwd
  local new_parts = {}
  for i = 1, #parts - 1 do
    local part = parts[i]
    if is_only_directory(current_path) then
      table.insert(new_parts, "...")
    else
      table.insert(new_parts, part)
    end
    current_path = current_path .. "/" .. part
  end
  table.insert(new_parts, parts[#parts])

  local collapsed = {}
  for _, part in ipairs(new_parts) do
    if part == "..." then
      if collapsed[#collapsed] ~= "..." then
        table.insert(collapsed, "...")
      end
    else
      table.insert(collapsed, part)
    end
  end

  return table.concat(collapsed, "/")
end

return M

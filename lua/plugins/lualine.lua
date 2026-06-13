local function is_only_directory(parent)
  local handle = vim.uv.fs_scandir(parent)
  if not handle then
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
  return dir_count == 1
end

local function custom_filename()
  local filepath = vim.api.nvim_buf_get_name(0)
  if filepath == "" then
    return "[No Name]"
  end

  local buftype = vim.bo.buftype
  if buftype ~= "" then
    return vim.fn.fnamemodify(filepath, ":t")
  end

  local cwd = vim.uv.cwd()
  local rel = filepath
  if filepath:sub(1, #cwd) == cwd then
    rel = filepath:sub(#cwd + 2)
  else
    return vim.fn.fnamemodify(filepath, ":~:.")
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
  for i, part in ipairs(new_parts) do
    if part == "..." then
      if collapsed[#collapsed] ~= "..." then
        table.insert(collapsed, "...")
      end
    else
      table.insert(collapsed, part)
    end
  end

  local result = table.concat(collapsed, "/")

  if vim.bo.modified then
    result = result .. " [+]"
  end
  if vim.bo.readonly or not vim.bo.modifiable then
    result = result .. " [RO]"
  end

  return result
end

require("lualine").setup({
  options = {
    theme = "material",
    globalstatus = true,
    section_separators = "",
    component_separators = "",
  },
  sections = {
    lualine_c = { custom_filename },
  },
})

local path_util = require("util.path")

local function custom_filename()
  local filepath = vim.api.nvim_buf_get_name(0)
  if filepath == "" then
    return "[No Name]"
  end

  local buftype = vim.bo.buftype
  if buftype ~= "" then
    return vim.fn.fnamemodify(filepath, ":t")
  end

  local result = path_util.collapse(filepath)

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

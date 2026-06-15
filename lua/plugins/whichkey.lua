local wk = require("which-key")
local material_colors = require("material.colors")

wk.setup({
  delay = 0,
  win = {
    no_overlap = false,
    padding = { 1, 2 },
    title_pos = "center",
    wo = {
      winblend = 0,
    },
  },
})

-- Keymap group labels.
wk.add({
  { "<leader>u", group = "ui" },
  { "<leader>uf", desc = "Toggle formatter (buffer)" },
  { "<leader>uF", desc = "Toggle formatter (global)" },
  { "<leader>ut", desc = "Toggle translations" },
})

-- Describe mini.ai text objects so they appear in which-key after the
-- around/inside (and next/last) prefixes in operator-pending and visual modes
-- (e.g. `daa`/`dia` for argument, `yaf`/`yif` for function, `dan`/`cil`).
--
-- The object->description labels are necessarily explicit: mini.ai maps only
-- the prefixes (a/i/an/in/...) and resolves the object id from the next typed
-- character, so there are no discrete keymaps for which-key to auto-discover,
-- and mini.ai stores no human-readable descriptions. The *prefixes*, however,
-- are read from mini.ai's config so this stays in sync if they're remapped.
-- (Approach adapted from LazyVim's lua/lazyvim/util/mini.lua.)
local objects = {
  { "(", desc = "() block" },
  { ")", desc = "() block with ws" },
  { "[", desc = "[] block" },
  { "]", desc = "[] block with ws" },
  { "{", desc = "{} block" },
  { "}", desc = "{} block with ws" },
  { "<", desc = "<> block" },
  { ">", desc = "<> block with ws" },
  { "'", desc = "' string" },
  { '"', desc = '" string' },
  { "`", desc = "` string" },
  { "?", desc = "user prompt" },
  { "a", desc = "argument" },
  { "b", desc = ")]} block" },
  { "c", desc = "class" },
  { "f", desc = "function" },
  { "o", desc = "block, conditional, loop" },
  { "q", desc = "quote `\"'" },
  { "t", desc = "tag" },
}

local ai_mappings = require("mini.ai").config.mappings or {}
local prefixes = {
  around = ai_mappings.around or "a",
  inside = ai_mappings.inside or "i",
  around_next = ai_mappings.around_next or "an",
  inside_next = ai_mappings.inside_next or "in",
  around_last = ai_mappings.around_last or "al",
  inside_last = ai_mappings.inside_last or "il",
}

local textobject_spec = { mode = { "o", "x" } }
for name, prefix in pairs(prefixes) do
  local group = name:gsub("^around_?", ""):gsub("^inside_?", "")
  textobject_spec[#textobject_spec + 1] = { prefix, group = group ~= "" and group or name }
  for _, obj in ipairs(objects) do
    local desc = obj.desc
    -- `i` (inside) variants strip the trailing whitespace from edges.
    if prefix:sub(1, 1) == "i" then
      desc = desc:gsub(" with ws", "")
    end
    textobject_spec[#textobject_spec + 1] = { prefix .. obj[1], desc = desc }
  end
end
wk.add(textobject_spec, { notify = false })

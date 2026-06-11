local wk = require("which-key")
wk.setup()

-- Keymap group labels.
wk.add({
  { "<leader>u", group = "ui" },
})

-- Describe mini.ai text objects so they appear in which-key after the
-- around/inside prefixes in operator-pending and visual modes
-- (e.g. `daa`/`dia` for argument, `yaf`/`yif` for function).
local textobjects = {
  { "a", "argument" },
  { "b", "balanced )]}" },
  { "c", "class" },
  { "f", "function" },
  { "o", "block/conditional/loop" },
  { "q", "quote" },
  { "t", "tag" },
  { "(", "parens" },
  { ")", "parens" },
  { "[", "brackets" },
  { "]", "brackets" },
  { "{", "braces" },
  { "}", "braces" },
  { "<", "angle bracket" },
  { ">", "angle bracket" },
  { "'", "single quote" },
  { '"', "double quote" },
  { "`", "backtick" },
  { "?", "user prompt" },
}

local textobject_spec = {
  mode = { "o", "x" },
  { "a", group = "around" },
  { "i", group = "inside" },
}
for _, t in ipairs(textobjects) do
  table.insert(textobject_spec, { "a" .. t[1], desc = t[2] })
  table.insert(textobject_spec, { "i" .. t[1], desc = t[2] })
end
wk.add(textobject_spec)

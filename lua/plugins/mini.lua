-- mini.nvim modules (mini.pairs was disabled in old config, so it is omitted)
local ai = require("mini.ai")

-- Treesitter-backed text objects (queries from nvim-treesitter-textobjects):
--   af/if  function (outer/inner)  -> daf, dif, yaf, cif, vaf, ...
--   ac/ic  class
--   ao/io  block / conditional / loop
--   aa/ia  argument / parameter
ai.setup({
  n_lines = 500,
  custom_textobjects = {
    f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
    c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
    o = ai.gen_spec.treesitter({
      a = { "@block.outer", "@conditional.outer", "@loop.outer" },
      i = { "@block.inner", "@conditional.inner", "@loop.inner" },
    }),
  },
})

require("mini.surround").setup()
require("mini.icons").setup()

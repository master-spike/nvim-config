-- mini.nvim modules (mini.pairs was disabled in old config, so it is omitted)
local ai = require("mini.ai")

-- Treesitter-based argument text object (see lua/util/ai_argument.lua). Handles
-- nested, multi-line calls correctly (cursor on `bar` in `foo(bar(a,b), ...)`
-- selects `bar(a,b)`) and keeps deletion whitespace-consistent.
local argument = require("util.ai_argument").spec

-- Treesitter-backed text objects (queries from nvim-treesitter-textobjects):
--   af/if  function (outer/inner)  -> daf, dif, yaf, cif, vaf, ...
--   ac/ic  class
--   ao/io  block / conditional / loop
--   aa/ia  argument / parameter (treesitter, nesting- & multiline-aware)
ai.setup({
  n_lines = 500,
  custom_textobjects = {
    a = argument,
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

-- mini.nvim modules (mini.pairs was disabled in old config, so it is omitted)
local ai = require("mini.ai")

-- Treesitter-based argument text object (see lua/util/ai_argument.lua). Handles
-- nested, multi-line calls correctly (cursor on `bar` in `foo(bar(a,b), ...)`
-- selects `bar(a,b)`) and keeps deletion whitespace-consistent.
local argument = require("util.ai_argument").spec

-- Treesitter text objects use a make-range-aware resolver (see
-- lua/util/ai_treesitter.lua) instead of ai.gen_spec.treesitter, so inner
-- objects defined upstream via `#make-range!` (function.inner, class.inner,
-- loop.inner, conditional.inner) resolve in every language with no per-language
-- override. after/queries only adds what upstream omits entirely (block.inner).
local treesitter = require("util.ai_treesitter").spec

-- Treesitter-backed text objects (queries from nvim-treesitter-textobjects):
--   af/if  function (outer/inner)  -> daf, dif, yaf, cif, vaf, ...
--   ac/ic  class
--   ao/io  block / conditional / loop
--   aa/ia  argument / parameter (treesitter, nesting- & multiline-aware)
ai.setup({
  n_lines = 500,
  custom_textobjects = {
    a = argument,
    f = treesitter({ a = "@function.outer", i = "@function.inner" }),
    c = treesitter({ a = "@class.outer", i = "@class.inner" }),
    o = treesitter({
      a = { "@block.outer", "@conditional.outer", "@loop.outer" },
      i = { "@block.inner", "@conditional.inner", "@loop.inner" },
    }),
  },
})

require("mini.surround").setup({
  mappings = {
    add = "gsa",      -- Add surrounding
    delete = "gsd",   -- Delete surrounding
    find = "gsf",     -- Find surrounding
    find_left = "gsF", -- Find left surrounding
    highlight = "gsh", -- Highlight surrounding
    replace = "gsr",  -- Replace surrounding
  },
})
require("mini.icons").setup()

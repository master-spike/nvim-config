-- nvim-treesitter-textobjects is used ONLY as a source of its
-- queries/<lang>/textobjects.scm files. mini.ai reads them via native
-- vim.treesitter (see lua/plugins/mini.lua). The plugin's own Lua runtime is
-- never loaded: its plugin/*.vim hard-requires the archived nvim-treesitter,
-- so pack.lua installs/pins it with a no-op `load` and we wire it up here.
--
-- Two things are required to consume those query files natively:
--   1. A `make-range!` directive handler. The textobjects queries define their
--      `*.outer`/some `*.inner` objects via `#make-range!`, a directive that
--      nvim-treesitter used to register. Without a handler, vim.treesitter
--      throws "No handler for make-range!" while iterating the query, which
--      breaks ALL textobjects. mini.ai cannot see make-range named ranges
--      anyway (they are not in the query's static capture list), so the inner
--      objects it needs are re-declared as real captures in after/queries.
--   2. Adding the repo to 'runtimepath' so the query files resolve. This is
--      deferred to VimEnter so the broken plugin/*.vim is never sourced during
--      startup's plugin pass. It is prepended so the upstream base queries come
--      before our after/queries overrides (which use `; extends`).

local M = {}

local plug_path = vim.fs.joinpath(vim.fn.stdpath("data"), "site/pack/core/opt/nvim-treesitter-textobjects")

local function register_make_range()
  vim.treesitter.query.add_directive("make-range!", function(match, _, _, directive, metadata)
    local name, start_id, end_id = directive[2], directive[3], directive[4]
    if not (name and start_id and end_id) then
      return
    end
    local start_nodes, end_nodes = match[start_id], match[end_id]
    if not start_nodes or not end_nodes then
      return
    end
    local start_node = type(start_nodes) == "table" and start_nodes[1] or start_nodes
    local end_list = type(end_nodes) == "table" and end_nodes or { end_nodes }
    local end_node = end_list[#end_list]
    if not start_node or not end_node then
      return
    end
    local sr, sc = start_node:start()
    local er, ec = end_node:end_()
    metadata[name] = metadata[name] or {}
    metadata[name].range = { sr, sc, er, ec }
  end, { force = true })
end

register_make_range()

if vim.fn.isdirectory(plug_path) == 1 then
  vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
      if not vim.tbl_contains(vim.opt.runtimepath:get(), plug_path) then
        vim.opt.runtimepath:prepend(plug_path)
      end
    end,
  })
end

return M

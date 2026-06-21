-- treesitter-context: sticky header showing the enclosing scope(s) at the top.
require("treesitter-context").setup({
  max_lines = 3,
  multiline_threshold = 1,
})

-- In tree-sitter-java a declaration node starts at its `modifiers` child, which
-- includes the annotations (@Override, @Service, ...). The plugin pins a
-- context node's start row, so by default Java context pins the annotation
-- lines. Showing the annotations *and* the signature is not viable: the plugin
-- trims header lines from the bottom up, so when a declaration has more
-- annotations than fit it drops the signature and keeps only annotations --
-- the worst outcome. We therefore re-anchor the start to the signature line via
-- the `@context.start` capture (always showing the signature, never the
-- annotations): `type` for methods, `name` for the other declarations.
--
-- The context query is merged additively from the runtimepath and the plugin
-- returns the FIRST matching pattern, so an after/queries override cannot beat
-- the plugin's own class/method patterns -- we must replace the query outright.
-- This inlined copy also adds constructor/record/interface/enum declarations,
-- which the bundled query does not pin.
pcall(vim.treesitter.query.set, "java", "context", [[
  (if_statement
    consequence: (_) @context.end) @context

  (method_declaration
    type: (_) @context.start
    body: (_) @context.end) @context

  (constructor_declaration
    name: (_) @context.start
    body: (_) @context.end) @context

  (for_statement
    body: (_) @context.end) @context

  (enhanced_for_statement
    body: (_) @context.end) @context

  (class_declaration
    name: (_) @context.start
    body: (_) @context.end) @context

  (record_declaration
    name: (_) @context.start
    body: (_) @context.end) @context

  (interface_declaration
    name: (_) @context.start
    body: (_) @context.end) @context

  (enum_declaration
    name: (_) @context.start
    body: (_) @context.end) @context

  (switch_expression) @context

  (switch_block_statement_group) @context

  (expression_statement) @context
]])

-- Jump to the top of the current context (upwards to the enclosing scope).
vim.keymap.set("n", "[c", function()
  require("treesitter-context").go_to_context(vim.v.count1)
end, { silent = true, desc = "Jump to context (upwards)" })

-- Toggle the context window via Snacks, matching the <leader>u toggle convention.
Snacks.toggle
  .new({
    id = "treesitter_context",
    name = "Treesitter Context",
    get = function()
      return require("treesitter-context").enabled()
    end,
    set = function(state)
      require("treesitter-context").toggle()
    end,
  })
  :map("<leader>uc")

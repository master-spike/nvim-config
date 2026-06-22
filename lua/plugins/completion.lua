-- Completion via blink.cmp
require("blink.cmp").setup({
  keymap = {
    preset = "default",
    -- Tab shows the menu and cycles forward through suggestions; Shift-Tab
    -- cycles backward. auto_insert (below) lets you keep typing after.
    ["<Tab>"] = { "show_and_insert", "select_next" },
    ["<S-Tab>"] = { "show_and_insert", "select_prev" },
  },
  appearance = { nerd_font_variant = "mono" },
  completion = {
    -- Don't preselect, and insert the highlighted item as you cycle so you
    -- can continue typing (or accept with <CR>/<C-y>, cancel with <C-e>).
    list = {
      selection = { preselect = false, auto_insert = true },
    },
    documentation = { auto_show = true, auto_show_delay_ms = 200 },
  },
  sources = {
    default = { "lsp", "path", "snippets", "akka", "buffer" },
    providers = {
      -- Akka Java SDK snippets that deduce the package from the file path.
      akka = { name = "Akka", module = "util.akka_snippets" },
    },
  },
  signature = { enabled = true },
})

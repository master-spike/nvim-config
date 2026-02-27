-- Configure Prettier for Markdown formatting with 80 char limit
return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        markdown = { "prettier" },
      },
      formatters = {
        prettier = {
          prepend_args = {
            "--prose-wrap", "always",
            "--print-width", "80",
          },
        },
      },
    },
  },
}

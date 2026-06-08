return {
  "folke/snacks.nvim",
  opts = {
    image = {
      enabled = true,
      doc = {
        conceal = false,
        enabled = true,
        inline = true,
        float = true,
      },
    },
  },
  init = function()
    vim.api.nvim_create_autocmd("User", {
      pattern = "VeryLazy",
      callback = function()
        -- Direct patch: opts merge doesn't reliably override function→false.
        -- inline.lua reads Snacks.image.config.doc.conceal on every update()
        -- so patching here is picked up for all subsequent renders.
        if Snacks and Snacks.image and Snacks.image.config then
          Snacks.image.config.doc.conceal = false
        end
      end,
    })
  end,
}

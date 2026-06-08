-- snacks.nvim (image support ported from previous config)
require("snacks").setup({
  image = {
    enabled = true,
    doc = {
      conceal = false,
      enabled = true,
      inline = true,
      float = true,
    },
  },
})

-- Direct patch: doc.conceal is read on every image update; force it off
-- for all subsequent renders (ported from previous snacks-image.lua).
if Snacks and Snacks.image and Snacks.image.config then
  Snacks.image.config.doc.conceal = false
end

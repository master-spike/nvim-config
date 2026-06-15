require("js-i18n").setup({
  -- Client-side (Neovim-specific) settings
  virt_text = {
    enabled = true, -- Show translation virtual text (toggle with <leader>ut)
    format = function(text, opts)
      text = text:sub(1, 60) -- truncate long translations
      return text
    end,
    conceal_key = false,
    max_length = 0,
    max_width = 60,
  },

  -- Server settings
  -- Can also be configured via .js-i18n.json file (which takes priority)
  server = {
    cmd = { "js-i18n-language-server" }, -- Server command
    translation_files = { file_pattern = "**/i18n/messages/**/*.json" },
    key_separator = ".",
    namespace_separator = nil,
    default_namespace = "common",
    primary_languages = nil,
    required_languages = nil,
    optional_languages = nil,
    diagnostics = { unused_keys = false },
  },
})

-- The plugin wraps virtual text in the `@i18n.translation` highlight group.
-- Link it to LspInlayHint so translations match inlay-hint styling, and
-- re-apply on colorscheme changes (which would otherwise clear the link).
local function set_i18n_hl()
  vim.api.nvim_set_hl(0, "@i18n.translation", { link = "LspInlayHint" })
end
set_i18n_hl()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("I18nTranslationHl", { clear = true }),
  callback = set_i18n_hl,
})

-- Global toggle for translation virtual text, with a which-key switch
-- indicator (enabled/disabled icon + color) via Snacks.toggle.
Snacks.toggle
  .new({
    id = "i18n_virt_text",
    name = "Translations",
    get = function()
      return require("js-i18n.config").config.virt_text.enabled
    end,
    set = function(state)
      vim.cmd(state and "I18nVirtualTextEnable" or "I18nVirtualTextDisable")
    end,
  })
  :map("<leader>ut")

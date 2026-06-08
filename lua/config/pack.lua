-- Plugin management via Neovim 0.12 builtin vim.pack.
-- Plugins are cloned into stdpath('data')/site/pack/core/opt and added to rtp.

vim.pack.add({
  -- Library / icons
  { src = "https://github.com/nvim-lua/plenary.nvim" },
  { src = "https://github.com/nvim-tree/nvim-web-devicons" },
  { src = "https://github.com/MunifTanjim/nui.nvim" },

  -- Colorschemes
  { src = "https://github.com/ellisonleao/gruvbox.nvim" },
  { src = "https://github.com/EdenEast/nightfox.nvim" },

  -- Treesitter (master branch = classic setup API, stable on 0.12)
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "master" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "master" },

  -- Fuzzy finder
  { src = "https://github.com/nvim-telescope/telescope.nvim" },
  { src = "https://github.com/nvim-telescope/telescope-fzf-native.nvim" },

  -- LSP / tooling
  { src = "https://github.com/neovim/nvim-lspconfig" },
  { src = "https://github.com/mason-org/mason.nvim" },
  { src = "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim" },

  -- Completion
  { src = "https://github.com/saghen/blink.cmp", version = "v1.6.0" },

  -- Formatting / linting
  { src = "https://github.com/stevearc/conform.nvim" },
  { src = "https://github.com/mfussenegger/nvim-lint" },

  -- Editing / UI
  { src = "https://github.com/echasnovski/mini.nvim" },
  { src = "https://github.com/lewis6991/gitsigns.nvim" },
  { src = "https://github.com/nvim-lualine/lualine.nvim" },
  { src = "https://github.com/akinsho/bufferline.nvim" },
  { src = "https://github.com/folke/trouble.nvim" },
  { src = "https://github.com/folke/which-key.nvim" },
  { src = "https://github.com/folke/snacks.nvim" },

  -- Neo-tree
  {
    src = "https://github.com/nvim-neo-tree/neo-tree.nvim",
    version = vim.version.range("3"),
  },
  -- Filetype / integrations
  { src = "https://github.com/mfussenegger/nvim-jdtls" },
  { src = "https://github.com/MeanderingProgrammer/render-markdown.nvim" },
  { src = "https://github.com/pwntester/octo.nvim" },
  { src = "https://github.com/christoomey/vim-tmux-navigator" },
  { src = "https://github.com/master-spike/minesweeper-nvim" },

  -- AI
  { src = "https://github.com/nvim-lua/plenary.nvim" },
  { src = "https://github.com/j-hui/fidget.nvim" },
  { src = "https://github.com/olimorris/codecompanion.nvim" },
})

-- Build step for telescope-fzf-native (compiles a C library).
local fzf_dir = vim.fn.stdpath("data") .. "/site/pack/core/opt/telescope-fzf-native.nvim"
if vim.fn.isdirectory(fzf_dir) == 1 and vim.fn.filereadable(fzf_dir .. "/build/libfzf.so") == 0 then
  if vim.fn.executable("make") == 1 then
    vim.fn.system({ "make", "-C", fzf_dir })
  end
end

-- Load per-plugin setup modules (each does its own require().setup()).
local modules = {
  "colorscheme",
  "treesitter",
  "telescope",
  "completion",
  "mason",
  "conform",
  "lint",
  "mini",
  "gitsigns",
  "lualine",
  "bufferline",
  "trouble",
  "whichkey",
  "snacks",
  "render-markdown",
  "octo",
  "jdtls",
  "tmux-navigator",
  "minesweeper",
  "fidget",
  "codecompanion",
  "neo-tree",
}

for _, m in ipairs(modules) do
  local ok, err = pcall(require, "plugins." .. m)
  if not ok then
    vim.notify("Failed to load plugin module '" .. m .. "': " .. err, vim.log.levels.ERROR)
  end
end

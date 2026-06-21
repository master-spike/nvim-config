-- Plugin management via Neovim 0.12 builtin vim.pack.
-- Plugins are cloned into stdpath('data')/site/pack/core/opt and added to rtp.

-- Self-heal stray non-git directories under the pack opt dir.
-- vim.pack's lock_sync() traverses EVERY entry in opt/ on startup and, for any
-- directory missing git metadata, calls lock_repair() which runs `git` inside
-- it and aborts init with a fatal "not a git repository" error. Every real
-- vim.pack plugin is a git clone (has .git); parsers from tree-sitter-manager
-- live under site/parser, never here. So any non-git directory in opt/ is stray
-- junk (e.g. a leftover `nvim-treesitter/parser` from the removed plugin) and is
-- safe to delete. Removing it here keeps startup resilient to recurrence.
local opt_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "site/pack/core/opt")
for name, fs_type in vim.fs.dir(opt_dir) do
  if fs_type == "directory" then
    local path = vim.fs.joinpath(opt_dir, name)
    if vim.uv.fs_stat(vim.fs.joinpath(path, ".git")) == nil then
      vim.fs.rm(path, { recursive = true, force = true })
    end
  end
end

vim.pack.add({
  -- Library / icons
  { src = "https://github.com/nvim-lua/plenary.nvim" },
  { src = "https://github.com/nvim-tree/nvim-web-devicons" },
  { src = "https://github.com/MunifTanjim/nui.nvim" },

  -- Colorschemes
  { src = "https://github.com/marko-cerovac/material.nvim" },

  -- Treesitter parser management (native vim.treesitter; no nvim-treesitter).
  -- tree-sitter-manager installs parsers + bundles highlight queries.
  { src = "https://github.com/romus204/tree-sitter-manager.nvim" },

  -- Fuzzy finder
  { src = "https://github.com/nvim-telescope/telescope.nvim" },
  { src = "https://github.com/nvim-telescope/telescope-fzf-native.nvim" },
  { src = "https://github.com/nvim-telescope/telescope-ui-select.nvim" },

  -- LSP / tooling
  { src = "https://github.com/neovim/nvim-lspconfig" },
  { src = "https://github.com/mason-org/mason.nvim" },
  { src = "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim" },
  { src = "https://github.com/nabekou29/js-i18n.nvim" },

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
  { src = "https://github.com/folke/flash.nvim" },
  { src = "https://github.com/norcalli/nvim-colorizer.lua" },
  { src = "https://github.com/Isrothy/neominimap.nvim" },
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
  { src = "https://github.com/master-spike/99", version = "dev" },
})

-- nvim-treesitter-textobjects is installed and pinned only as a source of its
-- queries/<lang>/textobjects.scm files (mini.ai consumes them via native
-- vim.treesitter). Its Lua runtime is NEVER loaded: its plugin/*.vim
-- hard-requires the removed nvim-treesitter and would error on startup. The
-- callable `load` makes vim.pack install + pin it without sourcing it; the
-- lua/plugins/treesitter-textobjects.lua module registers the make-range!
-- directive and adds the repo to 'runtimepath' after startup.
vim.pack.add({
  { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "master" },
}, {
  load = function() end,
})

-- Load the local development copy of 99 from pack/mine/opt/99.
-- vim.cmd.packadd("99")

-- Build step for telescope-fzf-native (compiles a C library).
local fzf_dir = vim.fn.stdpath("data") .. "/site/pack/core/opt/telescope-fzf-native.nvim"
if vim.fn.isdirectory(fzf_dir) == 1 and vim.fn.filereadable(fzf_dir .. "/build/libfzf.so") == 0 then
  if vim.fn.executable("make") == 1 then
    vim.fn.system({ "make", "-C", fzf_dir })
  end
end

-- Load per-plugin setup modules (each does its own require().setup()).
local modules = {
  "99",
  "colorscheme",
  "tree-sitter-manager",
  "treesitter-textobjects",
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
  "flash",
  "colorizer",
  "render-markdown",
  "octo",
  "jdtls",
  "tmux-navigator",
  "minesweeper",
  "fidget",
  "neo-tree",
  "js-i18n",
}

for _, m in ipairs(modules) do
  local ok, err = pcall(require, "plugins." .. m)
  if not ok then
    vim.notify("Failed to load plugin module '" .. m .. "': " .. err, vim.log.levels.ERROR)
  end
end

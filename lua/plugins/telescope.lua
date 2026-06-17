-- Telescope + fzf-native
local telescope = require("telescope")
local path_util = require("util.path")

telescope.setup({
  defaults = {
    layout_strategy = "horizontal",
    layout_config = { prompt_position = "top" },
    sorting_strategy = "ascending",
    winblend = 0,
    -- Minify paths in every picker that displays a filepath (find_files,
    -- live_grep, oldfiles, lsp, quickfix, ...) using the same collapsing rule
    -- as the lualine statusline. path_display returns the string to render plus
    -- an optional style table; we colour the final filename component (the part
    -- after the last "/") with TelescopeResultsFileName (orange, defined in
    -- colorscheme.lua) and leave the directory prefix in the default colour. Style entries are
    -- { { byte_start, byte_end }, hl_group } with 0-based, end-exclusive cols.
    path_display = function(_, path)
      local collapsed = path_util.collapse(path)
      local filename = collapsed:match("[^/]+$") or collapsed
      local start = #collapsed - #filename
      return collapsed, { { { start, #collapsed }, "TelescopeResultsFileName" } }
    end,
  },
  extensions = {
    fzf = {},
    ["ui-select"] = {
      require("telescope.themes").get_dropdown({}),
    },
  },
})

pcall(telescope.load_extension, "fzf")
pcall(telescope.load_extension, "ui-select")

-- Custom find_files / live_grep with one shared toggle:
--   * include_ignored: when true, gitignored files are also searched. Toggled
--     with <C-y> in BOTH find_files and live_grep (re-runs the picker).
-- Dotfiles are ALWAYS searched (git ls-files lists them; live_grep gets
-- --hidden), so there is intentionally no hidden-file toggle.
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local include_ignored = false

-- find_files command: tracked + untracked, dotfiles included. Dropping
-- --exclude-standard makes git list ignored files too.
local function files_command()
  local cmd = { "git", "ls-files", "--cached", "--others" }
  if not include_ignored then
    table.insert(cmd, "--exclude-standard")
  end
  return cmd
end

-- Extra ripgrep args for live_grep: always include hidden files but never
-- descend into .git; --no-ignore additionally pulls in gitignored files.
local function grep_additional_args()
  local args = { "--hidden", "--glob", "!**/.git/**" }
  if include_ignored then
    table.insert(args, "--no-ignore")
  end
  return args
end

local function live_grep(opts)
  opts = opts or {}
  opts.additional_args = grep_additional_args
  opts.prompt_title = include_ignored and "Live Grep (+ignored)" or "Live Grep"
  opts.attach_mappings = function(_, map_local)
    local function toggle_ignored(prompt_bufnr)
      local line = action_state.get_current_line()
      include_ignored = not include_ignored
      actions.close(prompt_bufnr)
      vim.schedule(function()
        live_grep({ default_text = line })
      end)
    end
    map_local("i", "<C-y>", toggle_ignored)
    map_local("n", "<C-y>", toggle_ignored)
    return true
  end
  require("telescope.builtin").live_grep(opts)
end

local function find_files(opts)
  opts = opts or {}
  opts.find_command = files_command()
  opts.prompt_title = include_ignored and "Find Files (+ignored)" or "Find Files"
  opts.attach_mappings = function(_, map_local)
    local function toggle_ignored(prompt_bufnr)
      local line = action_state.get_current_line()
      include_ignored = not include_ignored
      actions.close(prompt_bufnr)
      vim.schedule(function()
        find_files({ default_text = line })
      end)
    end
    map_local("i", "<C-y>", toggle_ignored)
    map_local("n", "<C-y>", toggle_ignored)
    return true
  end
  require("telescope.builtin").find_files(opts)
end

local builtin = require("telescope.builtin")
local map = vim.keymap.set
map("n", "<leader><space>", find_files, { desc = "Find files" })
map("n", "<leader>ff", find_files, { desc = "Find files" })
map("n", "<leader>f/", live_grep, { desc = "Grep" })
map("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })
map("n", "<leader>fh", builtin.help_tags, { desc = "Help" })
map("n", "<leader>fr", builtin.oldfiles, { desc = "Recent files" })
map("n", "<leader>sg", live_grep, { desc = "Grep" })
map("n", "<leader>sk", builtin.keymaps, { desc = "Keymaps" })

-- Define rules exactly how you want them in standard YAML format
local vacuum_ruleset_content = [=[
extends: [[vacuum:oas, recommended]]
rules:
  oas3-missing-example: false
  component-description: false
  operation-description: false
  oas3-parameter-description: false
  oas2-parameter-description: false
]=]

-- Establish a path in Neovim's cache directory to avoid cluttering your project
local cache_dir = vim.fn.stdpath("cache")
local global_ruleset_path = cache_dir .. "/vacuum-embedded-rules.yaml"

-- Write the configuration directly out to the filesystem on boot
local file = io.open(global_ruleset_path, "w")
if file then
  file:write(vacuum_ruleset_content)
  file:close()
end

return {
  -- 1. Ensure Mason installs vacuum
  {
    "mason/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "vacuum", "yaml-language-server" })
    end,
  },

  -- 2. Tell LazyVim's LSP handler to set up vacuum and yamlls
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      -- Configure Vacuum Linter
      opts.servers.vacuum = {
        cmd = { "vacuum", "language-server", "--ruleset", global_ruleset_path },
        filetypes = { "yaml", "json" },
      }
      -- Safely inject into existing Yamlls configs without breaking standard schemas
      opts.servers.yamlls = vim.tbl_deep_extend("force", opts.servers.yamlls or {}, {
        filetypes = { "yaml" },
        settings = {
          yaml = {
            validate = true,
            completion = true,
            schemas = {
              -- OpenAPI 3.x Specs
              ["https://www.schemastore.org/openapi-3.X.json"] = {
                "openapi.json",
                "openapi.yml",
                "openapi.yaml",
                "*openapi*.yaml",
                "*openapi*.yml",
              },

              -- OpenAPI 2.0 / Swagger Specs
              ["https://spec.openapis.org/oas/2.0/schema/2017-08-27"] = {
                "swagger.json",
                "swagger.yml",
                "swagger.yaml",
                "*swagger*.yaml",
                "*swagger*.yml",
              },

              -- OpenAPI Arazzo Specs (Optional but helpful addition)
              ["https://www.schemastore.org/openapi-arazzo-1.X.json"] = {
                "arazzo.json",
                "arazzo.yml",
                "arazzo.yaml",
              },
            },
          },
        },
      })
    end,
  },
}

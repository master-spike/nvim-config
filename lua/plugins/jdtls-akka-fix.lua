-- Fix jdtls output directories to prevent interference with Maven builds.
--
-- Problem: jdtls writes compiled classes to target/classes (same as Maven).
-- When jdtls does incremental builds, it can delete META-INF files that
-- Akka's annotation processor generated, breaking entity discovery.
--
-- Solution: Redirect jdtls output to target/jdtls-classes so it never
-- touches Maven's target/classes. Also enable annotation processing
-- so jdtls can properly understand Akka components.

local function fix_jdtls_project_settings(root_dir)
  if not root_dir then
    return
  end

  -- Find all subproject .classpath files
  local modules = vim.fn.glob(root_dir .. "/*/.classpath", false, true)
  for _, classpath_file in ipairs(modules) do
    local content = vim.fn.readfile(classpath_file)
    local modified = false
    for i, line in ipairs(content) do
      -- Redirect output directories away from Maven's target/classes
      if line:find('output="target/classes"') then
        content[i] = line:gsub('output="target/classes"', 'output="target/jdtls%-classes"')
        modified = true
      end
      if line:find('output="target/test%-classes"') then
        content[i] = line:gsub('output="target/test%-classes"', 'output="target/jdtls%-test%-classes"')
        modified = true
      end
      if line:find('path="target/classes"/>') then
        content[i] = line:gsub('path="target/classes"/>', 'path="target/jdtls%-classes"/>')
        modified = true
      end
    end
    if modified then
      vim.fn.writefile(content, classpath_file)
    end
  end

  -- Enable annotation processing in all subproject .settings
  local apt_prefs = vim.fn.glob(root_dir .. "/*/.settings/org.eclipse.jdt.apt.core.prefs", false, true)
  for _, prefs_file in ipairs(apt_prefs) do
    local content = vim.fn.readfile(prefs_file)
    for i, line in ipairs(content) do
      if line:find("org.eclipse.jdt.apt.aptEnabled=false") then
        content[i] = "org.eclipse.jdt.apt.aptEnabled=true"
      end
    end
    vim.fn.writefile(content, prefs_file)
  end

  local core_prefs = vim.fn.glob(root_dir .. "/*/.settings/org.eclipse.jdt.core.prefs", false, true)
  for _, prefs_file in ipairs(core_prefs) do
    local content = vim.fn.readfile(prefs_file)
    for i, line in ipairs(content) do
      if line:find("org.eclipse.jdt.core.compiler.processAnnotations=disabled") then
        content[i] = "org.eclipse.jdt.core.compiler.processAnnotations=enabled"
      end
    end
    vim.fn.writefile(content, prefs_file)
  end
end

return {
  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      -- Prevent jdtls from auto-regenerating .classpath on POM changes
      opts.settings = vim.tbl_deep_extend("force", opts.settings or {}, {
        java = {
          configuration = {
            updateBuildConfiguration = "interactive",
          },
        },
      })

      -- Hook into jdtls startup to fix project settings
      local original_on_attach = opts.on_attach
      opts.on_attach = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client and client.name == "jdtls" then
          -- Delay to let jdtls finish generating .classpath files
          vim.defer_fn(function()
            fix_jdtls_project_settings(client.root_dir)
          end, 5000)
        end
        if original_on_attach then
          original_on_attach(args)
        end
      end

      return opts
    end,
  },
}

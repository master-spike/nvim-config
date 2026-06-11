-- Native nvim-jdtls setup (replaces the LazyVim java extra + jdtls-akka-fix).
local ok, jdtls = pcall(require, "jdtls")
if not ok then
  return
end

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

local root_markers = {
  ".git",
  "mvnw",
  "gradlew",
  "pom.xml",
  "build.gradle",
  "build.gradle.kts",
  "settings.gradle",
  "settings.gradle.kts",
}

local jdtls_bin = vim.fn.stdpath("data") .. "/mason/bin/jdtls"

local function on_attach(client, bufnr)
  -- jdtls-specific keymaps (core LSP keymaps come from config/lsp.lua LspAttach)
  local function map(keys, fn, desc)
    vim.keymap.set("n", keys, fn, { buffer = bufnr, desc = "Java: " .. desc })
  end
  map("<leader>jo", jdtls.organize_imports, "Organize Imports")
  map("<leader>jv", jdtls.extract_variable, "Extract Variable")
  map("<leader>jc", jdtls.extract_constant, "Extract Constant")

  -- Delay to let jdtls finish generating .classpath files, then apply the
  -- Akka/Maven output-directory fix.
  vim.defer_fn(function()
    fix_jdtls_project_settings(client.root_dir)
  end, 5000)
end

local function start_jdtls()
  local root_dir = vim.fs.root(0, root_markers)
  if not root_dir then
    return
  end

  -- Unique workspace data dir per project.
  local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
  local workspace_dir = vim.fn.stdpath("cache") .. "/jdtls/workspace/" .. project_name

  local capabilities
  local ok_blink, blink = pcall(require, "blink.cmp")
  if ok_blink then
    capabilities = blink.get_lsp_capabilities()
  end

  jdtls.start_or_attach({
    cmd = { jdtls_bin, "-data", workspace_dir },
    root_dir = root_dir,
    capabilities = capabilities,
    on_attach = on_attach,
    settings = {
      java = {
        -- Prevent jdtls from auto-regenerating .classpath on POM changes
        configuration = {
          updateBuildConfiguration = "interactive",
        },
        -- Inlay hints: show parameter names for all arguments. JDT LS's "all"
        -- mode already suppresses the hint when the argument is a name/field
        -- matching the parameter name (no separate suppress flag exists).
        inlayHints = {
          parameterNames = {
            enabled = "all",
          },
        },
      },
    },
  })
end

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("config_jdtls", { clear = true }),
  pattern = "java",
  callback = start_jdtls,
})

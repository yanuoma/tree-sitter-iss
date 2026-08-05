-- Neovim integration for the Inno Setup grammar.
--
-- This file is sourced automatically once the repository is on the
-- runtimepath, which is what a plugin manager does for you. It exists so that
-- installing this grammar takes no configuration at all:
--
--     { "yanuoma/tree-sitter-iss", version = "*",
--       dependencies = { "nvim-treesitter/nvim-treesitter" } }
--
-- It registers the parser with nvim-treesitter, pointing at this checkout, and
-- installs both `iss` and `pascal`. Pascal is not optional: a [Code] section is
-- a whole Pascal program and queries/injections.scm delegates it, so without
-- that parser roughly two fifths of a typical script renders as plain text.
--
-- Set `vim.g.tree_sitter_iss_auto_install = false` before the plugin loads to
-- skip the install and register the parser only.

if vim.g.loaded_tree_sitter_iss then
  return
end
vim.g.loaded_tree_sitter_iss = true

if not pcall(require, "nvim-treesitter") then
  return
end

-- Directory holding this checkout: <root>/plugin/<this file>.
local root = vim.fs.normalize(vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h"))

-- Resolve the revision once, here, where a synchronous call is safe.
-- nvim-treesitter fires User TSUpdate from inside an async coroutine, and
-- vim.fn.* raises in that context, which would abort registration and surface
-- as a confusing "skipping unsupported language" rather than a real error.
local revision
if vim.uv.fs_stat(root .. "/.git") then
  local out = vim.fn.system({ "git", "-C", root, "rev-parse", "HEAD" })
  revision = vim.v.shell_error == 0 and vim.trim(out) or nil
end

local function register()
  local ok, parsers = pcall(require, "nvim-treesitter.parsers")
  if not ok then
    return
  end
  -- Compile from this checkout rather than from a URL, so the parser always
  -- matches the revision the plugin manager resolved. `queries` is linked from
  -- the same checkout, so the queries cannot drift from the parser. Recording
  -- the revision is what lets nvim-treesitter notice a stale parser after an
  -- update and rebuild it.
  parsers.iss = {
    install_info = {
      path = root,
      queries = "queries",
      revision = revision,
    },
    tier = 3,
  }
end

-- nvim-treesitter's install and update both call reload_parsers(), which clears
-- package.loaded for the parser table and re-requires it. That discards any
-- direct assignment, so registering once is not enough: it also has to happen
-- on the User TSUpdate event that reload_parsers() fires immediately after.
vim.api.nvim_create_autocmd("User", {
  pattern = "TSUpdate",
  group = vim.api.nvim_create_augroup("TreeSitterIssRegister", { clear = true }),
  callback = register,
})
register()

if vim.g.tree_sitter_iss_auto_install ~= false then
  -- Already-installed parsers are skipped, so this is a no-op after the first
  -- run; a version bump is picked up through the recorded revision.
  pcall(function()
    require("nvim-treesitter").install({ "iss", "pascal" })
  end)
end

-- Neovim already maps *.iss and *.isl to the `iss` filetype, and the parser
-- shares that name, so no vim.treesitter.language.register call is needed.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "iss",
  group = vim.api.nvim_create_augroup("TreeSitterIssStart", { clear = true }),
  callback = function()
    pcall(vim.treesitter.start)
  end,
})

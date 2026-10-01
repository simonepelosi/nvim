-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- ty is a new-style nvim 0.11+ LSP server (lsp/ty.lua); must be enabled via
-- vim.lsp.enable(), not through lspconfig's servers table.
vim.lsp.enable("ty")

-- rlsp-yaml: Rust YAML LSP (not in nvim-lspconfig yet, new-style config).
-- Install: cargo install rlsp-yaml
vim.lsp.config("rlsp-yaml", {
  cmd = { "rlsp-yaml" },
  filetypes = { "yaml" },
  root_markers = { ".git" },
  init_options = {
    schemaStore = true,
  },
})
vim.lsp.enable("rlsp-yaml")

-- shuck: Rust shell (bash/sh) linter/formatter/LSP, replaces Node
-- bash-language-server (disabled in overrides.lua).
-- Install: cargo install shuck-cli  (binary is `shuck`, subcommand `server`)
vim.lsp.config("shuck", {
  cmd = { "shuck", "server" },
  filetypes = { "sh", "bash" },
  root_markers = { ".git" },
})
vim.lsp.enable("shuck")

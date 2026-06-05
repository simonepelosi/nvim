return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        update_in_insert = false,
      },
      servers = {
        -- Python: Node.js pyright replaced by Rust ty.
        -- ty is a new-style server; enabled via vim.lsp.enable() in autocmds.lua
        pyright = { enabled = false },
        basedpyright = { enabled = false },

        -- JSON: vscode-json-language-server is Node.js; treesitter covers syntax.
        -- SchemaStore.nvim stays installed but goes dormant — no harm.
        jsonls = { enabled = false },

        -- YAML: yaml-language-server is Node.js.
        -- Re-enable if you need schema validation for K8s / GitHub Actions files.
        yamlls = { enabled = false },
      },
    },
  },

  -- Accept completions with Tab (like VS Code)
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        preset = "default",
        ["<Tab>"] = { "accept", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "fallback" },
      },
    },
  },

  -- Disable linting on save (remove BufWritePost trigger)
  {
    "mfussenegger/nvim-lint",
    opts = {
      events = { "BufReadPost", "InsertLeave" },
    },
  },
}

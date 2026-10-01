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

        -- Bash: bash-language-server is Node.js; replaced by Rust `shuck`
        -- (enabled via vim.lsp.enable() in autocmds.lua).
        bashls = { enabled = false },
      },
    },
  },

  -- Markdown: drop Node-based prettier/markdownlint-cli2/markdown-toc.
  -- Rust alternative: install `dprint` + `dprint-plugin-markdown` and add
  -- `dprint.json` to a project, then set formatters_by_ft.markdown = {"dprint"}.
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        markdown = {},
        ["markdown.mdx"] = {},
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        markdown = {},
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = vim.tbl_filter(function(name)
        return name ~= "markdownlint-cli2" and name ~= "markdown-toc"
      end, opts.ensure_installed)
    end,
  },

  -- Node/yarn-built browser preview; redundant with render-markdown.nvim
  -- (already installed, pure Lua in-buffer rendering).
  { "iamcco/markdown-preview.nvim", enabled = false },

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

return {
  -- Stop pyright from spamming messages while typing
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        update_in_insert = false,
      },
      servers = {
        pyright = {
          handlers = {
            ["$/progress"] = function() end,
            ["window/showMessage"] = function() end,
          },
        },
        basedpyright = {
          handlers = {
            ["$/progress"] = function() end,
            ["window/showMessage"] = function() end,
          },
        },
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

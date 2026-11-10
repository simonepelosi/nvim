return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        update_in_insert = false,
      },
      inlay_hints = { enabled = false },
      codelens = { enabled = false },
      servers = {
        -- Disable Node.js, .NET (C#), and heavy C++/Lua servers
        pyright = { enabled = false },
        basedpyright = { enabled = false },
        jsonls = { enabled = false },
        yamlls = { enabled = false },
        bashls = { enabled = false },
        marksman = { enabled = false }, -- .NET C# server from lang.markdown extra
        lua_ls = { enabled = false }, -- Replaced by Rust emmylua_ls
        dprint = { enabled = false }, -- Formatter via conform.nvim only; don't run as persistent LSP daemon

        -- Lua: emmylua_ls (Rust, ~5x lower RAM than lua_ls, supported by lazydev.nvim)
        emmylua_ls = {
          settings = {
            emmylua = {
              runtime = { version = "LuaJIT" },
              diagnostics = { globals = { "vim", "Snacks", "LazyVim" } },
              codeLens = { enable = false },
              hint = { enable = false },
            },
          },
        },

        -- Python: ty (Rust, Astral) + ruff (Rust, Astral) from ~/.local/bin
        ty = { mason = false },
        ruff = { mason = false },

        -- Markdown: rumdl (Rust Markdown linter/formatter LSP)
        rumdl = {},

        -- YAML: rlsp-yaml (Rust, installed via cargo in ~/.cargo/bin)
        ["rlsp-yaml"] = {
          mason = false,
          cmd = { "rlsp-yaml" },
          filetypes = { "yaml", "yaml.docker-compose", "yaml.gitlab" },
          root_markers = { ".git" },
          init_options = { schemaStore = true },
        },

        -- Shell/Bash: shuck (Rust linter/formatter/LSP, installed via cargo in ~/.cargo/bin)
        shuck = {
          mason = false,
          cmd = { "shuck", "server" },
          filetypes = { "sh", "bash" },
          root_markers = { ".git" },
        },

        -- Go: gopls handles LSP + staticcheck (linter) + gofumpt (formatter) in-process
        gopls = {
          init_options = {
            semanticTokens = false, -- Treesitter handles highlighting; saves gopls RAM/CPU
          },
          settings = {
            gopls = {
              gofumpt = true,
              staticcheck = true,
              completeUnimported = true,
              usePlaceholders = false,
              analyses = {
                nilness = true,
                unusedparams = true,
                unusedwrite = true,
                useany = true,
                unusedvariable = true,
                shadow = true,
              },
              directoryFilters = { "-.git", "-.vscode", "-.idea", "-.vscode-test", "-node_modules" },
            },
          },
        },

        -- Rust: rust-analyzer (from ~/.cargo/bin) with clippy + rustfmt + low-RAM profile
        rust_analyzer = {
          mason = false,
          settings = {
            ["rust-analyzer"] = {
              cachePriming = { enable = false }, -- Prevent background full-crate graph indexing spike
              checkOnSave = true,
              check = {
                command = "clippy",
                extraArgs = { "--no-deps" },
              },
              cargo = {
                allFeatures = true,
                loadOutDirsFromCheck = false,
                buildScripts = { enable = false },
              },
              procMacro = { enable = true },
              files = {
                watcher = "client",
                exclude = {
                  ".direnv",
                  ".git",
                  ".jj",
                  ".github",
                  ".gitlab",
                  "bin",
                  "node_modules",
                  "target",
                  "venv",
                  ".venv",
                },
              },
            },
          },
        },
      },
    },
  },

  -- Formatters: use pure Rust tools (stylua, rumdl, dprint, taplo, shuck LSP)
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        markdown = { "rumdl" },
        ["markdown.mdx"] = { "rumdl" },
        json = { "dprint" },
        jsonc = { "dprint" },
        sh = {}, -- handled by shuck LSP
        go = {}, -- handled in-process by gopls (gofumpt = true)
        rust = { "rustfmt" },
      },
    },
  },

  -- Disable linting on save; run golangci-lint ONLY in repos with .golangci.* config
  {
    "mfussenegger/nvim-lint",
    opts = {
      events = { "BufReadPost", "InsertLeave" },
      linters_by_ft = {
        markdown = {}, -- handled by rumdl LSP in Rust
        go = { "golangcilint" },
      },
      linters = {
        golangcilint = {
          condition = function(ctx)
            return vim.fs.find(
              { ".golangci.yml", ".golangci.yaml", ".golangci.toml", ".golangci.json" },
              { path = ctx.filename, upward = true }
            )[1] ~= nil
          end,
        },
      },
    },
  },

  -- Ensure rust and ron Treesitter parsers are installed
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "rust", "ron" },
    },
  },

  -- Keep Mason filter intact
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      local exclude = {
        "markdownlint-cli2",
        "markdown-toc",
        "shellcheck",
        "shfmt",
        "pyright",
        "json-lsp",
        "yaml-language-server",
        "bash-language-server",
        "marksman",
        "lua-language-server",
        "ruff",
        "gofumpt",
        "goimports",
      }
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "emmylua_ls",
        "rumdl",
        "dprint",
        "golangci-lint",
      })
      opts.ensure_installed = vim.tbl_filter(function(name)
        return not vim.tbl_contains(exclude, name)
      end, opts.ensure_installed)
    end,
  },

  -- Disable unused colorschemes and redundant Node/Lua plugins
  { "iamcco/markdown-preview.nvim", enabled = false },
  { "catppuccin/nvim", enabled = false },
  { "folke/tokyonight.nvim", enabled = false },
  { "b0o/SchemaStore.nvim", enabled = false },

  -- Blink.cmp: enforce prebuilt Rust fuzzy matcher (`libblink_cmp_fuzzy.so`) and Tab accept
  {
    "saghen/blink.cmp",
    opts = {
      fuzzy = {
        implementation = "prefer_rust_with_warning",
      },
      keymap = {
        preset = "default",
        ["<Tab>"] = { "accept", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "fallback" },
      },
    },
  },

  -- Snacks: disable smooth-scrolling animation timers to save CPU/frame ticks
  {
    "folke/snacks.nvim",
    opts = {
      scroll = { enabled = false },
    },
  },
}

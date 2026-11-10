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
        ["*"] = {
          keys = {
            { "gr", function() Snacks.picker.lsp_references() end, nowait = true, desc = "References", has = "references" },
          },
        },
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
          init_options = {
            schemaStore = true,
            flowStyle = "off", -- allow inline `{ from: x, to: y }` flow mappings without warning spam
          },
          settings = {
            schemaStore = true,
            flowStyle = "off",
          },
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

        -- Terraform / HCL: terraform-ls handles LSP, validation, and formatting in-process
        terraformls = {
          init_options = {
            terraform = {
              path = vim.fn.expand("~/.local/bin/terraform-ls-tf"),
            },
            experimentalFeatures = {
              validateOnSave = false, -- avoid spawning heavy `terraform validate` on save
              prefillRequiredFields = true,
            },
          },
          keys = {
            {
              "gd",
              function()
                local c = vim.lsp.get_clients({ bufnr = 0, name = "terraformls" })[1]
                if c then
                  local params = vim.lsp.util.make_position_params(0, c.offset_encoding)
                  local resp = c:request_sync("textDocument/definition", params, 600, 0)
                  if resp and resp.result and not vim.tbl_isempty(resp.result) then
                    vim.lsp.util.show_document(resp.result[1], c.offset_encoding, { focus = true })
                    return
                  end
                end
                -- Fallback for uninitialized directories (no .terraform) or "${local.foo}" strings:
                -- search for `variable "word"`, `output "word"`, `resource "..." "word"`, `data "..." "word"`, or `word =` across *.tf in module dir
                local is_kw = vim.bo.iskeyword
                vim.bo.iskeyword = is_kw .. ",-"
                local word = vim.fn.expand("<cword>")
                vim.bo.iskeyword = is_kw
                if word == "" then
                  return
                end
                local dir = vim.fn.expand("%:p:h")
                local tf_files = vim.fn.globpath(dir, "*.tf", false, true)
                local esc = vim.pesc(word)
                local patterns = {
                  '^%s*variable%s+"' .. esc .. '"',
                  '^%s*resource%s+"[^"]+"%s+"' .. esc .. '"',
                  '^%s*data%s+"[^"]+"%s+"' .. esc .. '"',
                  '^%s*module%s+"' .. esc .. '"',
                  '^%s*output%s+"' .. esc .. '"',
                  "^%s*" .. esc .. "%s*=",
                }
                for _, pat in ipairs(patterns) do
                  for _, file in ipairs(tf_files) do
                    local lines = vim.fn.readfile(file)
                    for lnum, line in ipairs(lines) do
                      if line:find(pat) then
                        vim.cmd("normal! m'")
                        if vim.fn.fnamemodify(file, ":p") ~= vim.api.nvim_buf_get_name(0) then
                          vim.cmd.edit(vim.fn.fnameescape(file))
                        end
                        local col = (line:find(esc) or 1) - 1
                        vim.api.nvim_win_set_cursor(0, { lnum, col })
                        return
                      end
                    end
                  end
                end
              end,
              desc = "Goto Terraform Definition",
            },
          },
          on_attach = function() end, -- prevent default codelens auto-enable
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
        terraform = {}, -- handled in-process by terraform-ls
        tf = {},
        ["terraform-vars"] = {},
        hcl = {},
      },
    },
  },

  -- Disable linting on save; run golangci-lint (Go) and check_bundles (Mojo Jinja YAML) conditionally
  {
    "mfussenegger/nvim-lint",
    opts = {
      events = { "BufReadPost", "InsertLeave", "BufWritePost" },
      linters_by_ft = {
        markdown = {}, -- handled by rumdl LSP in Rust
        go = { "golangcilint" },
        jinja = { "mojo_check_bundles" },
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
        mojo_check_bundles = {
          cmd = "python3",
          stdin = true,
          append_fname = false,
          stream = "both",
          ignore_exitcode = true,
          condition = function(ctx)
            return vim.fn.fnamemodify(ctx.filename, ":t") == "bundle.yaml"
              and vim.fs.find({ "check_bundles.py" }, { path = ctx.filename, upward = true })[1] ~= nil
          end,
          args = {
            "-c",
            [[
import re, sys, yaml
from pathlib import Path
from jinja2 import Environment, FileSystemLoader, TemplateError

bundle = Path(sys.argv[1]).resolve()
spec_dir = bundle.parent
root_dir = spec_dir.parent
sys.path.insert(0, str(root_dir))

content = sys.stdin.read()
stages = sorted(set(re.findall(r'stage_name\s*==\s*"([^"]+)"', content)) | {"devel"})

try:
    env = Environment(loader=FileSystemLoader(str(spec_dir)))
    tmpl = env.from_string(content)
except TemplateError as e:
    line = getattr(e, "lineno", 1) or 1
    print(f"{line}:1:error:Jinja2 syntax error: {e}")
    sys.exit(0)

check_mod = None
if (root_dir / "check_bundles.py").exists():
    import check_bundles as check_mod

for stage in stages:
    try:
        rendered = tmpl.render({"charm_dir": "fake-charm-dir", "stage_name": stage, "local_dir": "fake-local-dir"})
        yaml.safe_load(rendered)
    except Exception as e:
        line = getattr(getattr(e, "problem_mark", None), "line", 0) + 1
        col = getattr(getattr(e, "problem_mark", None), "column", 0) + 1
        print(f"{line}:{col}:error:[stage={stage}] YAML/Jinja render error: {e}")
        break
    if check_mod:
        for err in check_mod.validate_build_labels(spec_dir.name, stage, rendered):
            lnum = 1
            for idx, l in enumerate(content.splitlines(), 1):
                if "build_label:" in l:
                    lnum = idx
                    break
            print(f"{lnum}:1:error:{err}")
]],
            function()
              return vim.api.nvim_buf_get_name(0)
            end,
          },
          parser = function(output)
            local diags = {}
            for line in output:gmatch("[^\r\n]+") do
              local lnum, col, msg = line:match("^(%d+):(%d+):error:(.+)$")
              if lnum and msg then
                table.insert(diags, {
                  lnum = math.max(0, tonumber(lnum) - 1),
                  col = math.max(0, tonumber(col) - 1),
                  severity = vim.diagnostic.severity.ERROR,
                  source = "check_bundles",
                  message = msg,
                })
              end
            end
            return diags
          end,
        },
      },
    },
  },

  -- Ensure rust and ron Treesitter parsers are installed
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "rust", "ron", "jinja", "jinja_inline", "terraform", "hcl" },
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
        "terraform-ls",
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

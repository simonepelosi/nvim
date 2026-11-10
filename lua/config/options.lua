-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.relativenumber = false

vim.g.autoformat = false

-- Python: use Rust-based ty (LSP) + ruff (linter/formatter) instead of Node pyright
vim.g.lazyvim_python_lsp = "ty"
vim.g.lazyvim_python_ruff = "ruff"

-- Disable unused remote plugin providers (saves startup checks and sub-processes)
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_python3_provider = 0

-- Detect YAML files containing Jinja2 templates ({% ... %} or {{ ... }}) as `yaml.jinja`
-- so pure-YAML LSPs (rlsp-yaml) don't emit false syntax errors on Juju/Mojo bundle.yaml templates.
vim.filetype.add({
  extension = {
    j2 = "jinja",
    jinja = "jinja",
    jinja2 = "jinja",
    yaml = function(_, bufnr)
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 150, false)
      for _, line in ipairs(lines) do
        if line:find("{%%") or line:find("{#") or line:find("{{") then
          return "jinja"
        end
      end
      return "yaml"
    end,
    yml = function(_, bufnr)
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 150, false)
      for _, line in ipairs(lines) do
        if line:find("{%%") or line:find("{#") or line:find("{{") then
          return "jinja"
        end
      end
      return "yaml"
    end,
  },
})

-- Zero-RAM Jinja2 + YAML Treesitter highlighting & navigation (`gd`, `gr`, `%`)
local function set_jinja_keymaps(bufnr)
  pcall(vim.treesitter.start, bufnr, "jinja")

  -- `gd`: Goto first Jinja `{% set var = ... %}` definition (fallback: first occurrence)
  vim.keymap.set("n", "gd", function()
      local word = vim.fn.expand("<cword>")
      if word == "" then
        return
      end
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      local set_pat = "{%%%-?%s*set%s+" .. vim.pesc(word) .. "%f[^%w_]"
      local first_any = nil
      local word_pat = "%f[%w_]" .. vim.pesc(word) .. "%f[^%w_]"

      for i, line in ipairs(lines) do
        local s = line:find(set_pat)
        if s then
          local col = line:find(vim.pesc(word), s) or s
          vim.cmd("normal! m'")
          vim.api.nvim_win_set_cursor(0, { i, col - 1 })
          return
        end
        if not first_any then
          local w = line:find(word_pat)
          if w then
            first_any = { i, w - 1 }
          end
        end
      end

      if first_any then
        vim.cmd("normal! m'")
        vim.api.nvim_win_set_cursor(0, first_any)
      end
    end, { buffer = bufnr, desc = "Goto Jinja Variable Definition" })

    -- `gr`: List all stage definitions / usages of word under cursor in Snacks picker
    vim.keymap.set("n", "gr", function()
      local word = vim.fn.expand("<cword>")
      if word ~= "" and Snacks and Snacks.picker then
        Snacks.picker.lines({ search = word })
      end
    end, { buffer = bufnr, nowait = true, desc = "Jinja Variable References (Buffer)" })

    -- `%`: Jump between Jinja `if -> elif -> else -> endif` when on a `{% ... %}` line
    vim.keymap.set("n", "%", function()
      local cursor = vim.api.nvim_win_get_cursor(0)
      local row = cursor[1]
      local line = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1] or ""
      local tag = line:match("{%%%-?%s*([%w_]+)")
      if not tag then
        vim.cmd("normal! %")
        return
      end

      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      if tag == "if" or tag == "elif" or tag == "else" then
        local depth = 0
        for i = row + 1, #lines do
          local t = lines[i]:match("{%%%-?%s*([%w_]+)")
          if t == "if" then
            depth = depth + 1
          elseif t == "endif" then
            if depth == 0 then
              vim.cmd("normal! m'")
              vim.api.nvim_win_set_cursor(0, { i, (lines[i]:find("{%%") or 1) - 1 })
              return
            end
            depth = depth - 1
          elseif (t == "elif" or t == "else") and depth == 0 then
            vim.cmd("normal! m'")
            vim.api.nvim_win_set_cursor(0, { i, (lines[i]:find("{%%") or 1) - 1 })
            return
          end
        end
      elseif tag == "endif" then
        local depth = 0
        for i = row - 1, 1, -1 do
          local t = lines[i]:match("{%%%-?%s*([%w_]+)")
          if t == "endif" then
            depth = depth + 1
          elseif t == "if" then
            if depth == 0 then
              vim.cmd("normal! m'")
              vim.api.nvim_win_set_cursor(0, { i, (lines[i]:find("{%%") or 1) - 1 })
              return
            end
            depth = depth - 1
          end
        end
      else
        vim.cmd("normal! %")
      end
    end, { buffer = bufnr, desc = "Jump Jinja Block (if/elif/else/endif)" })
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "jinja",
  callback = function(ev)
    set_jinja_keymaps(ev.buf)
  end,
})


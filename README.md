# Neovim config

LazyVim-based. [Docs](https://lazyvim.github.io/installation).

## Required tools

| Tool | Purpose | Install |
|------|---------|---------|
| [`rg`](https://github.com/BurntSushi/ripgrep) | Live grep (`<leader>/`, `<leader>sg`) | `apt install ripgrep` |
| [`fd`](https://github.com/sharkdp/fd) | File picker (`<leader><space>`) — snacks prefers fd over rg for file listing | `apt install fd-find` |
| [`uv`](https://github.com/astral-sh/uv) | Python toolchain (venv-selector, running scripts) | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| [`ty`](https://github.com/astral-sh/ty) | Python LSP (replaces pyright — zero Node.js) | `uv tool install ty` |

## Notes

- `ty` is enabled via `vim.lsp.enable("ty")` in `lua/config/autocmds.lua` (new-style nvim 0.11+ LSP).
- Node.js LSPs (pyright, jsonls, yamlls) are disabled — see `lua/plugins/overrides.lua`.
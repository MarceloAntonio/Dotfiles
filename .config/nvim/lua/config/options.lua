-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Essenciais (que o LazyVim definia por padrão e foram perdidos)
vim.opt.mouse = "a" -- Habilita o mouse em todos os modos (corrige o bug de texto estranho)
vim.opt.clipboard = "unnamedplus" -- Sincroniza o copiar/colar com o sistema operacional
vim.opt.number = true -- Mostra o número das linhas
vim.opt.tabstop = 2 -- Tamanho do tab
vim.opt.shiftwidth = 2 -- Tamanho do recuo
vim.opt.expandtab = true -- Usa espaços ao invés de tabs reais
vim.opt.smartindent = true -- Indentação inteligente
vim.opt.signcolumn = "yes" -- Deixa a coluna da esquerda sempre ativa para não piscar a tela

-- Files: Auto Save (LazyVim default is FocusLost, this ensures it's fully enabled)
vim.opt.autowrite = true
vim.opt.autowriteall = true

-- Font (Note: Only applies if using a GUI client like Neovide)
vim.opt.guifont = "JetBrainsMono Nerd Font:h15"
vim.opt.linespace = 8 -- Roughly line height 1.8

-- Cursor & Animations
-- "editor.renderLineHighlight": "gutter"
vim.opt.cursorlineopt = "number" 
-- "editor.cursorBlinking": "smooth"
vim.opt.guicursor = "n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor"

-- Editor UI
-- "breadcrumbs.enabled": false
vim.opt.winbar = "" 
-- "workbench.statusBar.visible": false
vim.opt.laststatus = 0 

-- Formatting / Wrap
-- "editor.wordWrap": "on"
vim.opt.wrap = true 

-- Line Numbers: Use absolute line numbers (like VSCode) instead of relative
vim.opt.relativenumber = false

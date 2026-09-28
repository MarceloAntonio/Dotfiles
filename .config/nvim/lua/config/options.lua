local o = vim.opt

o.mouse = "a"
o.clipboard = "unnamedplus"
o.number = true
o.signcolumn = "yes"
o.laststatus = 0 -- sem statusline

o.tabstop = 2
o.shiftwidth = 2
o.expandtab = true
o.smartindent = true

o.autowriteall = true
o.guicursor = "n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor"

-- Autocompletar nativo (0.12): LSP primeiro, depois palavras dos buffers
o.autocomplete = true
o.complete = "o,.,w,b"
o.completeopt = "menuone,noinsert,popup,fuzzy"

-- Mostra o texto do erro no fim da linha (desligado por padrão desde o 0.11)
vim.diagnostic.config({ virtual_text = true })

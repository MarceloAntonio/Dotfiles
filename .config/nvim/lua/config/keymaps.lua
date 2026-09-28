local map = vim.keymap.set

-- Copiar (Ctrl + c)
map("n", "<C-c>", '"+yy', { desc = "Copiar linha", silent = true })
map("v", "<C-c>", '"+y', { desc = "Copiar seleção", silent = true })

-- Colar (Ctrl + v)
map({ "n", "v" }, "<C-v>", '"+p', { desc = "Colar", silent = true })
map("i", "<C-v>", "<C-r><C-p>+", { desc = "Colar", silent = true })
map("c", "<C-v>", "<C-r>+", { desc = "Colar", silent = true })

-- Cortar (Ctrl + x)
map("n", "<C-x>", '"+dd', { desc = "Cortar linha", silent = true })
map("v", "<C-x>", '"+d', { desc = "Cortar seleção", silent = true })

-- Desfazer (Ctrl + z)
map("n", "<C-z>", "u", { desc = "Desfazer", silent = true })
map("i", "<C-z>", "<C-o>u", { desc = "Desfazer", silent = true })
map("v", "<C-z>", "<Esc>u", { desc = "Desfazer", silent = true })

-- Refazer (Ctrl + y ou Ctrl + Shift + z)
map("n", "<C-y>", "<C-r>", { desc = "Refazer", silent = true })
map("i", "<C-y>", "<C-o><C-r>", { desc = "Refazer", silent = true })
map("v", "<C-y>", "<Esc><C-r>", { desc = "Refazer", silent = true })
map("n", "<C-S-z>", "<C-r>", { desc = "Refazer", silent = true })
map("i", "<C-S-z>", "<C-o><C-r>", { desc = "Refazer", silent = true })
map("v", "<C-S-z>", "<Esc><C-r>", { desc = "Refazer", silent = true })

-- Copiar linha para baixo / cima (Shift + Alt + Down / Up)
map("n", "<A-S-Down>", "<cmd>t.<CR>", { desc = "Copiar linha para baixo", silent = true })
map("i", "<A-S-Down>", "<Esc><cmd>t.<CR>gi", { desc = "Copiar linha para baixo", silent = true })
map("x", "<A-S-Down>", ":t'><CR>gv", { desc = "Copiar seleção para baixo", silent = true })

map("n", "<A-S-Up>", "<cmd>t -1<CR>", { desc = "Copiar linha para cima", silent = true })
map("i", "<A-S-Up>", "<Esc><cmd>t -1<CR>gi", { desc = "Copiar linha para cima", silent = true })
map("x", "<A-S-Up>", ":t'<-1<CR>gv", { desc = "Copiar seleção para cima", silent = true })

-- Selecionar tudo (Ctrl + a)
map("n", "<C-a>", "ggVG", { desc = "Selecionar tudo", silent = true })
map("i", "<C-a>", "<Esc>ggVG", { desc = "Selecionar tudo", silent = true })
map("v", "<C-a>", "<Esc>ggVG", { desc = "Selecionar tudo", silent = true })

-- Navegação entre janelas (Explorador <-> Código)
-- 1. Usando a tecla Tab para ficar alternando
map("n", "<Tab>", "<C-w>w", { desc = "Pular para a próxima janela", silent = true })

-- 2. Usando Ctrl + Setas para ir na direção exata
map("n", "<C-Left>", "<C-w>h", { desc = "Ir para a janela da Esquerda", silent = true })
map("n", "<C-Right>", "<C-w>l", { desc = "Ir para a janela da Direita", silent = true })
map("n", "<C-Up>", "<C-w>k", { desc = "Ir para a janela de Cima", silent = true })
map("n", "<C-Down>", "<C-w>j", { desc = "Ir para a janela de Baixo", silent = true })

-- Autocompletar: Enter aceita a sugestão, Ctrl+Espaço abre na hora
map("i", "<CR>", function() return vim.fn.pumvisible() == 1 and "<C-y>" or "<CR>" end, { expr = true })
map("i", "<C-Space>", "<C-x><C-o>", { desc = "Sugestões do LSP" })

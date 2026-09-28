-- Atalhos estilo VSCode
-- Obs: Ctrl+Shift+<tecla> é capturado pelo kitty (kitty_mod), por isso não aparece aqui
local map = vim.keymap.set

-- Arquivo
map({ "n", "i", "v" }, "<C-s>", "<cmd>w<cr>", { desc = "Salvar" })
map("n", "<C-p>", "<cmd>Telescope find_files<cr>", { desc = "Buscar Arquivos" })
map("n", "<C-f>", "/", { desc = "Buscar no Arquivo" })
map("n", "<C-b>", "<cmd>Neotree toggle<cr>", { desc = "Explorador de Arquivos" })

-- Copiar / Colar / Cortar
map("n", "<C-c>", '"+yy', { desc = "Copiar linha" })
map("v", "<C-c>", '"+y', { desc = "Copiar seleção" })
map({ "n", "v" }, "<C-v>", '"+p', { desc = "Colar" })
map("i", "<C-v>", "<C-r><C-p>+", { desc = "Colar" })
map("c", "<C-v>", "<C-r>+", { desc = "Colar" })
map("n", "<C-x>", '"+dd', { desc = "Cortar linha" })
map("v", "<C-x>", '"+d', { desc = "Cortar seleção" })

-- Desfazer / Refazer
map("n", "<C-z>", "u", { desc = "Desfazer" })
map("i", "<C-z>", "<C-o>u", { desc = "Desfazer" })
map("v", "<C-z>", "<Esc>u", { desc = "Desfazer" })
map("n", "<C-y>", "<C-r>", { desc = "Refazer" })
map("i", "<C-y>", "<C-o><C-r>", { desc = "Refazer" })
map("v", "<C-y>", "<Esc><C-r>", { desc = "Refazer" })

-- Selecionar tudo
map("n", "<C-a>", "ggVG", { desc = "Selecionar tudo" })
map({ "i", "v" }, "<C-a>", "<Esc>ggVG", { desc = "Selecionar tudo" })

-- Mover linha (Alt + ↑/↓)
map("n", "<A-Up>", "<cmd>m .-2<cr>==", { desc = "Mover linha para cima" })
map("n", "<A-Down>", "<cmd>m .+1<cr>==", { desc = "Mover linha para baixo" })
map("i", "<A-Up>", "<Esc><cmd>m .-2<cr>==gi", { desc = "Mover linha para cima" })
map("i", "<A-Down>", "<Esc><cmd>m .+1<cr>==gi", { desc = "Mover linha para baixo" })
map("x", "<A-Up>", ":m '<-2<cr>gv=gv", { desc = "Mover seleção para cima" })
map("x", "<A-Down>", ":m '>+1<cr>gv=gv", { desc = "Mover seleção para baixo" })

-- Duplicar linha (Shift + Alt + ↑/↓)
map("n", "<A-S-Down>", "<cmd>t.<cr>", { desc = "Duplicar linha para baixo" })
map("n", "<A-S-Up>", "<cmd>t -1<cr>", { desc = "Duplicar linha para cima" })
map("i", "<A-S-Down>", "<Esc><cmd>t.<cr>gi", { desc = "Duplicar linha para baixo" })
map("i", "<A-S-Up>", "<Esc><cmd>t -1<cr>gi", { desc = "Duplicar linha para cima" })
map("x", "<A-S-Down>", ":t'><cr>gv", { desc = "Duplicar seleção para baixo" })
map("x", "<A-S-Up>", ":t'<-1<cr>gv", { desc = "Duplicar seleção para cima" })

-- Comentar (Ctrl + /); <C-_> é como terminais antigos enviam Ctrl+/
for _, key in ipairs({ "<C-/>", "<C-_>" }) do
  map("n", key, "gcc", { remap = true, desc = "Comentar linha" })
  map("x", key, "gc", { remap = true, desc = "Comentar seleção" })
  map("i", key, "<C-o>gcc", { remap = true, desc = "Comentar linha" })
end

-- Apagar palavra (Ctrl + Backspace)
map("i", "<C-BS>", "<C-w>", { desc = "Apagar palavra" })

-- Janelas: Tab alterna, Ctrl + setas vai na direção
map("n", "<Tab>", "<C-w>w", { desc = "Próxima janela" })
map("n", "<C-Left>", "<C-w>h", { desc = "Janela da esquerda" })
map("n", "<C-Right>", "<C-w>l", { desc = "Janela da direita" })
map("n", "<C-Up>", "<C-w>k", { desc = "Janela de cima" })
map("n", "<C-Down>", "<C-w>j", { desc = "Janela de baixo" })

-- Autocompletar: Enter aceita a sugestão, Ctrl+Espaço abre na hora
map("i", "<CR>", function() return vim.fn.pumvisible() == 1 and "<C-y>" or "<CR>" end, { expr = true })
map("i", "<C-Space>", "<C-x><C-o>", { desc = "Sugestões do LSP" })

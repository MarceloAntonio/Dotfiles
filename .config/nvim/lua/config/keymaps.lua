-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

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

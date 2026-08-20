return {
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      require("toggleterm").setup({
        -- Atalho para abrir/fechar o terminal
        open_mapping = [[<C-\>]], 
        
        -- Onde o terminal vai aparecer (pode ser "float", "horizontal", "vertical")
        direction = "horizontal",
        
        -- Tamanho do terminal (altura)
        size = 15,
        
        -- Se for "float", você pode deixar ele flutuando no meio da tela
        -- direction = "float",
        -- float_opts = { border = "curved" },

        -- Esconde a numeração das linhas no terminal
        hide_numbers = true, 
      })

      -- Atalho rápido para sair do modo de digitação do terminal
      -- Quando você abre o terminal, para voltar a mexer no Neovim sem fechá-lo,
      -- precisa usar <C-\><C-n>. O código abaixo simplifica isso para "Esc" duplo.
      function _G.set_terminal_keymaps()
        local opts = {buffer = 0}
        vim.keymap.set('t', '<esc><esc>', [[<C-\><C-n>]], opts)
      end
      vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')

      -- Mapeamento para ver a lista de terminais abertos (estilo abas do VSCode)
      vim.keymap.set("n", "<leader>tt", "<cmd>TermSelect<cr>", { desc = "Selecionar Terminal Aberto" })

      -- Atalhos muito mais amigáveis para abrir terminais específicos
      vim.keymap.set({"n", "t"}, "<leader>t1", "<cmd>1ToggleTerm<cr>", { desc = "Terminal 1" })
      vim.keymap.set({"n", "t"}, "<leader>t2", "<cmd>2ToggleTerm<cr>", { desc = "Terminal 2" })
      vim.keymap.set({"n", "t"}, "<leader>t3", "<cmd>3ToggleTerm<cr>", { desc = "Terminal 3" })
      
      -- Atalho para um terminal flutuante no meio da tela
      vim.keymap.set({"n", "t"}, "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", { desc = "Terminal Flutuante" })
    end
  }
}

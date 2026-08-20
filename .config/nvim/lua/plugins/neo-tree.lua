return {

  -- Explorer: Neo-tree (Estilo VSCode)
  {
    "nvim-neo-tree/neo-tree.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    lazy = false,
    cmd = "Neotree",
    keys = {
      {
        "<leader>e",
        function()
          require("neo-tree.command").execute({ toggle = true, dir = vim.uv.cwd() })
        end,
        desc = "Explorador de Arquivos (Neo-tree)",
      },
    },
    opts = {
      window = {
        mappings = {
          ["<C-c>"] = "copy_to_clipboard",
          ["<C-x>"] = "cut_to_clipboard",
          ["<C-v>"] = "paste_from_clipboard",
          ["<Delete>"] = "delete",
          
          -- Seleção Múltipla (a tal da bolinha)
          ["<C-LeftMouse>"] = "select", -- Segurar Ctrl e clicar
          ["<C-Space>"] = "select",     -- Pelo teclado
          
          ["<Tab>"] = function()
            vim.cmd("wincmd w")
          end,
        },
      },
      filesystem = {
        hijack_netrw_behavior = "open_default",
        group_empty_dirs = true,
        use_libuv_file_watcher = true,
        follow_current_file = {
          enabled = true, -- Garante que a árvore sempre pule para a pasta do arquivo que você está editando
        },
        filtered_items = {
          hide_dotfiles = false, -- Mostra arquivos ocultos (ex: .config, .env)
          hide_gitignored = false, -- Mostra arquivos ignorados pelo git
        },
      },
    },
    config = function(_, opts)
      require("neo-tree").setup(opts)
      
      -- Abre o Neo-tree automaticamente caso abra o Neovim passando um arquivo (ex: nvim arquivo.txt)
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          if vim.fn.argc() == 1 then
            local stat = vim.loop.fs_stat(vim.fn.argv(0))
            if stat and stat.type == "file" then
              vim.cmd("Neotree show")
            end
          end
        end,
      })
    end,
  },
}

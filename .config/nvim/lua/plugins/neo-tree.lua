return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    lazy = false, -- precisa carregar cedo para substituir o netrw
    dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons", "MunifTanjim/nui.nvim" },
    keys = {
      { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Explorador de Arquivos" },
    },
    opts = {
      window = {
        mappings = {
          ["<C-c>"] = "copy_to_clipboard",
          ["<C-x>"] = "cut_to_clipboard",
          ["<C-v>"] = "paste_from_clipboard",
          ["<Delete>"] = "delete",
          ["<C-LeftMouse>"] = "select",
          ["<C-Space>"] = "select",
          ["<Tab>"] = function() vim.cmd("wincmd w") end, -- padrão do neo-tree é "select"
        },
      },
      filesystem = {
        hijack_netrw_behavior = "open_default",
        group_empty_dirs = true,
        use_libuv_file_watcher = true,
        follow_current_file = { enabled = true },
        filtered_items = { hide_dotfiles = false, hide_gitignored = false },
      },
    },
    config = function(_, opts)
      require("neo-tree").setup(opts)
      -- `nvim arquivo.txt` já abre com a árvore do lado
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          local stat = vim.fn.argc() == 1 and vim.uv.fs_stat(vim.fn.argv(0))
          if stat and stat.type == "file" then vim.cmd("Neotree show") end
        end,
      })
    end,
  },
}

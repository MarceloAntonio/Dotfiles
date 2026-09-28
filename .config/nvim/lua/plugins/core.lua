return {
  { "folke/which-key.nvim", event = "VeryLazy", opts = {} },

  -- Linhas alteradas/adicionadas/removidas na lateral
  {
    "lewis6991/gitsigns.nvim",
    event = "BufReadPre",
    opts = {},
    keys = {
      { "<leader>gb", "<cmd>Gitsigns blame_line<cr>", desc = "Git: Blame da Linha" },
      { "<leader>gp", "<cmd>Gitsigns preview_hunk<cr>", desc = "Git: Ver Alteração" },
      { "<leader>gr", "<cmd>Gitsigns reset_hunk<cr>", desc = "Git: Desfazer Alteração" },
    },
  },

  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Buscar Arquivos" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Buscar Texto" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers Abertos" },
    },
    opts = {},
  },

  {
    "nvim-treesitter/nvim-treesitter",
    build = function()
      require("nvim-treesitter").install({
        "c", "lua", "vim", "vimdoc", "query", "bash", "json", "markdown",
        "python", "javascript", "typescript", "tsx", "html", "css",
      })
    end,
    config = function()
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args) pcall(vim.treesitter.start, args.buf) end,
      })
    end,
  },

  {
    "neovim/nvim-lspconfig",
    dependencies = { "williamboman/mason.nvim", "williamboman/mason-lspconfig.nvim" },
    config = function()
      require("mason").setup()
      -- mason-lspconfig já dá vim.lsp.enable() em tudo que estiver instalado
      require("mason-lspconfig").setup({ ensure_installed = { "lua_ls", "pyright", "ruff", "ts_ls", "clangd", "html", "cssls" } })

      vim.lsp.config("lua_ls", {
        settings = { Lua = { diagnostics = { globals = { "vim" } } } },
      })

      -- K (hover) já é padrão do nvim
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = args.buf, desc = "LSP: " .. desc })
          end
          map("gd", require("telescope.builtin").lsp_definitions, "Ir para Definição")
          map("gr", require("telescope.builtin").lsp_references, "Ir para Referências")
          map("<leader>rn", vim.lsp.buf.rename, "Renomear Variável")
          map("<leader>ca", vim.lsp.buf.code_action, "Code Action")
          map("<leader>fm", vim.lsp.buf.format, "Formatar Arquivo")
        end,
      })

      -- Formatar ao salvar (só se algum LSP do buffer formata)
      vim.api.nvim_create_autocmd("BufWritePre", {
        callback = function(args)
          if #vim.lsp.get_clients({ bufnr = args.buf, method = "textDocument/formatting" }) > 0 then
            vim.lsp.buf.format({ bufnr = args.buf, timeout_ms = 500 })
          end
        end,
      })
    end,
  },
}

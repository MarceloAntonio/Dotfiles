return {
  -- 1. Which-Key: Mostra um menu de atalhos ao pressionar a tecla líder (Espaço)
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {},
  },

  -- 2. Telescope: O melhor buscador de arquivos e textos
  {
    "nvim-telescope/telescope.nvim",
    branch = "master",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Buscar Arquivos (Find Files)" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Buscar Texto (Live Grep)" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers Abertos" },
    },
    config = function()
      require("telescope").setup({})
    end,
  },

  -- 3. Treesitter: Melhoria drástica na sintaxe (cores e parsing)
  {
    "nvim-treesitter/nvim-treesitter",
    build = function()
      pcall(function()
        require("nvim-treesitter").install({ "c", "lua", "vim", "vimdoc", "query", "javascript", "python", "html", "css" })
      end)
    end,
    config = function()
      -- No Neovim 0.11+, o highlight via treesitter é nativo e ativado com vim.treesitter.start()
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
        end,
      })
    end,
  },

  -- 4. Mason & LSP Config: Gerenciador e configuração de inteligência de código (Erros, Go-to-definition)
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      require("mason").setup()
      
      require("mason-lspconfig").setup({
        -- Coloque aqui os servidores LSP que você quer que o Neovim instale sozinho
        ensure_installed = { "lua_ls" }, 
      })

      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Configuração específica para o Lua usando a nova API do Neovim 0.11+
      vim.lsp.config('lua_ls', {
        capabilities = capabilities,
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
          },
        },
      })
      
      -- Ativa o LSP (pode ser repetido para outras linguagens como 'pyright', etc)
      vim.lsp.enable('lua_ls')
      
      -- Atalhos de LSP (só funcionam quando há um servidor LSP ativo no arquivo atual)
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local map = function(keys, func, desc)
            vim.keymap.set('n', keys, func, { buffer = args.buf, desc = 'LSP: ' .. desc })
          end
          map('gd', require('telescope.builtin').lsp_definitions, 'Ir para Definição')
          map('gr', require('telescope.builtin').lsp_references, 'Ir para Referências')
          map('K', vim.lsp.buf.hover, 'Ver Documentação (Hover)')
          map('<leader>rn', vim.lsp.buf.rename, 'Renomear Variável')
          map('<leader>ca', vim.lsp.buf.code_action, 'Code Action (Sugestão de Correção)')
        end,
      })
    end,
  },

  -- 5. Nvim-CMP: Motor de autocompletar (sugestões enquanto digita)
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "L3MON4D3/LuaSnip",             -- Engine de snippets
      "saadparwaiz1/cmp_luasnip",     -- Conecta snippets ao cmp
      "hrsh7th/cmp-nvim-lsp",         -- Conecta o LSP ao cmp
      "hrsh7th/cmp-buffer",           -- Autocompleta palavras baseadas no próprio arquivo
      "hrsh7th/cmp-path",             -- Autocompleta caminhos de arquivos (ex: ./pasta/arquivo.txt)
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }), -- Aceita sugestão com Enter
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }, {
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  },

  -- 6. Conform: Formatação de código ao salvar (estilo Prettier)
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>fm",
        function()
          require("conform").format({ async = true, lsp_fallback = true })
        end,
        mode = "",
        desc = "Formatar Arquivo",
      },
    },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        -- python = { "isort", "black" },
        -- javascript = { "prettier" },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
      },
    },
  },
}

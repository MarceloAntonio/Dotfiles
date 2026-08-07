return {
  -- Theme: Catppuccin Mocha
  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = {
      flavour = "mocha",
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },

  -- Explorer: Disable compact folders
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      filesystem = {
        hijack_netrw_behavior = "disabled",
        group_empty_dirs = true,
      },
    },
  },

  -- Status Bar: Disable (Lualine)
  {
    "nvim-lualine/lualine.nvim",
    enabled = false,
  },

  -- Breadcrumbs: Disable (if using Navic/Dropbar in LazyVim)
  {
    "SmiteshP/nvim-navic",
    enabled = false,
  },
}

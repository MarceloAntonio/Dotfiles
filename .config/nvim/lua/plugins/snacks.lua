return {
  {
    "folke/snacks.nvim",
    lazy = false, -- dashboard precisa carregar na abertura
    priority = 1000,
    -- Terminal: <C-\> abre/fecha embaixo; 2<C-\> abre o terminal 2; Esc Esc volta ao modo normal
    keys = {
      { "<C-\\>", function() Snacks.terminal.toggle(nil, { win = { height = 15, wo = { winbar = "" } } }) end, mode = { "n", "t" }, desc = "Terminal" },
      { "<leader>tf", function() Snacks.terminal.toggle(nil, { count = 99, win = { position = "float" } }) end, desc = "Terminal Flutuante" },
    },
    opts = {
      dashboard = {
        preset = {
          header = [[ 

 ███▄ ▄███▓ ██▓ ██ ▄█▀ █    ██     ██▒   █▓ ██▓ ███▄ ▄███▓
▓██▒▀█▀ ██▒▓██▒ ██▄█▒  ██  ▓██▒   ▓██░   █▒▓██▒▓██▒▀█▀ ██▒
▓██    ▓██░▒██▒▓███▄░ ▓██  ▒██░    ▓██  █▒░▒██▒▓██    ▓██░
▒██    ▒██ ░██░▓██ █▄ ▓▓█  ░██░     ▒██ █░░░██░▒██    ▒██ 
▒██▒   ░██▒░██░▒██▒ █▄▒▒█████▓       ▒▀█░  ░██░▒██▒   ░██▒
░ ▒░   ░  ░░▓  ▒ ▒▒ ▓▒░▒▓▒ ▒ ▒       ░ ▐░  ░▓  ░ ▒░   ░  ░
░  ░      ░ ▒ ░░ ░▒ ▒░░░▒░ ░ ░       ░ ░░   ▒ ░░  ░      ░
░      ░    ▒ ░░ ░░ ░  ░░░ ░ ░         ░░   ▒ ░░      ░   
       ░    ░  ░  ░      ░              ░   ░         ░   
                                       ░                                                
]],
          keys = {
            { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
            { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
            { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
            {
              icon = " ",
              key = "c",
              desc = "Open .config",
              action = ":Neotree dir=~/.config",
            },
            { icon = "󰚰 ", key = "l", desc = "Update Plugins", action = ":Lazy" },
            { icon = " ", key = "e", desc = "File Explorer", action = ":Neotree toggle" },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
      },
    },
  },
}

return {
  {
    "folke/snacks.nvim",
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
              action = ":lua Snacks.explorer({ cwd = vim.fn.expand('~/.config') })",
            },
            { icon = "󰚰 ", key = "l", desc = "Update Plugins", action = ":Lazy" },
            { icon = " ", key = "e", desc = "File Explorer", action = ":Neotree toggle" },
            { icon = " ", key = "s", desc = "Restore Session", section = "session" },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
      },
    },
  },
}

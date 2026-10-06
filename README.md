# ~/dotfiles

These dotfiles use a monochromatic theme, except for the editor which uses Catppuccin Mocha. The compositor is Hyprland. An installation script is included. Wallpapers are in a separate repo: [wallpapers_dotfile](https://github.com/MarceloAntonio/wallpapers_dotfile) (the installer downloads them).

---

## The Stack

| Component      | Tool          |
| :------------- | :------------ |
| OS             | Arch Linux    |
| Window Manager | Hyprland      |
| Status Bar     | Waybar        |
| Terminal       | Kitty         |
| Launcher       | Rofi          |
| Browser        | Firefox       |
| File Manager   | Nautilus      |
| Wallpaper      | awww          |
| Login Manager  | SDDM          |
| Screen Lock    | Hyprlock      |
| Editor         | VSCodium / Neovim |
| Fetch          | Fastfetch     |

---

## Keybindings

The modifier key is `SUPER` (Windows key).

| Action            | Shortcut              |
| :---------------- | :-------------------- |
| Open terminal     | `SUPER + Enter`       |
| Open launcher     | `SUPER + Space`       |
| Open browser      | `SUPER + B`           |
| Open file manager | `SUPER + E`           |
| Close window      | `SUPER + Q`           |
| Toggle floating   | `SUPER + Z`           |
| Toggle split      | `SUPER + J`           |
| Change wallpaper  | `SUPER + W`           |
| Theme changer     | `SUPER + T`           |
| Screenshot        | `SUPER + SHIFT + S`   |
| Lock screen       | `SUPER + L`           |
| Exit / shutdown   | `SUPER + M`           |

---

## Features

- **Theme Changer:** Runs entirely through Rofi (`SUPER + T`). Instantly changes your Hyprland wallpaper, SDDM background, and Fastfetch logo. 
- **Dynamic Lockscreen:** Hyprlock features a custom "Liquid Glass" aesthetic matching Waybar, fully synced with the current wallpaper, and includes interactive power buttons (Shutdown, Reboot, Logout).
- **Waybar:** Dynamic OS logo based on your distribution, using a custom script.

---

## Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/MarceloAntonio/Dotfiles
   cd Dotfiles
   ```

2. **Run the installer**

   ```bash
   ./install.sh
   ```

> **Note:** The script backs up your existing configs to `~/BKP.config` before applying changes. It installs dependencies via `pacman` (no AUR helper needed), detects Intel or AMD to pick the right drivers, optionally applies the SDDM theme, and sets ZSH as your default shell. VSCodium is not installed by the script; get it from the AUR (`vscodium-bin`) if you want it.
---

## Wallpapers
To see the available wallpapers, click [here](https://github.com/MarceloAntonio/wallpapers_dotfile).

---

## References

- [ViegPhunt/Dotfile](https://github.com/ViegPhunt/Dotfile)
- [Keyitdev/sddm-astronaut-theme](https://github.com/Keyitdev/sddm-astronaut-theme)

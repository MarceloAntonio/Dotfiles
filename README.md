# ~/dotfiles

These dotfiles use a monochromatic theme, except for the editor which uses Catppuccin Mocha. The compositor is Hyprland. An installation script is included. Wallpapers are available in the Wallpapers folder.

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
| Editor         | Code - OSS / LazyVim |
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
| Exit / shutdown   | `SUPER + M`           |

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

> **Note:** The script backs up your existing configs to `~/BKP.config` before applying changes. It installs dependencies via `pacman` and `yay`, applies the SDDM theme, sets up Code - OSS, and sets ZSH as your default shell.
---

## Theme Changer

You can change your Hyprland wallpaper, SDDM background, and Fastfetch icon using the built in Theme Changer. It runs entirely through Rofi.

---
## Wallpapers
To see the available wallpapers, click [here](./Wallpapers/WALLPAPERS.md).

---

## References

- [ViegPhunt/Dotfile](https://github.com/ViegPhunt/Dotfile)
- [Keyitdev/sddm-astronaut-theme](https://github.com/Keyitdev/sddm-astronaut-theme)

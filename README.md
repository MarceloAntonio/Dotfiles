# ~/dotfiles

My Dotfiles have a monochromatic theme, except for the editor which has a catpuccin mocha theme. The compositor is Hyprland. I created an installation script, so if you want the Dotfile, just follow the instructions below. I've also included some wallpapers in the Wallpapers folder if you need them.

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
| File Manager   | Nemo          |
| Wallpaper      | awww          |
| Login Manager  | SDDM          |
| Screen Lock    | Hyprlock      |
| Editor         | Lazyvim        |
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
| Toggle floating   | `SUPER + V`           |
| Toggle split      | `SUPER + J`           |
| Change wallpaper  | `SUPER + W`           |
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

> **Note:** The script backs up your existing configs to `~/BKP.config` before applying any
> changes. It installs dependencies via `pacman` and `yay`, applies the SDDM theme, and sets
> ZSH as your default shell.
---

## Theme Changer *(work in progress)*

The theme changer is a program written in Python where you can change your Hyprland and SDDM wallpapers, and the Fastfetch icon. It's still under development, so it's not 100% perfect yet. I intend to migrate it to Rofi.

---
## Wallpapers
To see the available wallpapers, just click [here](./Wallpapers/WALLPAPERS.md).

---

## References

- [ViegPhunt/Dotfile](https://github.com/ViegPhunt/Dotfile)
- [Keyitdev/sddm-astronaut-theme](https://github.com/Keyitdev/sddm-astronaut-theme)

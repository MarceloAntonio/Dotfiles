# ~/dotfiles

A minimal, focused desktop environment built on Hyprland with a fully monochromatic system theme
and Catppuccin Mocha for the editor. Fastfetch is customized with image support — swap the image
to whatever you like.

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
| Wallpaper      | swww          |
| Login Manager  | SDDM          |
| Screen Lock    | Hyprlock      |
| Editor         | Neovim        |
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

## Structure

```text
~/dotfiles
├── .config/
│   ├── colors/
│   │   ├── colors.css
│   │   └── colors.rasi
│   ├── fastfetch/
│   │   ├── icons/
│   │   │   ├── Chihiro.png
│   │   │   ├── Cinna.png
│   │   │   ├── Miku.png
│   │   │   ├── Nerv.png
│   │   │   ├── Tomoko.png
│   │   │   └── Tomoko2.png
│   │   └── config.jsonc
│   ├── gtk-3.0/
│   │   └── settings.ini
│   ├── gtk-4.0/
│   │   └── settings.ini
│   ├── hypr/
│   │   ├── configs/
│   │   │   ├── animations.conf
│   │   │   ├── autostart.conf
│   │   │   ├── keybinds.conf
│   │   │   ├── monitors.conf
│   │   │   ├── programs.conf
│   │   │   └── windowrules.conf
│   │   ├── scripts/
│   │   │   └── change-wallpaper.sh
│   │   ├── hyprland.conf
│   │   └── hyprlock.conf
│   ├── kitty/
│   │   ├── kitty.conf
│   │   └── theme.conf
│   ├── rofi/
│   │   └── config.rasi
│   ├── vscode/
│   │   └── settings.json
│   └── waybar/
│       ├── config
│       └── style.css
├── scripts/
│   ├── install_theme_changer.sh
│   ├── sddm-setup.sh
│   └── theme_changer.py
├── Wallpapers/
├── .zshrc
├── install.sh
└── README.md
```

## Theme Changer *(work in progress)*

A utility that reads the `wallpaper/` folder and syncs the selected wallpaper to both SDDM
and swww in one step. Currently functional but slow — keyboard navigation is not yet supported.

---

## References

- [ViegPhunt/Dotfile](https://github.com/ViegPhunt/Dotfile)
- [Keyitdev/sddm-astronaut-theme](https://github.com/Keyitdev/sddm-astronaut-theme)

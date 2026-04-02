# Dotfiles

A clean, modular, and highly functional dotfiles repository for Arch Linux, powered by Hyprland. 

Built with a focus on simplicity, Clean Code, and maintainability. Every configuration is separated by application and purpose. The window manager settings strictly follow the Single Responsibility Principle (splitting monitors, keybinds, rules, and autostart into dedicated files), keeping the environment lightweight and making it easy to read, modify, and extend without breaking the system.

![Desktop Showcase](link-para-sua-imagem-aqui.png)
*(Replace with a screenshot of your clean desktop)*

![Terminal & Fetch](link-para-sua-imagem-aqui.png)
*(Replace with a screenshot showing Kitty, Fastfetch with the Chihiro logo, and your minimal VSCode)*

## The Stack

This environment strips away visual noise to keep you focused:

* **OS:** Arch Linux
* **Window Manager:** [Hyprland](https://hyprland.org/) 
* **Status Bar:** Waybar 
* **Terminal:** Kitty 
* **Launcher:** Rofi 
* **Browser:** Firefox
* **Wallpaper Manager:** awww 
* **Login Manager:** SDDM
* **Editor:** Code OSS / VSCode 
* **Fetch:** Fastfetch

## Essential Keybindings

The main modifier key is set to `SUPER` (Windows key). Here are the primary shortcuts to navigate the system:

| Action | Shortcut |
| :--- | :--- |
| **Open Terminal** | `SUPER + Enter` |
| **Open App Launcher** | `SUPER + Space` |
| **Open Browser** | `SUPER + B` |
| **Open File Manager** | `SUPER + E` |
| **Close Window** | `SUPER + Q` |
| **Toggle Floating** | `SUPER + V` |
| **Toggle Split** | `SUPER + J` |
| **Change Wallpaper** | `SUPER + W` |
| **Screenshot** | `SUPER + SHIFT + S` |
| **Exit / Shutdown** | `SUPER + M` |

## Installation

An automated installation script is included to safely back up your current configurations and apply these dotfiles.

1. Clone the repository:
```bash
git clone https://github.com/MarceloAntonio/Dotfiles
cd Dotfiles
```

2. Make the script executable:
```bash
chmod +x install.sh
```

3. Run the installer:
```bash
./install.sh
```

> **Note:** The script automatically creates a backup of your existing configurations at `~/BKP.config` before making any changes. It also installs the necessary dependencies via `pacman` and `yay`, configures the SDDM theme, and sets ZSH as the default shell.

## Structure

Everything is modular and logically separated:

```text
Dotfiles/
├── .config/
│   ├── colors/      # Base color palettes
│   ├── fastfetch/   # Terminal system info & logos
│   ├── hypr/        # Hyprland configs
│   │   ├── configs/ # Modular files (monitors, keybinds, rules, etc.)
│   │   └── scripts/ # Hyprland scripts (e.g., change-wallpaper.sh)
│   ├── kitty/       # Terminal emulator settings
│   ├── rofi/        # App launcher styling
│   ├── vscode/      # Minimal workspace settings (settings.json)
│   └── waybar/      # Minimal floating status bar config
├── scripts/         # Installation utilities (e.g., sddm-setup.sh)
├── Wallpapers/      # Desktop backgrounds
├── .zshrc           # Zsh shell configuration
├── install.sh       # Automated setup script
└── README.md
```

## VSCode Setup Notes
If you are using the provided VSCode settings, make sure to install the following extensions to match the look:
* `Catppuccin Theme`
* `Catppuccin Icons`
* Font: `JetBrainsMono Nerd Font` (`sudo pacman -S ttf-jetbrains-mono-nerd`)

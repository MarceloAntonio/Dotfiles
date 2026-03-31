#!/bin/bash

BACKUP_DIR="$HOME/BKP.config"
CONFIG_DIR="$HOME/.config"
DOTFILES_DIR="$(pwd)"

DEPENDENCIES=(
    hyprland
    firefox
    kitty
    rofi-wayland
    fastfetch
    waybar
    network-manager-applet
    pavucontrol
    ttf-jetbrains-mono-nerd
    grim
    slurp
    wl-clipboard
    dolphin
    code
    hyprpaper
    polkit-kde-agent
    brightnessctl
    playerctl
)

echo "Starting dotfiles installation..."
echo "----------------------------------------"

echo "[1/6] Installing dependencies..."
sudo pacman -S --needed --noconfirm "${DEPENDENCIES[@]}"

echo "[2/6] Preparing backup directory..."
mkdir -p "$BACKUP_DIR"

echo "[3/6] Moving old configurations to backup..."
for app in hypr rofi colors kitty fastfetch waybar; do
    if [ -d "$CONFIG_DIR/$app" ]; then
        mv "$CONFIG_DIR/$app" "$BACKUP_DIR/"
        echo "  -> Backup of '$app' completed."
    fi
done

echo "[4/6] Installing new configurations..."
for app in hypr rofi colors kitty fastfetch waybar; do
    if [ -d "$DOTFILES_DIR/.config/$app" ]; then
        cp -a "$DOTFILES_DIR/.config/$app" "$CONFIG_DIR/"
        echo "  -> '$app' installed."
    fi
done

echo "[5/6] Applying code editor configurations..."
if [ -d "$CONFIG_DIR/Code - OSS/User" ]; then
    cp -a "$DOTFILES_DIR/.config/vscode/"* "$CONFIG_DIR/Code - OSS/User/" 2>/dev/null
    echo "  -> Configurations applied to Code OSS."
elif [ -d "$CONFIG_DIR/Code/User" ]; then
    cp -a "$DOTFILES_DIR/.config/vscode/"* "$CONFIG_DIR/Code/User/" 2>/dev/null
    echo "  -> Configurations applied to VSCode."
else
    echo "  -> No VSCode/Code OSS folder found. Skipping."
fi

echo "[6/6] Copying wallpapers..."
if [ -d "$DOTFILES_DIR/Wallpapers" ]; then
    PICTURES_DIR="$HOME/Pictures"
    [ -d "$HOME/Imagens" ] && PICTURES_DIR="$HOME/Imagens"
    
    cp -a "$DOTFILES_DIR/Wallpapers" "$PICTURES_DIR/"
    echo "  -> Wallpapers copied to $PICTURES_DIR/Wallpapers."
fi

echo "----------------------------------------"
echo "Installation completed successfully!"
#!/bin/bash

# Cores para o terminal
GREEN='\033[1;32m'
NC='\033[0m'

# Caminhos
WALL_DIR="$HOME/Pictures/Wallpaper"
THEME_PATH="$HOME/.config/rofi/themes/rofi-wallpaper-selector.rasi"

# Verifica se o diretório existe
if [ ! -d "$WALL_DIR" ]; then
    notify-send "Erro" "Diretório de wallpapers não encontrado!"
    exit 1
fi

# Rofi Menu
# O printf passa o nome do arquivo e o ícone (o próprio arquivo) para o rofi
CHOICE=$(find "$WALL_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) -printf "%f\0icon\037%p\n" | \
         rofi -dmenu -i -show-icons -p "Wallpaper" -config "$THEME_PATH")

if [ -n "$CHOICE" ]; then
    FULL_PATH="$WALL_DIR/$CHOICE"

    # Aplica com o awww
    awww img "$FULL_PATH" --transition-type wipe --transition-angle 30 --transition-step 90 --transition-fps 60

    # Atualiza o link para o Hyprlock
    ln -sf "$FULL_PATH" "$HOME/.config/hypr/hyprlock/wallpaper" 2>/dev/null

    notify-send "Wallpaper Alterado" "$CHOICE" -i "$FULL_PATH"
    echo -e "${GREEN}Sucesso: $CHOICE aplicado.${NC}"
else
    echo "Operação cancelada."
fi
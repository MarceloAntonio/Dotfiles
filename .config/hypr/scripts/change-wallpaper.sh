#!/bin/bash
GREEN='\033[1;32m'
NC='\033[0m'
WALL_DIR="$HOME/Pictures/Wallpaper"
THEME_PATH="$HOME/.config/rofi/themes/rofi-wallpaper-selector.rasi"
CACHE_FILE="$HOME/.config/hypr/.current_wallpaper"
if [ ! -d "$WALL_DIR" ]; then
    notify-send "Erro" "Diretório de wallpapers não encontrado!"
    exit 1
fi
CHOICE=$(find "$WALL_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \) \
         -printf "%f\0icon\037%p\n" | sort | rofi -dmenu -i -show-icons -p "Wallpaper" -config "$THEME_PATH")

if [ -n "$CHOICE" ]; then
    FULL_PATH="$WALL_DIR/$CHOICE"
    if [ ! -f "$FULL_PATH" ]; then
        notify-send "Erro" "Arquivo não encontrado: $CHOICE"
        exit 1
    fi
    echo "$FULL_PATH" > "$CACHE_FILE"
    awww img "$FULL_PATH" \
        --transition-type fade \
        --transition-duration 0.5 \
        --transition-fps 60 \
        --transition-bezier ".4,0,.2,1"
    mkdir -p "$HOME/.config/hypr/hyprlock"
    ln -sf "$FULL_PATH" "$HOME/.config/hypr/hyprlock/wallpaper" 2>/dev/null

    notify-send "Wallpaper Alterado" "$CHOICE" -i "$FULL_PATH"
    echo -e "${GREEN}Sucesso: $CHOICE aplicado.${NC}"
else
    echo "Operação cancelada."
fi

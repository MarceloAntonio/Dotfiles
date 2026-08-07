#!/bin/bash

# Cores para o terminal
GREEN='\033[1;32m'
NC='\033[0m'

# Caminhos
WALL_DIR="$HOME/Pictures/Wallpaper"
THEME_PATH="$HOME/.config/rofi/themes/rofi-wallpaper-selector.rasi"
CACHE_FILE="$HOME/.config/hypr/.current_wallpaper"

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

    # Verifica se o arquivo realmente existe
    if [ ! -f "$FULL_PATH" ]; then
        notify-send "Erro" "Arquivo não encontrado: $CHOICE"
        exit 1
    fi

    # Salva o wallpaper atual para restaurar no próximo boot
    echo "$FULL_PATH" > "$CACHE_FILE"

    # Aplica com o awww (fade rápido em todas as telas)
    awww img "$FULL_PATH" \
        --transition-type fade \
        --transition-duration 0.5 \
        --transition-fps 60 \
        --transition-bezier ".4,0,.2,1"

    # Atualiza o link para o Hyprlock
    ln -sf "$FULL_PATH" "$HOME/.config/hypr/hyprlock/wallpaper" 2>/dev/null

    notify-send "Wallpaper Alterado" "$CHOICE" -i "$FULL_PATH"
    echo -e "${GREEN}Sucesso: $CHOICE aplicado.${NC}"
else
    echo "Operação cancelada."
fi

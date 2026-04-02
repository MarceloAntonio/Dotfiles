#!/bin/bash

# Define o caminho da sua pasta de wallpapers
WALLPAPER_DIR="$HOME/Imagens/Wallpapers"

# Pega uma imagem aleatória (jpg, png ou jpeg) dentro da pasta
WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) | shuf -n 1)

# Se encontrou uma imagem, manda o awww aplicar
if [ -n "$WALLPAPER" ]; then
    awww img "$WALLPAPER"
fi
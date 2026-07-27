#!/bin/bash
#
# Theme Changer — rofi edition
# Usa o mesmo tema do wallpaper-selector para tudo
#

# ── Paths ──────────────────────────────────────────────
WALL_DIR="$HOME/Pictures/Wallpaper"
FASTFETCH_ICONS="$HOME/.config/fastfetch/icons"
FASTFETCH_CONFIG="$HOME/.config/fastfetch/config.jsonc"
CACHE_FILE="$HOME/.config/hypr/.current_wallpaper"

SDDM_CONF="/usr/share/sddm/themes/sddm-astronaut-theme/Themes/astronaut.conf"
SDDM_BG_DIR="/usr/share/sddm/themes/sddm-astronaut-theme/Backgrounds"

ROFI_THEME="$HOME/.config/rofi/themes/rofi-wallpaper-selector.rasi"

# ── Rofi ───────────────────────────────────────────────
rofi_pick() {
    rofi -dmenu -i -show-icons -p "$1" -config "$ROFI_THEME"
}

list_images() {
    local dir="$1"
    [ -d "$dir" ] || return
    find "$dir" -maxdepth 1 -type f \
        \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \
        -o -iname "*.webp" -o -iname "*.gif" -o -iname "*.bmp" \) \
        -printf "%f\0icon\037%p\n" | sort
}

# ── Actions ────────────────────────────────────────────
apply_fastfetch() {
    local img="$1"
    local name=$(basename "$img")

    [ -f "$FASTFETCH_CONFIG" ] || { notify-send "Erro" "Config do fastfetch não encontrado!" -u critical; return 1; }

    sed -i "s|\"source\"[[:space:]]*:[[:space:]]*\"[^\"]*\"|\"source\": \"$img\"|" "$FASTFETCH_CONFIG"
    notify-send "Fastfetch ✓" "Logo: $name" -i "$img"
}

apply_wallpaper() {
    local img="$1"
    local name=$(basename "$img")

    echo "$img" > "$CACHE_FILE"

    awww img "$img" \
        --transition-type fade \
        --transition-duration 0.5 \
        --transition-fps 60 \
        --transition-bezier ".4,0,.2,1"

    ln -sf "$img" "$HOME/.config/hypr/hyprlock/wallpaper" 2>/dev/null
    notify-send "Wallpaper ✓" "$name" -i "$img"
}

apply_sddm() {
    local img="$1"
    local name=$(basename "$img")

    [ -f "$SDDM_CONF" ] || { notify-send "Erro" "SDDM config não encontrado!" -u critical; return 1; }

    pkexec cp "$img" "$SDDM_BG_DIR/$name"

    local tmp="/tmp/_sddm_tmp.conf"
    sed "s|^Background[[:space:]]*=.*|Background=Backgrounds/$name|" "$SDDM_CONF" > "$tmp"
    pkexec cp "$tmp" "$SDDM_CONF"
    rm -f "$tmp"

    notify-send "SDDM ✓" "Background: $name" -i "$img"
}

# ── Main ───────────────────────────────────────────────
MENU=$(printf "  Fastfetch Logo\n  Wallpaper\n  SDDM Background" | rofi -dmenu -i -p "  Theme Changer" -config "$ROFI_THEME")

[ -z "$MENU" ] && exit 0

case "$MENU" in
    *Fastfetch*)
        DIR="$FASTFETCH_ICONS"
        CHOICE=$(list_images "$DIR" | rofi_pick "  Fastfetch")
        [ -n "$CHOICE" ] && [ -f "$DIR/$CHOICE" ] && apply_fastfetch "$DIR/$CHOICE"
        ;;
    *Wallpaper*)
        DIR="$WALL_DIR"
        CHOICE=$(list_images "$DIR" | rofi_pick "  Wallpaper")
        [ -n "$CHOICE" ] && [ -f "$DIR/$CHOICE" ] && apply_wallpaper "$DIR/$CHOICE"
        ;;
    *SDDM*)
        DIR="$WALL_DIR"
        CHOICE=$(list_images "$DIR" | rofi_pick "  SDDM")
        [ -n "$CHOICE" ] && [ -f "$DIR/$CHOICE" ] && apply_sddm "$DIR/$CHOICE"
        ;;
esac

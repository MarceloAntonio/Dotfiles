#!/bin/bash
WALL_DIR="$HOME/Pictures/Wallpaper"
WALL_CACHE="$HOME/.config/hypr/.current_wallpaper"
FF_ICONS="$HOME/.config/fastfetch/icons"
FF_CONFIG="$HOME/.config/fastfetch/config.jsonc"
KITTY_DIR="$HOME/.config/kitty"
SDDM_CONF="/usr/share/sddm/themes/sddm-astronaut-theme/Themes/astronaut.conf"
SDDM_BG_DIR="/usr/share/sddm/themes/sddm-astronaut-theme/Backgrounds"
PREVIEWS="$HOME/.cache/theme-changer"
MENU_THEME="$HOME/.config/rofi/themes/menu.rasi"
GRID_THEME="$HOME/.config/rofi/themes/rofi-wallpaper-selector.rasi"

glyph() { printf "<span font_family='JetBrainsMono Nerd Font' size='large'>%s</span>" "$1"; }
esc() { local s=${1//&/&amp;}; s=${s//</&lt;}; printf '%s' "${s//>/&gt;}"; }
basename_noext() { local s=${1##*/}; printf '%s' "${s%.*}"; }

load_images() {
    mapfile -t PATHS < <(find "$1" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' \) | sort -V)
    ICONS=("${PATHS[@]}")
    NAMES=()
    for p in "${PATHS[@]}"; do NAMES+=("$(basename_noext "$p")"); done
}

index_of() {
    for i in "${!PATHS[@]}"; do
        [ "${PATHS[i]}" = "$1" ] && { echo "$i"; return; }
    done
}

grid() {
    local lines=$(( (${#NAMES[@]} + 3) / 4 )) current=()
    (( lines > 2 )) && lines=2
    [ -n "$2" ] && current=(-a "$2" -selected-row "$2")
    local choice
    choice=$(for i in "${!NAMES[@]}"; do printf '%s\0icon\x1f%s\n' "${NAMES[i]}" "${ICONS[i]}"; done |
        rofi -dmenu -i -show-icons -format i -config "$GRID_THEME" "${current[@]}" \
            -theme-str "entry { placeholder: \"$1\"; } listview { lines: $lines; }")
    [[ $choice =~ ^[0-9]+$ ]] && (( choice < ${#NAMES[@]} )) && echo "$choice"
}

current_wallpaper() { cat "$WALL_CACHE" 2>/dev/null; }
current_fastfetch() {
    local s
    s=$(sed -n 's/.*"source"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$FF_CONFIG")
    printf '%s' "${s/#\~/$HOME}"
}
current_sddm() { sed -n 's|^Background[[:space:]]*=[[:space:]]*"\{0,1\}Backgrounds/\([^"]*\)"\{0,1\}$|\1|p' "$SDDM_CONF" 2>/dev/null; }
current_kitty() {
    for f in "$KITTY_DIR"/*.conf; do
        case ${f##*/} in kitty.conf | current-theme.conf) continue ;; esac
        cmp -s "$f" "$KITTY_DIR/current-theme.conf" && { basename_noext "$f"; return; }
    done
}

set_wallpaper() {
    echo "$1" > "$WALL_CACHE"
    awww img "$1" --transition-type fade --transition-duration 0.5 --transition-fps 60 --transition-bezier ".4,0,.2,1"
    mkdir -p "$HOME/.config/hypr/hyprlock"
    ln -sf "$1" "$HOME/.config/hypr/hyprlock/wallpaper"
    notify-send "Wallpaper" "$(basename_noext "$1")" -i "$1"
}

set_fastfetch() {
    local src=${1/#$HOME/\~}
    sed -i "s|\"source\"[[:space:]]*:[[:space:]]*\"[^\"]*\"|\"source\": \"${src//&/\\&}\"|" "$FF_CONFIG"
    if [ "$1" = auto ]; then
        notify-send "Fastfetch" "Logo da distro"
    else
        notify-send "Fastfetch" "$(basename_noext "$1")" -i "$1"
    fi
}

set_kitty() {
    ln -sfn "$1.conf" "$KITTY_DIR/current-theme.conf"
    killall -USR1 kitty 2>/dev/null
    notify-send "Tema do kitty" "$1"
}

set_sddm() {
    local name=${1##*/}
    if pkexec bash -c '
        cp "$1" "$2/$3" && chmod 644 "$2/$3" &&
        sed -i "s|^Background[[:space:]]*=.*|Background=\"Backgrounds/${3//&/\\&}\"|" "$4"
    ' _ "$1" "$SDDM_BG_DIR" "$name" "$SDDM_CONF"; then
        notify-send "Tela de login" "$(basename_noext "$1")" -i "$1"
    else
        notify-send "Tela de login" "Não foi possível aplicar (autenticação cancelada ou erro)" -u critical
    fi
}

kitty_preview() {
    local out="$PREVIEWS/$(basename_noext "$1").png"
    if [ ! -f "$out" ] || [ "$1" -nt "$out" ]; then
        mkdir -p "$PREVIEWS"
        local bg colors
        bg=$(awk '$1 == "background" { print $2 }' "$1")
        colors=$(awk '$1 == "foreground" || $1 ~ /^color[1-6]$/ { printf "xc:%s ", $2 }' "$1")
        magick -size 34x150 $colors +append -bordercolor "$bg" -border 28 "$out"
    fi
    printf '%s' "$out"
}

pick_wallpaper() {
    load_images "$WALL_DIR"
    local i
    i=$(grid "Escolha um wallpaper..." "$(index_of "$(current_wallpaper)")") && set_wallpaper "${PATHS[i]}"
}

pick_sddm() {
    [ -f "$SDDM_CONF" ] || { notify-send "Tela de login" "Tema do SDDM não encontrado" -u critical; return 1; }
    load_images "$WALL_DIR"
    local current i
    current=$(current_sddm)
    for i in "${!PATHS[@]}"; do [ "${PATHS[i]##*/}" = "$current" ] && break; done
    [ "${PATHS[i]##*/}" = "$current" ] || i=
    i=$(grid "Fundo da tela de login..." "$i") && set_sddm "${PATHS[i]}"
}

pick_fastfetch() {
    load_images "$FF_ICONS"
    PATHS=(auto "${PATHS[@]}")
    NAMES=("Logo da distro" "${NAMES[@]}")
    ICONS=(distributor-logo-archlinux "${ICONS[@]}")
    local i
    i=$(grid "Logo do fastfetch..." "$(index_of "$(current_fastfetch)")") && set_fastfetch "${PATHS[i]}"
}

pick_kitty() {
    PATHS=() NAMES=() ICONS=()
    for f in "$KITTY_DIR"/*.conf; do
        case ${f##*/} in kitty.conf | current-theme.conf) continue ;; esac
        PATHS+=("$f")
        NAMES+=("$(basename_noext "$f")")
        ICONS+=("$(kitty_preview "$f")")
    done
    local i current
    current=$(current_kitty)
    i=$(grid "Tema do kitty..." "$(index_of "$KITTY_DIR/$current.conf")") && set_kitty "${NAMES[i]}"
}

main_menu() {
    local ff wp sd
    ff=$(current_fastfetch)
    [ "$ff" = auto ] && ff="Logo da distro" || ff=$(basename_noext "$ff")
    wp=$(basename_noext "$(current_wallpaper)")
    sd=$(current_sddm)
    row() { printf "%s    <b>%s</b>   <span alpha='55%%'>%s</span>\n" "$(glyph "$1")" "$2" "$(esc "$3")"; }
    {
        row $'\U000F02E9' "Wallpaper" "$wp"
        row $'\U000F033E' "Tela de login" "${sd%.*}"
        row $'\U000F018D' "Logo do fastfetch" "$ff"
        row $'\U000F011B' "Tema do kitty" "$(current_kitty)"
    } | rofi -dmenu -markup-rows -format i -config "$MENU_THEME" -mesg "$(glyph $'\U000F03D8')   Personalizar"
}

case "${1:-$(main_menu)}" in
    0 | wallpaper) pick_wallpaper ;;
    1 | sddm) pick_sddm ;;
    2 | fastfetch) pick_fastfetch ;;
    3 | kitty) pick_kitty ;;
esac

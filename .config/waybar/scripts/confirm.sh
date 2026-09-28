#!/bin/bash
action=$1
shift
case $action in
    Desligar) icon=$'\U000F0906' ;;
    Reiniciar) icon=$'\U000F0709' ;;
    *) icon=$'\U000F05FC' ;;
esac
span() { printf "<span font_family='JetBrainsMono Nerd Font'>%s</span>" "$1"; }

choice=$(printf '%s   Cancelar\n%s   %s\n' "$(span $'\U000F0156')" "$(span "$icon")" "$action" |
    rofi -dmenu -markup-rows -format i -selected-row 0 -config ~/.config/rofi/themes/menu.rasi \
        -mesg "Deseja ${action,,}?" \
        -theme-str 'window { width: 380px; } listview { columns: 2; lines: 1; } element-text, textbox { horizontal-align: 0.5; }')

[ "$choice" = 1 ] && exec "$@"

#!/bin/bash
[ "$(printf 'Não\nSim' | rofi -dmenu -i -p "$1")" = "Sim" ] || exit 0
shift
exec "$@"

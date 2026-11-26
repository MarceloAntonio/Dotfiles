#!/usr/bin/env bash
# Print de área com a tela congelada (igual ao Win+Shift+S).
# hyprpicker -z cobre a tela com o frame parado; o grim captura antes de soltar o congelamento.
# Sem hyprpicker instalado, tira o print normal (sem congelar).
if command -v hyprpicker >/dev/null; then
    hyprpicker -r -z &
    freeze=$!
    sleep 0.15
fi
area=$(slurp)
[ -n "$area" ] && grim -g "$area" - | wl-copy
[ -n "$freeze" ] && kill "$freeze"

#!/usr/bin/env bash

hyprctl binds -j | python3 -c '
import html, json, sys
mods = [(64, "SUPER"), (4, "CTRL"), (8, "ALT"), (1, "SHIFT")]
names = {"left": "Setas", "mouse:272": "Mouse Esq.", "mouse:273": "Mouse Dir.", "mouse_down": "Scroll",
         "1": "1~0", "XF86AudioRaiseVolume": "Teclas de mídia", "space": "Espaço"}
for b in json.load(sys.stdin):
    if not b["description"]:
        continue
    keys = " + ".join([name for bit, name in mods if b["modmask"] & bit] + [names.get(b["key"], b["key"])])
    print("<span font_family=\"JetBrainsMono Nerd Font\" weight=\"bold\">{:<22}</span>  <span alpha=\"60%\">{}</span>".format(html.escape(keys), html.escape(b["description"])))
' | rofi -dmenu -i -no-show-icons -markup-rows -theme-str 'listview { lines: 12; } window { width: 640px; } entry { placeholder: "Buscar atalho..."; }'

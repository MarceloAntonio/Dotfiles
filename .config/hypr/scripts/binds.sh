#!/usr/bin/env bash

# Menu de atalhos do Hyprland

echo -e "<span font_family='monospace'>SUPER + Return       ➔ Kitty</span>
<span font_family='monospace'>SUPER + B            ➔ Firefox</span>
<span font_family='monospace'>SUPER + E            ➔ Nautilus</span>
<span font_family='monospace'>SUPER + Space        ➔ Rofi</span>
<span font_family='monospace'>SUPER + V            ➔ Clipboard Manager</span>
<span font_family='monospace'>SUPER + Q            ➔ Close Window</span>
<span font_family='monospace'>SUPER + Z            ➔ Toggle Floating</span>
<span font_family='monospace'>SUPER + F            ➔ Toggle Fullscreen</span>
<span font_family='monospace'>SUPER + M            ➔ Maximize</span>
<span font_family='monospace'>SUPER + P            ➔ Pseudo Tiling</span>
<span font_family='monospace'>SUPER + J            ➔ Toggle Split</span>
<span font_family='monospace'>SUPER + SHIFT + S    ➔ Screenshot</span>
<span font_family='monospace'>SUPER + W            ➔ Change Wallpaper</span>
<span font_family='monospace'>SUPER + T            ➔ Change Theme(Beta)</span>
<span font_family='monospace'>SUPER + L            ➔ Lock</span>
<span font_family='monospace'>SUPER + Mouse        ➔ Move/Resize Window</span>
<span font_family='monospace'>Media Keys           ➔ Volume / Brightness</span>
<span font_family='monospace'>SUPER + 1~0          ➔ Switch Workspace</span>
<span font_family='monospace'>SUPER + SHIFT + 1~0  ➔ Move Window to Workspace</span>" | rofi -dmenu -i -markup-rows -p "Keybinds" -theme-str 'listview { lines: 15; } window { width: 600px; }'

#!/bin/bash
set -e
# Link (não cópia): edições no script do hypr já valem para o comando e o .desktop
SRC="$HOME/.config/hypr/scripts/theme-changer.sh"
DEST="/usr/local/bin/theme-changer"
DESKTOP="$HOME/.local/share/applications/theme-changer.desktop"

echo "==> Instalando theme-changer (rofi)..."

[ -f "$SRC" ] || { echo "Erro: $SRC não encontrado (rode o install.sh antes)"; exit 1; }
chmod +x "$SRC"
sudo ln -sf "$SRC" "$DEST"
echo "    [ok] $DEST -> $SRC"

# Cria .desktop
mkdir -p "$(dirname "$DESKTOP")"
cat > "$DESKTOP" << EOF2
[Desktop Entry]
Name=Theme Changer
Comment=Troca fastfetch logo, wallpaper, SDDM background e tema do kitty
Exec=$DEST
Icon=preferences-desktop-theme
Terminal=false
Type=Application
Categories=Utility;Settings;
EOF2
echo "    [ok] $DESKTOP"

echo ""
echo "Pronto! Execute: theme-changer"

#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/theme-changer.sh"
DEST="/usr/local/bin/theme-changer"
DESKTOP="$HOME/.local/share/applications/theme-changer.desktop"

echo "==> Instalando theme-changer (rofi)..."

# Instala o script
sudo install -Dm755 "$SRC" "$DEST"
echo "    [ok] $DEST"

# Cria .desktop
mkdir -p "$HOME/.local/share/applications"
cat > "$DESKTOP" << EOF
[Desktop Entry]
Name=Theme Changer
Comment=Troca fastfetch logo, wallpaper e SDDM background
Exec=$DEST
Icon=preferences-desktop-theme
Terminal=false
Type=Application
Categories=Utility;Settings;
EOF
echo "    [ok] $DESKTOP"

echo ""
echo "Pronto! Execute: theme-changer"
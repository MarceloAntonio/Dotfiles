SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/theme_changer.py"
DEST="/usr/local/bin/theme-changer"
DESKTOP="$HOME/.local/share/applications/theme-changer.desktop"
 
echo "==> Instalando theme-changer..."
 
# Copia e torna executável
sudo cp "$SRC" "$DEST"
sudo chmod +x "$DEST"
echo "    [ok] $DEST"
 
# Cria .desktop
mkdir -p "$HOME/.local/share/applications"
cat > "$DESKTOP" << EOF
[Desktop Entry]
Name=Theme Changer
Comment=Troca fastfetch logo, wallpaper e SDDM background
Exec=$DEST
Icon=image-viewer
Terminal=false
Type=Application
Categories=Utility;
EOF
echo "    [ok] $DESKTOP"
 
echo ""
echo "Run theme-changer"
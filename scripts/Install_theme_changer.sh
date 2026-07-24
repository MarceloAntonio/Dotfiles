#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$SCRIPT_DIR/theme-changer"
BIN="theme-changer"
DEST="/usr/local/bin/$BIN"
DESKTOP="$HOME/.local/share/applications/theme-changer.desktop"

echo "==> Compilando theme-changer..."

# Verifica dependências
if ! pkg-config --exists gtk4; then
    echo "    [ERRO] gtk4 não encontrado. Instale com: sudo pacman -S gtk4"
    exit 1
fi

# Compila
make -C "$SRC_DIR" clean all
if [ $? -ne 0 ]; then
    echo "    [ERRO] Falha na compilação."
    exit 1
fi
echo "    [ok] Compilado"

# Instala binário
sudo install -Dm755 "$SRC_DIR/$BIN" "$DEST"
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
#!/usr/bin/env bash

# NixOS Dotfiles Installer
# This script copies your dotfiles for your user on NixOS.

set -e

CONFIG_DIR="$HOME/.config"
# Pega o diretório base (volta uma pasta a partir de 'nixos/')
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="$HOME/BKP.config"

RED="\033[1;31m"
GREEN="\033[1;32m"
CYAN="\033[1;36m"
RESET="\033[0m"

echo -e "${CYAN}========================================${RESET}"
echo -e "${CYAN}    NIXOS DOTFILES INSTALLER${RESET}"
echo -e "${CYAN}========================================${RESET}"

mkdir -p "$BACKUP_DIR"
mkdir -p "$CONFIG_DIR"

if [ -d "$DOTFILES_DIR/.config" ]; then
    echo -e "➜ Configurando pasta .config..."
    cd "$DOTFILES_DIR/.config" || exit 1
    
    # Cria a estrutura de diretórios
    find . -type d | while IFS= read -r dir; do
        rel_path="${dir#./}"
        [ -n "$rel_path" ] && mkdir -p "$CONFIG_DIR/$rel_path"
    done
    
    # Copia os arquivos para a pasta .config do usuário
    find . -type f -o -type l | while IFS= read -r file; do
        rel_path="${file#./}"
        target_path="$CONFIG_DIR/$rel_path"
        backup_path="$BACKUP_DIR/$rel_path"
        
        # Se o arquivo já existe no sistema, faz backup
        if [ -e "$target_path" ]; then
            mkdir -p "$(dirname "$backup_path")"
            mv "$target_path" "$backup_path" 2>/dev/null
        fi
        
        # Copia o arquivo para a pasta do usuário
        cp -a "$DOTFILES_DIR/.config/$rel_path" "$target_path"
    done
    echo -e "${GREEN}✔ Diretório .config configurado com sucesso!${RESET}"
fi

# Zshrc
if [ -f "$DOTFILES_DIR/.zshrc" ]; then
    echo -e "➜ Configurando .zshrc..."
    if [ -f "$HOME/.zshrc" ]; then
        mv "$HOME/.zshrc" "$BACKUP_DIR/" 2>/dev/null
    fi
    cp -a "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
    echo -e "${GREEN}✔ .zshrc configurado com sucesso!${RESET}"
fi

# Wallpapers
if [ -d "$DOTFILES_DIR/Wallpapers" ]; then
    echo -e "➜ Copiando Wallpapers..."
    DEST="$HOME/Pictures/Wallpaper"
    mkdir -p "$DEST"
    cp -r "$DOTFILES_DIR/Wallpapers/"* "$DEST/"
    echo -e "${GREEN}✔ Wallpapers copiados!${RESET}"
fi

# VSCode config
if [ -f "$DOTFILES_DIR/.config/vscode/settings.json" ]; then
    echo -e "➜ Configurando VSCode..."
    VSCODE_DEST="$HOME/.config/Code/User"
    mkdir -p "$VSCODE_DEST"
    cp -a "$DOTFILES_DIR/.config/vscode/settings.json" "$VSCODE_DEST/settings.json"
    echo -e "${GREEN}✔ VSCode configurado com sucesso!${RESET}"
fi

# McMojave Cursors
echo -e "➜ Instalando cursores McMojave..."
rm -rf /tmp/McMojave-cursors
git clone https://github.com/vinceliuice/McMojave-cursors /tmp/McMojave-cursors
cd /tmp/McMojave-cursors
./install.sh
rm -rf /tmp/McMojave-cursors
echo -e "${GREEN}✔ Cursores instalados!${RESET}"

echo -e "➜ Aplicando configurações do NixOS..."
# É necessário o sudo para copiar o arquivo e aplicar no sistema
sudo cp "$DOTFILES_DIR/nixos/configuration.nix" /etc/nixos/
sudo NIXPKGS_ALLOW_UNFREE=1 nixos-rebuild switch

echo -e "${GREEN}========================================${RESET}"
echo -e "${GREEN}   ✔ INSTALAÇÃO COMPLETA CONCLUÍDA${RESET}"
echo -e "${GREEN}========================================${RESET}"

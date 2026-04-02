#!/bin/bash

## SDDM Astronaut Theme Installer - Automated Version
## Based on original by Keyitdev https://github.com/Keyitdev/sddm-astronaut-theme

set -euo pipefail

# ========================
# CONFIG
# ========================
readonly THEME_REPO="https://github.com/Keyitdev/sddm-astronaut-theme.git"
readonly THEME_NAME="sddm-astronaut-theme"
readonly THEMES_DIR="/usr/share/sddm/themes"
readonly PATH_TO_GIT_CLONE="/tmp/$THEME_NAME"
readonly METADATA="$THEMES_DIR/$THEME_NAME/metadata.desktop"
readonly DATE=$(date +%s)

# ========================
# LOGGING
# ========================
info() {
    echo -e "\e[32m[INFO]\e[0m $*"
}

warn() {
    echo -e "\e[33m[WARN]\e[0m $*"
}

error() {
    echo -e "\e[31m[ERROR]\e[0m $*" >&2
}

# ========================
# STEPS
# ========================

install_deps() {
    info "Installing SDDM and Qt6 dependencies..."
    # Focado em Arch Linux (Pacman)
    sudo pacman -S --needed --noconfirm sddm qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg
}

clone_repo() {
    info "Cloning repository to $PATH_TO_GIT_CLONE..."
    [[ -d "$PATH_TO_GIT_CLONE" ]] && rm -rf "$PATH_TO_GIT_CLONE"
    git clone -b master --depth 1 "$THEME_REPO" "$PATH_TO_GIT_CLONE"
}

install_theme() {
    local src="$PATH_TO_GIT_CLONE"
    local dst="$THEMES_DIR/$THEME_NAME"

    info "Installing theme files to $dst..."
    [[ -d "$dst" ]] && sudo mv "$dst" "${dst}_$DATE"
    sudo mkdir -p "$dst"
    sudo cp -r "$src"/* "$dst"/

    if [[ -d "$dst/Fonts" ]]; then
        info "Installing theme fonts..."
        sudo cp -r "$dst/Fonts"/* /usr/share/fonts/
        fc-cache -f
    fi

    # Configuração do SDDM
    info "Configuring sddm.conf..."
    echo -e "[Theme]\nCurrent=$THEME_NAME" | sudo tee /etc/sddm.conf >/dev/null

    sudo mkdir -p /etc/sddm.conf.d
    echo -e "[General]\nInputMethod=qtvirtualkeyboard" | sudo tee /etc/sddm.conf.d/virtualkbd.conf >/dev/null
}

select_variant() {
    # Define a variante 'astronaut' (padrão) automaticamente
    info "Setting theme variant to: astronaut"
    if [[ -f "$METADATA" ]]; then
        sudo sed -i "s|^ConfigFile=.*|ConfigFile=Themes/astronaut.conf|" "$METADATA"
    else
        error "Metadata file not found, skipping variant selection."
    fi
}

enable_sddm() {
    info "Enabling SDDM service..."
    sudo systemctl disable display-manager.service 2>/dev/null || true
    sudo systemctl enable sddm.service
}

# ========================
# MAIN EXECUTION
# ========================

main() {
    [[ $EUID -eq 0 ]] && { error "Don't run as root directly. The script uses sudo."; exit 1; }
    
    install_deps
    clone_repo
    install_theme
    select_variant
    enable_sddm

    info "SDDM Astronaut Theme installation finished!"
}

main "$@"
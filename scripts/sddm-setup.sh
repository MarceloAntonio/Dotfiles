#!/bin/bash

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

info() { echo -e "\e[32m[INFO]\e[0m $*"; }
warn() { echo -e "\e[33m[WARN]\e[0m $*"; }
error() { echo -e "\e[31m[ERROR]\e[0m $*" >&2; }

# ========================
# INIT SYSTEM DETECTION
# ========================
INIT_SYS="unknown"
if [ -d /run/systemd/system ]; then INIT_SYS="systemd"
elif command -v rc-update >/dev/null 2>&1; then INIT_SYS="openrc"
elif command -v sv >/dev/null 2>&1; then INIT_SYS="runit"
elif command -v dinitctl >/dev/null 2>&1; then INIT_SYS="dinit"
fi

# ========================
# STEPS
# ========================
install_deps() {
    info "Installing SDDM and Qt6 dependencies..."
    sudo pacman -S --needed --noconfirm sddm qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg
    
    # Install init integration package (if not systemd)
    if [[ "$INIT_SYS" == "openrc" ]]; then
        sudo pacman -S --needed --noconfirm sddm-openrc
    elif [[ "$INIT_SYS" == "runit" ]]; then
        sudo pacman -S --needed --noconfirm sddm-runit
    elif [[ "$INIT_SYS" == "dinit" ]]; then
        sudo pacman -S --needed --noconfirm sddm-dinit
    fi
}

clone_repo() {
    info "Cloning repository to $PATH_TO_GIT_CLONE..."
    [[ -d "$PATH_TO_GIT_CLONE" ]] && rm -rf "$PATH_TO_GIT_CLONE"
    git clone -b master --depth 1 "$THEME_REPO" "$PATH_TO_GIT_CLONE"
}

install_theme() {
    local src="$PATH_TO_GIT_CLONE"
    local dst="$THEMES_DIR/$THEME_NAME"

    info "Installing theme files..."
    [[ -d "$dst" ]] && sudo mv "$dst" "${dst}_$DATE"
    sudo mkdir -p "$dst"
    sudo cp -r "$src"/* "$dst"/

    if [[ -d "$dst/Fonts" ]]; then
        info "Installing theme fonts..."
        sudo cp -r "$dst/Fonts"/* /usr/share/fonts/
        fc-cache -f
    fi

    info "Configuring sddm.conf..."
    echo -e "[Theme]\nCurrent=$THEME_NAME" | sudo tee /etc/sddm.conf >/dev/null
    sudo mkdir -p /etc/sddm.conf.d
    echo -e "[General]\nInputMethod=qtvirtualkeyboard" | sudo tee /etc/sddm.conf.d/virtualkbd.conf >/dev/null
}

select_variant() {
    info "Setting theme variant to: astronaut"
    if [[ -f "$METADATA" ]]; then
        sudo sed -i "s|^ConfigFile=.*|ConfigFile=Themes/astronaut.conf|" "$METADATA"
    fi
}

enable_sddm() {
    info "Enabling SDDM service for init system: $INIT_SYS"
    
    if [[ "$INIT_SYS" == "systemd" ]]; then
        sudo systemctl disable display-manager.service 2>/dev/null || true
        sudo systemctl enable sddm.service
    elif [[ "$INIT_SYS" == "openrc" ]]; then
        sudo rc-update add sddm default
    elif [[ "$INIT_SYS" == "runit" ]]; then
        sudo ln -sf /etc/runit/sv/sddm /run/runit/service/
    elif [[ "$INIT_SYS" == "dinit" ]]; then
        sudo dinitctl enable sddm
    else
        warn "Init system not recognized automatically. Please enable SDDM manually."
    fi
}

# ========================
# MAIN EXECUTION
# ========================
main() {
    install_deps
    clone_repo
    install_theme
    select_variant
    enable_sddm
    info "SDDM Astronaut Theme installation finished!"
}

main "$@"

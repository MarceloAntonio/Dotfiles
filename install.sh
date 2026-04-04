#!/bin/bash

# ========================
# CONFIG
# ========================
set -e

BACKUP_DIR="$HOME/BKP.config"
CONFIG_DIR="$HOME/.config"
DOTFILES_DIR="$(pwd)"
INSTALL_DIR="/tmp/yay"

# ========================
# COLORS
# ========================
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
RESET="\033[0m"

# ========================
# UTILS
# ========================
log() {
    echo -e "${BLUE}[$1]${RESET} $2"
}

success() {
    echo -e "${GREEN}✔ $1${RESET}"
}

warn() {
    echo -e "${YELLOW}⚠ $1${RESET}"
}

error() {
    echo -e "${RED}✖ $1${RESET}"
}

progress() {
    echo -e "${CYAN}➜ $1...${RESET}"
    sleep 0.5
}

run_step() {
    DESC="$1"
    shift

    progress "$DESC"

    if "$@"; then
        success "$DESC"
    else
        error "$DESC failed"
    fi
}

# ========================
# PACKAGES
# ========================
PACMAN_DEPS=(
    hyprland firefox kitty rofi-wayland fastfetch waybar
    network-manager-applet pavucontrol ttf-jetbrains-mono-nerd
    grim slurp wl-clipboard dolphin code hyprpaper
    polkit-kde-agent brightnessctl playerctl inter-font 
    awww hyprlock zsh breeze-icons zsh-autosuggestions zsh-syntax-highlighting
    papirus-icon-theme breeze-gtk base-devel git imagemagick blueman
    python python-pip tk python-pillow eza
)

AUR_DEPS=(
    bibata-cursor-theme zsh-you-should-use zsh-history-substring-search
)

echo -e "${CYAN}"
echo "========================================"
echo "    DOTFILES FULL INSTALLER"
echo "========================================"
echo -e "${RESET}"

# ========================
# 1. YAY
# ========================
if ! command -v yay &> /dev/null; then
    run_step "Installing yay" bash -c "
        sudo pacman -S --needed --noconfirm base-devel git &&
        git clone https://aur.archlinux.org/yay.git $INSTALL_DIR &&
        cd $INSTALL_DIR &&
        makepkg -si --noconfirm &&
        cd ~ &&
        rm -rf $INSTALL_DIR
    "
else
    warn "yay already installed"
fi

# ========================
# 2. PACMAN
# ========================
run_step "Installing pacman packages" sudo pacman -S --needed --noconfirm "${PACMAN_DEPS[@]}"

# ========================
# 3. AUR
# ========================
run_step "Installing AUR packages" yay -S --needed --noconfirm "${AUR_DEPS[@]}"

# ========================
# 4. SDDM
# ========================
run_step "Installing SDDM Astronaut Theme" bash "$DOTFILES_DIR/scripts/sddm-setup.sh"
# ========================
# 5. BACKUP
# ========================
run_step "Backing up configs" bash -c "
    mkdir -p $BACKUP_DIR
    mkdir -p $CONFIG_DIR
    for item in $CONFIG_DIR/*; do
        mv \$item $BACKUP_DIR/ 2>/dev/null
    done
"

# ========================
# 6. DOTFILES
# ========================
run_step "Installing dotfiles" bash -c "
    for dir in $DOTFILES_DIR/.config/*; do
        cp -a \$dir $CONFIG_DIR/
    done
"

run_step "Installing .zshrc" bash -c "
    [ -f $DOTFILES_DIR/.zshrc ] && cp $DOTFILES_DIR/.zshrc $HOME/
"

# ========================
# 7. THEMES
# ========================
run_step "Applying themes" bash -c "
    mkdir -p ~/.icons/default
    cat > ~/.icons/default/index.theme <<EOF
[Icon Theme]
Inherits=Bibata-Original-Ice
EOF

    
    mkdir -p ~/.config/gtk-3.0
    cat > ~/.config/gtk-3.0/settings.ini <<EOF
[Settings]
gtk-theme-name=Adwaita
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Inter Display 11
gtk-cursor-theme-name=Bibata-Original-Ice
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_ICONS
gtk-toolbar-icon-size=GTK_ICON_SIZE_SMALL_TOOLBAR
gtk-button-images=0
gtk-menu-images=0
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
gtk-application-prefer-dark-theme=1
EOF

    
    mkdir -p ~/.config/gtk-4.0
    cat > ~/.config/gtk-4.0/settings.ini <<EOF
[Settings]
gtk-theme-name=Adwaita
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Inter Display 11
gtk-cursor-theme-name=Bibata-Original-Ice
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=1
EOF

    
    gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Original-Ice'
    gsettings set org.gnome.desktop.interface cursor-size 24
    gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
    gsettings set org.gnome.desktop.interface font-name 'Inter Display 11'
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
"

# ========================
# 8. THEME CHANGER
# ========================
run_step "Instalando e configurando o Theme Changer" bash -c "
    # Dá permissão de execução para o script
    chmod +x scripts/Install_theme_changer.sh
    
    # Executa o script
    ./scripts/Install_theme_changer.sh
"

# ========================
# 9. WALLPAPER
# ========================
run_step "Copying wallpapers" bash -c "
    if [ -d $DOTFILES_DIR/Wallpapers ]; then
        DEST=\$HOME/Pictures/Wallpaper
        mkdir -p \$DEST
        cp -a $DOTFILES_DIR/Wallpapers/* \$DEST/
    fi
"

# ========================
# 10. ZSH DEFAULT
# ========================
run_step "Setting ZSH as default shell" bash -c "
    chsh -s \$(which zsh)
"

echo -e "${GREEN}"
echo "========================================"
echo "   ✔ INSTALLATION COMPLETED"
echo "========================================"
echo -e "${RESET}"

echo -e "${CYAN}Reboot recommended${RESET}"
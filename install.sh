#!/bin/bash

# ========================
# ROOT CHECK
# ========================
if [[ $EUID -eq 0 ]]; then
  echo -e "\033[1;31m✖ Do not run this script as root (sudo). The script will prompt for your password when needed.\033[0m"
  exit 1
fi

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
log() { echo -e "${BLUE}[$1]${RESET} $2"; }
success() { echo -e "${GREEN}✔ $1${RESET}"; }
warn() { echo -e "${YELLOW}⚠ $1${RESET}"; }
error() { echo -e "${RED}✖ $1${RESET}"; }
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
  grim slurp wl-clipboard nautilus hyprpaper
  polkit-kde-agent brightnessctl playerctl inter-font
  awww hyprlock zsh breeze-icons zsh-autosuggestions zsh-syntax-highlighting
  breeze-gtk base-devel git imagemagick blueman
  python python-pip tk python-pillow eza nvim imv pipewire pipewire-pulse wireplumber swaync
)

AUR_DEPS=(
  zsh-you-should-use zsh-history-substring-search mcmojave-cursors
)

echo -e "${CYAN}"
echo "========================================"
echo "    DOTFILES FULL INSTALLER"
echo "========================================"
echo -e "${RESET}"

# ========================
# 1. YAY
# ========================
if ! command -v yay &>/dev/null; then
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
# 3.5 PULSAR (Network Manager)
# ========================
run_step "Installing Pulsar (Binary)" bash -c "
    rm -rf /tmp/pulsar &&
    git clone https://github.com/MarceloAntonio/pulsar.git /tmp/pulsar &&
    cd /tmp/pulsar &&
    makepkg -si --noconfirm &&
    rm -rf /tmp/pulsar
"

# ========================
# 4. SDDM
# ========================
echo -ne "${YELLOW}⚠ Deseja instalar o tema SDDM Astronaut e substituir o atual? (s/N): ${RESET}"
read -r change_sddm
if [[ "$change_sddm" =~ ^[SsYy]$ ]]; then
  run_step "Installing SDDM Astronaut Theme" bash "$DOTFILES_DIR/scripts/sddm-setup.sh"
else
  success "Mantendo o tema SDDM atual"
fi

# ========================
# 5. BACKUP & 6. DOTFILES
# ========================
run_step "Backing up and installing configs" bash -c '
    mkdir -p "'$BACKUP_DIR'"
    mkdir -p "'$CONFIG_DIR'"
    
    if [ -d "'$DOTFILES_DIR'"/.config ]; then
        cd "'$DOTFILES_DIR'"/.config || exit 1
        
        # Create directory structures
        find . -type d | while IFS= read -r dir; do
            rel_path="${dir#./}"
            [ -n "$rel_path" ] && mkdir -p "'$CONFIG_DIR'/$rel_path"
        done
        
        # Back up and copy files individually
        find . -type f -o -type l | while IFS= read -r file; do
            rel_path="${file#./}"
            target_path="'$CONFIG_DIR'/$rel_path"
            backup_path="'$BACKUP_DIR'/$rel_path"
            
            # If the target file already exists in the system, back it up
            if [ -e "$target_path" ]; then
                mkdir -p "$(dirname "$backup_path")"
                mv "$target_path" "$backup_path" 2>/dev/null
            fi
            
            # Copy the new dotfile
            cp -a "$file" "$target_path"
        done
    fi
'

run_step "Installing .zshrc" bash -c '
    if [ -f "'$DOTFILES_DIR'/.zshrc" ]; then
        [ -f "$HOME/.zshrc" ] && mv "$HOME/.zshrc" "'$BACKUP_DIR'/"
        cp "'$DOTFILES_DIR'/.zshrc" "$HOME/"
    fi
'

# ========================
# 7. THEMES
# ========================
run_step "Installing WhiteSur Icon Theme" bash -c '
    rm -rf /tmp/WhiteSur-icon-theme
    git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git /tmp/WhiteSur-icon-theme
    cd /tmp/WhiteSur-icon-theme
    ./install.sh -a
    rm -rf /tmp/WhiteSur-icon-theme
'

run_step "Applying themes" bash -c "
    mkdir -p ~/.icons/default
    cat > ~/.icons/default/index.theme <<EOF
[Icon Theme]
Inherits=mcmojave-cursors
EOF

    mkdir -p ~/.config/gtk-3.0
    cat > ~/.config/gtk-3.0/settings.ini <<EOF
[Settings]
gtk-theme-name=Adwaita
gtk-icon-theme-name=WhiteSur-dark
gtk-font-name=Inter Display 11
gtk-cursor-theme-name=mcmojave-cursors
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
gtk-icon-theme-name=WhiteSur-dark
gtk-font-name=Inter Display 11
gtk-cursor-theme-name=mcmojave-cursors
gtk-cursor-theme-size=24
gtk-application-prefer-dark-theme=1
EOF

    # Added '|| true' to prevent failures if run outside a graphical interface (TTY)
    gsettings set org.gnome.desktop.interface cursor-theme 'mcmojave-cursors' || true
    gsettings set org.gnome.desktop.interface cursor-size 24 || true
    gsettings set org.gnome.desktop.interface icon-theme 'WhiteSur-dark' || true
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita' || true
    gsettings set org.gnome.desktop.interface font-name 'Inter Display 11' || true
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true
"

# ========================
# 8. THEME CHANGER
# ========================
run_step "Installing Theme Changer" bash -c "
    # Grant execution permissions to the script
    chmod +x scripts/Install_theme_changer.sh
    
    # Run the script
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
# 10. LAZYVIM
# ========================
run_step "Installing LazyVim" bash -c "git clone https://github.com/LazyVim/starter ~/.config/nvim"

run_step "Cleaning cache" bash -c "rm -rf ~/.config/nvim/.git"

run_step "Configuring LazyVim Theme (Mocha + Transparency)" bash -c "
mkdir -p ~/.config/nvim/lua/plugins && \
cat << 'EOF' > ~/.config/nvim/lua/plugins/catppuccin.lua
return {
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
    opts = {
      flavour = 'mocha',
      transparent_background = true,
      integrations = {
        telescope = true,
        mason = true,
        neotree = true,
        which_key = true,
        navic = { enabled = true },
        mini = true,
      },
    },
  },
  {
    'LazyVim/LazyVim',
    opts = {
      colorscheme = 'catppuccin-mocha',
    },
  },
}
EOF
"

run_step "Pre-installing LazyVim plugins" bash -c "nvim --headless +Lazy! sync +qa"

# ========================
# 11. CODE OSS
# ========================
run_step "Installing Code OSS settings" bash -c '
    DEST="$HOME/.config/Code - OSS/User"
    mkdir -p "$DEST"
    if [ -f "'"$DOTFILES_DIR"'/.config/vscode/settings.json" ]; then
        cp "'"$DOTFILES_DIR"'/.config/vscode/settings.json" "$DEST/settings.json"
    fi
'

run_step "Installing Code OSS extensions" bash -c '
    code --install-extension esbenp.prettier-vscode
    code --install-extension Catppuccin.catppuccin-vsc-pack
'

# ========================
# 12. ORBIT
# ========================
run_step "Setting ZSH as default shell" bash -c "
    systemctl --user enable --now orbit
"
# ========================
# 13. ZSH DEFAULT
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

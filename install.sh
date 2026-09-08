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

# Ask for the administrator password upfront
sudo -v
# Keep-alive: update existing sudo time stamp until the script has finished
while true; do
  sudo -n true
  sleep 60
  kill -0 "$$" || exit
done 2>/dev/null &

BACKUP_DIR="$HOME/BKP.config"
CONFIG_DIR="$HOME/.config"
DOTFILES_DIR="$(pwd)"

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
# Agrupados por categoria: se um pacote de um grupo falhar
# (nome errado, saiu do repo, etc), só aquele grupo é afetado —
# o resto da instalação continua normalmente.
# ========================
HYPRLAND_WAYLAND=(hyprland hyprlock awww xdg-desktop-portal-hyprland polkit-kde-agent qt5-wayland qt6-wayland)
TERMINAL_SHELL=(kitty zsh zsh-autosuggestions zsh-syntax-highlighting)
BAR_NOTIFICATIONS=(waybar swaync)
LAUNCHER_CLIPBOARD=(rofi-wayland cliphist wl-clipboard)
APPS=(firefox thunar pavucontrol)
SCREENSHOT_MEDIA=(grim slurp brightnessctl playerctl pipewire pipewire-pulse wireplumber)
NETWORK_BLUETOOTH=(network-manager-applet blueman)
FONTS_THEMES=(ttf-jetbrains-mono-nerd inter-font breeze-icons breeze-gtk)
DEV_TOOLS=(neovim git base-devel nodejs npm ripgrep fd unzip)
UTILITIES=(fastfetch eza starship python python-pip imagemagick libnotify bat tmux ncdu zathura zathura-pdf-mupdf)
SYSTEM_OPTIMIZATION=(intel-ucode sof-firmware power-profiles-daemon zram-generator earlyoom reflector ufw intel-media-driver libva-utils vpl-gpu-rt intel-compute-runtime opencl-mesa vulkan-intel clinfo)

PACMAN_GROUPS=(
  HYPRLAND_WAYLAND
  TERMINAL_SHELL
  BAR_NOTIFICATIONS
  LAUNCHER_CLIPBOARD
  APPS
  SCREENSHOT_MEDIA
  NETWORK_BLUETOOTH
  FONTS_THEMES
  DEV_TOOLS
  UTILITIES
  SYSTEM_OPTIMIZATION
)

echo -e "${CYAN}"
echo "========================================"
echo "    DOTFILES FULL INSTALLER"
echo "========================================"
echo -e "${RESET}"

# ========================
# 1. SYSTEM UPDATE
# ========================
run_step "Updating system (pacman -Syu)" sudo pacman -Syu --noconfirm

# ========================
# 2. PACMAN (por grupo)
# ========================
for group_name in "${PACMAN_GROUPS[@]}"; do
  declare -n group_ref="$group_name"
  run_step "Installing group: $group_name" sudo pacman -S --needed --noconfirm "${group_ref[@]}"
  unset -n group_ref
done

# ========================
# 3. MANUAL INSTALLS (ZSH Plugins & Cursors)
# ========================
run_step "Installing zsh-history-substring-search" bash -c "
    mkdir -p ~/.local/share/zsh/plugins
    if [ ! -d ~/.local/share/zsh/plugins/zsh-history-substring-search ]; then
        git clone https://github.com/zsh-users/zsh-history-substring-search ~/.local/share/zsh/plugins/zsh-history-substring-search
    fi
"

run_step "Installing McMojave-cursors" bash -c "
    rm -rf /tmp/McMojave-cursors
    git clone https://github.com/vinceliuice/McMojave-cursors /tmp/McMojave-cursors
    cd /tmp/McMojave-cursors
    ./install.sh
    rm -rf /tmp/McMojave-cursors
    if [ -d ~/.icons/McMojave-cursors ]; then
        mv ~/.icons/McMojave-cursors ~/.icons/mcmojave-cursors
    fi
"

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
echo -ne "${YELLOW}⚠ Do you want to install the SDDM Astronaut theme and replace the current one? (Y/N): ${RESET}"
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

    # gtk-3.0/settings.ini e gtk-4.0/settings.ini já vêm do seu
    # repo de dotfiles (passo 5&6, Backup & Dotfiles) — não são
    # regerados aqui pra não sobrescrever o que já está versionado.

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
# 10. NEOVIM PLUGINS
# ========================

run_step "Pre-installing Neovim plugins (lazy.nvim)" bash -c "nvim --headless '+Lazy! sync' +qa"

# ========================
# 11. ZSH DEFAULT
# ========================
run_step "Setting ZSH as default shell" bash -c "
    if [ \"\$SHELL\" != \"\$(which zsh)\" ]; then
        chsh -s \$(which zsh)
    fi
"

echo -e "${GREEN}"
echo "========================================"
echo "   ✔ INSTALLATION COMPLETED"
echo "========================================"
echo -e "${RESET}"
echo -e "${CYAN}Reboot recommended${RESET}"

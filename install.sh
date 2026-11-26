#!/usr/bin/env bash
# Arch Linux / Hyprland Lua desktop installer.
set -Eeuo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false
INSTALL_ASSETS=true
INSTALL_WALLPAPERS=true
INSTALL_NVIM=true
INSTALL_SDDM=false
SET_SHELL=false

usage() {
  cat <<'HELP'
Uso: ./install.sh [opções]

Instala o rice Hyprland + Quickshell no Arch Linux. Execute como usuário comum.

  --dry-run          Mostra o plano e os pacotes, sem sudo nem alterações
  --skip-assets      Não baixa ícones, cursores e a fonte SF Pro
  --skip-wallpapers  Não baixa a coleção de wallpapers
  --skip-nvim        Não sincroniza os plugins do Neovim
  --sddm             Instala e habilita o tema SDDM Astronaut (opcional)
  --set-shell        Define Zsh como shell padrão (opcional)
  -h, --help         Mostra esta ajuda

As configurações substituídas recebem backup em
~/.local/state/dotfiles-backups/<data-hora-pid>/.
Waybar, SwayNC e Pulsar não são instalados; pacotes existentes não são removidos.
HELP
}
for option in "$@"; do
  case "$option" in
    --dry-run) DRY_RUN=true ;;
    --skip-assets) INSTALL_ASSETS=false ;;
    --skip-wallpapers) INSTALL_WALLPAPERS=false ;;
    --skip-nvim) INSTALL_NVIM=false ;;
    --sddm) INSTALL_SDDM=true ;;
    --set-shell) SET_SHELL=true ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Opção desconhecida: %s\n' "$option" >&2; usage >&2; exit 2 ;;
  esac
done

# Quickshell supplies the Qt/PAM, NetworkManager, BlueZ, PipeWire and MPRIS APIs.
# GTK3/PyGObject resolves the WhiteSur application icons; python-dbus serves
# Bluetooth pairing and the independent logind lock bridge.
DESKTOP=(hyprland hyprlock quickshell awww xdg-desktop-portal-hyprland polkit polkit-kde-agent qt6-wayland)
SHELL_TOOLS=(kitty zsh zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search)
INTEGRATION=(python python-pillow python-gobject python-dbus gtk3 networkmanager nm-connection-editor bluez bluez-utils power-profiles-daemon)
MEDIA=(pipewire pipewire-audio pipewire-pulse wireplumber brightnessctl playerctl grim slurp hyprpicker rofi cliphist wl-clipboard libnotify imagemagick)
APPS=(firefox nautilus neovim tree-sitter-cli git lazygit base-devel nodejs npm ripgrep fd unzip)
APPEARANCE=(desktop-file-utils ttf-jetbrains-mono-nerd noto-fonts-emoji inter-font breeze-icons breeze-gtk fontconfig)
UTILITIES=(fastfetch eza starship bat tmux ncdu zathura zathura-pdf-mupdf 7zip curl cpio procps-ng sof-firmware)
PACKAGES=("${DESKTOP[@]}" "${SHELL_TOOLS[@]}" "${INTEGRATION[@]}" "${MEDIA[@]}" "${APPS[@]}" "${APPEARANCE[@]}" "${UTILITIES[@]}")

if $DRY_RUN; then
  printf 'Origem: %s\nDestino: %s\n' "$DOTFILES_DIR" "$HOME"
  printf 'Pacotes (pacman -Syu --needed):\n  %s\n' "${PACKAGES[*]}"
  printf 'Etapas: backup por timestamp; copiar .config, .local e .zshrc; gerar caminhos e paletas; habilitar serviços de rede/Bluetooth/áudio/bloqueio.\n'
  printf 'Assets: %s | wallpapers: %s | plugins Nvim: %s | SDDM: %s | alterar shell: %s\n' "$INSTALL_ASSETS" "$INSTALL_WALLPAPERS" "$INSTALL_NVIM" "$INSTALL_SDDM" "$SET_SHELL"
  printf 'Não executado: sudo, instalação, downloads, bloqueio, suspensão ou remoção de pacotes.\n'
  exit 0
fi
if ((EUID == 0)); then
  printf 'Execute sem sudo; o instalador pedirá a senha quando necessário.\n' >&2
  exit 1
fi
command -v pacman >/dev/null || { printf 'Este instalador requer Arch Linux/pacman.\n' >&2; exit 1; }
BACKUP_DIR="$HOME/.local/state/dotfiles-backups/$(date +%Y%m%d-%H%M%S)-$$"
mkdir -p -- "$BACKUP_DIR"
trap 'printf "Instalação interrompida na linha %s. Backups: %s\n" "$LINENO" "$BACKUP_DIR" >&2' ERR
step() { printf '\n➜ %s\n' "$1"; shift; "$@"; }

install_tree() {
  local source=$1 destination=$2 backup_prefix=$3 file relative target backup
  [[ -d "$source" ]] || return 0
  while IFS= read -r -d '' file; do
    relative=${file#"$source"/}
    target="$destination/$relative"
    backup="$BACKUP_DIR/$backup_prefix/$relative"
    mkdir -p -- "$(dirname -- "$target")"
    if [[ -e "$target" || -L "$target" ]]; then
      mkdir -p -- "$(dirname -- "$backup")"
      mv -- "$target" "$backup"
    fi
    cp -a -- "$file" "$target"
  done < <(find "$source" -type d -name __pycache__ -prune -o \( -type f -o -type l \) ! -name '*.pyc' ! -name '*.bak' -print0)
}
backup_generated() {
  local relative target
  for relative in .local/state/quickshell-theme.json .config/hypr/.current_wallpaper .config/hypr/hyprlock/wallpaper; do
    target="$HOME/$relative"
    if [[ -e "$target" || -L "$target" ]]; then
      mkdir -p -- "$(dirname -- "$BACKUP_DIR/$relative")"
      cp -a -- "$target" "$BACKUP_DIR/$relative"
    fi
  done
}
install_configs() {
  install_tree "$DOTFILES_DIR/.config" "$HOME/.config" .config
  install_tree "$DOTFILES_DIR/.local" "$HOME/.local" .local
  if [[ -f "$DOTFILES_DIR/.zshrc" ]]; then
    if [[ -e "$HOME/.zshrc" || -L "$HOME/.zshrc" ]]; then mv -- "$HOME/.zshrc" "$BACKUP_DIR/.zshrc"; fi
    cp -- "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
  fi
  chmod +x "$HOME/.local/bin/rice-lock" "$HOME/.local/bin/rice-monitors"
  find "$HOME/.config/hypr/scripts" -maxdepth 1 -type f -name '*.sh' -exec chmod +x {} +
  # Desktop launchers cannot rely on a login shell to add ~/.local/bin to PATH.
  python "$DOTFILES_DIR/scripts/prepare-user-config.py"
}
install_wallpapers() {
  local work
  work=$(mktemp -d -t dotfiles-wallpapers.XXXXXXXX)
  curl -fL --retry 2 -o "$work/wallpapers.tar.gz" 'https://github.com/MarceloAntonio/wallpapers_dotfile/archive/refs/tags/wallpapers.tar.gz'
  mkdir -p "$HOME/Images/Wallpaper"
  tar xzf "$work/wallpapers.tar.gz" -C "$HOME/Images/Wallpaper" --strip-components=1 --exclude=README.md
  rm -rf -- "$work"
}
configure_locales() {
  sudo sed -i -E 's/^#[[:space:]]*(pt_BR.UTF-8 UTF-8|en_US.UTF-8 UTF-8)/\1/' /etc/locale.gen
  sudo locale-gen
  # Inglês é o padrão; Português fica a um clique em Central → Geral.
  sudo localectl set-locale LANG=en_US.UTF-8
}
configure_services() {
  sudo systemctl enable NetworkManager.service bluetooth.service power-profiles-daemon.service
  if systemctl --user show-environment >/dev/null 2>&1; then
    systemctl --user daemon-reload
    systemctl --user enable pipewire.socket pipewire-pulse.socket wireplumber.service rice-lock-bridge.service
    # Old daemons would compete for org.freedesktop.Notifications.
    systemctl --user disable --now swaync.service waybar.service 2>/dev/null || true
    systemctl --user mask swaync.service
    if [[ -n ${WAYLAND_DISPLAY:-} && -n ${XDG_SESSION_ID:-} ]]; then
      systemctl --user import-environment WAYLAND_DISPLAY XDG_SESSION_ID
      [[ -z ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] || systemctl --user import-environment HYPRLAND_INSTANCE_SIGNATURE
      [[ -z ${XDG_CURRENT_DESKTOP:-} ]] || systemctl --user import-environment XDG_CURRENT_DESKTOP
      systemctl --user restart rice-lock-bridge.service
    fi
  else
    printf 'Sem sessão systemd de usuário ativa; os serviços de usuário serão habilitados no próximo login.\n'
    mkdir -p "$HOME/.config/systemd/user/graphical-session.target.wants"
    ln -sfn ../rice-lock-bridge.service "$HOME/.config/systemd/user/graphical-session.target.wants/rice-lock-bridge.service"
  fi
}
configure_appearance() {
  mkdir -p "$HOME/.icons/default"
  printf '[Icon Theme]\nInherits=mcmojave-cursors\n' > "$HOME/.icons/default/index.theme"
  if [[ -n ${DBUS_SESSION_BUS_ADDRESS:-} ]]; then
    gsettings set org.gnome.desktop.interface cursor-theme mcmojave-cursors || true
    gsettings set org.gnome.desktop.interface cursor-size 24 || true
    gsettings set org.gnome.desktop.interface icon-theme WhiteSur-dark || true
    gsettings set org.gnome.desktop.interface gtk-theme Adwaita || true
    gsettings set org.gnome.desktop.interface font-name 'SF Pro Display 11' || true
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark || true
  fi
}

step 'Atualizando o sistema e instalando dependências' sudo pacman -Syu --needed --noconfirm "${PACKAGES[@]}"
step 'Preservando estado gerado e wallpaper' backup_generated
step 'Instalando configurações e comandos locais' install_configs
if $INSTALL_ASSETS; then step 'Instalando ícones, cursores e SF Pro' bash "$DOTFILES_DIR/scripts/install-assets.sh"; fi
if $INSTALL_WALLPAPERS; then step 'Baixando wallpapers' install_wallpapers; fi
step 'Preparando wallpaper e paletas do usuário' python "$DOTFILES_DIR/scripts/prepare-user-config.py" --initialize
step 'Registrando o seletor de personalização Quickshell' bash "$DOTFILES_DIR/scripts/install-theme-changer.sh"
step 'Aplicando preferências de aparência' configure_appearance
[[ -r /etc/pam.d/hyprlock ]] || { printf 'A política PAM /etc/pam.d/hyprlock não foi instalada.\n' >&2; exit 1; }
step 'Habilitando locales pt_BR e en_US (padrão: inglês)' configure_locales
step 'Habilitando serviços' configure_services
if $INSTALL_SDDM; then step 'Instalando SDDM Astronaut' bash "$DOTFILES_DIR/scripts/sddm-setup.sh"; fi
if $INSTALL_NVIM; then step 'Sincronizando plugins do Neovim' nvim --headless '+Lazy! sync' +qa; fi
if $SET_SHELL; then
  if [[ ${SHELL:-} != "$(command -v zsh)" ]]; then step 'Definindo Zsh como shell padrão' chsh -s "$(command -v zsh)"; fi
fi
printf '\nInstalação concluída. Backup: %s\nEntre novamente na sessão Hyprland para usar toda a configuração.\n' "$BACKUP_DIR"

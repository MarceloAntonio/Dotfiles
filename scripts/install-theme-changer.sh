#!/usr/bin/env bash
# Keep the historical command name while using the native Quickshell selector.
set -Eeuo pipefail
source_script="$HOME/.config/hypr/scripts/theme-changer.sh"
command_path="$HOME/.local/bin/theme-changer"
desktop="$HOME/.local/share/applications/theme-changer.desktop"
[[ -f "$source_script" ]] || { printf 'Seletor Quickshell não instalado: %s\n' "$source_script" >&2; exit 1; }
mkdir -p "$(dirname "$command_path")" "$(dirname "$desktop")"
chmod +x "$source_script"
ln -sfn ../../.config/hypr/scripts/theme-changer.sh "$command_path"
# Quote the absolute path; launchers do not expand $HOME in an Exec field.
python - "$desktop" "$command_path" <<'PY'
from pathlib import Path
import sys
path, command = map(Path, sys.argv[1:])
quoted = str(command).replace('\\', '\\\\').replace('"', '\\"').replace('`', '\\`').replace('$', '\\$')
path.write_text('[Desktop Entry]\nName=Personalizar\nComment=Wallpaper, tela de login, Fastfetch e temas do Kitty\nExec="' + quoted + '"\nIcon=preferences-desktop-theme\nTerminal=false\nType=Application\nCategories=Settings;DesktopSettings;\n')
PY
if command -v update-desktop-database >/dev/null; then
  update-desktop-database "$HOME/.local/share/applications"
fi
printf 'Seletor Quickshell disponível em %s\n' "$command_path"

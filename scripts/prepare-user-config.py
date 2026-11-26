#!/usr/bin/env python3
"""Resolve install-time paths and create user-owned generated shell data."""
from pathlib import Path
import shutil
import subprocess
import sys

HOME = Path.home()
CONFIG = HOME / '.config'
LOCAL = HOME / '.local'
DEFAULT_WALLPAPER = Path(__file__).resolve().parents[1] / 'assets/wallpaper/os-windows-7-arch-linux.jpg'


def desktop_home(value):
    # Exec fields have Desktop Entry string escapes and command-line quotes.
    return str(value).replace('\\', '\\\\').replace('"', '\\"').replace('`', '\\`').replace('$', '\\$')


def prepare_paths():
    templates = [CONFIG / 'rofi/config.rasi', LOCAL / 'share/applications/rice-monitors.desktop', LOCAL / 'share/applications/theme-changer.desktop']
    for path in templates:
        if not path.is_file():
            continue
        text = path.read_text()
        if '@HOME@' in text:
            value = desktop_home(HOME) if path.suffix == '.desktop' else str(HOME).replace('\\', '\\\\').replace('"', '\\"')
            path.write_text(text.replace('@HOME@', value))
    for name in ['rice-monitors', 'rice-lock']:
        desktop = LOCAL / 'share/applications' / (name + '.desktop')
        if desktop.exists():
            lines = desktop.read_text().splitlines()
            lines = ['Exec="' + desktop_home(LOCAL / 'bin' / name) + '"' if line.startswith('Exec=') else line for line in lines]
            desktop.write_text('\n'.join(lines) + '\n')


def initialize():
    (HOME / 'Images/Wallpaper').mkdir(parents=True, exist_ok=True)
    cache = CONFIG / 'hypr/.current_wallpaper'
    current = None
    try:
        candidate = Path(cache.read_text().strip()).expanduser()
        if candidate.is_file():
            current = candidate
    except OSError:
        pass
    if current is None:
        folder = HOME / 'Images/Wallpaper'
        preferred = folder / DEFAULT_WALLPAPER.name
        if not preferred.is_file() and DEFAULT_WALLPAPER.is_file():
            shutil.copy2(DEFAULT_WALLPAPER, preferred)
        if preferred.is_file():
            current = preferred
        elif folder.is_dir():
            current = next((p for p in sorted(folder.iterdir()) if p.is_file() and p.suffix.lower() in {'.jpg', '.jpeg', '.png', '.webp'}), None)
    if current is not None:
        cache.parent.mkdir(parents=True, exist_ok=True)
        cache.write_text(str(current) + '\n')
        lock_wall = CONFIG / 'hypr/hyprlock/wallpaper'
        lock_wall.parent.mkdir(parents=True, exist_ok=True)
        if not lock_wall.exists() and not lock_wall.is_symlink():
            lock_wall.symlink_to(current)
    else:
        print('Nenhum wallpaper local: use Personalizar para escolher uma imagem depois da instalação.')
    shell = CONFIG / 'quickshell/control-center'
    subprocess.run([sys.executable, str(shell / 'theme-mode.py')], check=True, stdout=subprocess.DEVNULL)
    subprocess.run([sys.executable, str(shell / 'kitty_adaptive.py')], check=True)


if __name__ == '__main__':
    prepare_paths()
    if '--initialize' in sys.argv:
        initialize()

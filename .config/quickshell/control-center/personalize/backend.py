#!/usr/bin/env python3
"""Catalog and apply the four existing personalization sources without a shell."""
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import tempfile

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from kitty_adaptive import generate as generate_kitty_adaptive, refresh as refresh_kitty_adaptive

HOME = Path.home()
WALLPAPERS = HOME / "Pictures/Wallpaper"
WALL_CACHE = HOME / ".config/hypr/.current_wallpaper"
LOCK_WALL = HOME / ".config/hypr/hyprlock/wallpaper"
KITTY = HOME / ".config/kitty"
FASTFETCH = HOME / ".config/fastfetch/config.jsonc"
FF_ICONS = HOME / ".config/fastfetch/icons"
SDDM = Path("/usr/share/sddm/themes/sddm-astronaut-theme/Themes/astronaut.conf")
SDDM_IMAGES = SDDM.parent.parent / "Backgrounds"
EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp", ".gif"}


def read(path):
    try:
        return path.read_text()
    except (OSError, UnicodeError):
        return ""


def natural(value):
    return [int(x) if x.isdigit() else x.casefold() for x in re.split(r"(\d+)", str(value))]


def images(folder):
    return sorted((p for p in folder.glob("*") if p.is_file() and p.suffix.lower() in EXTENSIONS), key=lambda p: natural(p.name))


def image_item(path):
    return {"id": str(path), "name": path.stem, "preview": path.as_uri(), "kind": "image"}


def palette(path):
    values = dict(re.findall(r"(?m)^\s*(\w+)\s+(#[0-9a-fA-F]{6})\b", read(path)))
    return {"background": values.get("background", "#131313"), "foreground": values.get("foreground", "#ffffff"),
            "colors": [values.get(f"color{i}", "#ffffff") for i in range(16)]}


def logo_source(text):
    # Restrict changes to logo.source, preserving JSONC comments and all modules.
    logo = re.search(r'"logo"\s*:\s*\{[^}]*\}', text, re.S)
    if not logo:
        raise ValueError("A configuração do Fastfetch não contém a seção logo.")
    source = re.search(r'"source"\s*:\s*("(?:\\.|[^"\\])*")', logo.group())
    if not source:
        raise ValueError("A configuração do Fastfetch não contém logo.source.")
    start = logo.start() + source.start(1)
    end = logo.start() + source.end(1)
    return json.loads(source[1]), start, end


def catalog():
    generate_kitty_adaptive()
    wallpapers = images(WALLPAPERS)
    wall_current = read(WALL_CACHE).strip()
    sddm_match = re.search(r'^Background\s*=\s*"?([^"\n]+)"?\s*$', read(SDDM), re.M)
    sddm_path = (SDDM.parent.parent / sddm_match[1]).resolve() if sddm_match else None
    sddm_current = next((str(p) for p in wallpapers if sddm_path and p.name == sddm_path.name), str(sddm_path) if sddm_path else "")
    sddm_items = [image_item(p) for p in wallpapers]
    if sddm_path and sddm_path.is_file() and not any(p.name == sddm_path.name for p in wallpapers):
        sddm_items.insert(0, image_item(sddm_path))
    themes = [p for p in sorted(KITTY.glob("*.conf"), key=lambda p: natural(p.name)) if p.name not in {"kitty.conf", "current-theme.conf"}]
    kitty_current = next((str(p) for p in themes if read(p) == read(KITTY / "current-theme.conf")), "")
    try:
        ff_source, _, _ = logo_source(read(FASTFETCH))
        ff_current = str(Path(ff_source).expanduser()) if ff_source != "auto" else "auto"
    except (ValueError, json.JSONDecodeError):
        ff_current = ""
    groups = [
        {"id": "wallpaper", "title": "Wallpaper", "icon": "󰸉", "description": "Fundo do Hyprland e da tela de bloqueio", "current": wall_current, "available": WALLPAPERS.is_dir(), "items": [image_item(p) for p in wallpapers]},
        {"id": "sddm", "title": "Tela de login", "icon": "󰌾", "description": "Fundo do SDDM · pede autenticação ao aplicar", "current": sddm_current, "available": SDDM.is_file(), "items": sddm_items},
        {"id": "fastfetch", "title": "Logo do Fastfetch", "icon": "󰆍", "description": "Imagem exibida ao executar o Fastfetch", "current": ff_current, "available": FASTFETCH.is_file(), "items": [{"id": "auto", "name": "Logo da distro", "preview": "", "kind": "distro"}, *[image_item(p) for p in images(FF_ICONS)]]},
        {"id": "kitty", "title": "Tema do Kitty", "icon": "󰄛", "description": "Paleta de cores do terminal · aplica nas janelas abertas", "current": kitty_current, "available": (KITTY / "kitty.conf").is_file(), "items": [{"id": str(p), "name": p.stem, "preview": "", "kind": "terminal", "palette": palette(p)} for p in themes]},
    ]
    for group in groups:
        group["items"].sort(key=lambda item: item["id"] != group["current"])
        selected = next((item for item in group["items"] if item["id"] == group["current"]), None)
        group["currentName"] = selected["name"] if selected else Path(group["current"]).stem if group["current"] else "Não definido"
    return {"groups": groups}


def atomic_write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    mode = path.stat().st_mode & 0o777 if path.exists() else 0o644
    fd, name = tempfile.mkstemp(prefix=".quickshell-", dir=path.parent)
    try:
        with os.fdopen(fd, "w") as stream:
            stream.write(text)
        os.chmod(name, mode)
        os.replace(name, path)
    finally:
        if os.path.exists(name):
            os.unlink(name)


def atomic_link(path, target):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temp = tempfile.mkstemp(prefix=".quickshell-", dir=path.parent)
    os.close(fd)
    os.unlink(temp)
    try:
        os.symlink(target, temp)
        os.replace(temp, path)
    finally:
        if os.path.lexists(temp):
            os.unlink(temp)


def run(command, timeout=30):
    result = subprocess.run(command, text=True, capture_output=True, timeout=timeout)
    if result.returncode:
        raise RuntimeError((result.stderr or result.stdout).strip() or "Não foi possível concluir a alteração.")


# Only this fixed operation runs as root, after the user's Polkit authentication.
SDDM_CODE = r'''
import os, pwd, re, shutil, sys, tempfile
from pathlib import Path
user = pwd.getpwuid(int(os.environ['PKEXEC_UID']))
source = Path(sys.argv[1]).resolve(strict=True)
wallpapers = (Path(user.pw_dir) / 'Pictures/Wallpaper').resolve()
if source.parent != wallpapers or source.suffix.lower() not in {'.jpg','.jpeg','.png','.webp','.gif'}:
    raise ValueError('Escolha uma imagem da pasta de wallpapers.')
if any(c in source.name for c in (chr(10), chr(13), chr(34), chr(92))):
    raise ValueError('O nome da imagem contém caracteres incompatíveis com o SDDM.')
config = Path('/usr/share/sddm/themes/sddm-astronaut-theme/Themes/astronaut.conf')
target = config.parent.parent / 'Backgrounds' / source.name
original = config.read_text()
updated, count = re.subn(r'^Background\s*=.*$', lambda m: 'Background="Backgrounds/' + source.name + '"', original, count=1, flags=re.M)
if count != 1:
    raise ValueError('A configuração do SDDM não contém Background.')
backup = config.with_suffix('.conf.quickshell.bak')
if not backup.exists():
    shutil.copy2(config, backup)
fd, temp = tempfile.mkstemp(prefix='.quickshell-', dir=target.parent)
os.close(fd)
try:
    shutil.copyfile(source, temp)
    os.chmod(temp, 0o644)
    os.replace(temp, target)
finally:
    if os.path.exists(temp): os.unlink(temp)
fd, temp = tempfile.mkstemp(prefix='.quickshell-', dir=config.parent)
try:
    with os.fdopen(fd, 'w') as stream: stream.write(updated)
    os.chmod(temp, 0o644)
    os.replace(temp, config)
finally:
    if os.path.exists(temp): os.unlink(temp)
'''


def apply(category, selection):
    group = next((g for g in catalog()["groups"] if g["id"] == category), None)
    if not group or not group["available"]:
        raise ValueError("Esta opção não está disponível nesta máquina.")
    item = next((i for i in group["items"] if i["id"] == selection), None)
    if not item:
        raise ValueError("A seleção não existe mais. Atualize a lista e tente novamente.")
    if selection == group["current"]:
        return {"ok": True, "message": "Esta opção já está aplicada."}
    if category == "wallpaper":
        run(["awww", "img", selection, "--transition-type", "fade", "--transition-duration", "0.5", "--transition-fps", "60", "--transition-bezier", ".4,0,.2,1"])
        atomic_write(WALL_CACHE, selection + "\n")
        atomic_link(LOCK_WALL, selection)
        refresh_kitty_adaptive()
    elif category == "fastfetch":
        text = FASTFETCH.read_text()
        _, start, end = logo_source(text)
        source = "~" + selection[len(str(HOME)):] if selection.startswith(str(HOME) + "/") else selection
        atomic_write(FASTFETCH, text[:start] + json.dumps(source, ensure_ascii=False) + text[end:])
    elif category == "kitty":
        atomic_link(KITTY / "current-theme.conf", Path(selection).name)
        # SIGUSR1 is Kitty's supported configuration reload signal.
        result = subprocess.run(["pgrep", "-u", str(os.getuid()), "-x", "kitty"], capture_output=True, text=True)
        for pid in result.stdout.split():
            try:
                os.kill(int(pid), signal.SIGUSR1)
            except ProcessLookupError:
                pass
    elif category == "sddm":
        result = subprocess.run(["pkexec", "/usr/bin/python3", "-c", SDDM_CODE, selection], capture_output=True, text=True, timeout=180)
        if result.returncode in (126, 127):
            raise RuntimeError("Autenticação cancelada ou não autorizada. O fundo do SDDM foi mantido.")
        if result.returncode:
            raise RuntimeError(result.stderr.strip().splitlines()[-1] if result.stderr.strip() else "Não foi possível alterar o fundo do SDDM.")
    return {"ok": True, "message": "Aplicado: " + item["name"]}


def main():
    try:
        if len(sys.argv) == 2 and sys.argv[1] == "catalog":
            result = catalog()
        elif len(sys.argv) == 4 and sys.argv[1] == "apply":
            result = apply(sys.argv[2], sys.argv[3])
        else:
            raise ValueError("Uso: backend.py catalog | apply categoria seleção")
        print(json.dumps(result, ensure_ascii=False))
    except (OSError, ValueError, RuntimeError, subprocess.TimeoutExpired) as error:
        print(json.dumps({"ok": False, "message": str(error)}, ensure_ascii=False))
        sys.exit(1)


if __name__ == "__main__":
    main()

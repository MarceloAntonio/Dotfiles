#!/usr/bin/env python3
"""Sincroniza configurações públicas do HOME com este repositório.

Uso: python3 scripts/backup_dotfiles.py [--auto | --dry]
O repositório é localizado pelo script, independentemente do nome ou cwd.
"""

import argparse
from pathlib import Path
import posixpath
import re
import shutil
import subprocess
import sys


class Colors:
    RESET = "\033[0m"
    BOLD = "\033[1m"
    RED = "\033[91m"
    GREEN = "\033[92m"
    YELLOW = "\033[93m"
    BLUE = "\033[94m"
    MAGENTA = "\033[95m"
    CYAN = "\033[96m"
    DIM = "\033[2m"


def colored(text: str, color: str) -> str:
    return f"{color}{text}{Colors.RESET}"


HOME = Path.home()
DOTFILES_DIR = Path(__file__).resolve().parents[1]
HOME_FILES = [".zshrc"]
LOCAL_FILES = {
    ".local/bin/rice-lock",
    ".local/bin/rice-monitors",
    ".local/share/applications/rice-monitors.desktop",
    ".local/share/dbus-1/services/org.erikreider.swaync.service",
    ".config/systemd/user/rice-lock-bridge.service",
}
OWNED_DIRS = (
    ".config/quickshell/control-center",
    ".config/quickshell/session-lock",
)
EXCLUDED_FILES = {
    # Bootstrap palettes are generated at install/runtime; repository docs are
    # maintained alongside README.md, not imported from a running session.
    ".config/kitty/Adaptativo.conf",
    ".config/rofi/themes/shell-palette.rasi",
    ".config/quickshell/control-center/README.md",
    ".config/quickshell/session-lock/README.md",
    ".config/hypr/.current_wallpaper",
    ".config/hypr/configs/monitors-managed.lua",
    ".config/hypr/scripts/binds.sh",
    ".config/hypr/scripts/lock-music.sh",
    ".config/hypr/scripts/music.webp",
    ".config/rofi/themes/menu.rasi",
    ".config/rofi/themes/rofi-wallpaper-selector.rasi",
}
EXCLUDED_DIRS = (
    ".config/waybar/", ".config/swaync/", ".config/pulsar/",
    ".config/hypr/hyprlock/", ".local/state/", ".cache/",
)


def allowed(relative: Path) -> bool:
    value = relative.as_posix()
    if value in EXCLUDED_FILES or value.startswith(EXCLUDED_DIRS):
        return False
    if any(part in {"__pycache__", ".git"} or part.endswith((".wants", ".requires")) for part in relative.parts):
        return False
    if ".bak" in relative.name or relative.suffix in {".pyc", ".pyo"}:
        return False
    if value.startswith((".local/", ".config/systemd/")):
        return value in LOCAL_FILES
    return value.startswith(".config/") or value in HOME_FILES


def portable_bytes(src: Path, dst: Path) -> bytes:
    """Normalize only known machine-specific fields, also before comparison."""
    raw = src.read_bytes()
    relative = dst.relative_to(DOTFILES_DIR).as_posix()
    if not relative.endswith((".desktop", ".rasi", ".lua")):
        return raw
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError:
        return raw
    if relative.endswith(".desktop"):
        text = text.replace(str(HOME) + "/.local/bin/", "@HOME@/.local/bin/")
    if relative.startswith(".config/rofi/") and relative.endswith(".rasi"):
        parent = posixpath.dirname(relative.removeprefix(".config/rofi/")) or "."
        text = text.replace(str(HOME) + "/.config/rofi/themes/shell-palette.rasi",
                            posixpath.relpath("themes/shell-palette.rasi", parent))
    if relative == ".config/hypr/configs/windowrules.lua":
        text = re.sub(r'hl\.layer_rule\(\{\s*name\s*=\s*"(?:blur-waybar|blur-swaync-cc|blur-swaync-notif|blur-pulsar)".*?\n\}\)\n\n?', "", text, flags=re.S)
        def namespaces(match):
            names = match[1].split("|")
            for name in ("commands", "power", "monitors", "workspace-overview"):
                if name not in names:
                    names.append(name)
            return 'namespace = "^qs-(' + "|".join(names) + ')$"'
        text = re.sub(r'namespace\s*=\s*"\^qs-\(([^)]+)\)\$"', namespaces, text)
    if relative == ".config/hypr/configs/autostart.lua":
        text = "".join(line for line in text.splitlines(keepends=True)
                       if not re.search(r'''hl\.exec_cmd\(["'](?:nm-applet|waybar|swaync|pulsar)(?:\s|["'])''', line))
    return text.encode("utf-8")


def safe_symlink(src: Path, dst: Path) -> bool:
    target = src.readlink()
    return not target.is_absolute() and (dst.parent / target).resolve().is_relative_to(DOTFILES_DIR)


def differs(src: Path, dst: Path) -> bool:
    if src.is_symlink():
        if not safe_symlink(src, dst):
            return False
        return not (dst.is_symlink() and src.readlink() == dst.readlink())
    if dst.is_symlink() or not dst.exists():
        return True
    return (portable_bytes(src, dst) != dst.read_bytes()
            or bool(src.stat().st_mode & 0o111) != bool(dst.stat().st_mode & 0o111))


def get_tracked_configs() -> list[Path]:
    root = DOTFILES_DIR / ".config"
    return sorted(root.iterdir()) if root.is_dir() else []


def compare_files(src: Path, dst: Path) -> list[tuple[Path, Path]]:
    """Compare known repository files without discovering unrelated HOME files."""
    if src.is_symlink() or src.is_file():
        return [(src, dst)] if allowed(dst.relative_to(DOTFILES_DIR)) and differs(src, dst) else []
    changed = []
    if src.is_dir() and dst.is_dir():
        for target in sorted(dst.rglob("*")):
            if target.is_file() or target.is_symlink():
                source = src / target.relative_to(dst)
                if source.is_file() or source.is_symlink():
                    changed.extend(compare_files(source, target))
    return changed


def find_all_changes() -> list[tuple[Path, Path]]:
    candidates = {Path(name) for name in HOME_FILES + sorted(LOCAL_FILES)}
    config = DOTFILES_DIR / ".config"
    if config.is_dir():
        candidates.update(p.relative_to(DOTFILES_DIR) for p in config.rglob("*") if p.is_file() or p.is_symlink())
    # New native shell components are welcome; caches, logs and arbitrary data
    # are excluded. Other applications must first be added to the repository.
    for name in OWNED_DIRS:
        source = HOME / name
        if source.is_dir():
            candidates.update(p.relative_to(HOME) for p in source.rglob("*")
                              if (p.is_file() or p.is_symlink())
                              and (p.suffix in {".qml", ".py", ".md"} or p.name == "qmldir"))
    changed = []
    for relative in sorted(candidates):
        if not allowed(relative):
            continue
        src, dst = HOME / relative, DOTFILES_DIR / relative
        if (src.is_file() or src.is_symlink()) and differs(src, dst):
            changed.append((src, dst))
    return drop_gitignored(changed)


def drop_gitignored(changes: list[tuple[Path, Path]]) -> list[tuple[Path, Path]]:
    if not changes:
        return []
    relatives = [str(dst.relative_to(DOTFILES_DIR)) for _, dst in changes]
    result = subprocess.run(["git", "-C", str(DOTFILES_DIR), "check-ignore", "--no-index", "-z", "--stdin"],
                            input="\0".join(relatives) + "\0", capture_output=True, text=True)
    ignored = set(result.stdout.split("\0"))
    return [change for change, relative in zip(changes, relatives) if relative not in ignored]


def copy_files(changes: list[tuple[Path, Path]], dry_run: bool = False) -> int:
    count = 0
    for src, dst in changes:
        relative = dst.relative_to(DOTFILES_DIR)
        # Recheck the boundary if callers provide their own change list.
        if not allowed(relative) or (src.is_symlink() and not safe_symlink(src, dst)):
            continue
        if dry_run:
            print(f"  {colored('→', Colors.CYAN)} {colored(str(src.relative_to(HOME)), Colors.DIM)} → {colored(str(relative), Colors.YELLOW)}")
        else:
            normalized = None if src.is_symlink() else portable_bytes(src, dst)
            dst.parent.mkdir(parents=True, exist_ok=True)
            dst.unlink(missing_ok=True)
            shutil.copy2(src, dst, follow_symlinks=False)
            if normalized is not None and normalized != dst.read_bytes():
                dst.write_bytes(normalized)
            print(f"  {colored('✓', Colors.GREEN)} {colored(str(relative), Colors.YELLOW)}")
        count += 1
    return count


def print_header():
    print()
    print(colored("  ╔══════════════════════════════════════╗", Colors.MAGENTA))
    print(colored("  ║     🔄 Backup Automático Dotfiles    ║", Colors.MAGENTA))
    print(colored("  ╚══════════════════════════════════════╝", Colors.MAGENTA))
    print()

def interactive_selection(changes: list[tuple[Path, Path]]) -> list[tuple[Path, Path]]:
    import tty
    import termios
    import select

    def get_key():
        fd = sys.stdin.fileno()
        old_settings = termios.tcgetattr(fd)
        try:
            tty.setraw(sys.stdin.fileno())
            ch = sys.stdin.read(1)
            if ch == '\x1b':
                r, _, _ = select.select([sys.stdin], [], [], 0.1)
                if r:
                    ch2 = sys.stdin.read(1)
                    if ch2 == '[':
                        ch3 = sys.stdin.read(1)
                        return '\x1b[' + ch3
            return ch
        finally:
            termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)

    selected = [True] * len(changes)
    cursor_idx = 0

    print("\n  Selecione os arquivos para backup:")
    print(colored("  (Setas/j/k para mover, Espaço para alternar, Enter para confirmar, 'a' todos, 'n' nenhum, 'q' sair)", Colors.DIM))
    print()
    sys.stdout.write("\033[?25l")
    sys.stdout.flush()

    try:
        while True:
            for i, (src, dst) in enumerate(changes):
                rel = dst.relative_to(DOTFILES_DIR)
                mark = colored("x", Colors.GREEN) if selected[i] else " "

                if i == cursor_idx:
                    pointer = colored(">", Colors.CYAN)
                    line_color = Colors.BOLD
                else:
                    pointer = " "
                    line_color = ""
                line = f"\r\033[K    {pointer} [{mark}] {colored(str(rel), line_color)}"
                sys.stdout.write(line + "\n")

            sys.stdout.flush()
            key = get_key()
            sys.stdout.write(f"\033[{len(changes)}A")

            if key in ('\x1b[A', 'k'): # Up
                cursor_idx = max(0, cursor_idx - 1)
            elif key in ('\x1b[B', 'j'): # Down
                cursor_idx = min(len(changes) - 1, cursor_idx + 1)
            elif key == ' ': # Space
                selected[cursor_idx] = not selected[cursor_idx]
            elif key == '\r' or key == '\n': # Enter
                sys.stdout.write(f"\033[{len(changes)}B") # Move cursor down
                break
            elif key == 'a':
                selected = [True] * len(changes)
            elif key == 'n':
                selected = [False] * len(changes)
            elif key == '\x03' or key == 'q': # Ctrl+C or q
                sys.stdout.write(f"\033[{len(changes)}B") # Move cursor down
                sys.stdout.write("\033[?25h") # Show cursor
                print(colored("\n  Cancelado.", Colors.DIM))
                sys.exit(0)

    finally:
        sys.stdout.write("\033[?25h")
        sys.stdout.flush()

    return [changes[i] for i in range(len(changes)) if selected[i]]

def main():
    parser = argparse.ArgumentParser(description="Backup automático dos dotfiles")
    parser.add_argument("--auto", action="store_true", help="Modo automático (sem confirmação)")
    parser.add_argument("--dry", action="store_true", help="Apenas mostra o que seria feito")
    args = parser.parse_args()

    print_header()
    if not DOTFILES_DIR.exists():
        print(colored(f"  ✗ Diretório {DOTFILES_DIR} não encontrado!", Colors.RED))
        sys.exit(1)
    print(colored("  Procurando alterações...", Colors.BLUE))
    changes = find_all_changes()

    if not changes:
        print(f"\n  {colored('✓', Colors.GREEN)} Tudo sincronizado! Nenhuma alteração encontrada.")
        print()
        sys.exit(0)

    print(f"\n  {colored(str(len(changes)), Colors.BOLD + Colors.YELLOW)} arquivo(s) com diferenças encontrados.\n")

    if args.dry:
        print(colored("  [Dry Run] Arquivos que seriam copiados:\n", Colors.YELLOW))
        copy_files(changes, dry_run=True)
        print()
        sys.exit(0)

    if not args.auto:
        if not sys.stdin.isatty():
            print(colored("  ✗ Modo interativo precisa de um terminal. Use --auto ou --dry.", Colors.RED))
            sys.exit(1)

        changes = interactive_selection(changes)

        if not changes:
            print(colored("\n  Nenhum arquivo selecionado. Cancelado.", Colors.DIM))
            print()
            sys.exit(0)
    print(colored("  Copiando arquivos...\n", Colors.BLUE))
    count = copy_files(changes)
    print(f"\n  {colored('✓', Colors.GREEN)} {count} arquivo(s) atualizado(s)")

    print(f"\n  {colored('✅ Backup concluído!', Colors.GREEN + Colors.BOLD)}\n")

if __name__ == "__main__":
    main()

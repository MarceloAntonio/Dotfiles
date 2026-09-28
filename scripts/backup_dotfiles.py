#!/usr/bin/env python3
"""
Backup automático dos dotfiles.

Compara os arquivos em ~/.config (e outros como .zshrc) com os que já existem
em ~/dotfiles e copia apenas os que mudaram.

Uso:
    python3 backup_dotfiles.py          # Modo interativo (pede confirmação)
    python3 backup_dotfiles.py --auto   # Modo automático (sem confirmação)
    python3 backup_dotfiles.py --dry    # Apenas mostra o que seria feito
"""

import argparse
import filecmp
import shutil
import subprocess
import sys
from pathlib import Path

# ── Cores para o terminal ──────────────────────────────────────────────────────
class Colors:
    RESET   = "\033[0m"
    BOLD    = "\033[1m"
    RED     = "\033[91m"
    GREEN   = "\033[92m"
    YELLOW  = "\033[93m"
    BLUE    = "\033[94m"
    MAGENTA = "\033[95m"
    CYAN    = "\033[96m"
    DIM     = "\033[2m"


def colored(text: str, color: str) -> str:
    return f"{color}{text}{Colors.RESET}"


# ── Configuração ───────────────────────────────────────────────────────────────
HOME = Path.home()
DOTFILES_DIR = HOME / "dotfiles"

# Pastas de ~/.config já rastreadas em dotfiles/.config são sincronizadas automaticamente.
# Arquivos avulsos da home → dotfiles/ (adicione aqui)
HOME_FILES = [".zshrc"]


def get_tracked_configs() -> list[Path]:
    """Retorna as pastas/arquivos que já existem em dotfiles/.config/."""
    config_dest = DOTFILES_DIR / ".config"
    if not config_dest.exists():
        return []
    return sorted(p for p in config_dest.iterdir())


def differs(src: Path, dst: Path) -> bool:
    """Symlinks são comparados pelo alvo, não pelo conteúdo (evita versionar a imagem do wallpaper)."""
    if src.is_symlink() or dst.is_symlink():
        return not (src.is_symlink() and dst.is_symlink() and src.readlink() == dst.readlink())
    return not filecmp.cmp(src, dst, shallow=False)


def compare_files(src: Path, dst: Path) -> list[tuple[Path, Path]]:
    """Compara recursivamente e retorna lista de (src, dst) que diferem."""
    changed = []

    if src.is_file() and dst.is_file():
        if differs(src, dst):
            changed.append((src, dst))
        return changed

    if src.is_dir() and dst.is_dir():
        # Percorre todos os arquivos no destino (dotfiles) para ver se mudaram na origem
        for dst_file in sorted(dst.rglob("*")):
            if dst_file.is_dir() and not dst_file.is_symlink():
                continue
            rel = dst_file.relative_to(dst)
            src_file = src / rel
            if src_file.exists():
                if differs(src_file, dst_file):
                    changed.append((src_file, dst_file))

        # Verifica arquivos novos na origem que não existem no destino
        for src_file in sorted(src.rglob("*")):
            # is_file() pula pastas, symlinks quebrados, sockets e fifos
            if not src_file.is_file():
                continue
            rel = src_file.relative_to(src)
            dst_file = dst / rel
            if not dst_file.exists():
                changed.append((src_file, dst_file))

    return changed


def find_all_changes() -> list[tuple[Path, Path]]:
    """Encontra todas as diferenças entre configs atuais e dotfiles."""
    all_changes = []

    # 1. Pastas em .config
    for tracked in get_tracked_configs():
        src = HOME / ".config" / tracked.name
        if src.exists():
            all_changes.extend(compare_files(src, tracked))

    # 2. Arquivos avulsos na home
    for fname in HOME_FILES:
        src, dst = HOME / fname, DOTFILES_DIR / fname
        if src.exists() and dst.exists():
            all_changes.extend(compare_files(src, dst))

    return drop_gitignored(all_changes)


def drop_gitignored(changes: list[tuple[Path, Path]]) -> list[tuple[Path, Path]]:
    """Remove o que o .gitignore do dotfiles ignora (estado local, caches)."""
    rels = [str(dst.relative_to(DOTFILES_DIR)) for _, dst in changes]
    ignored = set(subprocess.run(
        ["git", "-C", str(DOTFILES_DIR), "check-ignore", "--stdin"],
        input="\n".join(rels), capture_output=True, text=True,
    ).stdout.splitlines())
    return [c for c, rel in zip(changes, rels) if rel not in ignored]


def copy_files(changes: list[tuple[Path, Path]], dry_run: bool = False) -> int:
    """Copia os arquivos alterados. Retorna quantidade de arquivos copiados."""
    count = 0
    for src, dst in changes:
        rel_src = src.relative_to(HOME)
        rel_dst = dst.relative_to(DOTFILES_DIR)

        if dry_run:
            print(f"  {colored('→', Colors.CYAN)} {colored(str(rel_src), Colors.DIM)} → {colored(str(rel_dst), Colors.YELLOW)}")
        else:
            dst.parent.mkdir(parents=True, exist_ok=True)
            dst.unlink(missing_ok=True)  # copy2 não sobrescreve symlink
            shutil.copy2(src, dst, follow_symlinks=False)
            print(f"  {colored('✓', Colors.GREEN)} {colored(str(rel_dst), Colors.YELLOW)}")
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
    
    # Hide cursor
    sys.stdout.write("\033[?25l")
    sys.stdout.flush()

    try:
        while True:
            # Draw the list
            for i, (src, dst) in enumerate(changes):
                rel = dst.relative_to(DOTFILES_DIR)
                mark = colored("x", Colors.GREEN) if selected[i] else " "
                
                if i == cursor_idx:
                    pointer = colored(">", Colors.CYAN)
                    line_color = Colors.BOLD
                else:
                    pointer = " "
                    line_color = ""
                
                # Use clear line escape sequence \033[K
                line = f"\r\033[K    {pointer} [{mark}] {colored(str(rel), line_color)}"
                sys.stdout.write(line + "\n")
            
            sys.stdout.flush()
            
            # Wait for key
            key = get_key()
            
            # Move cursor up to overwrite the list
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

    # Verificar se o diretório dotfiles existe
    if not DOTFILES_DIR.exists():
        print(colored(f"  ✗ Diretório {DOTFILES_DIR} não encontrado!", Colors.RED))
        sys.exit(1)

    # Encontrar mudanças
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

    # Copiar arquivos
    print(colored("  Copiando arquivos...\n", Colors.BLUE))
    count = copy_files(changes)
    print(f"\n  {colored('✓', Colors.GREEN)} {count} arquivo(s) atualizado(s)")

    print(f"\n  {colored('✅ Backup concluído!', Colors.GREEN + Colors.BOLD)}\n")


if __name__ == "__main__":
    main()

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

# Mapeamento: origem → destino no dotfiles
# Adicione novas configs aqui conforme necessário
MAPPINGS = {
    # Pastas de .config → dotfiles/.config
    ".config": {
        "source_base": HOME / ".config",
        "dest_base": DOTFILES_DIR / ".config",
    },
    # Arquivos avulsos na home → dotfiles/
    "home_files": {
        "source_base": HOME,
        "dest_base": DOTFILES_DIR,
        "files": [".zshrc"],
    },
}


def get_tracked_configs() -> list[Path]:
    """Retorna as pastas/arquivos que já existem em dotfiles/.config/."""
    config_dest = DOTFILES_DIR / ".config"
    if not config_dest.exists():
        return []
    return sorted(p for p in config_dest.iterdir())


def compare_files(src: Path, dst: Path) -> list[tuple[Path, Path]]:
    """Compara recursivamente e retorna lista de (src, dst) que diferem."""
    changed = []

    if src.is_file() and dst.is_file():
        if not filecmp.cmp(src, dst, shallow=False):
            changed.append((src, dst))
        return changed

    if src.is_dir() and dst.is_dir():
        # Percorre todos os arquivos no destino (dotfiles) para ver se mudaram na origem
        for dst_file in sorted(dst.rglob("*")):
            if dst_file.is_dir():
                continue
            rel = dst_file.relative_to(dst)
            src_file = src / rel
            if src_file.exists():
                if not filecmp.cmp(src_file, dst_file, shallow=False):
                    changed.append((src_file, dst_file))

        # Verifica arquivos novos na origem que não existem no destino
        for src_file in sorted(src.rglob("*")):
            if src_file.is_dir():
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
    config_src = MAPPINGS[".config"]["source_base"]
    config_dst = MAPPINGS[".config"]["dest_base"]

    for tracked in get_tracked_configs():
        name = tracked.name
        src = config_src / name
        if src.exists():
            changes = compare_files(src, tracked)
            all_changes.extend(changes)

    # 2. Arquivos avulsos na home
    home_info = MAPPINGS["home_files"]
    for fname in home_info["files"]:
        src = home_info["source_base"] / fname
        dst = home_info["dest_base"] / fname
        if src.exists() and dst.exists():
            changes = compare_files(src, dst)
            all_changes.extend(changes)

    return all_changes


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
            shutil.copy2(src, dst)
            print(f"  {colored('✓', Colors.GREEN)} {colored(str(rel_dst), Colors.YELLOW)}")
        count += 1

    return count


def print_header():
    print()
    print(colored("  ╔══════════════════════════════════════╗", Colors.MAGENTA))
    print(colored("  ║     🔄 Backup Automático Dotfiles    ║", Colors.MAGENTA))
    print(colored("  ╚══════════════════════════════════════╝", Colors.MAGENTA))
    print()


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

    # Mostrar mudanças
    print(f"\n  {colored(str(len(changes)), Colors.BOLD + Colors.YELLOW)} arquivo(s) com diferenças:\n")

    for src, dst in changes:
        rel = dst.relative_to(DOTFILES_DIR)
        print(f"    {colored('•', Colors.CYAN)} {rel}")

    print()

    if args.dry:
        print(colored("  [Dry Run] Arquivos que seriam copiados:\n", Colors.YELLOW))
        copy_files(changes, dry_run=True)
        print()
        sys.exit(0)

    # Confirmação
    if not args.auto:
        resp = input(colored("  Deseja prosseguir com o backup? [S/n] ", Colors.BOLD))
        if resp.strip().lower() in ("n", "não", "nao", "no"):
            print(colored("  Cancelado.", Colors.DIM))
            sys.exit(0)
        print()

    # Copiar arquivos
    print(colored("  Copiando arquivos...\n", Colors.BLUE))
    count = copy_files(changes)
    print(f"\n  {colored('✓', Colors.GREEN)} {count} arquivo(s) atualizado(s)")

    print(f"\n  {colored('✅ Backup concluído!', Colors.GREEN + Colors.BOLD)}\n")


if __name__ == "__main__":
    main()

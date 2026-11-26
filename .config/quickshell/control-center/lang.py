"""Idioma da interface a partir do locale do sistema (/etc/locale.conf)."""
from pathlib import Path

try:
    EN = any(line.strip().startswith('LANG=en') for line in Path('/etc/locale.conf').read_text().splitlines())
except OSError:
    EN = False


def tr(pt, en):
    return en if EN else pt

"""Wallpaper-derived Kitty palette; no shell and no terminal remote control."""
import colorsys
import os
from pathlib import Path
import signal
import subprocess
import tempfile
from PIL import Image

HOME = Path.home()
TARGET = HOME / '.config/kitty/Adaptativo.conf'
CURRENT = HOME / '.config/kitty/current-theme.conf'

def rgb(h, s, v):
    return '#' + ''.join(f'{round(c*255):02x}' for c in colorsys.hsv_to_rgb(h % 1, s, v))

def generate():
    h, s = .60, .4
    colors = []
    try:
        path = Path((HOME / '.config/hypr/.current_wallpaper').read_text().strip()).expanduser()
        with Image.open(path) as image:
            image.thumbnail((96,96))
            colors = image.convert('RGB').quantize(colors=12).convert('RGB').getcolors(96*96)
        def score(item):
            count, value = item
            _, sat, bright = colorsys.rgb_to_hsv(*(v/255 for v in value))
            return count * (.15 + sat) * (.3 if bright < .12 or bright > .95 else 1)
        _, value = max(colors, key=score)
        h, s, _ = colorsys.rgb_to_hsv(*(v/255 for v in value))
    except (OSError, ValueError):
        pass
    accent = rgb(h, min(.55,max(.25,s)), .94)
    values = {
        'background': rgb(h, .25, .085), 'foreground': rgb(h, .055, .94),
        'cursor': accent, 'cursor_text_color': rgb(h,.25,.085),
        'selection_background': rgb(h,.38,.40), 'selection_foreground': '#ffffff',
        'url_color': accent, 'active_border_color': accent,
        'inactive_border_color': rgb(h,.17,.24),
        'active_tab_background': accent, 'active_tab_foreground': rgb(h,.25,.085),
        'inactive_tab_background': rgb(h,.20,.15), 'inactive_tab_foreground': rgb(h,.08,.70),
        'tab_bar_background': rgb(h,.25,.085),
        'color0': rgb(h,.16,.16), 'color8': rgb(h,.14,.42),
        'color7': rgb(h,.05,.85), 'color15': rgb(h,.025,.99),
    }
    # All ANSI swatches come from the image, rather than a fixed pastel palette.
    candidates = []
    for count, value in sorted(colors, key=lambda item: item[0], reverse=True):
        ch, cs, cv = colorsys.rgb_to_hsv(*(v/255 for v in value))
        if cs >= .12 and .10 < cv < .98:
            candidates.append((ch, cs, cv))
    if not candidates:
        candidates = [(h, max(s,.22), .8)]
    selected = [min(candidates, key=lambda c: min(abs(c[0]-h), 1-abs(c[0]-h)))]
    remaining = [c for c in candidates if c != selected[0]]
    def distance(a,b):
        hue = min(abs(a[0]-b[0]), 1-abs(a[0]-b[0]))
        return 3*hue + .35*abs(a[1]-b[1]) + .20*abs(a[2]-b[2])
    while remaining and len(selected) < 6:
        candidate = max(remaining, key=lambda c: min(distance(c, x) for x in selected))
        selected.append(candidate); remaining.remove(candidate)
    while len(selected) < 6:
        source = selected[len(selected) % len(candidates)]
        selected.append(((source[0] + .025 * len(selected)) % 1, source[1], source[2]))
    for i, (hue, saturation, brightness) in enumerate(selected, 1):
        values[f'color{i}'] = rgb(hue, min(.78,max(.30,saturation*.85)), max(.72,min(.88,brightness)))
        values[f'color{i+8}'] = rgb(hue, min(.65,max(.24,saturation*.65)), .98)
    text = '# Adaptativo · gerado a partir do wallpaper\n' + '\n'.join(f'{k} {v}' for k,v in values.items()) + '\n'
    changed = not TARGET.exists() or TARGET.read_text() != text
    if changed:
        TARGET.parent.mkdir(parents=True,exist_ok=True)
        fd, name = tempfile.mkstemp(dir=TARGET.parent,prefix='.adaptive-')
        try:
            with os.fdopen(fd,'w') as file: file.write(text)
            os.replace(name,TARGET)
        finally:
            Path(name).unlink(missing_ok=True)
    return changed

def refresh():
    # Other Kitty themes are never changed or reloaded by this watcher.
    if not CURRENT.is_symlink() or CURRENT.resolve() != TARGET: return
    if not generate(): return
    result = subprocess.run(['pgrep','-u',str(os.getuid()),'-x','kitty'],capture_output=True,text=True)
    for pid in result.stdout.split():
        try: os.kill(int(pid),signal.SIGUSR1)
        except ProcessLookupError: pass

if __name__ == '__main__':
    import sys
    if '--refresh' in sys.argv: refresh()
    else: generate()

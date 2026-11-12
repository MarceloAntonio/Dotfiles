import hashlib, json, pathlib
from PIL import Image, ImageFilter, ImageOps
home = pathlib.Path.home()
cache = home / '.cache/quickshell-lock'
cache.mkdir(parents=True, exist_ok=True)
try: theme = json.loads((home / '.local/state/quickshell-theme.json').read_text())
except (OSError, ValueError): theme = {}
wallpaper = ''
original = ''
try:
    path = pathlib.Path((home / '.config/hypr/.current_wallpaper').read_text().strip()).expanduser()
    original = path.as_uri()
    key = hashlib.sha256((str(path) + str(path.stat().st_mtime_ns)).encode()).hexdigest()[:20]
    output = cache / (key + '.jpg')
    if not output.exists():
        with Image.open(path) as im:
            im = ImageOps.exif_transpose(im).convert('RGB')
            im.thumbnail((1600,1000))
            im.filter(ImageFilter.GaussianBlur(16)).save(output, quality=88)
        for old in cache.glob('*.jpg'):
            if old != output: old.unlink(missing_ok=True)
    wallpaper = output.as_uri()
except (OSError, ValueError): pass
mode = theme.get('mode','dark')
accent = theme.get('accent','#b2c5e0') if mode == 'wallpaper' else '#ededed'
if mode == 'wallpaper':
    r,g,b = (int(accent[i:i+2],16) for i in (1,3,5))
    tint = '#' + ''.join(f'{round(c*.15):02x}' for c in (r,g,b))
    surface = '#54' + tint[1:]
    hover = '#38' + accent[1:]
else:
    surface = '#0fffffff' if mode == 'light' else '#54121924'
    hover = '#24ffffff' if mode == 'light' else '#73303b4b'
print(json.dumps(dict(wallpaper=wallpaper, original=original, accent=accent, mode=mode, surface=surface, hover=hover)))

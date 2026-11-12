import colorsys, json, pathlib, sys
from PIL import Image
home = pathlib.Path.home()
state = home / ".local/state/quickshell-theme.json"
try: saved = json.loads(state.read_text())
except (OSError, ValueError): saved = {}
mode = sys.argv[1] if len(sys.argv) > 1 else saved.get("mode", "light")
if mode not in ("light", "dark", "wallpaper"): raise SystemExit(2)
accent = saved.get("accent", "#b2c5e0")
if mode == "wallpaper":
    try:
        path = pathlib.Path((home / ".config/hypr/.current_wallpaper").read_text().strip()).expanduser()
        signature = str(path) + str(path.stat().st_mtime_ns)
        if signature != saved.get("wallpaper"):
            with Image.open(path) as im:
                im.thumbnail((96,96))
                colors = im.convert("RGB").quantize(colors=12).convert("RGB").getcolors(96*96)
            def score(item):
                n, rgb = item
                h,s,v = colorsys.rgb_to_hsv(*(x/255 for x in rgb))
                return n * (0.15 + s) * (0.3 if v < .12 or v > .95 else 1)
            rgb = max(colors, key=score)[1]
            h,s,v = colorsys.rgb_to_hsv(*(x/255 for x in rgb))
            accent = "#" + "".join(f"{round(c*255):02x}" for c in colorsys.hsv_to_rgb(h,min(.52,max(.20,s)),.92))
            saved["wallpaper"] = signature
    except (OSError, ValueError): pass
r,g,b = (int(accent[i:i+2],16) for i in (1,3,5))
tint = "#" + "".join(f"{round(c*.15):02x}" for c in (r,g,b))
saved.update(mode=mode,accent=accent)
state.parent.mkdir(parents=True,exist_ok=True)
state.write_text(json.dumps(saved)+"\n")
bg = f"rgba({round(r*.15)},{round(g*.15)},{round(b*.15)},0.33)" if mode == "wallpaper" else "rgba(18,25,36,0.33)" if mode == "dark" else "rgba(255,255,255,0.06)"
border = "transparent" if mode != "light" else "rgba(255,255,255,0.10)"
selected = f"rgba({r},{g},{b},0.25)" if mode == "wallpaper" else "rgba(255,255,255,0.12)"
(home / ".config/rofi/themes/shell-palette.rasi").write_text("* { glass-bg: "+bg+"; glass-bg-element: rgba(255,255,255,0.04); glass-bg-hover: "+selected+"; glass-bg-selected: "+selected+"; glass-border: "+border+"; glass-border-hover: "+border+"; text-primary: #FFFFFF; text-muted: rgba(255,255,255,0.60); }\n")
print(json.dumps(dict(mode=mode,accent=accent,tint=tint)))

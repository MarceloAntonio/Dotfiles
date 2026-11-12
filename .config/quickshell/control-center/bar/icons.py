#!/usr/bin/env python3
"""Resolve the exact icon theme used by the previous Waybar taskbar."""
import json
from pathlib import Path
import sys
import subprocess

import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk

Gtk.init_check([])
theme = Gtk.IconTheme.new()
theme.set_custom_theme("WhiteSur-dark")
result = {}
for name in json.loads(sys.argv[1]):
    if not name:
        continue
    if name.startswith("/") and Path(name).is_file():
        result[name] = Path(name).as_uri()
        continue
    info = theme.lookup_icon(name, 18, Gtk.IconLookupFlags.FORCE_SIZE)
    if info and info.get_filename():
        result[name] = Path(info.get_filename()).as_uri()
try:
    clients = json.loads(subprocess.check_output(["hyprctl", "-j", "clients"], text=True, timeout=3))
    order = [c["address"].lower().removeprefix("0x") for c in clients]
except (OSError, ValueError, subprocess.SubprocessError):
    order = []
print(json.dumps({"icons": result, "order": order}))

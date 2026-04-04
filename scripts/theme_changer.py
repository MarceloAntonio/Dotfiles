#!/usr/bin/env python3

import tkinter as tk
from tkinter import messagebox
from PIL import Image, ImageTk
import os
import re
import subprocess

# ── Caminhos ──────────────────────────────────────────────────────────────────
HOME             = os.path.expanduser("~")
FASTFETCH_ICONS  = os.path.join(HOME, ".config", "fastfetch", "icons")
FASTFETCH_CONFIG = os.path.join(HOME, ".config", "fastfetch", "config.jsonc")
WALLPAPER_DIR    = os.path.join(HOME, "Pictures", "Wallpaper")
SDDM_CONF        = "/usr/share/sddm/themes/sddm-astronaut-theme/Themes/astronaut.conf"

# ── Visuais ───────────────────────────────────────────────────────────────────
COLS       = 9
THUMB_SIZE = 100
THUMB_PAD  = 8
BG         = "#131313"   # background do terminal
CARD_BG    = "#1A1A1A"   # color0
CARD_HOVER = "#252525"   # entre card e hover
BORDER     = "#535353"   # active_tab_background
ACCENT     = "#FFFFFF"   # foreground puro — destaque principal
ACCENT2    = "#D6D6D6"   # cinza claro — secundário
ACCENT3    = "#9D9D9D"   # cursor do terminal — terciário / avisos
TEXT       = "#FCFCFC"   # color7 / foreground
MUTED      = "#535353"   # active_tab usado como muted
SUPPORTED  = {".png", ".jpg", ".jpeg", ".gif", ".bmp", ".webp", ".tiff", ".ico"}

MENU_ITEMS = [
    {
        "key":    "fastfetch",
        "icon":   "F",
        "label":  "Fastfetch Logo",
        "sub":    "~/.config/fastfetch/icons",
        "color":  ACCENT,
        "folder": FASTFETCH_ICONS,
    },
    {
        "key":    "wallpaper",
        "icon":   "W",
        "label":  "Wallpaper",
        "sub":    "~/Pictures/Wallpaper",
        "color":  ACCENT2,
        "folder": WALLPAPER_DIR,
    },
    {
        "key":    "sddm",
        "icon":   "S",
        "label":  "SDDM Background",
        "sub":    "~/Pictures/Wallpaper",
        "color":  ACCENT3,
        "folder": WALLPAPER_DIR,
    },
]


# ── Helpers ───────────────────────────────────────────────────────────────────
def list_images(folder):
    if not folder or not os.path.isdir(folder):
        return []
    try:
        return sorted(
            [os.path.join(folder, f) for f in os.listdir(folder)
             if os.path.splitext(f)[1].lower() in SUPPORTED],
            key=lambda p: os.path.basename(p).lower()
        )
    except PermissionError:
        return []


def make_thumbnail(path, size):
    try:
        img = Image.open(path).convert("RGBA")
        img.thumbnail((size, size), Image.LANCZOS)
        bg = Image.new("RGBA", (size, size), (26, 26, 26, 255))
        bg.paste(img, ((size - img.width) // 2, (size - img.height) // 2), img)
        return ImageTk.PhotoImage(bg.convert("RGB"))
    except Exception:
        return None


def all_children(widget):
    kids = list(widget.winfo_children())
    for k in list(kids):
        kids += all_children(k)
    return kids


# ── Ações ─────────────────────────────────────────────────────────────────────
def apply_fastfetch(path):
    name = os.path.basename(path)
    if not os.path.exists(FASTFETCH_CONFIG):
        messagebox.showerror("Erro", f"Config não encontrado:\n{FASTFETCH_CONFIG}")
        return
    try:
        with open(FASTFETCH_CONFIG, "r", encoding="utf-8") as f:
            content = f.read()
        new = re.sub(r'("source"\s*:\s*)"[^"]*"', f'"source": "{path}"', content)
        with open(FASTFETCH_CONFIG, "w", encoding="utf-8") as f:
            f.write(new)
        messagebox.showinfo("Fastfetch ✓", f"Fastfetch logo trocado para\n{name}")
    except Exception as e:
        messagebox.showerror("Erro", f"Falha ao editar config:\n{e}")


def apply_wallpaper(path):
    name = os.path.basename(path)
    try:
        subprocess.Popen(["awww", "img", path])
        messagebox.showinfo("Wallpaper ✓", f"Wallpaper trocado para\n{name}")
    except FileNotFoundError:
        messagebox.showerror("Erro", "Comando 'awww' não encontrado.")
    except Exception as e:
        messagebox.showerror("Erro", f"Falha ao rodar awww:\n{e}")


def apply_sddm(path):
    name = os.path.basename(path)
    sddm_bg_dir  = "/usr/share/sddm/themes/sddm-astronaut-theme/Backgrounds"
    dest_image   = os.path.join(sddm_bg_dir, name)
    relative_bg  = f"Backgrounds/{name}"

    if not os.path.exists(SDDM_CONF):
        messagebox.showerror("Erro", f"Arquivo SDDM não encontrado:\n{SDDM_CONF}")
        return
    try:
        # 1. Copia a imagem para a pasta Backgrounds/ via pkexec
        r1 = subprocess.run(["pkexec", "cp", path, dest_image],
                            capture_output=True)
        if r1.returncode != 0:
            messagebox.showerror("Erro",
                f"Não foi possível copiar a imagem para:\n{sddm_bg_dir}\n\n"
                f"Verifique se o tema sddm-astronaut está instalado.")
            return

        # 2. Edita o conf trocando Background=
        with open(SDDM_CONF, "r", encoding="utf-8") as f:
            content = f.read()

        new = re.sub(r'^(Background\s*=\s*).*$',
                     f'\\g<1>{relative_bg}',
                     content, flags=re.MULTILINE)

        tmp = "/tmp/_sddm_tmp.conf"
        with open(tmp, "w", encoding="utf-8") as f:
            f.write(new)

        r2 = subprocess.run(["pkexec", "cp", tmp, SDDM_CONF],
                            capture_output=True)
        os.remove(tmp)

        if r2.returncode == 0:
            messagebox.showinfo("SDDM ✓",
                f"Background SDDM trocado para\n{name}\n\n"
                f"Copiado para: {dest_image}\n"
                f"Config:  Background=\"{relative_bg}\"")
        else:
            messagebox.showerror("Erro", f"Permissão negada ao editar:\n{SDDM_CONF}")
    except Exception as e:
        messagebox.showerror("Erro", f"Falha ao configurar SDDM:\n{e}")


ACTION = {
    "fastfetch": apply_fastfetch,
    "wallpaper":  apply_wallpaper,
    "sddm":       apply_sddm,
}


# ── Tela Menu ─────────────────────────────────────────────────────────────────
class MenuScreen(tk.Frame):
    def __init__(self, master, on_select):
        super().__init__(master, bg=BG)
        self._on_select = on_select
        self._build()

    def _build(self):
        tk.Label(self, text="THEME CHANGER",
                 bg=BG, fg=TEXT,
                 font=("JetBrains Mono", 20, "bold")).pack(pady=(52, 2))
        tk.Frame(self, bg=BORDER, height=1, width=260).pack(pady=(4, 8))
        tk.Label(self, text="Select what you want to change.",
                 bg=BG, fg=MUTED,
                 font=("JetBrains Mono", 9)).pack(pady=(0, 34))

        for item in MENU_ITEMS:
            self._card(item)

        tk.Label(self, text="python + tkinter",
                 bg=BG, fg="#2a2a2a",
                 font=("JetBrains Mono", 8)).pack(pady=(44, 0))

    def _card(self, item):
        color  = item["color"]
        folder = item["folder"]
        exists = os.path.isdir(folder)
        count  = len(list_images(folder)) if exists else 0

        wrap = tk.Frame(self, bg=BG)
        wrap.pack(pady=7)

        # barra lateral monocromatica
        bar = tk.Frame(wrap, bg=BORDER, width=2, height=80)
        bar.pack(side="left")

        card = tk.Frame(wrap, bg=CARD_BG, padx=24, pady=16, cursor="hand2")
        card.pack(side="left")

        # ícone
        tk.Label(card, text=f"[{item['icon']}]",
                 bg=CARD_BG, fg=ACCENT2,
                 font=("JetBrains Mono", 20, "bold")).pack(side="left", padx=(0, 20))

        info = tk.Frame(card, bg=CARD_BG)
        info.pack(side="left")

        tk.Label(info, text=item["label"],
                 bg=CARD_BG, fg=TEXT,
                 font=("JetBrains Mono", 12, "bold")).pack(anchor="w")
        tk.Label(info, text=item["sub"],
                 bg=CARD_BG, fg=MUTED,
                 font=("JetBrains Mono", 8)).pack(anchor="w")

        status = f"{count} imagem(ns)" if exists else "! pasta nao encontrada"
        tk.Label(info, text=status,
                 bg=CARD_BG, fg=ACCENT2 if exists else ACCENT3,
                 font=("JetBrains Mono", 8)).pack(anchor="w", pady=(2, 0))

        tk.Label(card, text=">>",
                 bg=CARD_BG, fg=MUTED,
                 font=("JetBrains Mono", 13)).pack(side="right", padx=(20, 0))

        # eventos em todos os filhos
        def enter(e, c=card): c.config(bg=CARD_HOVER)
        def leave(e, c=card): c.config(bg=CARD_BG)
        def click(e, i=item): self._on_select(i)

        for w in [card] + all_children(card):
            w.bind("<Enter>",    enter)
            w.bind("<Leave>",    leave)
            w.bind("<Button-1>", click)


# ── Tela Galeria ──────────────────────────────────────────────────────────────
class GalleryScreen(tk.Frame):
    def __init__(self, master, item, on_back):
        super().__init__(master, bg=BG)
        self._item    = item
        self._on_back = on_back
        self._thumbs  = []
        self._build()
        self._load()

    def _build(self):
        color = self._item["color"]

        # cabeçalho
        hdr = tk.Frame(self, bg=BG)
        hdr.pack(fill="x", padx=20, pady=(14, 0))

        tk.Button(hdr, text="<< voltar",
                  bg=CARD_BG, fg=MUTED, activebackground=CARD_HOVER,
                  activeforeground=TEXT, relief="flat", cursor="hand2",
                  font=("JetBrains Mono", 9), padx=12, pady=5,
                  command=self._on_back).pack(side="left")

        tk.Label(hdr,
                 text=f"  [{self._item['icon']}]  {self._item['label'].upper()}",
                 bg=BG, fg=TEXT,
                 font=("JetBrains Mono", 13, "bold")).pack(side="left", padx=14)

        tk.Frame(self, bg=BORDER, height=1).pack(fill="x", padx=20, pady=8)

        self._info_var = tk.StringVar(value="Carregando…")
        tk.Label(self, textvariable=self._info_var,
                 bg=BG, fg=MUTED,
                 font=("JetBrains Mono", 8)).pack(anchor="w", padx=22)

        # canvas + scroll
        cont = tk.Frame(self, bg=BG)
        cont.pack(fill="both", expand=True, padx=8, pady=(6, 8))

        self._canvas = tk.Canvas(cont, bg=BG, highlightthickness=0)
        sb = tk.Scrollbar(cont, orient="vertical",
                          command=self._canvas.yview,
                          bg=BG, troughcolor=CARD_BG,
                          activebackground=color)
        self._canvas.configure(yscrollcommand=sb.set)

        sb.pack(side="right", fill="y")
        self._canvas.pack(side="left", fill="both", expand=True)

        self._grid = tk.Frame(self._canvas, bg=BG)
        self._win  = self._canvas.create_window((0, 0), window=self._grid,
                                                anchor="nw")

        self._grid.bind("<Configure>",
                        lambda e: self._canvas.configure(
                            scrollregion=self._canvas.bbox("all")))
        self._canvas.bind("<Configure>",
                          lambda e: self._canvas.itemconfig(
                              self._win, width=e.width))
        self._canvas.bind("<MouseWheel>", self._scroll)
        self._canvas.bind("<Button-4>",   self._scroll)
        self._canvas.bind("<Button-5>",   self._scroll)

    def _scroll(self, event):
        if event.num == 4:
            self._canvas.yview_scroll(-1, "units")
        elif event.num == 5:
            self._canvas.yview_scroll(1, "units")
        else:
            self._canvas.yview_scroll(int(-1 * event.delta / 120), "units")

    def _load(self):
        images = list_images(self._item["folder"])
        self._info_var.set(
            f"Pasta: {self._item['folder']}    ·    {len(images)} imagem(ns)"
        )
        self._render(images)

    def _render(self, images):
        for w in self._grid.winfo_children():
            w.destroy()
        self._thumbs.clear()
        color = self._item["color"]

        if not images:
            tk.Label(self._grid,
                     text="Nenhuma imagem encontrada nesta pasta.",
                     bg=BG, fg=MUTED,
                     font=("Courier New", 11)).grid(
                         row=0, column=0, pady=60, padx=40)
            return

        for idx, path in enumerate(images):
            row, col = divmod(idx, COLS)
            thumb = make_thumbnail(path, THUMB_SIZE)
            self._thumbs.append(thumb)

            card = tk.Frame(self._grid, bg=CARD_BG,
                            width=THUMB_SIZE + 16,
                            height=THUMB_SIZE + 36,
                            cursor="hand2")
            card.grid(row=row, column=col, padx=THUMB_PAD, pady=THUMB_PAD)
            card.grid_propagate(False)

            img_lbl = (tk.Label(card, image=thumb, bg=CARD_BG)
                       if thumb else
                       tk.Label(card, text="?", bg=CARD_BG,
                                fg=MUTED, font=("Courier New", 24)))
            img_lbl.place(x=8, y=6)

            name  = os.path.splitext(os.path.basename(path))[0]
            short = name if len(name) <= 12 else name[:11] + "…"
            name_lbl = tk.Label(card, text=short, bg=CARD_BG,
                                fg=ACCENT3, font=("JetBrains Mono", 7),
                                wraplength=THUMB_SIZE + 8)
            name_lbl.place(x=8, y=THUMB_SIZE + 8)

            for w in (card, img_lbl, name_lbl):
                w.bind("<Enter>",    lambda e, c=card: c.config(bg=CARD_HOVER))
                w.bind("<Leave>",    lambda e, c=card: c.config(bg=CARD_BG))
                w.bind("<Button-1>", lambda e, p=path: self._click(p))

        self._canvas.yview_moveto(0)

    def _click(self, path):
        ACTION[self._item["key"]](path)


# ── App ───────────────────────────────────────────────────────────────────────
class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("image-switcher")
        self.configure(bg=BG)
        self._cur = None
        self._show_menu()

    def _clear(self):
        if self._cur:
            self._cur.destroy()
            self._cur = None

    def _show_menu(self):
        self._clear()
        self.geometry("620x500")
        self._cur = MenuScreen(self, on_select=self._show_gallery)
        self._cur.pack(fill="both", expand=True)

    def _show_gallery(self, item):
        self._clear()
        self.geometry("1020x700")
        self._cur = GalleryScreen(self, item, on_back=self._show_menu)
        self._cur.pack(fill="both", expand=True)


if __name__ == "__main__":
    App().mainloop()

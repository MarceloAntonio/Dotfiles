#ifndef CONFIG_H
#define CONFIG_H

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <strings.h>
#include <limits.h>
#include <sys/stat.h>
#include <dirent.h>

/* ── Paths ─────────────────────────────────────── */
#define FASTFETCH_ICONS_REL  ".config/fastfetch/icons"
#define FASTFETCH_CONFIG_REL ".config/fastfetch/config.jsonc"
#define WALLPAPER_DIR_REL    "Pictures/Wallpaper"
#define SDDM_CONF           "/usr/share/sddm/themes/sddm-astronaut-theme/Themes/astronaut.conf"
#define SDDM_BG_DIR         "/usr/share/sddm/themes/sddm-astronaut-theme/Backgrounds"

/* ── Visual ────────────────────────────────────── */
#define THUMB_SIZE  100
#define THUMB_PAD   8
#define MAX_COLS    9

#define MENU_WIN_W  620
#define MENU_WIN_H  500
#define GAL_WIN_W   1020
#define GAL_WIN_H   700

/* ── Supported image formats ───────────────────── */
static const char *SUPPORTED_EXTS[] = {
    ".png", ".jpg", ".jpeg", ".gif", ".bmp", ".webp", ".tiff", ".ico", NULL
};

/* ── Menu item definition ──────────────────────── */
typedef struct {
    const char *key;
    const char *icon;
    const char *label;
    const char *sub;
    const char *folder_rel;
} MenuItem;

static const MenuItem MENU_ITEMS[] = {
    { "fastfetch", "F", "Fastfetch Logo",  "~/.config/fastfetch/icons", FASTFETCH_ICONS_REL },
    { "wallpaper", "W", "Wallpaper",       "~/Pictures/Wallpaper",      WALLPAPER_DIR_REL   },
    { "sddm",     "S", "SDDM Background", "~/Pictures/Wallpaper",      WALLPAPER_DIR_REL   },
};
#define MENU_ITEMS_COUNT 3

/* ── Helpers ───────────────────────────────────── */
static inline void build_path(char *buf, size_t len, const char *rel) {
    const char *home = getenv("HOME");
    snprintf(buf, len, "%s/%s", home ? home : "/tmp", rel);
}

static inline int is_supported_ext(const char *filename) {
    const char *dot = strrchr(filename, '.');
    if (!dot) return 0;
    for (int i = 0; SUPPORTED_EXTS[i]; i++) {
        if (strcasecmp(dot, SUPPORTED_EXTS[i]) == 0) return 1;
    }
    return 0;
}

static inline int path_is_dir(const char *path) {
    struct stat st;
    return (stat(path, &st) == 0 && S_ISDIR(st.st_mode));
}

static inline int count_images(const char *folder) {
    DIR *dir = opendir(folder);
    if (!dir) return -1;
    int count = 0;
    struct dirent *ent;
    while ((ent = readdir(dir))) {
        if (ent->d_name[0] == '.') continue;
        if (is_supported_ext(ent->d_name)) count++;
    }
    closedir(dir);
    return count;
}

/* ── CSS ───────────────────────────────────────── */
static const char APP_CSS[] =
    /* Window */
    "window { background-color: #131313; }"

    /* Menu title / subtitle */
    ".menu-title {"
    "  font-size: 20px; font-weight: bold; color: #FCFCFC;"
    "  font-family: 'JetBrains Mono', monospace;"
    "}"
    ".menu-sub {"
    "  font-size: 10px; color: #535353;"
    "  font-family: 'JetBrains Mono', monospace;"
    "}"

    /* Separator */
    ".sep { background-color: #535353; min-height: 1px; }"

    /* Menu cards */
    "button.menu-card {"
    "  background: #1A1A1A; border-radius: 6px;"
    "  padding: 16px 24px;"
    "  border-left: 2px solid #535353;"
    "  border-top: none; border-right: none; border-bottom: none;"
    "  transition: background 150ms ease;"
    "}"
    "button.menu-card:hover { background: #252525; }"
    "button.menu-card:active { background: #303030; }"

    ".card-icon {"
    "  font-size: 20px; font-weight: bold; color: #D6D6D6;"
    "  font-family: 'JetBrains Mono', monospace;"
    "}"
    ".card-label {"
    "  font-size: 13px; font-weight: bold; color: #FCFCFC;"
    "  font-family: 'JetBrains Mono', monospace;"
    "}"
    ".card-sub {"
    "  font-size: 9px; color: #535353;"
    "  font-family: 'JetBrains Mono', monospace;"
    "}"
    ".card-status {"
    "  font-size: 9px; color: #D6D6D6;"
    "  font-family: 'JetBrains Mono', monospace;"
    "}"
    ".card-status-err { color: #9D9D9D; }"
    ".card-arrow {"
    "  font-size: 13px; color: #535353;"
    "  font-family: 'JetBrains Mono', monospace;"
    "}"
    ".footer {"
    "  font-size: 8px; color: #2a2a2a;"
    "  font-family: 'JetBrains Mono', monospace;"
    "}"

    /* Gallery header */
    "button.back-btn {"
    "  background: #1A1A1A; color: #535353;"
    "  font-family: 'JetBrains Mono', monospace; font-size: 10px;"
    "  border: none; border-radius: 6px; padding: 6px 14px;"
    "  transition: all 150ms ease;"
    "}"
    "button.back-btn:hover { background: #252525; color: #FCFCFC; }"
    ".gal-title {"
    "  font-size: 14px; font-weight: bold; color: #FCFCFC;"
    "  font-family: 'JetBrains Mono', monospace;"
    "}"
    ".gal-info {"
    "  font-size: 9px; color: #535353;"
    "  font-family: 'JetBrains Mono', monospace;"
    "}"

    /* Thumbnail grid */
    "flowboxchild {"
    "  background: #1A1A1A; border-radius: 8px;"
    "  padding: 6px; transition: background 150ms ease;"
    "}"
    "flowboxchild:hover { background: #252525; }"
    "flowboxchild:active { background: #303030; }"
    ".thumb-name {"
    "  font-size: 8px; color: #9D9D9D;"
    "  font-family: 'JetBrains Mono', monospace;"
    "}"
    ".thumb-placeholder {"
    "  font-size: 24px; color: #535353;"
    "  font-family: 'JetBrains Mono', monospace;"
    "}"
    ".empty-label {"
    "  font-size: 11px; color: #535353;"
    "  font-family: 'JetBrains Mono', monospace;"
    "}"

    /* Scrollbar */
    "scrollbar { background: transparent; }"
    "scrollbar slider {"
    "  background: #535353; border-radius: 4px; min-width: 6px;"
    "}"
    "scrollbar slider:hover { background: #777777; }"
;

#endif /* CONFIG_H */

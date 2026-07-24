#include "actions.h"
#include "config.h"
#include <stdio.h>
#include <string.h>
#include <unistd.h>

/* ── Helpers ───────────────────────────────────── */

static void show_dialog(GtkWindow *parent, const char *title, const char *detail) {
    GtkAlertDialog *dlg = gtk_alert_dialog_new("%s", title);
    if (detail)
        gtk_alert_dialog_set_detail(dlg, detail);
    gtk_alert_dialog_show(dlg, parent);
    g_object_unref(dlg);
}

static char *read_file_text(const char *path) {
    FILE *f = fopen(path, "rb");
    if (!f) return NULL;
    fseek(f, 0, SEEK_END);
    long len = ftell(f);
    fseek(f, 0, SEEK_SET);
    char *buf = malloc(len + 1);
    if (!buf) { fclose(f); return NULL; }
    fread(buf, 1, len, f);
    buf[len] = '\0';
    fclose(f);
    return buf;
}

static int write_file_text(const char *path, const char *content) {
    FILE *f = fopen(path, "w");
    if (!f) return -1;
    fputs(content, f);
    fclose(f);
    return 0;
}

/* ── Fastfetch ─────────────────────────────────── */

static void apply_fastfetch(const char *img_path, GtkWindow *parent) {
    char conf[PATH_MAX];
    build_path(conf, sizeof(conf), FASTFETCH_CONFIG_REL);

    char *content = read_file_text(conf);
    if (!content) {
        show_dialog(parent, "Erro", "Config do fastfetch não encontrado.");
        return;
    }

    /* Find "source" : "..." and replace the path */
    GRegex *re = g_regex_new("(\"source\"\\s*:\\s*)\"[^\"]*\"", 0, 0, NULL);
    if (!re) {
        free(content);
        show_dialog(parent, "Erro", "Falha ao compilar regex.");
        return;
    }

    char replacement[PATH_MAX + 32];
    snprintf(replacement, sizeof(replacement), "\\1\"%s\"", img_path);

    char *result = g_regex_replace(re, content, -1, 0, replacement, 0, NULL);
    g_regex_unref(re);
    free(content);

    if (!result) {
        show_dialog(parent, "Erro", "Falha ao aplicar regex.");
        return;
    }

    if (write_file_text(conf, result) < 0) {
        g_free(result);
        show_dialog(parent, "Erro", "Falha ao salvar config.");
        return;
    }
    g_free(result);

    const char *name = strrchr(img_path, '/');
    name = name ? name + 1 : img_path;

    char msg[PATH_MAX + 64];
    snprintf(msg, sizeof(msg), "Logo trocado para\n%s", name);
    show_dialog(parent, "Fastfetch ✓", msg);
}

/* ── Wallpaper ─────────────────────────────────── */

static void apply_wallpaper(const char *img_path, GtkWindow *parent) {
    const char *name = strrchr(img_path, '/');
    name = name ? name + 1 : img_path;

    GError *err = NULL;
    gchar *argv[] = { "awww", "img", (gchar *)img_path, NULL };
    gboolean ok = g_spawn_async(NULL, argv, NULL,
                                 G_SPAWN_SEARCH_PATH, NULL, NULL, NULL, &err);
    if (!ok) {
        char msg[512];
        snprintf(msg, sizeof(msg), "Falha ao rodar awww:\n%s",
                 err ? err->message : "desconhecido");
        g_clear_error(&err);
        show_dialog(parent, "Erro", msg);
        return;
    }

    char msg[PATH_MAX + 64];
    snprintf(msg, sizeof(msg), "Wallpaper trocado para\n%s", name);
    show_dialog(parent, "Wallpaper ✓", msg);
}

/* ── SDDM ─────────────────────────────────────── */

static void apply_sddm(const char *img_path, GtkWindow *parent) {
    const char *name = strrchr(img_path, '/');
    name = name ? name + 1 : img_path;

    if (access(SDDM_CONF, F_OK) != 0) {
        show_dialog(parent, "Erro",
                    "Arquivo SDDM não encontrado:\n" SDDM_CONF);
        return;
    }

    /* 1. Copy image to SDDM Backgrounds/ via pkexec */
    char dest[PATH_MAX];
    snprintf(dest, sizeof(dest), "%s/%s", SDDM_BG_DIR, name);

    GError *err = NULL;
    gint status = 0;
    gchar *cp_argv[] = { "pkexec", "cp", (gchar *)img_path, dest, NULL };
    gboolean ok = g_spawn_sync(NULL, cp_argv, NULL,
                                G_SPAWN_SEARCH_PATH, NULL, NULL,
                                NULL, NULL, &status, &err);
    if (!ok || status != 0) {
        g_clear_error(&err);
        show_dialog(parent, "Erro",
                    "Não foi possível copiar a imagem.\n"
                    "Verifique se o tema sddm-astronaut está instalado.");
        return;
    }

    /* 2. Read conf, replace Background= line */
    char *content = read_file_text(SDDM_CONF);
    if (!content) {
        show_dialog(parent, "Erro", "Falha ao ler config SDDM.");
        return;
    }

    char relative_bg[PATH_MAX];
    snprintf(relative_bg, sizeof(relative_bg), "Backgrounds/%s", name);

    GRegex *re = g_regex_new("^(Background\\s*=\\s*).*$",
                              G_REGEX_MULTILINE, 0, NULL);
    char replacement[PATH_MAX + 16];
    snprintf(replacement, sizeof(replacement), "\\1%s", relative_bg);

    char *result = g_regex_replace(re, content, -1, 0, replacement, 0, NULL);
    g_regex_unref(re);
    free(content);

    if (!result) {
        show_dialog(parent, "Erro", "Falha ao processar config SDDM.");
        return;
    }

    /* 3. Write to tmp, then pkexec cp to real location */
    const char *tmp = "/tmp/_sddm_tmp.conf";
    if (write_file_text(tmp, result) < 0) {
        g_free(result);
        show_dialog(parent, "Erro", "Falha ao criar arquivo temporário.");
        return;
    }
    g_free(result);

    gchar *cp2_argv[] = { "pkexec", "cp", (gchar *)tmp, (gchar *)SDDM_CONF, NULL };
    ok = g_spawn_sync(NULL, cp2_argv, NULL,
                       G_SPAWN_SEARCH_PATH, NULL, NULL,
                       NULL, NULL, &status, &err);
    unlink(tmp);

    if (!ok || status != 0) {
        g_clear_error(&err);
        show_dialog(parent, "Erro", "Permissão negada ao editar config SDDM.");
        return;
    }

    char msg[PATH_MAX * 2 + 128];
    snprintf(msg, sizeof(msg),
             "Background SDDM trocado para\n%s\n\n"
             "Copiado para: %s\n"
             "Config: Background=\"%s\"",
             name, dest, relative_bg);
    show_dialog(parent, "SDDM ✓", msg);
}

/* ── Dispatcher ────────────────────────────────── */

void apply_action(const char *key, const char *path, GtkWindow *parent) {
    if (strcmp(key, "fastfetch") == 0)
        apply_fastfetch(path, parent);
    else if (strcmp(key, "wallpaper") == 0)
        apply_wallpaper(path, parent);
    else if (strcmp(key, "sddm") == 0)
        apply_sddm(path, parent);
}

#include "gallery.h"
#include "actions.h"
#include "config.h"

/* ── Image list ────────────────────────────────── */

typedef struct {
    char **paths;
    int    count;
} ImageList;

static int cmp_basename(const void *a, const void *b) {
    const char *pa = *(const char **)a;
    const char *pb = *(const char **)b;
    const char *ba = strrchr(pa, '/');
    const char *bb = strrchr(pb, '/');
    ba = ba ? ba + 1 : pa;
    bb = bb ? bb + 1 : pb;
    return strcasecmp(ba, bb);
}

static ImageList list_images(const char *folder) {
    ImageList list = { NULL, 0 };
    DIR *dir = opendir(folder);
    if (!dir) return list;

    int cap = 64;
    list.paths = malloc(cap * sizeof(char *));

    struct dirent *ent;
    while ((ent = readdir(dir))) {
        if (ent->d_name[0] == '.') continue;
        if (!is_supported_ext(ent->d_name)) continue;

        if (list.count >= cap) {
            cap *= 2;
            list.paths = realloc(list.paths, cap * sizeof(char *));
        }
        char path[PATH_MAX];
        snprintf(path, sizeof(path), "%s/%s", folder, ent->d_name);
        list.paths[list.count++] = g_strdup(path);
    }
    closedir(dir);

    if (list.count > 0)
        qsort(list.paths, list.count, sizeof(char *), cmp_basename);

    return list;
}

static void free_image_list(ImageList *list) {
    for (int i = 0; i < list->count; i++)
        g_free(list->paths[i]);
    free(list->paths);
    list->paths = NULL;
    list->count = 0;
}

/* ── Gallery data ──────────────────────────────── */

typedef struct {
    char                key[32];
    char                folder[PATH_MAX];
    GtkWindow          *parent;
    GalleryBackCallback on_back;
    ImageList           images;
} GalleryData;

static void gallery_data_free(gpointer data) {
    GalleryData *gd = data;
    free_image_list(&gd->images);
    g_free(gd);
}

/* ── Thumbnail ─────────────────────────────────── */

static GtkWidget *make_thumbnail(const char *path, int size) {
    GdkPixbuf *pixbuf = gdk_pixbuf_new_from_file_at_scale(
        path, size, size, TRUE, NULL);

    if (!pixbuf) {
        GtkWidget *lbl = gtk_label_new("?");
        gtk_widget_add_css_class(lbl, "thumb-placeholder");
        gtk_widget_set_size_request(lbl, size, size);
        return lbl;
    }

    /* Convert pixbuf → PNG bytes → GdkTexture (avoids deprecated API) */
    gchar *buf = NULL;
    gsize buf_len = 0;
    gdk_pixbuf_save_to_buffer(pixbuf, &buf, &buf_len, "png", NULL, NULL);
    g_object_unref(pixbuf);

    if (!buf) {
        GtkWidget *lbl = gtk_label_new("?");
        gtk_widget_add_css_class(lbl, "thumb-placeholder");
        gtk_widget_set_size_request(lbl, size, size);
        return lbl;
    }

    GBytes *bytes = g_bytes_new_take(buf, buf_len);
    GdkTexture *texture = gdk_texture_new_from_bytes(bytes, NULL);
    g_bytes_unref(bytes);

    if (!texture) {
        GtkWidget *lbl = gtk_label_new("?");
        gtk_widget_add_css_class(lbl, "thumb-placeholder");
        gtk_widget_set_size_request(lbl, size, size);
        return lbl;
    }

    GtkWidget *picture = gtk_picture_new_for_paintable(GDK_PAINTABLE(texture));
    gtk_picture_set_content_fit(GTK_PICTURE(picture), GTK_CONTENT_FIT_CONTAIN);
    gtk_widget_set_size_request(picture, size, size);
    g_object_unref(texture);

    return picture;
}

/* ── Events ────────────────────────────────────── */

static void on_child_activated(GtkFlowBox *flowbox,
                                GtkFlowBoxChild *child,
                                gpointer user_data) {
    (void)flowbox;
    GalleryData *gd = user_data;
    GtkWidget *card = gtk_flow_box_child_get_child(child);
    const char *path = g_object_get_data(G_OBJECT(card), "path");
    if (path)
        apply_action(gd->key, path, gd->parent);
}

static void on_back_clicked(GtkButton *btn, gpointer user_data) {
    (void)btn;
    GalleryData *gd = user_data;
    if (gd->on_back) gd->on_back();
}

/* ── Build ─────────────────────────────────────── */

GtkWidget *gallery_screen_new(const char *key, const char *label,
                               const char *folder, GtkWindow *parent,
                               GalleryBackCallback on_back) {
    GalleryData *gd = g_new0(GalleryData, 1);
    g_strlcpy(gd->key, key, sizeof(gd->key));
    g_strlcpy(gd->folder, folder, sizeof(gd->folder));
    gd->parent  = parent;
    gd->on_back = on_back;
    gd->images  = list_images(folder);

    GtkWidget *vbox = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
    g_object_set_data_full(G_OBJECT(vbox), "gal-data", gd, gallery_data_free);

    /* ── Header ── */
    GtkWidget *hdr = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 14);
    gtk_widget_set_margin_start(hdr, 20);
    gtk_widget_set_margin_end(hdr, 20);
    gtk_widget_set_margin_top(hdr, 14);

    GtkWidget *back = gtk_button_new_with_label("<< voltar");
    gtk_widget_add_css_class(back, "flat");
    gtk_widget_add_css_class(back, "back-btn");
    g_signal_connect(back, "clicked", G_CALLBACK(on_back_clicked), gd);
    gtk_box_append(GTK_BOX(hdr), back);

    char title_str[128];
    snprintf(title_str, sizeof(title_str), "  [%s]  %s",
             key[0] >= 'a' ? (char[]){key[0]-32, '\0'} : (char[]){key[0], '\0'},
             label);
    /* Build uppercase title from key initial */
    char icon_char = key[0];
    if (icon_char >= 'a' && icon_char <= 'z') icon_char -= 32;
    snprintf(title_str, sizeof(title_str), "  [%c]  ", icon_char);

    /* Uppercase the label */
    char upper_label[64];
    g_strlcpy(upper_label, label, sizeof(upper_label));
    for (char *p = upper_label; *p; p++)
        if (*p >= 'a' && *p <= 'z') *p -= 32;
    strncat(title_str, upper_label, sizeof(title_str) - strlen(title_str) - 1);

    GtkWidget *title = gtk_label_new(title_str);
    gtk_widget_add_css_class(title, "gal-title");
    gtk_box_append(GTK_BOX(hdr), title);

    gtk_box_append(GTK_BOX(vbox), hdr);

    /* Separator */
    GtkWidget *sep = gtk_separator_new(GTK_ORIENTATION_HORIZONTAL);
    gtk_widget_add_css_class(sep, "sep");
    gtk_widget_set_margin_start(sep, 20);
    gtk_widget_set_margin_end(sep, 20);
    gtk_widget_set_margin_top(sep, 8);
    gtk_widget_set_margin_bottom(sep, 4);
    gtk_box_append(GTK_BOX(vbox), sep);

    /* Info */
    char info_str[PATH_MAX + 64];
    snprintf(info_str, sizeof(info_str),
             "Pasta: %s    ·    %d imagem(ns)", folder, gd->images.count);
    GtkWidget *info = gtk_label_new(info_str);
    gtk_widget_add_css_class(info, "gal-info");
    gtk_label_set_xalign(GTK_LABEL(info), 0);
    gtk_widget_set_margin_start(info, 22);
    gtk_widget_set_margin_bottom(info, 6);
    gtk_box_append(GTK_BOX(vbox), info);

    /* ── Scrolled grid ── */
    GtkWidget *scrolled = gtk_scrolled_window_new();
    gtk_widget_set_vexpand(scrolled, TRUE);
    gtk_widget_set_margin_start(scrolled, 8);
    gtk_widget_set_margin_end(scrolled, 8);
    gtk_widget_set_margin_bottom(scrolled, 8);

    GtkWidget *flowbox = gtk_flow_box_new();
    gtk_flow_box_set_max_children_per_line(GTK_FLOW_BOX(flowbox), MAX_COLS);
    gtk_flow_box_set_min_children_per_line(GTK_FLOW_BOX(flowbox), 3);
    gtk_flow_box_set_selection_mode(GTK_FLOW_BOX(flowbox), GTK_SELECTION_NONE);
    gtk_flow_box_set_homogeneous(GTK_FLOW_BOX(flowbox), TRUE);
    gtk_flow_box_set_column_spacing(GTK_FLOW_BOX(flowbox), THUMB_PAD);
    gtk_flow_box_set_row_spacing(GTK_FLOW_BOX(flowbox), THUMB_PAD);
    gtk_flow_box_set_activate_on_single_click(GTK_FLOW_BOX(flowbox), TRUE);
    g_signal_connect(flowbox, "child-activated",
                     G_CALLBACK(on_child_activated), gd);

    if (gd->images.count == 0) {
        GtkWidget *empty = gtk_label_new("Nenhuma imagem encontrada nesta pasta.");
        gtk_widget_add_css_class(empty, "empty-label");
        gtk_widget_set_margin_top(empty, 60);
        gtk_flow_box_append(GTK_FLOW_BOX(flowbox), empty);
    } else {
        for (int i = 0; i < gd->images.count; i++) {
            const char *path = gd->images.paths[i];
            const char *basename = strrchr(path, '/');
            basename = basename ? basename + 1 : path;

            /* Card: vertical box with thumbnail + name */
            GtkWidget *card = gtk_box_new(GTK_ORIENTATION_VERTICAL, 4);
            gtk_widget_set_size_request(card, THUMB_SIZE + 16, THUMB_SIZE + 36);
            g_object_set_data_full(G_OBJECT(card), "path",
                                   g_strdup(path), g_free);

            GtkWidget *thumb = make_thumbnail(path, THUMB_SIZE);
            gtk_box_append(GTK_BOX(card), thumb);

            /* Truncate name */
            char name_noext[256];
            g_strlcpy(name_noext, basename, sizeof(name_noext));
            char *dot = strrchr(name_noext, '.');
            if (dot) *dot = '\0';

            char short_name[16];
            if (strlen(name_noext) > 12) {
                g_strlcpy(short_name, name_noext, 12);
                strcat(short_name, "…");
            } else {
                g_strlcpy(short_name, name_noext, sizeof(short_name));
            }

            GtkWidget *name_lbl = gtk_label_new(short_name);
            gtk_widget_add_css_class(name_lbl, "thumb-name");
            gtk_label_set_xalign(GTK_LABEL(name_lbl), 0.5);
            gtk_box_append(GTK_BOX(card), name_lbl);

            gtk_flow_box_append(GTK_FLOW_BOX(flowbox), card);
        }
    }

    gtk_scrolled_window_set_child(GTK_SCROLLED_WINDOW(scrolled), flowbox);
    gtk_box_append(GTK_BOX(vbox), scrolled);

    return vbox;
}

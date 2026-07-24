#include "menu.h"
#include "config.h"

typedef struct {
    MenuSelectCallback on_select;
} MenuData;

typedef struct {
    MenuData       *menu;
    const MenuItem *item;
    char            folder[PATH_MAX];
} CardData;

static void on_card_clicked(GtkButton *btn, gpointer user_data) {
    (void)btn;
    CardData *cd = user_data;
    cd->menu->on_select(cd->item->key, cd->item->label, cd->folder);
}

static GtkWidget *make_card(const MenuItem *item, MenuData *md) {
    CardData *cd = g_new0(CardData, 1);
    cd->menu = md;
    cd->item = item;
    build_path(cd->folder, sizeof(cd->folder), item->folder_rel);

    int exists = path_is_dir(cd->folder);
    int img_count = exists ? count_images(cd->folder) : 0;

    /* Button container */
    GtkWidget *btn = gtk_button_new();
    gtk_widget_add_css_class(btn, "flat");
    gtk_widget_add_css_class(btn, "menu-card");
    g_signal_connect(btn, "clicked", G_CALLBACK(on_card_clicked), cd);
    /* Free CardData when button is destroyed */
    g_signal_connect_swapped(btn, "destroy", G_CALLBACK(g_free), cd);

    /* Horizontal layout: icon | info | arrow */
    GtkWidget *hbox = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 20);

    /* Icon */
    char icon_str[8];
    snprintf(icon_str, sizeof(icon_str), "[%s]", item->icon);
    GtkWidget *icon = gtk_label_new(icon_str);
    gtk_widget_add_css_class(icon, "card-icon");
    gtk_box_append(GTK_BOX(hbox), icon);

    /* Info column */
    GtkWidget *vbox = gtk_box_new(GTK_ORIENTATION_VERTICAL, 2);
    gtk_widget_set_hexpand(vbox, TRUE);

    GtkWidget *label = gtk_label_new(item->label);
    gtk_widget_add_css_class(label, "card-label");
    gtk_label_set_xalign(GTK_LABEL(label), 0);
    gtk_box_append(GTK_BOX(vbox), label);

    GtkWidget *sub = gtk_label_new(item->sub);
    gtk_widget_add_css_class(sub, "card-sub");
    gtk_label_set_xalign(GTK_LABEL(sub), 0);
    gtk_box_append(GTK_BOX(vbox), sub);

    char status_str[64];
    if (exists)
        snprintf(status_str, sizeof(status_str), "%d imagem(ns)", img_count);
    else
        snprintf(status_str, sizeof(status_str), "! pasta não encontrada");

    GtkWidget *status = gtk_label_new(status_str);
    gtk_widget_add_css_class(status, "card-status");
    if (!exists) gtk_widget_add_css_class(status, "card-status-err");
    gtk_label_set_xalign(GTK_LABEL(status), 0);
    gtk_box_append(GTK_BOX(vbox), status);

    gtk_box_append(GTK_BOX(hbox), vbox);

    /* Arrow */
    GtkWidget *arrow = gtk_label_new(">>");
    gtk_widget_add_css_class(arrow, "card-arrow");
    gtk_box_append(GTK_BOX(hbox), arrow);

    gtk_button_set_child(GTK_BUTTON(btn), hbox);
    return btn;
}

GtkWidget *menu_screen_new(MenuSelectCallback on_select) {
    MenuData *md = g_new0(MenuData, 1);
    md->on_select = on_select;

    GtkWidget *vbox = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
    gtk_widget_set_halign(vbox, GTK_ALIGN_CENTER);
    gtk_widget_set_valign(vbox, GTK_ALIGN_CENTER);

    /* Free MenuData when vbox is destroyed */
    g_signal_connect_swapped(vbox, "destroy", G_CALLBACK(g_free), md);

    /* Title */
    GtkWidget *title = gtk_label_new("THEME CHANGER");
    gtk_widget_add_css_class(title, "menu-title");
    gtk_widget_set_margin_bottom(title, 4);
    gtk_box_append(GTK_BOX(vbox), title);

    /* Separator */
    GtkWidget *sep = gtk_separator_new(GTK_ORIENTATION_HORIZONTAL);
    gtk_widget_add_css_class(sep, "sep");
    gtk_widget_set_size_request(sep, 260, -1);
    gtk_widget_set_margin_bottom(sep, 8);
    gtk_box_append(GTK_BOX(vbox), sep);

    /* Subtitle */
    GtkWidget *sub = gtk_label_new("Select what you want to change.");
    gtk_widget_add_css_class(sub, "menu-sub");
    gtk_widget_set_margin_bottom(sub, 34);
    gtk_box_append(GTK_BOX(vbox), sub);

    /* Cards */
    for (int i = 0; i < MENU_ITEMS_COUNT; i++) {
        GtkWidget *card = make_card(&MENU_ITEMS[i], md);
        gtk_widget_set_margin_bottom(card, 14);
        gtk_box_append(GTK_BOX(vbox), card);
    }

    /* Footer */
    GtkWidget *footer = gtk_label_new("C + GTK4");
    gtk_widget_add_css_class(footer, "footer");
    gtk_widget_set_margin_top(footer, 30);
    gtk_box_append(GTK_BOX(vbox), footer);

    return vbox;
}

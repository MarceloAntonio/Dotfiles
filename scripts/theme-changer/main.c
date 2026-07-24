#include <gtk/gtk.h>
#include "config.h"
#include "menu.h"
#include "gallery.h"

static GtkStack  *stack;
static GtkWindow *main_window;

/* ── Navigation ────────────────────────────────── */

static void show_menu(void);

static void show_gallery(const char *key, const char *label, const char *folder) {
    /* Remove previous gallery if any */
    GtkWidget *old = gtk_stack_get_child_by_name(stack, "gallery");
    if (old) gtk_stack_remove(stack, old);

    GtkWidget *gal = gallery_screen_new(key, label, folder,
                                         main_window, show_menu);
    gtk_stack_add_named(stack, gal, "gallery");
    gtk_stack_set_visible_child_name(stack, "gallery");

    gtk_window_set_default_size(main_window, GAL_WIN_W, GAL_WIN_H);
}

static void show_menu(void) {
    gtk_stack_set_visible_child_name(stack, "menu");
    gtk_window_set_default_size(main_window, MENU_WIN_W, MENU_WIN_H);
}

/* ── App activate ──────────────────────────────── */

static void activate(GtkApplication *app, gpointer data) {
    (void)data;

    main_window = GTK_WINDOW(gtk_application_window_new(app));
    gtk_window_set_title(main_window, "Theme Changer");
    gtk_window_set_default_size(main_window, MENU_WIN_W, MENU_WIN_H);

    /* Load CSS */
    GtkCssProvider *css = gtk_css_provider_new();
    gtk_css_provider_load_from_string(css, APP_CSS);
    gtk_style_context_add_provider_for_display(
        gdk_display_get_default(),
        GTK_STYLE_PROVIDER(css),
        GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
    g_object_unref(css);

    /* Stack for screen switching */
    stack = GTK_STACK(gtk_stack_new());
    gtk_stack_set_transition_type(stack,
        GTK_STACK_TRANSITION_TYPE_SLIDE_LEFT_RIGHT);
    gtk_stack_set_transition_duration(stack, 200);

    /* Menu screen */
    GtkWidget *menu = menu_screen_new(show_gallery);
    gtk_stack_add_named(stack, menu, "menu");

    gtk_window_set_child(main_window, GTK_WIDGET(stack));
    gtk_window_present(main_window);
}

/* ── Main ──────────────────────────────────────── */

int main(int argc, char *argv[]) {
    GtkApplication *app = gtk_application_new(
        "com.celo.theme-changer",
        G_APPLICATION_DEFAULT_FLAGS);

    g_signal_connect(app, "activate", G_CALLBACK(activate), NULL);

    int status = g_application_run(G_APPLICATION(app), argc, argv);
    g_object_unref(app);
    return status;
}

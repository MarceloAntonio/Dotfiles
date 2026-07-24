#ifndef MENU_H
#define MENU_H

#include <gtk/gtk.h>

typedef void (*MenuSelectCallback)(const char *key, const char *label,
                                   const char *folder);

GtkWidget *menu_screen_new(MenuSelectCallback on_select);

#endif /* MENU_H */

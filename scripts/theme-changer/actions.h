#ifndef ACTIONS_H
#define ACTIONS_H

#include <gtk/gtk.h>

/* Apply the appropriate action for the given key */
void apply_action(const char *key, const char *path, GtkWindow *parent);

#endif /* ACTIONS_H */

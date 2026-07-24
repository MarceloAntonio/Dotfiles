#ifndef GALLERY_H
#define GALLERY_H

#include <gtk/gtk.h>

typedef void (*GalleryBackCallback)(void);

GtkWidget *gallery_screen_new(const char *key, const char *label,
                               const char *folder, GtkWindow *parent,
                               GalleryBackCallback on_back);

#endif /* GALLERY_H */

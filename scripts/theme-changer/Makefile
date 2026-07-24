CC      = gcc
CFLAGS  = $(shell pkg-config --cflags gtk4) -O2 -Wall -Wextra
LIBS    = $(shell pkg-config --libs gtk4)
SRC     = main.c menu.c gallery.c actions.c
OBJ     = $(SRC:.c=.o)
BIN     = theme-changer

all: $(BIN)

$(BIN): $(OBJ)
	$(CC) -o $@ $^ $(LIBS)

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

install: $(BIN)
	sudo install -Dm755 $(BIN) /usr/local/bin/$(BIN)

uninstall:
	sudo rm -f /usr/local/bin/$(BIN)

clean:
	rm -f $(OBJ) $(BIN)

.PHONY: all install uninstall clean

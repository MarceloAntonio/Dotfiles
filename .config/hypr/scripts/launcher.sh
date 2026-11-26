#!/usr/bin/env bash
# Abre o Rofi no idioma atual do sistema, mesmo antes de sair e entrar na sessão.
# Os aplicativos abertos por ele herdam o mesmo LANG.
. /etc/locale.conf 2>/dev/null
export LANG
case $LANG in en*) hint="Search..." ;; *) hint="Pesquisar..." ;; esac
exec rofi -show drun -theme-str "entry { placeholder: \"$hint\"; }" "$@"

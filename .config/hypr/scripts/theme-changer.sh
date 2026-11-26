#!/usr/bin/env bash
# The four existing personalization shortcuts now open Quickshell.
set -u
if grep -qs '^LANG=en' /etc/locale.conf; then en=1; else en=; fi
case "${1:-menu}" in
    0 | wallpaper) category=wallpaper ;;
    1 | sddm) category=sddm ;;
    2 | fastfetch) category=fastfetch ;;
    3 | kitty) category=kitty ;;
    *) category=menu ;;
esac
qs -c control-center --no-duplicate --daemonize >/dev/null 2>&1
for ((attempt=0; attempt<40; attempt++)); do
    if qs -c control-center ipc call personalize open "$category" >/dev/null 2>&1; then
        exit 0
    fi
    sleep 0.05
done
if [ -n "$en" ]; then
    notify-send 'Customize' 'Could not open the Quickshell selector.' -u critical
else
    notify-send 'Personalizar' 'Não foi possível abrir o seletor do Quickshell.' -u critical
fi
exit 1

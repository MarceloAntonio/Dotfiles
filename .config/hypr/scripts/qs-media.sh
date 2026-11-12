#!/usr/bin/env bash
# Keep hardware keys functional even if the control center is stopped.
set -u
kind=volume
case "${1:-}" in
    volume-up) wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+ || exit ;;
    volume-down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- || exit ;;
    mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle || exit ;;
    mic-mute) wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle || exit; kind=mic ;;
    brightness-up) brightnessctl -e4 -n2 set 5%+ >/dev/null || exit; kind=brightness ;;
    brightness-down) brightnessctl -e4 -n2 set 5%- >/dev/null || exit; kind=brightness ;;
    *) exit 2 ;;
esac
qs -c control-center ipc call osd display "$kind" >/dev/null 2>&1 || true

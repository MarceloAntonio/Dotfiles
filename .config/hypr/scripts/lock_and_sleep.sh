#!/bin/bash
hyprlock &
HYPRLOCK_PID=$!

sleep 15

if kill -0 $HYPRLOCK_PID 2>/dev/null; then
    hyprctl dispatch dpms off
fi

wait $HYPRLOCK_PID
hyprctl dispatch dpms on

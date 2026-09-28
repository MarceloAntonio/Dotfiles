---@module 'hl'

hl.window_rule({
    name  = "suppress-maximize-events",
    match = {
        class = ".*",
    },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

hl.window_rule({
    name  = "move-hyprland-run",
    match = {
        class = "hyprland-run",
    },
    move = { 20, "monitor_h-120" },
    float = true,
})

hl.layer_rule({
    name = "blur-waybar",
    match = { namespace = "^waybar$" },
    blur = true,
    blur_popups = true,
    ignore_alpha = 0.02,
})

hl.layer_rule({
    name = "blur-swaync-cc",
    match = { namespace = "^swaync-control-center$" },
    blur = true,
    ignore_alpha = 0.02,
})

hl.layer_rule({
    name = "blur-swaync-notif",
    match = { namespace = "^swaync-notification-window$" },
    blur = true,
    ignore_alpha = 0.02,
})

hl.layer_rule({
    name = "blur-rofi",
    match = { namespace = "^rofi$" },
    blur = true,
    ignore_alpha = 0.02,
})

hl.layer_rule({
    name = "blur-pulsar",
    match = { namespace = "^pulsar$" },
    blur = true,
    ignore_alpha = 0.02,
})

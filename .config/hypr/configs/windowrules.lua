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
    name = "blur-rofi",
    match = { namespace = "^rofi$" },
    animation = "popin 92%",
    no_anim = false,
    blur = true,
    ignore_alpha = 0.02,
})

hl.layer_rule({
    name = "blur-quickshell-controls",
    match = { namespace = "^qs-(bar|calendar|control-center|osd|notifications|personalize|commands|power|monitors|workspace-overview)$" },
    blur = true,
    ignore_alpha = 0.02,
})

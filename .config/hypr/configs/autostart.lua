---@module 'hl'

hl.on("hyprland.start", function()
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("sleep 1 && awww img \"$(cat " .. os.getenv("HOME") .. "/.config/hypr/.current_wallpaper)\"")
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1 &")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("qs -c control-center --no-duplicate --daemonize")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_SESSION_ID XDG_CURRENT_DESKTOP && systemctl --user restart rice-lock-bridge.service")
end)

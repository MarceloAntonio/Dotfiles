---@module 'hl'

hl.on("hyprland.start", function()
    hl.exec_cmd("waybar &")
    hl.exec_cmd("nm-applet --indicator &")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("sleep 1 && awww img \"$(cat " .. os.getenv("HOME") .. "/.config/hypr/.current_wallpaper 2>/dev/null || echo " .. os.getenv("HOME") .. "/Pictures/Wallpaper/wallpaper_16.png)\"")
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1 &")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("pulsar daemon")
end)

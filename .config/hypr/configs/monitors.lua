---@module 'hl'

hl.monitor({
    output   = "eDP-1",
    mode     = "1920x1080@60.00",
    position = "0x0",
    scale    = 1,
})

hl.monitor({
    output   = "HDMI-A-1",
    mode     = "1920x1080@144.00",
    position = "1920x0",
    scale    = 1,
})
hl.monitor({ output = '', mode = 'preferred', position = 'auto', scale = 1 })
for i = 1, 5 do
    hl.workspace_rule({
        workspace = i,
        monitor = "HDMI-A-1",
        default = (i == 1)
    })
end

for i = 6, 10 do
    hl.workspace_rule({
        workspace = i,
        monitor = "eDP-1",
        default = (i == 6)
    })
end

-- Optional layout saved by the Quickshell monitor configurator.
local managed = os.getenv("HOME") .. "/.config/hypr/configs/monitors-managed.lua"
local managed_file = io.open(managed, "r")
if managed_file then
    managed_file:close()
    dofile(managed)
end

# Monitor configurator backend

[Português](README.md) · **English**

This backend uses `hyprctl eval` with `hl.monitor()` from the installed Hyprland Lua.
The QML must run processes with an argument list, without a shell.

## JSON contract

- `python backend.py catalog`: `{ok:true, monitors:[...], primary, pending}`.
  Each monitor keeps the fields from `hyprctl -j monitors all` and adds:
  `label`, `mode` (`1920x1080@144.00`), `availableModes` (strings without `Hz`),
  `modes` (`[{id,width,height,refreshRate,label}]`) and `primary` as a boolean.
  `pending` is `null` or `{token,deadline,expiresAt,secondsLeft}`.
- `python backend.py validate JSON`: validates and normalizes without applying.
- `python backend.py apply JSON`: receives `{monitors:[{name,mode,x,y,scale,
  transform?,disabled?}],primary}`. Include all connected monitors.
  Returns `{ok:true,token,deadline,expiresAt,seconds:20,message}`.
- `python backend.py confirm TOKEN`: persists and confirms the preview.
- `python backend.py revert TOKEN`: restores the previous configuration.
- Errors return `{ok:false,message}` and exit code 1.

`deadline` and `expiresAt` are Unix seconds. The UI clock is only visual;
the revert is executed by an independent process, even if the QML closes.
A token is only valid for its own transaction. Do not disarm the watchdog in QML.
When the UI reopens, restore the pending confirmation from the catalog.

## Persistence and integration

Add to the END of `~/.config/hypr/configs/monitors.lua`, after the current rules:

```lua
local monitor_config = os.getenv("HOME") .. "/.config/hypr/configs/monitors-managed.lua"
local monitor_file = io.open(monitor_config, "r")
if monitor_file then
    monitor_file:close()
    dofile(monitor_config)
end
```

The backend only creates this file after confirmation. It stores the
`hl.monitor()` calls and the `cursor.default_monitor` option. The primary
preference is also saved in `~/.local/state/quickshell-monitors/layout.json`. This
represents the cursor's starting screen and the rice's preference, not a global
"primary" attribute of the Wayland protocol. It does not change the current focus
or assign workspaces to other monitors.

A preview never writes the permanent configuration. If applying fails, the backend
tries to restore immediately and keeps the watchdog if needed.
Operations are serialized by flock. Modes must belong to the monitor, coordinates and
scales must be finite, connector names cannot contain code, and overlapping screens
or a layout with no active output are rejected.

## Validation performed

- Catalog of the real screens and their available modes, read without changing them.
- Generated Lua syntax validated in a function that is not invoked in Hyprland.
- Six isolated tests cover validation, watchdog before apply, revert, wrong token,
  expired confirmation and persistence failure.

`python test_backend.py` does not call Hyprland and does not change the real screens.
Real mode/position changes and rollback with the compositor require interactive
testing; they were not run during implementation so as not to interrupt the user.

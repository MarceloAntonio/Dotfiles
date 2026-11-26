# Architecture and diagnostics

[Português](arquitetura.md) · **English**

## Processes

The `control-center` Quickshell configuration runs the bar, control center, calendar, player, notifications, customization and monitors. It is started by Hyprland's autostart and supports QML reloading.

The `session-lock` configuration runs in **a separate process**, started by `rice-lock` only when needed. It disables automatic reloading so that changes to the rice do not interfere with the lock.

`rice-lock-bridge.service` follows the lock signals and the suspend preparation signals from logind. The Python helpers handle palette generation, customization application, Bluetooth pairing and the monitor configurator transactions.

## Integrations

| Function | Service or protocol |
| --- | --- |
| Windows and workspaces | Hyprland IPC |
| Audio and per-application volume | PipeWire |
| Player | MPRIS |
| Battery and power profiles | UPower / power-profiles-daemon |
| Wi-Fi and connections | NetworkManager |
| Bluetooth | BlueZ, with a confirmation agent |
| Notifications | Quickshell's `org.freedesktop.Notifications` server |
| Lock | `ext-session-lock-v1` and PAM |
| Wallpaper | awww |

Rofi remains the application and clipboard selector. Waybar, SwayNC and Pulsar are no longer started by the rice. The D-Bus activation of notifications points to Quickshell; there should not be two servers competing for the same name.

## File organization

| Path | Contents |
| --- | --- |
| `.config/quickshell/control-center/` | Shell, services and shared components |
| `control-center/bar/` | Bar, calendar, commands and workspace view |
| `control-center/bar/motion/` | Persistent items and sliding highlight |
| `control-center/personalize/` | Gallery and customization backend |
| `control-center/monitors/` | Layout editor and revert watchdog |
| `control-center/widgets/` | Tooltips and scrollbars |
| `.config/quickshell/session-lock/` | Locker, preview and logind integration |
| `.config/hypr/configs/` | Lua configuration, shortcuts, rules and autostart |
| `.local/bin/` | `rice-lock` and `rice-monitors` |
| `.config/systemd/user/` | Locker integration service |

## Local state

Preferences, images and runtime state are specific to each installation and should not be copied from the author's computer:

| Path in the user's home | Use |
| --- | --- |
| `~/.config/hypr/.current_wallpaper` | Selected wallpaper |
| `~/.local/state/quickshell-theme.json` | Theme and extracted color |
| `~/.config/kitty/Adaptativo.conf` | Generated terminal palette |
| `~/.config/rofi/themes/shell-palette.rasi` | Shared Rofi palette |
| `~/.config/hypr/configs/monitors-managed.lua` | Confirmed monitor layout |
| `~/.local/state/quickshell-monitors/layout.json` | Monitor preference |
| `$XDG_RUNTIME_DIR/quickshell-monitors/` | Temporary preview transaction |
| `~/.cache/quickshell-lock/` | Pre-blurred locker wallpapers |
| `~/.local/state/quickshell-lock/last.log` | Log of the last locker opening |

The installer prepares the state needed for the target user. Do not version caches, pending transactions, passwords or paths to personal images.

## Diagnostics

```sh
qs -c control-center log -t 50
qs -c control-center ipc call control status
qs -c control-center ipc call bar status
qs -c control-center ipc call calendar status
qs -c control-center ipc call personalize status
qs -c control-center ipc call monitors status
qs -c control-center ipc call theme status
hyprctl configerrors
systemctl --user status rice-lock-bridge.service
rice-lock --status
```

If the bar is not running, start it with:

```sh
qs -c control-center --no-duplicate --daemonize
```

Restarting this process clears the notification history. Reloading QML files does not restart the separate locker process.

## Lock and suspend

The controller releases the lock only after `PamResult.Success`. The password is never passed on the command line, in a file or in a log. The policy used is `/etc/pam.d/hyprlock`; password rules and attempt limits remain the responsibility of the system's PAM. The IPC exposes the state, without offering an unlock command.

The compositor covers all monitors through the session lock protocol. If the client dies, the session stays locked. Do not kill the process while locked; a failure in this situation requires recovery through the session/compositor or a TTY. The launcher tries Hyprlock when the process exits with an error, but this does not guarantee recovery of a lock that has already been acquired.

The logind bridge keeps a delay inhibitor while it waits for the lock. External suspend requests are still subject to logind's wait limit. From the menu, `rice-lock --suspend` cancels the suspend if it does not confirm `secure=true`.

## Validation

The checks done during development included QML reloading, the visual preview, lock configuration with `locked=false`, panel navigation and isolated tests of the monitor backend. The monitor tests do not change the real outputs:

```sh
python .config/quickshell/control-center/monitors/test_backend.py
```

Real authentication, locking during hotplug, suspend/resume and video mode changes must be verified interactively on the target hardware. The installer should not be run just to test syntax or file generation.

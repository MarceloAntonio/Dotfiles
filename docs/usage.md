# Interface usage

[Português](uso.md) · **English**

## Bar and control center

The control center opens with `Super + C` or from the gear icon. The volume, network, Bluetooth and battery buttons open the matching section; the highlight follows the selected button. `Esc`, the close button or a click outside closes the panel.

In **Sound**, select the audio output or input. Applications that play audio appear with their own volume and mute. The mouse wheel over the bar's volume adjusts in 5% steps; the volume and brightness keys show an OSD without capturing focus.

Brightness controls the notebook's internal screen. Personal Wi-Fi can be connected from the panel; enterprise networks, VPNs and IP settings are in the NetworkManager advanced editor. Bluetooth asks for PIN/code confirmation when needed.

The power button opens a compact menu with lock, suspend, restart, shut down and log out. Session actions ask for confirmation. The **Power** tab keeps the battery information and the power profiles available on the system.

## Workspaces and applications

The highlight slides between the active workspace or application. Click an application icon to activate it; middle-click closes the window.

Right-click the workspace numbers to open the overview. It shows **representations of the window layout**, with icons and titles, without capturing content. Click a preview or use the arrow keys and `Enter` to switch; `Esc` closes it.

The example layout reserves workspaces 1–5 for HDMI and 6–10 for the notebook. Output names and these rules are in `.config/hypr/configs/monitors.lua`; adapt them to your hardware. With only one screen, the bar can show the existing workspaces from 1 to 10.

## Calendar and player

Click the clock to open the calendar on the same screen. Arrow keys move between days; `Page Up`/`Page Down` change the month and `Home` returns to today. The mouse wheel and the calendar buttons also change the month.

The music card uses the available MPRIS players. Click anywhere on the card to open the horizontal player; the playback buttons remain independent. The dedicated view shows cover art, artist, title, controls and bars with the real audio output level. They are not a frequency spectrum and may reflect other sounds played through that output.

The arrow returns to the calendar. `Esc` in the player also returns; in the calendar, it closes the panel. The audio monitor only runs while the dedicated view is open and something is playing.

## Notifications and commands

The bell inside the control center opens the history and the **Do not disturb** button. Clicking the body of a notification runs the main action offered by the application. Secondary actions and the dismiss button stay separate. The history belongs to the session: reloading the QML keeps it, but restarting the process clears it.

Left-click the distro icon to search the active Hyprland shortcuts. This menu shows the commands and their keys; it is not a terminal. Right-click the icon opens Rofi for applications.

## Themes and customization

Choose the theme in **General → Interface theme** or in **Customize**:

- **Light:** translucent light glass.
- **Dark:** cold charcoal glass, without light outlines.
- **Adaptive:** tinted glass and accents extracted from the wallpaper.

The choice applies to the bar, panels, calendar, notifications, commands, OSDs and Rofi. In the locker, the choice is read the next time it opens. The monitor configurator uses a more opaque background to keep the text readable.

### Language

Under **General → System language**, choose **Português** or **English**. The button runs `localectl set-locale` with `pt_BR.UTF-8` or `en_US.UTF-8`, asks for the password through Polkit, and reloads Hyprland. The control center, bar, notifications, locker and shortcut descriptions read `/etc/locale.conf` and switch language immediately. Other applications follow the new language after logging out and back in.

`Super + W` opens customization in the wallpaper category; the sidebar leads to the others. The categories are:

| Category | Source and effect |
| --- | --- |
| Wallpaper | Images in `~/Images/Wallpaper`, applied by awww |
| Login screen | Updates the background of the Astronaut theme, with Polkit authentication |
| Fastfetch | Images in `~/.config/fastfetch/icons` or the distro's automatic logo |
| Kitty | `.conf` themes in `~/.config/kitty` and the Adaptive option |

A click selects; **double-click**, `Enter` or Apply applies the choice. Use the arrow keys to navigate, `Tab` to switch areas, `Ctrl + F` to search and `Ctrl + R` to refresh. `Esc` clears the search or closes the selector.

Kitty's Adaptive option is independent of the interface theme. When selected, it generates the background, text, cursor, selections, tabs and the 16 ANSI colors from the wallpaper, and updates open Kitty windows. This way, the dots of the `colors` module in Fastfetch follow the terminal palette.

## Monitors

Open it under **General → Monitors**, with `Super + Shift + D`, from the Monitors application in Rofi, or by running `rice-monitors`.

Select a screen in the diagram and drag it to position it to the left, right, above or below the other one. Screens snap to the edges and cannot overlap. Use the selectors for resolution, refresh rate and scale. **Primary** sets the saved preference and the cursor's starting screen; it does not change the current focus or move workspaces.

**Test changes** applies a preview. Click **Keep** to save or **Revert** to restore. After 20 seconds without confirmation, an independent process reverts the layout, even if the interface closes. The editor does not offer mirroring or turning outputs off.

## Lock

`Super + L` and the Lock button start `rice-lock`. The screen shows the wallpaper, date, clock and battery. Click with the mouse or start typing to reveal the field; moving the mouse alone does not activate it. The empty field returns to rest after eight seconds without authentication or a pending error.

The screen shows no name or avatar. The field has no "Senha" label; error messages appear in a capsule with a readable background. Authentication is done by the system's PAM. When you interact with another monitor, the previous field is cleared. `Esc` clears the input and returns to rest, without unlocking.

To check the look without locking the session:

```sh
rice-lock --preview
```

The preview does not authenticate. In it, `Esc` closes the window. To check the real state, use `rice-lock --status`. The `rice-lock --suspend` command, used by the power menu, only requests suspend after confirming the lock in the compositor.

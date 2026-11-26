# Installation and migration

[Português](migracao.md) · **English**

## Expected environment

The installer targets Arch Linux with `pacman`, systemd and a Wayland session. The configuration uses Hyprland's Lua API, including `hl.monitor()` and `hyprctl eval`; old versions that accept only `.conf` configuration do not work with these files. Development was done with Hyprland 0.57.1 and Quickshell 0.3.2.

Dependencies include Quickshell and the Qt/Wayland modules, PipeWire and WirePlumber, NetworkManager, BlueZ, awww, Rofi, Kitty and the Python helpers with Pillow, D-Bus and GObject. The lock uses PAM and keeps Hyprlock as an alternative. The installer prints the list of packages it intends to install.

## Before installing

Clone the repository and review the plan without changing the machine:

```sh
git clone https://github.com/MarceloAntonio/Dotfiles.git
cd Dotfiles
./install.sh --dry-run
```

The `--dry-run` mode does not run `sudo`, install packages or copy files. To see all options:

```sh
./install.sh --help
```

The installation uses the network for packages and visual resources. Run it as a regular user:

```sh
./install.sh
```

Previous configurations that would be replaced are preserved in a timestamped directory inside `~/.local/state/dotfiles-backups/`. The script copies the configurations, the commands from `~/.local/bin`, application entries and service integration to the target user; it does not depend on the user being named like the author of the repository.

## Options

| Option | Effect |
| --- | --- |
| `--dry-run` | Shows the plan without applying it |
| `--skip-assets` | Skips the download/installation of external visual resources |
| `--skip-wallpapers` | Keeps the existing wallpaper collection |
| `--skip-nvim` | Does not pre-install the Neovim plugins |
| `--sddm` | Installs/configures the Astronaut SDDM theme |
| `--set-shell` | Sets Zsh as the default shell |

For example, to apply the configuration without downloading the visual resources, wallpapers and plugins again:

```sh
./install.sh --skip-assets --skip-wallpapers --skip-nvim
```

The installer no longer installs Waybar, SwayNC and Pulsar, but it does not remove packages you already had installed. An AUR helper is not needed for the default flow. The SDDM theme and the shell change are explicit options.

## Upgrading an old installation

The bar and the panels now belong to Quickshell. The customization shortcut is `Super + W`; `Super + T` was removed because it did the same thing. It opens the QML interface instead of the old Rofi selectors. Rofi remains for applications and the clipboard.

The lock now goes through the `rice-lock` command, which opens an independent Quickshell configuration and authenticates through the `hyprlock` PAM service. Hyprlock remains installed, with an alternative configuration available. The `rice-lock-bridge` service integrates lock and suspend requests with the logind session.

When the installation finishes, close and reopen the Hyprland session so the components start with the new environment variables. In a session that is already open, check that no old Waybar/Pulsar is still running and that SwayNC is not competing with Quickshell for `org.freedesktop.Notifications`. Stop only the legacy components you identify; do not terminate a locker while the session is locked.

## First use

1. Check `hyprctl configerrors` and open the control center with `Super + C`.
2. Choose Light, Dark or Adaptive in the General tab.
3. Open Monitors with `Super + Shift + D`, arrange the screens and test the configuration. It is only saved when you click **Keep**.
4. Open customization with `Super + W` to choose your wallpaper and Kitty theme. The author's personal photos or selections are not copied.
5. Check the locker with `rice-lock --preview`. This window is only a preview; the real lock uses `Super + L`.

The meaning of Primary in the editor is the rice's preference and the cursor's starting screen. Workspace rules and connector names are configured in `.config/hypr/configs/monitors.lua`; adjust the example profile to your hardware when needed.

Monitor changes are automatically reverted after 20 seconds without confirmation. The watchdog runs outside the interface; closing or reloading Quickshell does not cancel this protection.

## Returning to a previous configuration

Use the files from the backup directory created by the installation to restore the components you want. The copy preserves the paths relative to the user's directory. Compare the files before replacing preferences made after the installation.

If you go back to the old lock, also restore the shortcut, the autostart and the buttons that call `rice-lock`. Then disable the new bridge:

```sh
systemctl --user disable --now rice-lock-bridge.service
```

If you go back to another notification server, stop the `control-center` configuration, remove the Quickshell D-Bus activation and only then start the chosen server. Do not keep two competing notification servers.

## What was validated

The installer update is verified with syntax analysis, dry-run mode and checks of the files that would be installed. This does not replace a full installation on a target machine. The locker had its loading and visuals validated without taking over the session; real authentication, suspend/resume and hotplug during the lock still require interactive testing.

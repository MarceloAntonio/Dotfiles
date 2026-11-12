pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: theme
    property string mode: "light"
    readonly property bool dark: mode !== "light"
    readonly property bool adaptive: mode === "wallpaper"
    property color wallpaperAccent: "#b2c5e0"
    property color wallpaperTint: "#181e25"
    readonly property color accent: adaptive ? wallpaperAccent : "#ededed"
    function glass(color, alpha) { return Qt.rgba(color.r, color.g, color.b, alpha); }
    function receive(text) {
        try { const data = JSON.parse(text); mode = data.mode; wallpaperAccent = data.accent; wallpaperTint = data.tint; } catch(e) { console.warn("Tema: resposta inválida"); }
    }
    readonly property color background: adaptive ? glass(wallpaperTint, 0.33) : dark ? "#54121924" : "#0fffffff"
    readonly property color barBackground: adaptive ? glass(wallpaperTint, 0.33) : dark ? "#54121924" : "#0fffffff"
    readonly property color barHover: adaptive ? glass(wallpaperAccent, 0.22) : dark ? "#73303b4b" : "#24ffffff"
    readonly property color barHoverBorder: dark ? "transparent" : "#33ffffff"
    readonly property color barSelected: adaptive ? glass(wallpaperAccent, 0.30) : dark ? "#7049576b" : "#29ffffff"
    readonly property color barBorder: dark ? "transparent" : "#1affffff"
    readonly property color card: "#0effffff"
    readonly property color hover: adaptive ? glass(wallpaperAccent, 0.22) : dark ? "#73303b4b" : "#1cffffff"
    readonly property color selected: adaptive ? glass(wallpaperAccent, 0.30) : dark ? "#7049576b" : "#2affffff"
    readonly property color border: dark ? "transparent" : "#1affffff"
    readonly property color text: "#f5f5f5"
    readonly property color muted: "#99ffffff"
    readonly property color danger: "#ffb4ab"
    readonly property color tooltip: dark ? "#b8121924" : "#d04a5260"
    readonly property string font: "SF Pro Display"
    readonly property string icons: "JetBrainsMono Nerd Font Propo"
    function setMode(value) {
        if (!["light", "dark", "wallpaper"].includes(value)) return;
        mode = value;
        writer.exec(["python", Quickshell.shellDir + "/theme-mode.py", value]);
    }
    Process {
        id: reader
        running: true
        command: ["python", Quickshell.shellDir + "/theme-mode.py"]
        stdout: StdioCollector { onStreamFinished: theme.receive(text) }
    }
    Process { id: writer; stdout: StdioCollector { onStreamFinished: theme.receive(text) } }
    Process {
        id: kittyUpdater
        running: true
        command: ["python", Quickshell.shellDir + "/kitty_adaptive.py", "--refresh"]
    }
    FileView {
        path: Quickshell.env("HOME") + "/.config/hypr/.current_wallpaper"
        watchChanges: true
        onFileChanged: {
            if (theme.adaptive && !reader.running && !writer.running) reader.running = true;
            if (!kittyUpdater.running) kittyUpdater.running = true;
        }
    }
    IpcHandler {
        target: "theme"
        function set(mode: string): void { theme.setMode(mode); }
        function status(): string { return theme.mode; }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import ".." as Shell
import "../widgets" as Widgets

PanelWindow {
    id: panel
    required property string outputName
    readonly property bool opened: BarState.commandsOpened && BarState.commandsScreen === outputName
    property var entries: []
    readonly property var filteredEntries: opened ? entries.filter(b => (b.description + " " + panel.keys(b)).toLowerCase().includes(search.text.toLowerCase())) : []
    property real progress: opened ? 1 : 0
    visible: opened || progress > 0.001
    implicitWidth: Math.min(620, screen.width - 32)
    implicitHeight: Math.min(660, screen.height - 60)
    anchors { top: true; left: true }
    margins { top: 36; left: 16 }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "qs-commands"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    mask: Region { item: surface; radius: 14 }
    BackgroundEffect.blurRegion: Region { item: surface; radius: 14 }
    Behavior on progress { NumberAnimation { duration: 420; easing.type: Easing.InOutCubic } }
    IpcHandler {
        target: "commands-" + panel.outputName
        function open(output: string): void { BarState.closePanels(); BarState.commandsScreen = output; BarState.commandsOpened = true; }
        function close(): void { panel.close(); }
        function status(): string { return JSON.stringify({ output: panel.outputName, opened: panel.opened, entries: panel.entries.length }); }
    }
    function close() { BarState.commandsOpened = false; }
    function keys(b) {
        const mods = [[64,"Super"],[4,"Ctrl"],[8,"Alt"],[1,"Shift"]];
        return mods.filter(m => b.modmask & m[0]).map(m => m[1]).concat([b.key]).join(" + ");
    }
    onOpenedChanged: {
        if (opened) { reader.running = true; search.text = ""; focusTimer.restart(); }
        else grab.active = false;
    }
    Timer { id: focusTimer; interval: 100; onTriggered: { if (panel.opened) { grab.active = true; search.forceActiveFocus(); } } }
    HyprlandFocusGrab { id: grab; windows: [panel, BarState.bars[panel.outputName]].filter(w => w?.visible); onCleared: if (panel.opened && !focusTimer.running) panel.close() }
    Process {
        id: reader
        command: ["hyprctl", "-j", "binds"]
        stdout: StdioCollector { onStreamFinished: {
            try { panel.entries = JSON.parse(text).filter(b => b.description); } catch(e) { panel.entries = []; }
        } }
    }
    Rectangle {
        id: surface
        width: 38 + (panel.width - 38) * panel.progress
        height: panel.height * panel.progress
        radius: 14
        color: Shell.Theme.background
        border.color: Shell.Theme.dark ? "transparent" : (Shell.Theme.border)
        clip: true
        ColumnLayout {
            width: panel.width - 32
            height: panel.height - 32
            x: 16; y: 16
            opacity: Math.max(0, (panel.progress - 0.25) / 0.75)
            spacing: 14
            RowLayout {
                Shell.GlassText { text: "󰣇  " + Shell.Theme.tr("Comandos do Hyprland", "Hyprland commands"); font.pixelSize: 18; Layout.fillWidth: true }
                Shell.ActionButton { text: "×"; onClicked: panel.close(); tooltipText: Shell.Theme.tr("Fechar · Esc", "Close · Esc") }
            }
            TextField {
                id: search
                Layout.fillWidth: true
                placeholderText: Shell.Theme.tr("Buscar comando ou atalho…", "Search commands or shortcuts…")
                color: "white"
                placeholderTextColor: "#99ffffff"
                background: Rectangle { radius: 10; color: "#18ffffff"; border.color: Shell.Theme.dark ? "transparent" : ("#26ffffff")}
                Keys.onEscapePressed: panel.close()
                Keys.onDownPressed: { list.forceActiveFocus(); list.currentIndex = 0; }
            }
            ListView {
                id: list
                Layout.fillWidth: true; Layout.fillHeight: true
                clip: true
                spacing: 5
                model: panel.filteredEntries
                ScrollBar.vertical: Widgets.GlassScrollBar {}
                Keys.onEscapePressed: panel.close()
                Keys.onUpPressed: { if (currentIndex <= 0) search.forceActiveFocus(); else currentIndex--; }
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    width: list.width - 14; height: 48; radius: 10
                    color: list.activeFocus && list.currentIndex === index ? "#29ffffff" : hover.hovered ? "#20ffffff" : "#0cffffff"
                    HoverHandler { id: hover }
                    RowLayout {
                        anchors.fill: parent; anchors.margins: 12
                        Shell.GlassText { text: modelData.description; Layout.fillWidth: true; elide: Text.ElideRight }
                        Shell.GlassText { text: panel.keys(modelData); font.pixelSize: 11; color: "#bbffffff" }
                    }
                }
                Shell.GlassText { anchors.centerIn: parent; visible: list.count === 0; text: Shell.Theme.tr("Nenhum atalho encontrado", "No shortcuts found"); color: "#bbffffff" }
            }
            Shell.GlassText { text: Shell.Theme.tr("Atalhos ativos da sua configuração · Esc para fechar", "Active shortcuts from your config · Esc to close"); font.pixelSize: 11; color: "#99ffffff" }
        }
    }
}

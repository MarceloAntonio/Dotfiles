import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import ".." as Shell

PanelWindow {
    id: panel
    required property string outputName
    readonly property bool opened: BarState.overviewOpened && BarState.overviewScreen === outputName
    property real progress: opened ? 1 : 0
    visible: opened || progress > 0.001
    color: "transparent"
    implicitWidth: Math.min(920, screen.width - 40)
    implicitHeight: Math.min(620, screen.height - 80)
    anchors.top: true
    margins.top: 40
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "qs-workspace-overview"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    mask: Region { item: surface; radius: 18 }
    BackgroundEffect.blurRegion: Region { item: surface; radius: 18 }
    Behavior on progress { NumberAnimation { duration: 300; easing.type: Easing.InOutCubic } }
    function close() { BarState.overviewOpened = false; }
    function select(id) { close(); Hyprland.dispatch(Hyprland.usingLua ? "hl.dsp.focus({ workspace = " + id + " })" : "workspace " + id); }
    onOpenedChanged: { if (opened) focusDelay.restart(); else grab.active = false; }
    Timer { id: focusDelay; interval: 100; onTriggered: { if (panel.opened) { grab.active = true; grid.currentIndex = 0; grid.forceActiveFocus(); } } }
    HyprlandFocusGrab {
        id: grab
        windows: [panel, BarState.bars[panel.outputName]].filter(w => w?.visible)
        onCleared: if (panel.opened && !focusDelay.running) panel.close()
    }
    IpcHandler {
        target: "overview-" + panel.outputName
        function open(): void { BarState.closePanels(); BarState.overviewScreen = panel.outputName; BarState.overviewOpened = true; }
        function close(): void { panel.close(); }
    }
    Rectangle {
        id: surface
        anchors.fill: parent
        radius: 18
        color: Shell.Theme.background
        border.color: Shell.Theme.dark ? "transparent" : (Shell.Theme.border)
        opacity: panel.progress
        scale: 0.96 + 0.04 * panel.progress
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 20; spacing: 14
            RowLayout {
                Shell.GlassText { text: "Workspaces · " + panel.outputName; font.pixelSize: 18; Layout.fillWidth: true }
                Shell.ActionButton { text: "×"; onClicked: panel.close() }
            }
            GridView {
                id: grid
                Layout.fillWidth: true; Layout.fillHeight: true
                clip: true
                cellWidth: width / (width > 700 ? 3 : 2)
                cellHeight: 215
                model: panel.visible ? BarState.workspaceIds(panel.outputName) : []
                keyNavigationEnabled: true
                Keys.onEscapePressed: panel.close()
                Keys.onReturnPressed: panel.select(model[currentIndex])
                Keys.onEnterPressed: panel.select(model[currentIndex])
                delegate: Item {
                    id: preview
                    required property int modelData
                    required property int index
                    width: grid.cellWidth; height: grid.cellHeight
                    readonly property var windows: Hyprland.toplevels.values.filter(t => t.workspace?.id === modelData)
                    readonly property var monitor: BarState.monitor(panel.outputName)
                    Rectangle {
                        anchors.fill: parent; anchors.margins: 5
                        color: hover.hovered ? Shell.Theme.hover : Shell.Theme.card
                        border.color: Shell.Theme.dark ? "transparent" : (preview.monitor?.activeWorkspace?.id === preview.modelData || (grid.activeFocus && grid.currentIndex === preview.index) ? "#90ffffff" : Shell.Theme.border)
                        radius: 12
                        HoverHandler { id: hover }
                        TapHandler { onTapped: panel.select(preview.modelData) }
                        Shell.GlassText { x: 12; y: 10; text: "Workspace " + preview.modelData + " · " + preview.windows.length; font.pixelSize: 12 }
                        Item {
                            id: desktop
                            x: 10; y: 38; width: parent.width - 20; height: parent.height - 48
                            clip: true
                            Repeater {
                                model: preview.windows
                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property var clientGeometry: modelData.lastIpcObject
                                    readonly property real mw: preview.monitor?.width || 1920
                                    readonly property real mh: preview.monitor?.height || 1080
                                    x: Math.max(0, ((clientGeometry?.at?.[0] ?? 0) - (preview.monitor?.x ?? 0)) / mw * desktop.width)
                                    y: Math.max(0, ((clientGeometry?.at?.[1] ?? 0) - (preview.monitor?.y ?? 0)) / mh * desktop.height)
                                    width: Math.max(30, (clientGeometry?.size?.[0] ?? 800) / mw * desktop.width)
                                    height: Math.max(24, (clientGeometry?.size?.[1] ?? 600) / mh * desktop.height)
                                    radius: 5; color: Shell.Theme.selected; border.color: Shell.Theme.dark ? "transparent" : (Shell.Theme.border)
                                    clip: true
                                    Column {
                                        anchors.centerIn: parent; spacing: 3; width: parent.width - 8
                                        Image { anchors.horizontalCenter: parent.horizontalCenter; width: 22; height: 22; source: BarState.iconFor(modelData); asynchronous: true }
                                        Shell.GlassText { width: parent.width; text: modelData.title; font.pixelSize: 9; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight }
                                    }
                                }
                            }
                            Shell.GlassText { anchors.centerIn: parent; visible: preview.windows.length === 0; text: "Vazio"; color: Shell.Theme.muted }
                        }
                    }
                }
            }
            Shell.GlassText { text: "Clique para abrir · Setas e Enter para navegar · Esc para fechar"; color: Shell.Theme.muted; font.pixelSize: 11 }
        }
    }
}

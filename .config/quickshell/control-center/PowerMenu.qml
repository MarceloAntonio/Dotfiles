import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "bar" as DesktopBar

PanelWindow {
    id: panel
    required property string outputName
    readonly property bool opened: Service.powerOpened && Service.powerScreen === outputName
    property string confirmation: ""
    property real progress: opened ? 1 : 0
    visible: opened || progress > 0.001
    color: "transparent"
    implicitWidth: 350
    implicitHeight: confirmation ? 208 : 290
    anchors { top: true; right: true }
    margins { top: 35; right: 16 }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "qs-power"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    mask: Region { item: surface; radius: 16 }
    BackgroundEffect.blurRegion: Region { item: surface; radius: 16 }
    Behavior on progress { NumberAnimation { duration: 300; easing.type: Easing.InOutCubic } }
    Behavior on implicitHeight { NumberAnimation { duration: 220; easing.type: Easing.InOutCubic } }
    IpcHandler {
        target: "power-" + panel.outputName
        function status(): string { return JSON.stringify({ opened: panel.opened, presented: panel.visible, progress: panel.progress }); }
    }
    function close() { Service.powerOpened = false; }
    onOpenedChanged: { if (opened) { confirmation = ""; focusDelay.restart(); } else grab.active = false; }
    Timer { id: focusDelay; interval: 100; onTriggered: if (panel.opened) { grab.active = true; keys.forceActiveFocus(); } }
    HyprlandFocusGrab {
        id: grab
        windows: [panel, DesktopBar.BarState.bars[panel.outputName]].filter(w => w?.visible)
        onCleared: if (panel.opened && !focusDelay.running) panel.close()
    }
    Rectangle {
        id: surface
        anchors.fill: parent
        radius: 16
        color: Theme.background
        border.color: Theme.border
        opacity: panel.progress
        transformOrigin: Item.TopRight
        scale: 0.93 + 0.07 * panel.progress
        FocusScope {
            id: keys
            anchors.fill: parent
            Keys.onEscapePressed: { if (panel.confirmation) panel.confirmation = ""; else panel.close(); }
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 18; spacing: 10
                RowLayout {
                    GlassText { text: panel.confirmation ? "Confirmar ação" : "Energia e sessão"; font.pixelSize: 17; Layout.fillWidth: true }
                    ActionButton { text: "×"; onClicked: panel.close() }
                }
                GridLayout {
                    visible: !panel.confirmation
                    Layout.fillWidth: true; Layout.fillHeight: true
                    columns: 2; columnSpacing: 8; rowSpacing: 8
                    Repeater {
                        model: [{label:"󰌾  Bloquear",action:"bloquear"},{label:"󰒲  Suspender",action:"suspender"},{label:"󰜉  Reiniciar",action:"reiniciar"},{label:"󰐥  Desligar",action:"desligar"}]
                        delegate: ActionButton {
                            required property var modelData
                            Layout.fillWidth: true; Layout.fillHeight: true
                            text: modelData.label
                            onClicked: {
                                if (modelData.action === "bloquear") { panel.close(); Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/rice-lock"]); }
                                else panel.confirmation = modelData.action;
                            }
                        }
                    }
                }
                ActionButton { visible: !panel.confirmation; Layout.fillWidth: true; text: "󰗼  Sair da sessão"; onClicked: panel.confirmation = "sair" }
                GlassText { visible: !!panel.confirmation; Layout.fillWidth: true; text: "Deseja " + panel.confirmation + "?"; font.pixelSize: 18 }
                Item { visible: !!panel.confirmation; Layout.fillHeight: true }
                RowLayout {
                    visible: !!panel.confirmation; Layout.fillWidth: true
                    ActionButton { Layout.fillWidth: true; text: "Cancelar"; onClicked: panel.confirmation = "" }
                    ActionButton { Layout.fillWidth: true; text: "Confirmar"; selected: true; onClicked: { const action = panel.confirmation; panel.close(); Service.executePower(action); } }
                }
            }
        }
    }
}

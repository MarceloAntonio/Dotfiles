import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: osd
    required property string outputName
    readonly property bool microphone: Service.osdKind === "mic"
    readonly property bool brightness: Service.osdKind === "brightness"
    readonly property bool muted: !brightness && (microphone ? Service.source?.audio?.muted ?? false : Service.sink?.audio?.muted ?? false)
    readonly property real level: brightness ? Service.brightness : microphone ? Service.micVolume : Service.volume
    visible: Service.osdVisible && Service.osdScreen === outputName
    implicitWidth: 300
    implicitHeight: 80
    anchors.bottom: true
    margins.bottom: 70
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    mask: Region {}
    WlrLayershell.namespace: "qs-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    BackgroundEffect.blurRegion: Region { item: surface; radius: 16 }
    onVisibleChanged: if (visible) entrance.restart()
    ParallelAnimation {
        id: entrance
        NumberAnimation { target: surface; property: "opacity"; from: 0; to: 1; duration: 120 }
        NumberAnimation { target: slide; property: "y"; from: 8; to: 0; duration: 150; easing.type: Easing.OutCubic }
    }
    Rectangle {
        id: surface
        anchors.fill: parent
        anchors.margins: 3
        radius: 16
        color: Theme.background
        border.color: Theme.dark ? "transparent" : ("#28ffffff")
        transform: Translate { id: slide }
        RowLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 16
            GlassText {
                text: osd.brightness ? "󰃠" : osd.microphone ? (osd.muted ? "󰍭" : "󰍬") : osd.muted ? "󰝟" : "󰕾"
                font.family: Theme.icons
                font.pixelSize: 26
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10
                RowLayout {
                    Layout.fillWidth: true
                    GlassText { Layout.fillWidth: true; text: osd.brightness ? "Brilho" : osd.microphone ? "Microfone" : "Volume"; font.pixelSize: 12 }
                    GlassText { text: osd.muted ? "Mudo" : Math.round(osd.level) + "%"; color: Theme.muted; font.pixelSize: 12 }
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 5
                    radius: 3
                    color: "#25ffffff"
                    Rectangle {
                        width: parent.width * (osd.muted ? 0 : Math.max(0, Math.min(1, osd.level / 100)))
                        height: parent.height
                        radius: 3
                        color: Theme.accent
                        Behavior on width { NumberAnimation { duration: 100 } }
                    }
                }
            }
        }
    }
}

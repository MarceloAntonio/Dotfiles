import QtQuick

ActionButton {
    id: button
    property real feedback: 1
    readonly property bool playing: Service.player?.isPlaying ?? false
    text: playing ? "󰏤" : "󰐊"
    font.family: Theme.icons
    enabled: Service.player?.canTogglePlaying ?? false
    tooltipText: playing ? "Pausar" : "Reproduzir"
    scale: (down ? 0.89 : 1) * feedback
    Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
    onClicked: { pulse.restart(); Service.player.togglePlaying(); }
    SequentialAnimation {
        id: pulse
        NumberAnimation { target: button; property: "feedback"; to: 1.055; duration: 100; easing.type: Easing.OutCubic }
        NumberAnimation { target: button; property: "feedback"; to: 1; duration: 220; easing.type: Easing.OutCubic }
    }
    contentItem: Item {
        implicitWidth: button.font.pixelSize
        implicitHeight: button.font.pixelSize
        GlassText {
            anchors.centerIn: parent
            text: "󰐊"; font: button.font
            opacity: button.playing ? 0 : 1
            scale: button.playing ? 0.75 : 1
            Behavior on opacity { NumberAnimation { duration: 200 } }
            Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        }
        GlassText {
            anchors.centerIn: parent
            text: "󰏤"; font: button.font
            opacity: button.playing ? 1 : 0
            scale: button.playing ? 1 : 0.75
            Behavior on opacity { NumberAnimation { duration: 200 } }
            Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        }
    }
}

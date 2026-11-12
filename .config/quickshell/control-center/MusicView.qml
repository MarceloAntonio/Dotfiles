import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

Item {
    id: view
    signal back()
    property var levels: Array(32).fill(0)
    PwNodePeakMonitor {
        id: meter
        node: Service.sink
        enabled: view.visible && (Service.player?.isPlaying ?? false)
    }
    Timer {
        interval: 50
        repeat: true
        running: meter.enabled
        onTriggered: view.levels = view.levels.slice(1).concat([Math.min(1, Math.sqrt(Math.max(0, meter.peak)))])
    }
    Connections {
        target: Service.player
        function onIsPlayingChanged() { if (!Service.player?.isPlaying) view.levels = Array(32).fill(0); }
    }
    ColumnLayout {
        anchors.fill: parent
        spacing: 14
        RowLayout {
            Layout.fillWidth: true
            ActionButton { text: "‹"; font.pixelSize: 25; implicitWidth: 36; onClicked: view.back(); Accessible.name: "Voltar" }
            Item { Layout.fillWidth: true }
            GlassText { text: Service.player?.identity || "Música"; color: Theme.muted; font.pixelSize: 12 }
        }
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 24
        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: Math.min(200, view.width * 0.36)
            Layout.preferredHeight: Layout.preferredWidth
            radius: 18
            color: Theme.card
            clip: true
            GlassText { anchors.centerIn: parent; text: "󰎆"; font.family: Theme.icons; font.pixelSize: 70; color: Theme.muted }
            Image { anchors.fill: parent; source: Service.player?.trackArtUrl ?? ""; asynchronous: true; fillMode: Image.PreserveAspectCrop; visible: status === Image.Ready; sourceSize.width: 520; sourceSize.height: 520 }
        }
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 12
        GlassText { Layout.fillWidth: true; text: Service.player?.trackTitle || "Nada tocando"; font.pixelSize: 20; font.weight: Font.DemiBold; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight }
        GlassText { Layout.fillWidth: true; text: Service.player?.trackArtist || "Abra seu player para começar"; color: Theme.muted; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight }
        Row {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 56
            spacing: 2
            Repeater {
                model: 32
                Rectangle {
                    required property int index
                    width: Math.max(2, (view.width * 0.5 - 64) / 32); radius: 2
                    height: 3 + 49 * (view.levels[index] || 0)
                    y: (56 - height) / 2
                    color: Theme.accent
                    opacity: 0.45 + 0.55 * (view.levels[index] || 0)
                    Behavior on height { NumberAnimation { duration: meter.enabled ? 90 : 320; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 240 } }
                }
            }
        }
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 18
            ActionButton { text: "󰒮"; font.family: Theme.icons; font.pixelSize: 24; enabled: Service.player?.canGoPrevious ?? false; onClicked: Service.player.previous(); tooltipText: "Anterior" }
            PlaybackButton { font.pixelSize: 30; implicitWidth: 64; implicitHeight: 54; selected: true }
            ActionButton { text: "󰒭"; font.family: Theme.icons; font.pixelSize: 24; enabled: Service.player?.canGoNext ?? false; onClicked: Service.player.next(); tooltipText: "Próxima" }
        }
        }
        }
    }
}

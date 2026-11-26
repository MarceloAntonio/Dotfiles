import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Card {
    signal openRequested()
    id: mediaCard
    implicitHeight: 124
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: mediaCard.openRequested()
    }
    RowLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 14
        Rectangle {
            Layout.preferredWidth: 80
            Layout.preferredHeight: 80
            radius: 10
            color: Theme.hover
            clip: true
            GlassText {
                anchors.centerIn: parent
                font.family: Theme.icons
                font.pixelSize: 28
                color: Theme.muted
                text: "󰎆"
            }
            Image {
                anchors.fill: parent
                source: Service.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            GlassText {
                Layout.fillWidth: true
                text: Service.player?.trackTitle || Theme.tr("Nada tocando", "Nothing playing")
                    font.weight: Font.DemiBold
            }
            GlassText {
                Layout.fillWidth: true
                text: Service.player ? (Service.player.trackArtist || Service.player.identity) : Theme.tr("Abra seu player para começar", "Open a player to get started")
                font.pixelSize: 12
                color: Theme.muted
            }
            RowLayout {
                spacing: 6
                ActionButton {
                    text: "󰒮"; font.family: Theme.icons
                    enabled: Service.player?.canGoPrevious ?? false
                    onClicked: Service.player.previous()
                    tooltipText: Theme.tr("Anterior", "Previous")
                }
                PlaybackButton {}
                ActionButton {
                    text: "󰒭"; font.family: Theme.icons
                    enabled: Service.player?.canGoNext ?? false
                    onClicked: Service.player.next()
                    tooltipText: Theme.tr("Próxima", "Next")
                }
            }
        }
    }
}

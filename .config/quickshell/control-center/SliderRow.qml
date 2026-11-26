import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    property string title
    property string icon
    property real value: 0
    property bool muted: false
    property bool canMute: false
    signal moved(real value)
    signal muteClicked()
    spacing: 2
    RowLayout {
        Layout.fillWidth: true
        ActionButton {
            text: root.icon
            font.family: Theme.icons
            font.pixelSize: 18
            enabled: root.canMute
            tooltipText: root.muted ? Theme.tr("Ativar ", "Unmute ") + root.title.toLowerCase() : Theme.tr("Silenciar ", "Mute ") + root.title.toLowerCase()
            onClicked: root.muteClicked()
        }
        GlassText { text: root.title; Layout.fillWidth: true }
        GlassText {
            text: root.muted ? Theme.tr("Mudo", "Muted") : Math.round(root.value) + "%"
            color: Theme.muted
            font.pixelSize: 12
        }
    }
    GlassSlider {
        Layout.fillWidth: true
        enabled: root.enabled
        value: root.value
        onMoved: root.moved(value)
        Accessible.name: root.title
    }
}

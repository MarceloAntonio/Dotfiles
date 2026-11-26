import QtQuick
import QtQuick.Layouts

ColumnLayout {
    spacing: 12
    RowLayout {
        Layout.fillWidth: true
        GlassText { Layout.fillWidth: true; text: Theme.tr("Notificações", "Notifications"); font.pixelSize: 18; font.weight: Font.DemiBold }
        ActionButton {
            text: Theme.tr("Limpar", "Clear")
            enabled: Notifications.count > 0
            onClicked: Notifications.clear()
        }
    }
    ActionButton {
        Layout.fillWidth: true
        text: Theme.tr("Não perturbe  ·  ", "Do Not Disturb  ·  ") + (Notifications.dnd ? Theme.tr("Ativado", "On") : Theme.tr("Desativado", "Off"))
        selected: Notifications.dnd
        onClicked: Notifications.dnd = !Notifications.dnd
    }
    Card {
        Layout.fillWidth: true
        visible: Notifications.count === 0
        implicitHeight: 130
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 10
            GlassText { Layout.alignment: Qt.AlignHCenter; text: "󰂜"; font.family: Theme.icons; font.pixelSize: 30; color: Theme.muted }
            GlassText { text: Theme.tr("Nenhuma notificação por aqui", "No notifications here"); color: Theme.muted }
        }
    }
    Repeater {
        model: Notifications.items
        delegate: NotificationCard {
            required property var modelData
            Layout.fillWidth: true
            notification: modelData
        }
    }
}

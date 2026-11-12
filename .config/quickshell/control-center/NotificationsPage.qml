import QtQuick
import QtQuick.Layouts

ColumnLayout {
    spacing: 12
    RowLayout {
        Layout.fillWidth: true
        GlassText { Layout.fillWidth: true; text: "Notificações"; font.pixelSize: 18; font.weight: Font.DemiBold }
        ActionButton {
            text: "Limpar"
            enabled: Notifications.count > 0
            onClicked: Notifications.clear()
        }
    }
    ActionButton {
        Layout.fillWidth: true
        text: "Não perturbe  ·  " + (Notifications.dnd ? "Ativado" : "Desativado")
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
            GlassText { text: "Nenhuma notificação por aqui"; color: Theme.muted }
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

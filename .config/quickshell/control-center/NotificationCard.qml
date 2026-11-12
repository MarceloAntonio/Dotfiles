pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell

Card {
    id: card
    required property var notification
    property bool popup: false
    readonly property var primary: Notifications.primaryAction(notification)
    readonly property var secondaryActions: notification.actions.filter(action => action !== primary)
    readonly property bool actionable: !!primary || !!Notifications.applicationWindow(notification) || !!Notifications.applicationEntry(notification)
    activeFocusOnTab: actionable
    Keys.onReturnPressed: Notifications.activate(notification, popup)
    Keys.onSpacePressed: Notifications.activate(notification, popup)
    Accessible.role: Accessible.Button
    Accessible.name: notification.summary
    Accessible.onPressAction: Notifications.activate(notification, popup)
    function iconSource(icon) {
        if (!icon) return "";
        if (icon.startsWith("/")) return "file://" + icon;
        if (icon.startsWith("image://icon/")) return Quickshell.hasThemeIcon(decodeURIComponent(icon.slice(13).split("?")[0])) ? icon : "";
        if (icon.includes(":")) return icon;
        return Quickshell.hasThemeIcon(icon) ? Quickshell.iconPath(icon) : "";
    }
    function attachmentSource() {
        const hints = notification.hints;
        const path = String(hints["image-path"] || hints["image_path"] || "");
        const hasImage = hints["image-data"] || hints["image_data"] || hints["icon_data"]
            || path.startsWith("/") || path.startsWith("file:") || path.startsWith("https:");
        return hasImage ? notification.image : "";
    }
    signal openHistory()
    implicitHeight: content.implicitHeight + 28
    color: bodyClick.containsMouse && actionable ? Qt.tint(popup ? Theme.background : Theme.card, "#0affffff") : popup ? Theme.background : Theme.card
    Behavior on color { ColorAnimation { duration: 150 } }
    MouseArea {
        id: bodyClick
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: card.actionable || card.popup ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: Notifications.activate(card.notification, card.popup)
    }
    ColumnLayout {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
        spacing: 10
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Item {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                GlassText {
                    anchors.centerIn: parent
                    text: "󰂚"
                    font.family: Theme.icons
                    font.pixelSize: 20
                    color: Theme.muted
                    visible: !appIcon.source.toString() || appIcon.status !== Image.Ready
                }
                Image {
                    id: appIcon
                    anchors.fill: parent
                    source: card.iconSource(card.notification.appIcon)
                    asynchronous: true
                    fillMode: Image.PreserveAspectFit
                }
            }
            GlassText {
                Layout.fillWidth: true
                text: card.notification.appName || "Notificação"
                font.pixelSize: 12
                color: Theme.muted
            }
            ActionButton {
                text: "×"
                implicitHeight: 26
                implicitWidth: 28
                onClicked: Notifications.dismiss(card.notification)
                tooltipText: "Dispensar"
            }
        }
        GlassText {
            Layout.fillWidth: true
            text: card.notification.summary
            font.weight: Font.DemiBold
            wrapMode: Text.Wrap
            maximumLineCount: card.popup ? 3 : 8
        }
        GlassText {
            Layout.fillWidth: true
            visible: text.length > 0
            text: card.notification.body
            font.pixelSize: 13
            color: Theme.muted
            wrapMode: Text.Wrap
            maximumLineCount: card.popup ? 4 : 24
        }
        Image {
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            source: card.attachmentSource()
            asynchronous: true
            visible: status === Image.Ready
            fillMode: Image.PreserveAspectFit
        }
        Flow {
            visible: card.secondaryActions.length > 0
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: card.secondaryActions
                delegate: ActionButton {
                    required property var modelData
                    width: Math.min(implicitWidth, content.width)
                    text: modelData.text || "Abrir"
                    onClicked: Notifications.invoke(card.notification, modelData)
                }
            }
        }
        ActionButton {
            visible: card.popup
            Layout.fillWidth: true
            text: "Ver notificações"
            onClicked: { Service.open("notificacoes"); card.openHistory(); }
        }
    }
}

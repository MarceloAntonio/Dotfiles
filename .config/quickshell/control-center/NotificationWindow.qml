pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

PanelWindow {
    id: window
    required property string outputName
    visible: Notifications.popups.length > 0 && Notifications.popupScreen === outputName && !Service.opened
    color: "transparent"
    implicitWidth: 420
    implicitHeight: Math.min(screen.height - 80, stack.implicitHeight + 6)
    anchors { top: true; right: true }
    margins { top: 46; right: 12 }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "qs-notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    BackgroundEffect.blurRegion: Region { item: stack }
    ColumnLayout {
        id: stack
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 3 }
        spacing: 10
        Repeater {
            model: Notifications.popups
            delegate: NotificationCard {
                id: popup
                required property var modelData
                Layout.fillWidth: true
                notification: modelData
                popup: true
                readonly property int timeout: modelData.expireTimeout >= 0 ? modelData.expireTimeout : modelData.urgency === NotificationUrgency.Critical ? 0 : 8000
                Timer {
                    interval: Math.max(1, popup.timeout)
                    running: popup.timeout > 0 && window.visible
                    onTriggered: Notifications.hidePopup(popup.modelData)
                }
            }
        }
    }
}

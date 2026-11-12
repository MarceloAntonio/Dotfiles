import QtQuick
import QtQuick.Controls
import Quickshell
import ".." as Shell

Button {
    id: control
    property bool selected: false
    property string tooltipText: ""
    property bool scrollable: false
    property color textColor: "#ffffff"
    property bool tipReady: false
    property string glyph: ""
    property int glyphSize: 13
    property bool highlightHover: true
    property bool urgent: false
    property real alertLevel: 0
    signal rightClicked()
    signal middleClicked()
    signal scrolled(real delta)
    focusPolicy: Qt.NoFocus
    hoverEnabled: true
    implicitHeight: 24
    implicitWidth: Math.max(26, contentItem.implicitWidth + 16)
    padding: 0
    horizontalPadding: 8
    font.family: Shell.Theme.font
    font.pixelSize: 13
    font.weight: Font.DemiBold
    opacity: enabled ? 1 : 0.4
    background: Rectangle {
        radius: 9
        color: control.urgent ? Qt.rgba(1, 1, 1, 0.06 + 0.22 * control.alertLevel) : control.selected ? Shell.Theme.barSelected : control.highlightHover && (control.down || control.hovered) ? Shell.Theme.barHover : "transparent"
        Behavior on color { enabled: !control.urgent; ColorAnimation { duration: 250; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1] } }
    }
    SequentialAnimation on alertLevel {
        running: control.urgent
        loops: Animation.Infinite
        NumberAnimation { to: 1; duration: 800; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0; duration: 800; easing.type: Easing.InOutSine }
    }
    contentItem: Item {
        implicitWidth: glyphText.implicitWidth + label.implicitWidth + (glyphText.visible && label.visible ? 3.2 : 0)
        implicitHeight: Math.max(glyphText.implicitHeight, label.implicitHeight)
        Row {
            anchors.centerIn: parent
            spacing: glyphText.visible && label.visible ? 3.2 : 0
            Shell.GlassText {
                id: glyphText
                visible: control.glyph.length > 0
                text: control.glyph
                font.family: Shell.Theme.icons
                font.pixelSize: control.glyphSize
                font.weight: Font.DemiBold
                renderType: Text.NativeRendering
                color: control.textColor
                anchors.verticalCenter: parent.verticalCenter
            }
            Shell.GlassText {
                id: label
                visible: control.text.length > 0
                text: control.text
                font: control.font
                renderType: Text.NativeRendering
                color: control.textColor
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
    TapHandler { acceptedButtons: Qt.RightButton; onTapped: control.rightClicked() }
    TapHandler { acceptedButtons: Qt.MiddleButton; onTapped: control.middleClicked() }
    WheelHandler { enabled: control.scrollable; acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad; onWheel: event => { control.scrolled(event.angleDelta.y); event.accepted = true; } }
    onHoveredChanged: {
        tipReady = false;
        if (hovered && tooltipText) tipDelay.restart();
        else tipDelay.stop();
    }
    Timer { id: tipDelay; interval: 650; onTriggered: control.tipReady = true }
    // A native popup can extend below the 40px bar without being clipped.
    PopupWindow {
        anchor.item: control
        anchor.rect.x: control.width / 2
        anchor.rect.y: control.height + 8
        anchor.rect.width: 1
        anchor.rect.height: 1
        anchor.gravity: Edges.Bottom
        visible: control.hovered && control.tipReady && control.tooltipText.length > 0
        implicitWidth: Math.min(340, tipText.implicitWidth + 24)
        implicitHeight: tipText.implicitHeight + 20
        color: "transparent"
        mask: Region {}
        Rectangle {
            anchors.fill: parent
            radius: 10
            color: Shell.Theme.tooltip
            border.color: Shell.Theme.dark ? "transparent" : ("#38ffffff")
            Shell.GlassText {
                id: tipText
                anchors { fill: parent; leftMargin: 12; rightMargin: 12; topMargin: 10; bottomMargin: 10 }
                text: control.tooltipText
                wrapMode: Text.Wrap
                font.pixelSize: 12
            }
        }
    }
    Accessible.name: tooltipText || text
}

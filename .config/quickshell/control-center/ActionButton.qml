import QtQuick
import QtQuick.Controls
import "widgets" as Widgets

Button {
    id: control
    property bool selected: false
    property bool danger: false
    property string tooltipText: ""
    implicitHeight: 36
    implicitWidth: Math.max(36, contentItem.implicitWidth + 24)
    padding: 10
    hoverEnabled: true
    opacity: enabled ? 1 : 0.35
    font.family: Theme.font
    font.pixelSize: 13
    background: Rectangle {
        radius: 10
        color: control.down ? Theme.selected : control.hovered || control.activeFocus ? Theme.hover : control.selected ? Theme.selected : Theme.card
        border.width: 1
        border.color: Theme.dark ? "transparent" : (control.activeFocus ? "#80ffffff" : Theme.border)
        Behavior on color { ColorAnimation { duration: 120 } }
    }
    contentItem: GlassText {
        text: control.text
        font: control.font
        color: control.danger ? Theme.danger : Theme.text
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    Widgets.HoverTip {
        text: control.tooltipText
        visible: control.hovered && text.length > 0
    }
    Accessible.name: tooltipText || text
}

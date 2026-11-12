import QtQuick
import QtQuick.Controls

Slider {
    id: control
    from: 0
    to: 100
    stepSize: 1
    implicitHeight: 28
    leftPadding: 0
    rightPadding: 0
    background: Rectangle {
        x: control.leftPadding
        y: (control.height - height) / 2
        width: control.availableWidth
        height: 6
        radius: 3
        color: "#20ffffff"
        Rectangle {
            width: control.visualPosition * parent.width
            height: parent.height
            radius: parent.radius
            color: control.enabled ? Theme.accent : "#66ffffff"
        }
    }
    handle: Rectangle {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: (control.height - height) / 2
        width: control.pressed || control.activeFocus ? 16 : 12
        height: width
        radius: width / 2
        color: "white"
        border.color: Theme.dark ? "transparent" : ("#30000000")
        opacity: control.enabled ? 1 : 0.4
    }
}

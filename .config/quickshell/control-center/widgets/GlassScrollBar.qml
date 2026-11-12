import QtQuick
import QtQuick.Controls

ScrollBar {
    id: bar
    policy: ScrollBar.AsNeeded
    interactive: true
    hoverEnabled: true
    visible: size < 1
    implicitWidth: 12
    padding: 3
    minimumSize: 0.08
    contentItem: Rectangle {
        implicitWidth: 6
        implicitHeight: 28
        radius: 3
        color: bar.pressed ? "#e0ffffff" : bar.hovered ? "#a0ffffff" : "#60ffffff"
        Behavior on color { ColorAnimation { duration: 100 } }
    }
    background: Rectangle {
        radius: 6
        color: bar.hovered || bar.pressed ? "#20ffffff" : "#0cffffff"
    }
}

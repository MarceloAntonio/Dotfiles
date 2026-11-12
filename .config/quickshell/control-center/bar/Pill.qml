import QtQuick
import ".." as Shell

Rectangle {
    id: pill
    implicitHeight: 30
    radius: 12
    color: Shell.Theme.barBackground
    border.color: Shell.Theme.barBorder
    border.width: 1
    Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1] } }
    gradient: Shell.Theme.dark ? glassGradient : null
    Gradient {
        id: glassGradient
        GradientStop { position: 0; color: Qt.tint(pill.color, "#06e5efff") }
        GradientStop { position: 0.5; color: pill.color }
        GradientStop { position: 1; color: Qt.tint(pill.color, "#05080e18") }
    }
    Rectangle {
        anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: 1; leftMargin: 9; rightMargin: 9 }
        height: 1
        radius: 1
        color: Shell.Theme.dark ? "transparent" : "#0dffffff"
    }
}

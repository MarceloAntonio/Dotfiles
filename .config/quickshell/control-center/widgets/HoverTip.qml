import QtQuick
import QtQuick.Controls
import ".." as Shell

ToolTip {
    id: tip
    delay: 600
    timeout: 5000
    padding: 11
    horizontalPadding: 13
    implicitWidth: Math.min(320, contentItem.implicitWidth + leftPadding + rightPadding)
    x: (parent.width - width) / 2
    y: parent.height + 8
    contentItem: Text {
        text: tip.text
        color: Shell.Theme.text
        font.family: Shell.Theme.font
        font.pixelSize: 12
        wrapMode: Text.Wrap
        textFormat: Text.PlainText
    }
    background: Rectangle {
        color: Shell.Theme.tooltip
        radius: 10
        border.color: Shell.Theme.dark ? "transparent" : ("#38ffffff")
        border.width: 1
    }
    enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 100 } }
    exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 80 } }
}

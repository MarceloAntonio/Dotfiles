pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import ".." as Shell

Rectangle {
    id: preview
    required property var entry
    property bool detailed: false
    readonly property bool compact: height < 100
    color: entry?.kind === "terminal" ? entry.palette.background : "#18ffffff"
    radius: 10
    clip: true
    Image {
        anchors.fill: parent
        anchors.margins: Settings.category === "fastfetch" ? 10 : 0
        source: preview.entry?.preview ?? ""
        sourceSize.width: preview.detailed ? 800 : 360
        sourceSize.height: preview.detailed ? 500 : 220
        fillMode: Settings.category === "fastfetch" ? Image.PreserveAspectFit : Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        visible: preview.entry?.kind === "image"
    }
    Shell.GlassText {
        anchors.centerIn: parent
        visible: preview.entry?.kind === "distro"
        text: "󰣇"
        font.family: Shell.Theme.icons
        font.pixelSize: Math.min(parent.height * 0.65, 90)
        color: "#b8d8ee"
    }
    ColumnLayout {
        visible: preview.entry?.kind === "terminal"
        anchors.fill: parent
        anchors.margins: preview.detailed ? 24 : preview.compact ? 8 : 12
        spacing: preview.detailed ? 10 : preview.compact ? 3 : 5
        RowLayout {
            Repeater {
                model: [1, 3, 2]
                delegate: Rectangle {
                    required property int modelData
                    width: 7; height: 7; radius: 4
                    color: preview.entry?.palette?.colors[modelData] ?? "white"
                }
            }
            Item { Layout.fillWidth: true }
        }
        Shell.GlassText {
            Layout.fillWidth: true
            text: "celo ~  ❯"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: preview.detailed ? 17 : preview.compact ? 9 : 11
            color: preview.entry?.palette?.colors[2] ?? "white"
        }
        Shell.GlassText {
            visible: !preview.compact
            Layout.fillWidth: true
            text: "Hyprland · Kitty"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: preview.detailed ? 15 : 10
            color: preview.entry?.palette?.foreground ?? "white"
        }
        Item { Layout.fillHeight: true }
        Row {
            Layout.fillWidth: true
            spacing: 0
            Repeater {
                model: 8
                delegate: Rectangle {
                    required property int index
                    width: (preview.width - (preview.detailed ? 48 : preview.compact ? 16 : 24)) / 8
                    height: preview.detailed ? 20 : preview.compact ? 8 : 12
                    color: preview.entry?.palette?.colors[index] ?? "white"
                }
            }
        }
    }
}

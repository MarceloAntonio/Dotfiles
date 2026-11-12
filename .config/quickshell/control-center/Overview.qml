import QtQuick
import "monitors" as Monitors
import QtQuick.Layouts
import Quickshell.Networking
import Quickshell.Services.UPower

ColumnLayout {
    spacing: 12
    RowLayout {
        Layout.fillWidth: true
        GlassText { text: "Tema da interface"; Layout.fillWidth: true }
        ActionButton { text: "Claro"; selected: Theme.mode === "light"; onClicked: Theme.setMode("light") }
        ActionButton { text: "Escuro"; selected: Theme.mode === "dark"; onClicked: Theme.setMode("dark") }
        ActionButton { text: "Adaptativo"; selected: Theme.adaptive; onClicked: Theme.setMode("wallpaper") }
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        ActionButton {
            Layout.fillWidth: true
            implicitHeight: 64
            text: "󰤨   Wi-Fi  ·  " + (Networking.wifiEnabled ? "Ligado" : "Desligado")
            enabled: !!Service.wifi
            selected: Networking.wifiEnabled
            onClicked: Service.section = "wifi"
        }
        ActionButton {
            Layout.fillWidth: true
            implicitHeight: 64
            text: "󰂯   Bluetooth"
            selected: Service.adapter?.enabled ?? false
            enabled: !!Service.adapter
            onClicked: Service.section = "bluetooth"
        }
    }
    ActionButton {
        Layout.fillWidth: true
        text: "󰍹   Monitores  ·  posição, Hz e tela principal"
        onClicked: Monitors.Settings.open()
    }
    AudioControls { Layout.fillWidth: true }
    Card {
        Layout.fillWidth: true
        visible: Service.hasBrightness
        implicitHeight: brightnessControl.implicitHeight + 28
        SliderRow {
            id: brightnessControl
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
            title: "Brilho do notebook"
            icon: "󰃠"
            value: Service.brightness
            onMoved: value => Service.setBrightness(value)
        }
    }
    MediaCard { Layout.fillWidth: true }
    ActionButton {
        Layout.fillWidth: true
        text: Service.battery?.isPresent
            ? "󰁹   " + Math.round(Service.battery.percentage * 100) + "%  ·  " + (UPower.onBattery ? "Na bateria" : "Conectado à energia") + "    ›"
            : "󰐥   Energia e sessão    ›"
        onClicked: Service.section = "energia"
    }
}

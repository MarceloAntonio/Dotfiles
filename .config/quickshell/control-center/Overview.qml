import QtQuick
import "monitors" as Monitors
import QtQuick.Layouts
import Quickshell.Networking
import Quickshell.Services.UPower

ColumnLayout {
    spacing: 12
    RowLayout {
        Layout.fillWidth: true
        GlassText { text: Theme.tr("Tema da interface", "Interface theme"); Layout.fillWidth: true }
        ActionButton { text: Theme.tr("Claro", "Light"); selected: Theme.mode === "light"; onClicked: Theme.setMode("light") }
        ActionButton { text: Theme.tr("Escuro", "Dark"); selected: Theme.mode === "dark"; onClicked: Theme.setMode("dark") }
        ActionButton { text: Theme.tr("Adaptativo", "Adaptive"); selected: Theme.adaptive; onClicked: Theme.setMode("wallpaper") }
    }
    RowLayout {
        Layout.fillWidth: true
        GlassText { text: Theme.tr("Idioma do sistema", "System language"); Layout.fillWidth: true }
        ActionButton { text: "Português"; selected: !Theme.en; onClicked: Theme.setLanguage("pt") }
        ActionButton { text: "English"; selected: Theme.en; onClicked: Theme.setLanguage("en") }
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        ActionButton {
            Layout.fillWidth: true
            implicitHeight: 64
            text: "󰤨   Wi-Fi  ·  " + (Networking.wifiEnabled ? Theme.tr("Ligado", "On") : Theme.tr("Desligado", "Off"))
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
        text: "󰍹   " + Theme.tr("Monitores  ·  posição, Hz e tela principal", "Monitors  ·  position, Hz and primary screen")
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
            title: Theme.tr("Brilho do notebook", "Laptop brightness")
            icon: "󰃠"
            value: Service.brightness
            onMoved: value => Service.setBrightness(value)
        }
    }
    MediaCard { Layout.fillWidth: true }
    ActionButton {
        Layout.fillWidth: true
        text: Service.battery?.isPresent
            ? "󰁹   " + Math.round(Service.battery.percentage * 100) + "%  ·  " + (UPower.onBattery ? Theme.tr("Na bateria", "On battery") : Theme.tr("Conectado à energia", "Plugged in")) + "    ›"
            : "󰐥   " + Theme.tr("Energia e sessão", "Power and session") + "    ›"
        onClicked: Service.section = "energia"
    }
}

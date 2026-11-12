import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth

ColumnLayout {
    spacing: 12
    RowLayout {
        GlassText { Layout.fillWidth: true; text: "Bluetooth"; font.pixelSize: 18; font.weight: Font.DemiBold }
        ActionButton {
            text: Service.adapter?.enabled ? "Desligar" : "Ligar"
            enabled: !!Service.adapter
            selected: Service.adapter?.enabled ?? false
            onClicked: Service.adapter.enabled = !Service.adapter.enabled
        }
    }
    GlassText {
        Layout.fillWidth: true
        color: Theme.muted; font.pixelSize: 12; wrapMode: Text.Wrap
        text: !Service.adapter ? "Nenhum adaptador Bluetooth encontrado."
            : Service.adapter.state === BluetoothAdapterState.Blocked ? "Bluetooth bloqueado. Verifique o modo avião."
            : Service.adapter.enabled ? "Buscando dispositivos próximos. Selecione Parear para adicionar um novo." : "Ative o Bluetooth para conectar seus dispositivos."
    }
    Repeater {
        model: Service.adapter?.enabled ? Service.devices : []
        delegate: Card {
            id: deviceCard
            required property var modelData
            property bool busy: modelData.pairing || modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting
            Layout.fillWidth: true
            implicitHeight: deviceCard.modelData.paired ? 104 : 70
            color: modelData.connected ? Theme.selected : Theme.card
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 6
                RowLayout {
                    Layout.fillWidth: true
                    GlassText { text: "󰂯"; font.family: Theme.icons; font.pixelSize: 22 }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        GlassText { Layout.fillWidth: true; text: deviceCard.modelData.name || deviceCard.modelData.address; font.weight: Font.DemiBold }
                        GlassText {
                            Layout.fillWidth: true; font.pixelSize: 11; color: Theme.muted
                            text: (deviceCard.busy ? "Conectando…" : deviceCard.modelData.connected ? "Conectado" : deviceCard.modelData.paired ? "Pareado" : "Disponível")
                                + (deviceCard.modelData.batteryAvailable ? "  ·  " + Math.round(deviceCard.modelData.battery * 100) + "%" : "")
                        }
                    }
                    ActionButton {
                        text: deviceCard.busy ? "…" : deviceCard.modelData.connected ? "Sair" : deviceCard.modelData.paired ? "Conectar" : "Parear"
                        enabled: !deviceCard.busy
                        onClicked: Service.bluetoothAction(deviceCard.modelData, deviceCard.modelData.connected ? "disconnect" : deviceCard.modelData.paired ? "connect" : "pair")
                    }
                }
                ActionButton {
                    visible: deviceCard.modelData.paired
                    implicitHeight: 26
                    font.pixelSize: 11
                    text: "Esquecer dispositivo"
                    onClicked: {
                        if (text === "Confirmar remoção?") Service.bluetoothAction(deviceCard.modelData, "forget");
                        else text = "Confirmar remoção?";
                    }
                }
            }
        }
    }
    GlassText { visible: Service.adapter?.enabled && Service.devices.length === 0; text: "Nenhum dispositivo encontrado ainda."; color: Theme.muted }
}

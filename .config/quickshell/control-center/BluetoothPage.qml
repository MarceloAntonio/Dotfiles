import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth

ColumnLayout {
    spacing: 12
    RowLayout {
        GlassText { Layout.fillWidth: true; text: "Bluetooth"; font.pixelSize: 18; font.weight: Font.DemiBold }
        ActionButton {
            text: Service.adapter?.enabled ? Theme.tr("Desligar", "Turn off") : Theme.tr("Ligar", "Turn on")
            enabled: !!Service.adapter
            selected: Service.adapter?.enabled ?? false
            onClicked: Service.adapter.enabled = !Service.adapter.enabled
        }
    }
    GlassText {
        Layout.fillWidth: true
        color: Theme.muted; font.pixelSize: 12; wrapMode: Text.Wrap
        text: !Service.adapter ? Theme.tr("Nenhum adaptador Bluetooth encontrado.", "No Bluetooth adapter found.")
            : Service.adapter.state === BluetoothAdapterState.Blocked ? Theme.tr("Bluetooth bloqueado. Verifique o modo avião.", "Bluetooth is blocked. Check airplane mode.")
            : Service.adapter.enabled ? Theme.tr("Buscando dispositivos próximos. Selecione Parear para adicionar um novo.", "Searching for nearby devices. Select Pair to add a new one.") : Theme.tr("Ative o Bluetooth para conectar seus dispositivos.", "Turn on Bluetooth to connect your devices.")
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
                            text: (deviceCard.busy ? Theme.tr("Conectando…", "Connecting…") : deviceCard.modelData.connected ? Theme.tr("Conectado", "Connected") : deviceCard.modelData.paired ? Theme.tr("Pareado", "Paired") : Theme.tr("Disponível", "Available"))
                                + (deviceCard.modelData.batteryAvailable ? "  ·  " + Math.round(deviceCard.modelData.battery * 100) + "%" : "")
                        }
                    }
                    ActionButton {
                        text: deviceCard.busy ? "…" : deviceCard.modelData.connected ? Theme.tr("Sair", "Disconnect") : deviceCard.modelData.paired ? Theme.tr("Conectar", "Connect") : Theme.tr("Parear", "Pair")
                        enabled: !deviceCard.busy
                        onClicked: Service.bluetoothAction(deviceCard.modelData, deviceCard.modelData.connected ? "disconnect" : deviceCard.modelData.paired ? "connect" : "pair")
                    }
                }
                ActionButton {
                    visible: deviceCard.modelData.paired
                    implicitHeight: 26
                    font.pixelSize: 11
                    text: Theme.tr("Esquecer dispositivo", "Forget device")
                    onClicked: {
                        if (text === Theme.tr("Confirmar remoção?", "Confirm removal?")) Service.bluetoothAction(deviceCard.modelData, "forget");
                        else text = Theme.tr("Confirmar remoção?", "Confirm removal?");
                    }
                }
            }
        }
    }
    GlassText { visible: Service.adapter?.enabled && Service.devices.length === 0; text: Theme.tr("Nenhum dispositivo encontrado ainda.", "No devices found yet."); color: Theme.muted }
}

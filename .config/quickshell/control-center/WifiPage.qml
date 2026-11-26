import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking

ColumnLayout {
    spacing: 12
    RowLayout {
        GlassText { Layout.fillWidth: true; text: Theme.tr("Redes Wi-Fi", "Wi-Fi networks"); font.pixelSize: 18; font.weight: Font.DemiBold }
        ActionButton {
            text: Networking.wifiEnabled ? Theme.tr("Desligar", "Turn off") : Theme.tr("Ligar", "Turn on")
            enabled: !!Service.wifi && Networking.wifiHardwareEnabled
            selected: Networking.wifiEnabled
            onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
        }
    }
    GlassText {
        Layout.fillWidth: true
        color: Theme.muted
        font.pixelSize: 12
        wrapMode: Text.Wrap
        text: !Service.wifi ? Theme.tr("Nenhum adaptador Wi-Fi encontrado.", "No Wi-Fi adapter found.")
            : !Networking.wifiHardwareEnabled ? Theme.tr("Wi-Fi bloqueado pelo hardware.", "Wi-Fi is blocked by hardware.")
            : Networking.wifiEnabled ? Theme.tr("As redes são atualizadas enquanto este painel está aberto.", "Networks update while this panel is open.") : Theme.tr("Ative o Wi-Fi para ver as redes.", "Turn on Wi-Fi to see networks.")
    }
    Repeater {
        model: Networking.wifiEnabled ? Service.networks : []
        delegate: Card {
            id: networkCard
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: 70
            color: modelData.connected ? Theme.selected : Theme.card
            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12
                GlassText { text: networkCard.modelData.connected ? "󰤨" : "󰤥"; font.family: Theme.icons; font.pixelSize: 22 }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3
                    GlassText { Layout.fillWidth: true; text: networkCard.modelData.name; font.weight: Font.DemiBold }
                    GlassText {
                        Layout.fillWidth: true
                        font.pixelSize: 11; color: Theme.muted
                        text: (networkCard.modelData.stateChanging ? Theme.tr("Conectando…", "Connecting…") : networkCard.modelData.connected ? Theme.tr("Conectada", "Connected") : networkCard.modelData.known ? Theme.tr("Salva", "Saved") : networkCard.modelData.security === WifiSecurityType.Open ? Theme.tr("Aberta", "Open") : Theme.tr("Protegida", "Secured"))
                            + "  ·  " + Math.round(networkCard.modelData.signalStrength * 100) + "%"
                    }
                }
                ActionButton {
                    text: networkCard.modelData.stateChanging ? "…" : networkCard.modelData.connected ? Theme.tr("Sair", "Disconnect") : Theme.tr("Conectar", "Connect")
                    enabled: !networkCard.modelData.stateChanging
                    onClicked: {
                        if (networkCard.modelData.connected) Quickshell.execDetached(["nmcli", "device", "disconnect", Service.wifi.name]);
                        else Service.connectNetwork(networkCard.modelData);
                    }
                }
            }
        }
    }
    GlassText {
        visible: Networking.wifiEnabled && !!Service.wifi && Service.networks.length === 0
        text: Theme.tr("Procurando redes próximas…", "Searching for nearby networks…"); color: Theme.muted
    }
    ActionButton {
        Layout.fillWidth: true
        text: Theme.tr("Configurações avançadas de rede  ↗", "Advanced network settings  ↗")
        onClicked: { Service.close(); Quickshell.execDetached(["nm-connection-editor"]); }
    }
}

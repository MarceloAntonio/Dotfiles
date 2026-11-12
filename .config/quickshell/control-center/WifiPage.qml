import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking

ColumnLayout {
    spacing: 12
    RowLayout {
        GlassText { Layout.fillWidth: true; text: "Redes Wi-Fi"; font.pixelSize: 18; font.weight: Font.DemiBold }
        ActionButton {
            text: Networking.wifiEnabled ? "Desligar" : "Ligar"
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
        text: !Service.wifi ? "Nenhum adaptador Wi-Fi encontrado."
            : !Networking.wifiHardwareEnabled ? "Wi-Fi bloqueado pelo hardware."
            : Networking.wifiEnabled ? "As redes são atualizadas enquanto este painel está aberto." : "Ative o Wi-Fi para ver as redes."
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
                        text: (networkCard.modelData.stateChanging ? "Conectando…" : networkCard.modelData.connected ? "Conectada" : networkCard.modelData.known ? "Salva" : networkCard.modelData.security === WifiSecurityType.Open ? "Aberta" : "Protegida")
                            + "  ·  " + Math.round(networkCard.modelData.signalStrength * 100) + "%"
                    }
                }
                ActionButton {
                    text: networkCard.modelData.stateChanging ? "…" : networkCard.modelData.connected ? "Sair" : "Conectar"
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
        text: "Procurando redes próximas…"; color: Theme.muted
    }
    ActionButton {
        Layout.fillWidth: true
        text: "Configurações avançadas de rede  ↗"
        onClicked: { Service.close(); Quickshell.execDetached(["nm-connection-editor"]); }
    }
}

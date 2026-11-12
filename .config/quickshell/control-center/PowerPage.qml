import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower

ColumnLayout {
    spacing: 12
    Card {
        Layout.fillWidth: true
        implicitHeight: 100
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            GlassText {
                text: Service.battery?.isPresent ? Math.round(Service.battery.percentage * 100) + "%" : "Energia"
                font.pixelSize: 30; font.weight: Font.DemiBold
            }
            GlassText {
                color: Theme.muted
                text: UPower.onBattery ? "Usando a bateria" : "Conectado à energia"
            }
        }
    }
    GlassText { text: "PERFIL DE ENERGIA"; color: Theme.muted; font.pixelSize: 11; font.letterSpacing: 1.2 }
    RowLayout {
        Layout.fillWidth: true
        Repeater {
            model: [ { label: "Economia", profile: PowerProfile.PowerSaver }, { label: "Equilibrado", profile: PowerProfile.Balanced }, { label: "Desempenho", profile: PowerProfile.Performance } ]
            delegate: ActionButton {
                required property var modelData
                Layout.fillWidth: true
                text: modelData.label
                enabled: modelData.profile !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile
                selected: PowerProfiles.profile === modelData.profile
                onClicked: PowerProfiles.profile = modelData.profile
            }
        }
    }
    GlassText { text: "SESSÃO"; color: Theme.muted; font.pixelSize: 11; font.letterSpacing: 1.2; Layout.topMargin: 8 }
    ActionButton {
        Layout.fillWidth: true
        text: "󰌾   Bloquear tela"
        onClicked: { Service.close(); Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/rice-lock"]); }
    }
    Repeater {
        model: [ { label: "󰗼   Sair da sessão", action: "sair" }, { label: "󰜉   Reiniciar", action: "reiniciar" }, { label: "󰐥   Desligar", action: "desligar" } ]
        delegate: ActionButton {
            required property var modelData
            Layout.fillWidth: true
            text: modelData.label
            onClicked: Service.confirmation = modelData.action
        }
    }
}

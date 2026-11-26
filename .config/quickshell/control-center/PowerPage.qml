import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
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
                text: Service.battery?.isPresent ? Math.round(Service.battery.percentage * 100) + "%" : Theme.tr("Energia", "Power")
                font.pixelSize: 30; font.weight: Font.DemiBold
            }
            GlassText {
                color: Theme.muted
                text: UPower.onBattery ? Theme.tr("Usando a bateria", "Running on battery") : Theme.tr("Conectado à energia", "Plugged in")
            }
        }
    }
    GlassText { text: Theme.tr("DISPOSITIVOS", "DEVICES"); color: Theme.muted; font.pixelSize: 11; font.letterSpacing: 1.2; visible: devicesCol.visibleChildren.length > 0 }
    ColumnLayout {
        id: devicesCol
        Layout.fillWidth: true
        spacing: 4
        // Mouse/teclado/etc. que o UPower conhece (Logitech via hidpp, Bluetooth)
        Repeater {
            model: UPower.devices.values.filter(d => d.isPresent && !d.isLaptopBattery && d.type !== UPowerDeviceType.LinePower && d.type !== UPowerDeviceType.Battery)
            delegate: GlassText {
                required property var modelData
                text: (modelData.model || UPowerDeviceType.toString(modelData.type)) + "  " + Math.round(modelData.percentage * 100) + "%"
                    + (modelData.state === UPowerDeviceState.Charging ? " ⚡" : "")
            }
        }
        // Teclado AULA via pomni (lê a bateria pelo receptor 2.4)
        GlassText {
            id: keyboard
            property string label: ""
            visible: label !== ""
            text: label
            Process {
                id: keyboardProc
                command: [Quickshell.env("HOME") + "/.local/bin/pomni", "info", "--battery"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: {
                        const m = text.match(/(\d+)%/);
                        keyboard.label = m ? "AULA F75  " + m[1] + "%" : "";
                    }
                }
            }
            Timer { interval: 60000; running: true; repeat: true; onTriggered: keyboardProc.running = true }
        }
        // Headset via ~/.local/bin/hyperx-battery (headsetcontrol não suporta o Cloud III Wireless)
        GlassText {
            id: headset
            property string label: ""
            visible: label !== ""
            text: label
            Process {
                id: headsetProc
                command: [Quickshell.env("HOME") + "/.local/bin/hyperx-battery"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: {
                        const n = parseInt(text);
                        headset.label = Number.isFinite(n) ? "HyperX Cloud III  " + n + "%" + (text.includes("carregando") ? " ⚡" : "") : "";
                    }
                }
            }
            Timer { interval: 60000; running: true; repeat: true; onTriggered: headsetProc.running = true }
        }
    }
    GlassText { text: Theme.tr("PERFIL DE ENERGIA", "POWER PROFILE"); color: Theme.muted; font.pixelSize: 11; font.letterSpacing: 1.2 }
    RowLayout {
        Layout.fillWidth: true
        Repeater {
            model: [ { label: Theme.tr("Economia", "Power saver"), profile: PowerProfile.PowerSaver }, { label: Theme.tr("Equilibrado", "Balanced"), profile: PowerProfile.Balanced }, { label: Theme.tr("Desempenho", "Performance"), profile: PowerProfile.Performance } ]
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
    GlassText { text: Theme.tr("SESSÃO", "SESSION"); color: Theme.muted; font.pixelSize: 11; font.letterSpacing: 1.2; Layout.topMargin: 8 }
    ActionButton {
        Layout.fillWidth: true
        text: "󰌾   " + Theme.tr("Bloquear tela", "Lock screen")
        onClicked: { Service.close(); Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/rice-lock"]); }
    }
    Repeater {
        model: [ { label: "󰗼   " + Theme.tr("Sair da sessão", "Log out"), action: "sair" }, { label: "󰜉   " + Theme.tr("Reiniciar", "Restart"), action: "reiniciar" }, { label: "󰐥   " + Theme.tr("Desligar", "Shut down"), action: "desligar" } ]
        delegate: ActionButton {
            required property var modelData
            Layout.fillWidth: true
            text: modelData.label
            onClicked: Service.confirmation = modelData.action
        }
    }
}

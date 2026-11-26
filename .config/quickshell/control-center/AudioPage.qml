import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

ColumnLayout {
    spacing: 12
    AudioControls { Layout.fillWidth: true }
    GlassText { text: Theme.tr("SAÍDA DE ÁUDIO", "AUDIO OUTPUT"); color: Theme.muted; font.pixelSize: 11; font.letterSpacing: 1.2 }
    Repeater {
        model: Service.outputs
        delegate: ActionButton {
            required property var modelData
            Layout.fillWidth: true
            text: (Service.sink === modelData ? "✓   " : "󰓃   ") + (modelData.description || modelData.name)
            selected: Service.sink === modelData
            onClicked: Pipewire.preferredDefaultAudioSink = modelData
        }
    }
    GlassText { visible: Service.outputs.length === 0; text: Theme.tr("Nenhuma saída disponível", "No output available"); color: Theme.muted }
    GlassText { text: Theme.tr("ENTRADA DE ÁUDIO", "AUDIO INPUT"); color: Theme.muted; font.pixelSize: 11; font.letterSpacing: 1.2; Layout.topMargin: 6 }
    Repeater {
        model: Service.inputs
        delegate: ActionButton {
            required property var modelData
            Layout.fillWidth: true
            text: (Service.source === modelData ? "✓   " : "󰍬   ") + (modelData.description || modelData.name)
            selected: Service.source === modelData
            onClicked: Pipewire.preferredDefaultAudioSource = modelData
        }
    }
    GlassText { visible: Service.inputs.length === 0; text: Theme.tr("Nenhuma entrada disponível", "No input available"); color: Theme.muted }
    GlassText { text: Theme.tr("VOLUME POR APLICATIVO", "APP VOLUME"); color: Theme.muted; font.pixelSize: 11; Layout.topMargin: 6 }
    Repeater {
        model: Service.appStreams
        delegate: Card {
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: appVolume.implicitHeight + 24
            SliderRow {
                id: appVolume
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                title: modelData.properties["application.name"] || modelData.description || modelData.name
                icon: modelData.audio.muted ? "󰝟" : "󰕾"
                canMute: true
                muted: modelData.audio.muted
                value: modelData.audio.volume * 100
                onMoved: value => modelData.audio.volume = Math.max(0, Math.min(1, value / 100))
                onMuteClicked: modelData.audio.muted = !modelData.audio.muted
            }
        }
    }
    GlassText { visible: Service.appStreams.length === 0; text: Theme.tr("Os aplicativos aparecem quando reproduzem áudio", "Apps appear here when they play audio"); color: Theme.muted; wrapMode: Text.Wrap; Layout.fillWidth: true }
}

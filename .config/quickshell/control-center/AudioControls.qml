import QtQuick
import QtQuick.Layouts

Card {
    implicitHeight: content.implicitHeight + 28
    ColumnLayout {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
        spacing: 10
        SliderRow {
            Layout.fillWidth: true
            title: "Volume"
            icon: Service.sink?.audio?.muted ? "󰝟" : "󰕾"
            value: Service.volume
            muted: Service.sink?.audio?.muted ?? false
            canMute: true
            enabled: !!Service.sink?.audio
            onMoved: value => Service.setVolume(value, false)
            onMuteClicked: Service.mute(false)
        }
        SliderRow {
            Layout.fillWidth: true
            title: "Microfone"
            icon: Service.source?.audio?.muted ? "󰍭" : "󰍬"
            value: Service.micVolume
            muted: Service.source?.audio?.muted ?? false
            canMute: true
            enabled: !!Service.source?.audio
            onMoved: value => Service.setVolume(value, true)
            onMuteClicked: Service.mute(true)
        }
    }
}

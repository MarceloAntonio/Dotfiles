import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower

Item {
    id: face
    required property var controller
    readonly property color accent: controller.appearance.accent
    readonly property color surfaceColor: controller.appearance.surface || (light ? "#0fffffff" : "#54121924")
    readonly property color hoverColor: controller.appearance.hover || (light ? "#24ffffff" : "#73303b4b")
    readonly property bool light: controller.appearance.mode === "light"
    property bool engaged: false
    property real interaction: engaged && controller.activeFace === face ? 1 : 0
    property real departure: controller.authenticated ? 1 : 0
    property real entrance: 0
    property real shake: 0
    function wake() {
        if (controller.authenticated) return;
        controller.activeFace = face;
        engaged = true;
        idle.restart();
    }
    Component.onCompleted: { entrance = 1; input.forceActiveFocus(); }
    Behavior on entrance { NumberAnimation { duration: 650; easing.type: Easing.OutCubic } }
    Behavior on interaction { NumberAnimation { duration: 480; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1] } }
    Behavior on departure { NumberAnimation { duration: 620; easing.type: Easing.InOutCubic } }
    Timer {
        id: idle; interval: 8000
        onTriggered: if (!input.text.length && !face.controller.busy && !face.controller.failed) face.engaged = false
    }
    // Only the wallpaper is revealed; the compositor stays locked until PAM
    // succeeds and the independent lock controller releases it.
    Image {
        anchors.fill: parent
        source: face.controller.appearance.original || face.controller.appearance.wallpaper
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: face.width * 1.25
        sourceSize.height: face.height * 1.25
        asynchronous: true
    }
    Image {
        anchors.fill: parent
        source: face.controller.appearance.wallpaper
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        opacity: 0.12 * face.interaction * (1 - face.departure)
    }
    Rectangle {
        anchors.fill: parent
        color: face.light ? "#160d1725" : "#28101824"
        opacity: 1 - face.departure
    }
    Canvas {
        id: glow
        width: Math.min(640, face.width); height: width
        anchors.horizontalCenter: parent.horizontalCenter
        y: face.height * 0.18 - height / 2
        opacity: face.entrance * (0.05 + 0.03 * face.interaction) * (1 - face.departure)
        onWidthChanged: requestPaint()
        Connections { target: face; function onAccentChanged() { glow.requestPaint(); } }
        onPaint: {
            const ctx = getContext("2d"); ctx.reset();
            const g = ctx.createRadialGradient(width/2,height/2,0,width/2,height/2,width/2);
            g.addColorStop(0, face.accent); g.addColorStop(1, "transparent");
            ctx.fillStyle = g; ctx.fillRect(0,0,width,height);
        }
    }
    SystemClock { id: clock; precision: SystemClock.Minutes }
    Column {
        width: Math.min(680, parent.width - 48)
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(48, face.height * 0.105) - 6 * face.interaction - 16 * face.departure
        spacing: 0
        opacity: face.entrance * (1 - Math.min(1, face.departure * 1.5))
        Text {
            width: parent.width
            text: {
                const value = clock.date.toLocaleDateString(Qt.locale(face.controller.en ? "en_US" : "pt_BR"), face.controller.en ? "dddd, MMMM d" : "dddd, d 'de' MMMM");
                return value.charAt(0).toUpperCase() + value.slice(1);
            }
            font.family: "SF Pro Display"; font.pixelSize: 21; font.weight: Font.Medium
            color: "#e6f5f7fc"; horizontalAlignment: Text.AlignHCenter
        }
        Text {
            width: parent.width
            text: clock.date.toLocaleTimeString(Qt.locale(face.controller.en ? "en_US" : "pt_BR"), "HH:mm")
            font.family: "SF Pro Display"; font.pixelSize: Math.min(116, face.width * 0.15) - 4 * face.interaction; font.weight: Font.DemiBold
            font.letterSpacing: -4
            color: Qt.tint("#eef4ff", Qt.rgba(face.accent.r, face.accent.g, face.accent.b, 0.2))
            horizontalAlignment: Text.AlignHCenter
        }
    }
    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.min(face.height * 0.76, face.height - 208) + 6 * (1 - face.interaction)
        width: Math.min(270, parent.width - 64)
        spacing: 9
        opacity: face.entrance * (1 - Math.min(1, face.departure * 2.5))
        Rectangle {
            id: passwordBox
            transform: Translate { x: face.shake }
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Math.min(230, face.width - 64); implicitHeight: 36
            opacity: face.interaction
            enabled: !face.controller.authenticated
            radius: 18
            color: face.surfaceColor
            gradient: Gradient {
                GradientStop { position: 0; color: face.light ? face.surfaceColor : Qt.tint(face.surfaceColor, "#06e5efff") }
                GradientStop { position: 1; color: face.light ? face.surfaceColor : Qt.tint(face.surfaceColor, "#05080e18") }
            }
            border.width: 1
            border.color: face.controller.failed ? "#80ffb4ab" : face.light ? "#1affffff" : "transparent"
            Behavior on border.color { ColorAnimation { duration: 180 } }
            RowLayout {
                anchors.fill: parent; anchors.margins: 3; spacing: 2
                TextField {
                    id: input
                    Layout.fillWidth: true
                    color: "#f5f7fc"
                    font.family: "SF Pro Display"; font.pixelSize: 12
                    placeholderText: face.controller.busy ? face.controller.tr("Verificando…", "Verifying…") : face.controller.prompt === face.controller.tr("Senha", "Password") ? "" : face.controller.prompt
                    Accessible.name: face.controller.tr("Senha para desbloquear", "Password to unlock")
                    placeholderTextColor: "#99e5eaf2"
                    echoMode: face.controller.responseVisible ? TextInput.Normal : TextInput.Password
                    passwordCharacter: "●"
                    maximumLength: 512
                    enabled: !face.controller.busy
                    selectByMouse: false
                    background: Item {}
                    inputMethodHints: Qt.ImhHiddenText | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                    onTextEdited: face.wake()
                    onAccepted: { face.wake(); if (text.length && !face.controller.busy) face.controller.authenticate(text); }
                    Keys.onEscapePressed: { clear(); face.engaged = false; }
                    onEnabledChanged: if (enabled) forceActiveFocus()
                    Component.onCompleted: forceActiveFocus()
                }
                Button {
                    id: submit
                    text: "→"
                    implicitWidth: 28; implicitHeight: 28
                    enabled: input.text.length > 0 && !face.controller.busy
                    scale: down ? .9 : 1
                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    background: Rectangle { radius: 14; color: submit.down || submit.hovered ? face.hoverColor : "transparent" }
                    contentItem: Text { text: submit.text; font.pixelSize: 18; color: "#f5f7fc"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    onClicked: face.controller.authenticate(input.text)
                    Accessible.name: face.controller.tr("Desbloquear", "Unlock")
                }
            }
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: errorText.implicitHeight + 24
            radius: 13
            color: face.light ? "#eb46515f" : "#eb19212e"
            opacity: face.controller.message.length > 0 ? face.interaction : 0
            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
            Text {
                id: errorText
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                text: face.controller.message
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                font.family: "SF Pro Display"; font.pixelSize: 13
                color: face.controller.failed ? "#ffb4ab" : "#e5eaf2"
                Accessible.role: Accessible.AlertMessage
            }
        }
    }
    Text {
        anchors { top: parent.top; right: parent.right; topMargin: 22; rightMargin: 28 }
        text: UPower.displayDevice?.isPresent ? Math.round(UPower.displayDevice.percentage * 100) + "%  ·  " + (UPower.onBattery ? face.controller.tr("Na bateria", "On battery") : face.controller.tr("Conectado à energia", "Plugged in")) : ""
        color: UPower.onBattery && UPower.displayDevice?.percentage < 0.15 ? "#ffb4ab" : "#b3e5eaf2"
        font.family: "SF Pro Display"; font.pixelSize: 11
        opacity: face.entrance * (1 - face.departure)
        Behavior on color { ColorAnimation { duration: 300 } }
    }
    SequentialAnimation {
        id: errorMotion
        NumberAnimation { target: face; property: "shake"; to: -5; duration: 65; easing.type: Easing.OutCubic }
        NumberAnimation { target: face; property: "shake"; to: 4; duration: 80; easing.type: Easing.InOutCubic }
        NumberAnimation { target: face; property: "shake"; to: -2; duration: 70; easing.type: Easing.InOutCubic }
        NumberAnimation { target: face; property: "shake"; to: 0; duration: 100; easing.type: Easing.OutCubic }
    }
    Connections {
        target: face.controller
        function onClearInputs() { input.clear(); input.forceActiveFocus(); }
        function onActiveFaceChanged() { if (face.controller.activeFace !== face) { input.clear(); face.engaged = false; } }
        function onFailedChanged() {
            if (face.controller.failed && face.controller.activeFace === face) { face.wake(); errorMotion.restart(); }
        }
    }
    TapHandler { onTapped: { face.wake(); input.forceActiveFocus(); } }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "personalize" as Personalize
import "widgets" as Widgets
import "bar" as DesktopBar

PanelWindow {
    id: panel
    required property string outputName
    readonly property bool opened: Service.opened && Service.screenName === outputName
    readonly property real expandedWidth: Math.min(440, screen.width - 24)
    readonly property real desiredHeight: Math.min(820, screen.height - 80, Math.max(340, page.implicitHeight + 166 + (Service.error ? errorMessage.implicitHeight + 38 : 0)))
    property real expandedHeight: desiredHeight
    readonly property real originWidth: DesktopBar.BarState.bars[outputName]?.controlExtent ?? 38
    readonly property real originCenter: DesktopBar.BarState.bars[outputName]?.controlCenterX ?? screen.width - 78
    property real originLeft: originCenter - (screen.width - 12 - expandedWidth) - originWidth / 2
    Behavior on originLeft { enabled: panel.opened && panel.progress > 0.99; NumberAnimation { duration: 340; easing.type: Easing.InOutCubic } }
    property real progress: opened ? 1 : 0
    readonly property real bodyProgress: Math.max(0, Math.min(1, (progress - 0.12) / 0.88))
    property int focusRevision: 0
    visible: opened || progress > 0.001
    color: "transparent"
    implicitWidth: expandedWidth
    implicitHeight: expandedHeight + 4
    anchors { top: true; right: true }
    margins { top: 35; right: 12 }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "qs-control-center"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    mask: Region { item: surface; radius: surface.radius; Region { item: neck; radius: Math.min(5, neck.height / 2) } }
    BackgroundEffect.blurRegion: Region { item: surface; radius: surface.radius; Region { item: neck; radius: Math.min(5, neck.height / 2) } }
    Component.onCompleted: Service.registerPanel(outputName, panel)
    Component.onDestruction: Service.unregisterPanel(outputName, panel)
    Behavior on progress {
        NumberAnimation { duration: 480; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1] }
    }
    Behavior on expandedHeight {
        NumberAnimation { duration: 240; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1] }
    }
    function focusIfOpen() {
        if (visible && opened) {
            grab.active = true;
            if (secret.visible) secret.forceActiveFocus();
            else keyboard.forceActiveFocus();
        }
    }
    onOpenedChanged: {
        focusRevision++;
        focusDelay.stop();
        if (!opened) grab.active = false;
        else focusDelay.restart();
    }
    onVisibleChanged: {
        if (!visible) grab.active = false;
        else if (opened) focusDelay.restart();
    }
    Timer { id: focusDelay; interval: 90; onTriggered: panel.focusIfOpen() }

    HyprlandFocusGrab {
        id: grab
        windows: [panel, DesktopBar.BarState.bars[panel.outputName]].filter(window => window?.visible)
        onCleared: {
            const revision = panel.focusRevision;
            Qt.callLater(() => {
                if (revision === panel.focusRevision && panel.opened && !focusDelay.running && !grab.active) Service.close();
            });
        }
    }
    Item {
        id: neck
        x: panel.originLeft
        width: panel.originWidth
        height: (10 + 18 * panel.progress) * Math.min(1, panel.progress / 0.12)
    }
    Canvas {
        id: connectedSurface
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Connections { target: Theme; function onBackgroundChanged() { connectedSurface.requestPaint(); } }
        Connections { target: panel; function onProgressChanged() { connectedSurface.requestPaint(); } function onOriginLeftChanged() { connectedSurface.requestPaint(); } function onExpandedHeightChanged() { connectedSurface.requestPaint(); } }
        Connections {
            target: surface
            function onXChanged() { connectedSurface.requestPaint(); }
            function onYChanged() { connectedSurface.requestPaint(); }
            function onWidthChanged() { connectedSurface.requestPaint(); }
            function onRadiusChanged() { connectedSurface.requestPaint(); }
        }
        onPaint: {
            const c = getContext("2d"); c.reset();
            const x = surface.x, y = surface.y, w = surface.width, h = surface.height;
            const l = Math.max(x, Math.min(neck.x, x + w - neck.width));
            // Keep the stem under the button even at the far right edge.
            const r = surface.radius;
            const n = neck.width, t = Math.min(10, n / 2, y / 2);
            // Erase the remaining connector from its bottom edge toward the bar.
            c.save();
            c.beginPath();
            c.rect(0, 0, width, (y + h + 1) * Math.min(1, panel.progress / 0.12));
            c.clip();
            c.beginPath(); c.moveTo(l + t, 0);
            c.lineTo(l + n - t, 0); c.quadraticCurveTo(l + n, 0, l + n, t);
            c.lineTo(l + n, y); c.lineTo(x + w - r, y);
            c.quadraticCurveTo(x + w, y, x + w, y + r);
            c.lineTo(x + w, y + h - r); c.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
            c.lineTo(x + r, y + h); c.quadraticCurveTo(x, y + h, x, y + h - r);
            c.lineTo(x, y + r); c.quadraticCurveTo(x, y, x + r, y);
            c.lineTo(l, y); c.lineTo(l, t); c.quadraticCurveTo(l, 0, l + t, 0); c.closePath();
            const fill = Theme.background;
            c.fillStyle = Qt.rgba(fill.r, fill.g, fill.b, fill.a); c.fill();
            c.strokeStyle = Theme.dark ? "transparent" : "rgba(255, 255, 255, 0.102)"; c.lineWidth = 1; c.stroke(); c.restore();
        }
    }
    Rectangle {
        id: surface
        y: 10 * Math.min(1, panel.progress / 0.25)
        x: panel.originLeft * (1 - panel.bodyProgress) + 3 * panel.bodyProgress
        width: panel.originWidth + (panel.expandedWidth - 6 - panel.originWidth) * panel.bodyProgress
        height: 2 + (panel.expandedHeight - 8) * panel.bodyProgress
        radius: Math.max(0, Math.min(18, height / 2, x + width - Math.max(x, Math.min(neck.x, x + width - neck.width)) - neck.width))
        color: "transparent"
        clip: true
        MouseArea {
            width: parent.width
            height: Math.min(30, parent.height)
            onClicked: Service.toggle("geral")
        }

        FocusScope {
            id: keyboard
            width: panel.expandedWidth - 6
            height: panel.expandedHeight - 6
            x: (parent.width - width) / 2
            enabled: panel.opened
            opacity: Math.max(0, Math.min(1, (panel.progress - 0.18) / 0.65))
            focus: true
            Keys.onEscapePressed: {
                if (Service.passwordNetwork) Service.passwordNetwork = null;
                else if (Service.pairing) Service.pairingReply(false, "");
                else if (Service.confirmation) Service.confirmation = "";
                else Service.close();
            }
            ColumnLayout {
                enabled: panel.progress > 0.8
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14
                RowLayout {
                    Layout.fillWidth: true
                    Item { Layout.preferredWidth: 24; Layout.preferredHeight: 36 }
                    GlassText { text: clock.date.toLocaleDateString(Qt.locale("pt_BR"), "dddd, d 'de' MMMM"); font.pixelSize: 12; color: Theme.muted }
                    Item { Layout.fillWidth: true }
                    ActionButton {
                        text: "󰂚" + (Notifications.count > 0 ? "  " + Notifications.count : "")
                        font.family: Theme.icons
                        selected: Service.section === "notificacoes"
                        onClicked: Service.section = "notificacoes"
                        tooltipText: "Notificações"
                    }
                    ActionButton {
                        text: "×"
                        font.pixelSize: 22
                        onClicked: Service.close()
                        tooltipText: "Fechar · Esc"
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    Repeater {
                        model: [{ name: "geral", label: "Geral" }, { name: "som", label: "Som" }, { name: "wifi", label: "Wi-Fi" }, { name: "bluetooth", label: "Bluetooth" }, { name: "energia", label: "Energia" }]
                        delegate: ActionButton {
                            required property var modelData
                            Layout.fillWidth: true
                            padding: 6
                            implicitWidth: contentItem.implicitWidth + 12
                            font.pixelSize: 12
                            text: modelData.label
                            selected: Service.section === modelData.name
                            onClicked: { Service.section = modelData.name; Service.passwordNetwork = null; }
                        }
                    }
                }
                Card {
                    Layout.fillWidth: true
                    visible: Service.error.length > 0
                    implicitHeight: errorMessage.implicitHeight + 24
                    color: "#18ffb4ab"
                    GlassText {
                        id: errorMessage
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                        text: Service.error
                        color: Theme.danger
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                    }
                }
                Flickable {
                    id: scroll
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: width
                    contentHeight: page.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: Widgets.GlassScrollBar { id: pageScrollBar }
                    Item {
                        id: page
                        width: scroll.width - (pageScrollBar.visible ? 16 : 0)
                        implicitHeight: incoming.item?.implicitHeight ?? 174
                        property string section: Service.section
                        property int direction: 1
                        property real slide: 1
                        function url(tab) { return ({ geral: "Overview.qml", som: "AudioPage.qml", wifi: "WifiPage.qml", bluetooth: "BluetoothPage.qml", energia: "PowerPage.qml", notificacoes: "NotificationsPage.qml" })[tab] || "Overview.qml"; }
                        onSectionChanged: {
                            const order = ["geral", "som", "wifi", "bluetooth", "energia", "notificacoes"];
                            transition.stop();
                            outgoing.active = false;
                            const animate = panel.opened && panel.progress > 0.8;
                            if (animate) { outgoing.source = incoming.source; outgoing.active = true; }
                            direction = order.indexOf(section) >= order.indexOf(incoming.tab) ? 1 : -1;
                            incoming.tab = section;
                            incoming.source = url(section);
                            scroll.contentY = 0;
                            if (animate) { slide = 0; transition.restart(); }
                            else { slide = 1; outgoing.active = false; }
                        }
                        Loader {
                            id: outgoing
                            active: false
                            width: page.width
                            x: -page.direction * page.width * page.slide
                            visible: page.slide < 1
                        }
                        Loader {
                            id: incoming
                            active: panel.opened || panel.progress > 0.001
                            property string tab: "geral"
                            width: page.width
                            x: page.direction * page.width * (1 - page.slide)
                            source: page.url(tab)
                        }
                        NumberAnimation {
                            id: transition
                            target: page; property: "slide"; to: 1; duration: 340
                            easing.type: Easing.InOutCubic
                            onFinished: outgoing.active = false
                        }
                    }
                }
                GlassText {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Super + C  ·  Esc para fechar"
                    color: "#66ffffff"
                    font.pixelSize: 11
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: 18
                visible: !!Service.passwordNetwork || !!Service.pairing || Service.confirmation.length > 0
                color: Theme.tooltip
                MouseArea { anchors.fill: parent }
                ColumnLayout {
                    anchors.centerIn: parent
                    width: parent.width - 48
                    spacing: 16
                    GlassText {
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        text: Service.passwordNetwork ? "Conectar a " + Service.passwordNetwork.name
                            : Service.pairing ? "Pareamento Bluetooth" : "Confirmar " + Service.confirmation + "?"
                        font.pixelSize: 22; font.weight: Font.DemiBold
                    }
                    GlassText {
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                        color: Theme.muted
                        text: Service.passwordNetwork ? "Digite a senha da rede Wi-Fi."
                            : Service.pairing ? Service.pairing.name + (Service.pairing.kind === "confirm" ? "\nO código corresponde ao exibido no dispositivo?" : Service.pairing.kind === "pin" || Service.pairing.kind === "passkey" ? "\nDigite o código solicitado pelo dispositivo." : "")
                            : "Seus aplicativos podem ter alterações não salvas."
                    }
                    GlassText {
                        Layout.fillWidth: true
                        visible: !!Service.pairing?.code
                        text: Service.pairing?.code ?? ""
                        font.pixelSize: 36
                        font.letterSpacing: 5
                        horizontalAlignment: Text.AlignHCenter
                    }
                    TextField {
                        id: secret
                        Layout.fillWidth: true
                        visible: !!Service.passwordNetwork || ["pin", "passkey"].includes(Service.pairing?.kind)
                        echoMode: Service.passwordNetwork ? TextInput.Password : TextInput.Normal
                        placeholderText: Service.passwordNetwork ? "Senha da rede" : "Código"
                        color: Theme.text
                        placeholderTextColor: Theme.muted
                        font.family: Theme.font
                        font.pixelSize: 15
                        padding: 14
                        selectByMouse: true
                        background: Rectangle { color: Theme.card; radius: 10; border.color: Theme.dark ? "transparent" : (secret.activeFocus ? "#80ffffff" : Theme.border)}
                        onVisibleChanged: {
                            text = "";
                            if (visible) forceActiveFocus();
                        }
                        onAccepted: if (accept.enabled) accept.clicked()
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        ActionButton {
                            Layout.fillWidth: true
                            text: "Cancelar"
                            onClicked: {
                                Service.passwordNetwork = null;
                                Service.confirmation = "";
                                if (Service.pairing) Service.pairingReply(false, "");
                                secret.text = "";
                            }
                        }
                        ActionButton {
                            id: accept
                            Layout.fillWidth: true
                            text: Service.passwordNetwork ? "Conectar" : Service.pairing ? "Confirmar" : "Sim, " + Service.confirmation
                            selected: true
                            enabled: !secret.visible || secret.text.length > 0
                            visible: Service.pairing?.kind !== "display"
                            onClicked: {
                                if (Service.passwordNetwork) {
                                    Service.connectNetwork(Service.passwordNetwork, secret.text);
                                    Service.passwordNetwork = null;
                                } else if (Service.pairing) Service.pairingReply(true, secret.text);
                                else Service.executePower(Service.confirmation);
                                secret.text = "";
                            }
                        }
                    }
                }
            }
        }
        GlassText {
            text: DesktopBar.BarState.bars[panel.outputName]?.controlSource?.glyph || DesktopBar.BarState.bars[panel.outputName]?.controlSource?.text || "󰒓"
            font.family: Theme.icons
            font.pixelSize: 15
            font.weight: Font.DemiBold
            renderType: Text.NativeRendering
            color: "#ffffff"
            x: ((surface.width - implicitWidth) / 2) * (1 - panel.progress) + 18 * panel.progress
            y: ((30 - implicitHeight) / 2) * (1 - panel.progress) + (18 + (36 - implicitHeight) / 2) * panel.progress
            MouseArea { anchors.fill: parent; onClicked: Service.toggle("geral") }
        }
    }
    SystemClock { id: clock; precision: SystemClock.Minutes }
}

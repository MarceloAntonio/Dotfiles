pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Networking
import Quickshell.Services.UPower
import ".." as Shell
import "motion" as Motion

PanelWindow {
    id: bar
    required property string outputName
    readonly property var monitor: BarState.monitor(outputName)
    readonly property var windows: BarState.tasks(outputName)
    readonly property var nativeWindows: ToplevelManager.toplevels.values
    readonly property real workspaceExtent: workspacePill.width
    readonly property real taskExtent: tasksPill.width
    readonly property real clockExtent: clockPill.width
    readonly property var calendarPopup: BarState.calendars[outputName] ?? null
    readonly property var controlPopup: Shell.Service.panels[outputName] ?? null
    property var controlSource: controlButton
    readonly property real controlExtent: controlSource.width
    function sourcePosition(item) {
        let x = item.width / 2;
        for (let node = item; node && node !== bar.contentItem; node = node.parent) x += node.x;
        return x;
    }
    readonly property real controlCenterX: sourcePosition(controlSource)
    Component.onCompleted: BarState.registerBar(outputName, bar)
    Component.onDestruction: BarState.unregisterBar(outputName, bar)
    visible: BarState.enabled
    color: "transparent"
    anchors { top: true; left: true; right: true }
    implicitHeight: 40
    exclusiveZone: 40
    WlrLayershell.namespace: "qs-bar"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    BackgroundEffect.blurRegion: Region {
        Region { item: archPill; radius: archPill.radius }
        Region { item: workspacePill; radius: workspacePill.radius }
        Region { item: tasksPill; radius: tasksPill.radius }
        Region { item: clockPill; radius: 12 }
        Region { item: statusPill; radius: statusPill.radius }
        Region { item: controlPill; radius: controlPill.radius }
        Region { item: powerPill; radius: powerPill.radius }
    }
    MouseArea {
        width: parent.width
        height: 40
        onClicked: BarState.closePanels()
    }

    Row {
        id: leftRow
        anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter; verticalCenterOffset: 0 }
        spacing: 6
        Pill {
            id: archPill
            implicitWidth: archButton.contentItem.implicitWidth + 22
            color: archButton.hovered ? Shell.Theme.barHover : Shell.Theme.barBackground
            border.color: archButton.hovered ? Shell.Theme.barHoverBorder : (Shell.Theme.dark ? Shell.Theme.barBorder : "#26ffffff")
            BarButton {
                id: archButton
                anchors.fill: parent
                highlightHover: false
                text: "󰣇"
                font.family: Shell.Theme.icons
                font.pixelSize: 18
                tooltipText: Shell.Theme.tr("Atalhos · clique direito para abrir aplicativos", "Shortcuts · right-click to open apps")
                onClicked: {
                    BarState.closePanels();
                    BarState.commandsScreen = bar.outputName;
                    BarState.commandsOpened = !BarState.commandsOpened;
                }
                onRightClicked: { BarState.closePanels(); Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/launcher.sh"]); }
            }
        }
        Pill {
            id: workspacePill
            TapHandler {
                acceptedButtons: Qt.RightButton
                onTapped: { BarState.closePanels(); BarState.overviewScreen = bar.outputName; BarState.overviewOpened = !BarState.overviewOpened; }
            }
            implicitWidth: workspaceStrip.implicitWidth + 8
            clip: true
            Motion.AnimatedStrip {
                id: workspaceStrip
                anchors.centerIn: parent
                kind: "workspaces"
                outputName: bar.outputName
                entries: BarState.visibleWorkspaces(bar.outputName).map(id => ({
                    key: String(id), id: id, active: bar.monitor?.activeWorkspace?.id === id,
                    urgent: BarState.workspace(id)?.urgent ?? false,
                    span: (bar.monitor?.activeWorkspace?.id === id ? 42 : 30) + 2
                }))
            }
        }
        Pill {
            id: tasksPill
            property real chromeWidth: bar.windows.length > 0 ? 8 : 0
            visible: taskStrip.implicitWidth > 0.05 || bar.windows.length > 0
            opacity: Math.min(1, width / 20)
            implicitWidth: Math.min(taskStrip.implicitWidth + chromeWidth, Math.max(0, bar.width / 2 - clockPill.width / 2 - archPill.width - workspacePill.width - 52))
            clip: true
            Behavior on chromeWidth {
                NumberAnimation { duration: taskStrip.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1] }
            }
            Flickable {
                id: taskScroll
                anchors.fill: parent
                anchors { leftMargin: tasksPill.chromeWidth / 2; rightMargin: tasksPill.chromeWidth / 2; topMargin: 3; bottomMargin: 3 }
                contentWidth: taskStrip.implicitWidth
                contentHeight: height
                onContentWidthChanged: contentX = Math.max(0, Math.min(contentX, contentWidth - width))
                flickableDirection: Flickable.HorizontalFlick
                boundsBehavior: Flickable.StopAtBounds
                clip: true
                Motion.AnimatedStrip {
                    id: taskStrip
                    kind: "tasks"
                    outputName: bar.outputName
                    entries: bar.windows.map(window => ({key: String(window.address), icon: BarState.iconFor(window),
                        title: window.title, active: window.activated, span: 30}))
                }
                WheelHandler {
                    onWheel: event => {
                        taskScroll.contentX = Math.max(0, Math.min(taskScroll.contentWidth - taskScroll.width, taskScroll.contentX - event.angleDelta.y / 2));
                        event.accepted = true;
                    }
                }
            }
        }
    }

    Pill {
        id: clockPill
        opacity: bar.calendarPopup?.visible ? 0 : 1
        anchors { centerIn: parent; verticalCenterOffset: 0 }
        implicitWidth: clockButton.contentItem.implicitWidth + 32
        color: clockButton.hovered ? Shell.Theme.barHover : Shell.Theme.barBackground
        border.color: clockButton.hovered ? Shell.Theme.barHoverBorder : Shell.Theme.barBorder
        BarButton {
            id: clockButton
            anchors.fill: parent
            highlightHover: false
            text: Qt.formatDateTime(clock.date, "HH:mm")
            font.weight: Font.DemiBold
            font.letterSpacing: 0.3
            tooltipText: clock.date.toLocaleDateString(Shell.Theme.locale, Shell.Theme.tr("dddd, d 'de' MMMM 'de' yyyy", "dddd, MMMM d, yyyy")) + Shell.Theme.tr("\nClique para abrir o calendário", "\nClick to open the calendar")
            onClicked: BarState.toggleCalendar(bar.outputName)
        }
    }

    Row {
        id: rightRow
        anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter; verticalCenterOffset: 0 }
        spacing: 6
        Pill {
            id: statusPill
            implicitWidth: statusRow.implicitWidth + 10
            Row {
                id: statusRow
                anchors.centerIn: parent
                spacing: 0
                BarButton {
                    id: networkButton
                    selected: Shell.Service.opened && Shell.Service.screenName === bar.outputName && bar.controlSource === networkButton
                    glyph: BarState.networkIcon
                    text: BarState.wired ? BarState.ethernetAddress : ""
                    textColor: BarState.wired || BarState.wifiNetwork ? "#ffffff" : "#66ffffff"
                    tooltipText: BarState.networkDescription + " · Wi-Fi"
                    onClicked: BarState.openControl("wifi", bar.outputName, networkButton)
                    onRightClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                }
                BarButton {
                    id: bluetoothButton
                    selected: Shell.Service.opened && Shell.Service.screenName === bar.outputName && bar.controlSource === bluetoothButton
                    text: Shell.Service.adapter?.enabled ? (Shell.Service.devices.some(d => d.connected) ? "󰂱" : "󰂯") : "󰂲"
                    font.family: Shell.Theme.icons
                    font.pixelSize: 16
                    textColor: Shell.Service.adapter?.enabled ? "#ffffff" : "#66ffffff"
                    tooltipText: "Bluetooth · " + (Shell.Service.adapter?.enabled ? Shell.Theme.tr("Ligado", "On") : Shell.Theme.tr("Desligado", "Off"))
                    onClicked: BarState.openControl("bluetooth", bar.outputName, bluetoothButton)
                    onRightClicked: if (Shell.Service.adapter) Shell.Service.adapter.enabled = !Shell.Service.adapter.enabled
                }
                BarButton {
                    id: soundButton
                    selected: Shell.Service.opened && Shell.Service.screenName === bar.outputName && bar.controlSource === soundButton
                    glyph: BarState.audioIcon
                    text: Math.round(Shell.Service.volume) + "%"
                    textColor: Shell.Service.sink?.audio?.muted ? "#66ffffff" : "#ffffff"
                    tooltipText: Shell.Theme.tr("Som · role para ajustar", "Sound · scroll to adjust")
                    scrollable: true
                    onClicked: BarState.openControl("som", bar.outputName, soundButton)
                    onScrolled: delta => { if (delta) Shell.Service.setVolume(Shell.Service.volume + (delta > 0 ? 5 : -5), false); }
                }
                BarButton {
                    id: batteryButton
                    selected: Shell.Service.opened && Shell.Service.screenName === bar.outputName && bar.controlSource === batteryButton
                    visible: Shell.Service.battery?.isPresent ?? false
                    readonly property int percentage: Math.round((Shell.Service.battery?.percentage ?? 0) * 100)
                    glyph: UPower.onBattery ? ["", "", "", "", ""][Math.min(4, Math.floor(percentage / 20))] : ""
                    text: percentage + "%"
                    urgent: UPower.onBattery && percentage <= 15
                    tooltipText: (UPower.onBattery ? Shell.Theme.tr("Na bateria", "On battery") : Shell.Theme.tr("Conectado à energia", "Plugged in")) + Shell.Theme.tr(" · brilho e perfil de energia", " · brightness and power profile")
                    onClicked: BarState.openControl("energia", bar.outputName, batteryButton)
                }
            }
        }
        Pill {
            id: controlPill
            implicitWidth: controlButton.contentItem.implicitWidth + 24
            color: ((Shell.Service.opened && Shell.Service.screenName === bar.outputName && bar.controlSource === controlButton) || controlButton.hovered) ? Shell.Theme.barHover : Shell.Theme.barBackground
            border.color: ((Shell.Service.opened && Shell.Service.screenName === bar.outputName && bar.controlSource === controlButton) || controlButton.hovered) ? Shell.Theme.barHoverBorder : Shell.Theme.barBorder
            BarButton {
                id: controlButton
                anchors.fill: parent
                highlightHover: false
                text: "󰒓"
                font.family: Shell.Theme.icons
                font.pixelSize: 15
                tooltipText: Shell.Theme.tr("Central de controle · Super + C", "Control center · Super + C") + (Shell.Notifications.count ? "\n" + Shell.Notifications.count + Shell.Theme.tr(" notificações", " notifications") : "")
                onClicked: BarState.openControl("geral", bar.outputName, controlButton)
                onRightClicked: {
                    BarState.openControl("energia", bar.outputName, controlButton);
                }
            }
        }
        Pill {
            id: powerPill
            implicitWidth: controlButton.contentItem.implicitWidth + 24
            color: ((Shell.Service.powerOpened && Shell.Service.powerScreen === bar.outputName) || powerButton.hovered) ? Shell.Theme.barHover : Shell.Theme.barBackground
            border.color: ((Shell.Service.powerOpened && Shell.Service.powerScreen === bar.outputName) || powerButton.hovered) ? Shell.Theme.barHoverBorder : Shell.Theme.barBorder
            BarButton {
                id: powerButton
                anchors.fill: parent
                highlightHover: false
                text: "󰤆"; font.family: Shell.Theme.icons; font.pixelSize: 14
                contentItem: Text {
                    text: powerButton.text
                    font: powerButton.font
                    color: powerButton.textColor
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    renderType: Text.NativeRendering
                }
                Accessible.name: Shell.Theme.tr("Energia e sessão", "Power and session")
                onClicked: {
                    const wasOpen = Shell.Service.powerOpened && Shell.Service.powerScreen === bar.outputName;
                    BarState.closePanels();
                    Shell.Service.powerScreen = bar.outputName;
                    Shell.Service.powerOpened = !wasOpen;
                }
            }
        }
    }
    SystemClock { id: clock; precision: SystemClock.Minutes }
}

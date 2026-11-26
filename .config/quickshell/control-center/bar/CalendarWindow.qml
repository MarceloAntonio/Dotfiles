pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import ".." as Shell

PanelWindow {
    id: panel
    required property string outputName
    readonly property bool requested: BarState.calendarOpened && BarState.calendarScreen === outputName
    property bool musicMode: false
    property real expandedWidth: Math.min(musicMode ? 650 : 374, screen.width - 32)
    property real expandedHeight: Math.min(musicMode ? 340 : 584, screen.height - 52)
    Behavior on expandedWidth { NumberAnimation { duration: 480; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1] } }
    Behavior on expandedHeight { NumberAnimation { duration: 480; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1] } }
    readonly property real originWidth: BarState.bars[outputName]?.clockExtent ?? 66
    property real progress: requested ? 1 : 0
    property int focusRevision: 0
    visible: requested || progress > 0.001
    anchors.top: true
    margins.top: 5
    implicitWidth: expandedWidth
    implicitHeight: expandedHeight
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "qs-calendar"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: requested ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    mask: Region { item: surface; radius: surface.radius }
    BackgroundEffect.blurRegion: Region { item: surface; radius: surface.radius }
    Component.onCompleted: BarState.registerCalendar(outputName, panel)
    Component.onDestruction: BarState.unregisterCalendar(outputName, panel)
    Behavior on progress {
        NumberAnimation {
            duration: 480
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1]
        }
    }
    function focusIfOpen() {
        if (visible && requested) { grab.active = true; keyboard.forceActiveFocus(); }
    }
    onRequestedChanged: {
        focusRevision++;
        focusDelay.stop();
        if (!requested) { grab.active = false; musicMode = false; }
        else { Qt.callLater(() => keyboard.forceActiveFocus()); focusDelay.restart(); }
    }
    onVisibleChanged: {
        if (!visible) grab.active = false;
        else if (requested) focusDelay.restart();
    }
    Timer { id: focusDelay; interval: 90; onTriggered: panel.focusIfOpen() }
    HyprlandFocusGrab {
        id: grab
        windows: [panel, BarState.bars[panel.outputName]].filter(window => window?.visible)
        onCleared: {
            const revision = panel.focusRevision;
            Qt.callLater(() => {
                if (revision === panel.focusRevision && panel.requested && !focusDelay.running && !grab.active) BarState.closeCalendar();
            });
        }
    }
    Rectangle {
        id: surface
        anchors.horizontalCenter: parent.horizontalCenter
        width: panel.originWidth + (panel.expandedWidth - 6 - panel.originWidth) * panel.progress
        height: 30 + (panel.expandedHeight - 6 - 30) * panel.progress
        radius: 12 + 6 * panel.progress
        clip: true
        color: Shell.Theme.background
        border.color: Shell.Theme.dark ? "transparent" : (Shell.Theme.border)
        MouseArea {
            width: parent.width
            height: Math.min(36, parent.height)
            onClicked: BarState.toggleCalendar(panel.outputName)
        }
        FocusScope {
            id: keyboard
            width: panel.expandedWidth - 6
            height: panel.expandedHeight - 6
            x: (parent.width - width) / 2
            enabled: panel.requested
            focus: true
            Keys.onEscapePressed: { if (panel.musicMode) panel.musicMode = false; else BarState.closeCalendar(); }
            Keys.onLeftPressed: BarState.moveDay(-1)
            Keys.onRightPressed: BarState.moveDay(1)
            Keys.onUpPressed: BarState.moveDay(-7)
            Keys.onDownPressed: BarState.moveDay(7)
            Keys.onPressed: event => {
                if (event.key === Qt.Key_PageUp) { BarState.moveMonth(-1); event.accepted = true; }
                else if (event.key === Qt.Key_PageDown) { BarState.moveMonth(1); event.accepted = true; }
                else if (event.key === Qt.Key_Home) { BarState.today(); event.accepted = true; }
            }
            ColumnLayout {
                visible: !panel.musicMode
                opacity: Math.max(0, Math.min(1, (panel.progress - 0.18) / 0.65))
                enabled: panel.progress > 0.8
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12
                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        Item { Layout.fillWidth: true; Layout.preferredHeight: morphClock.implicitHeight }
                        Shell.GlassText { Layout.fillWidth: true; text: clock.date.toLocaleDateString(Shell.Theme.locale, Shell.Theme.tr("dddd, d 'de' MMMM", "dddd, MMMM d")); color: Shell.Theme.muted; font.pixelSize: 12 }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Shell.ActionButton { text: "‹"; implicitWidth: 36; font.pixelSize: 22; onClicked: BarState.moveMonth(-1); tooltipText: Shell.Theme.tr("Mês anterior · Page Up", "Previous month · Page Up") }
                    Shell.GlassText {
                        Layout.fillWidth: true
                        text: {
                            const label = new Date(BarState.year, BarState.month, 1, 12).toLocaleDateString(Shell.Theme.locale, "MMMM yyyy");
                            return label.charAt(0).toLocaleUpperCase() + label.slice(1);
                        }
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                    }
                    Shell.ActionButton { text: "›"; implicitWidth: 36; font.pixelSize: 22; onClicked: BarState.moveMonth(1); tooltipText: Shell.Theme.tr("Próximo mês · Page Down", "Next month · Page Down") }
                }
                GridLayout {
                    columns: 7
                    rowSpacing: 4
                    columnSpacing: 4
                    uniformCellWidths: true
                    Layout.fillWidth: true
                    Repeater {
                        model: Shell.Theme.tr(["Seg", "Ter", "Qua", "Qui", "Sex", "Sáb", "Dom"], ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"])
                        delegate: Shell.GlassText {
                            required property string modelData
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData
                            color: Shell.Theme.muted
                            font.pixelSize: 11
                            Layout.bottomMargin: 6
                        }
                    }
                    Repeater {
                        model: BarState.cells(clock.date)
                        delegate: Button {
                            id: dayButton
                            required property var modelData
                            Layout.fillWidth: true
                            implicitWidth: 36
                            implicitHeight: 32
                            hoverEnabled: true
                            onClicked: { BarState.selectDate(modelData.date); keyboard.forceActiveFocus(); }
                            background: Rectangle {
                                radius: 9
                                color: dayButton.modelData.selected ? "#40ffffff" : dayButton.hovered ? Shell.Theme.hover : "transparent"
                                border.color: Shell.Theme.dark ? "transparent" : (dayButton.modelData.today ? "#a0ffffff" : "transparent")
                            }
                            contentItem: Shell.GlassText {
                                text: dayButton.modelData.day
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                color: dayButton.modelData.currentMonth ? Shell.Theme.text : "#55ffffff"
                                font.weight: dayButton.modelData.today ? Font.Bold : Font.Normal
                                font.pixelSize: 13
                            }
                            Accessible.name: modelData.date.toLocaleDateString(Shell.Theme.locale, Shell.Theme.tr("dddd, d 'de' MMMM 'de' yyyy", "dddd, MMMM d, yyyy"))
                        }
                    }
                }
                Shell.MediaCard { Layout.fillWidth: true; Layout.preferredHeight: 124; onOpenRequested: panel.musicMode = true }
                RowLayout {
                    Layout.fillWidth: true
                    Shell.GlassText {
                        Layout.fillWidth: true
                        text: BarState.selectedDate.toLocaleDateString(Shell.Theme.locale, Shell.Theme.tr("dd/MM/yyyy", "MM/dd/yyyy"))
                        color: Shell.Theme.muted
                        font.pixelSize: 12
                    }
                    Shell.ActionButton { text: Shell.Theme.tr("Hoje", "Today"); onClicked: BarState.today(); tooltipText: Shell.Theme.tr("Voltar para hoje · Home", "Back to today · Home") }
                }
            }
        }
        Loader {
            id: musicLoader
            anchors.fill: parent
            anchors.margins: 18
            active: panel.musicMode && panel.visible
            property real reveal: 0
            onActiveChanged: { reveal = 0; if (active) revealAnimation.restart(); }
            NumberAnimation { id: revealAnimation; target: musicLoader; property: "reveal"; to: 1; duration: 420; easing.type: Easing.OutCubic }
            source: "../MusicView.qml"
            onLoaded: item.back.connect(() => panel.musicMode = false)
            opacity: reveal * Math.max(0, Math.min(1, (panel.progress - 0.18) / 0.65))
        }
        Shell.GlassText {
            id: morphClock
            visible: !panel.musicMode
            text: Qt.formatDateTime(clock.date, "HH:mm")
            font.pixelSize: 27
            font.weight: Font.DemiBold
            color: "#ffffff"
            transformOrigin: Item.TopLeft
            scale: (13 + 14 * panel.progress) / 27
            x: ((surface.width - implicitWidth * scale) / 2) * (1 - panel.progress) + 18 * panel.progress
            y: ((30 - implicitHeight * scale) / 2) * (1 - panel.progress) + 18 * panel.progress
            MouseArea { anchors.fill: parent; onClicked: BarState.toggleCalendar(panel.outputName) }
        }
        WheelHandler { enabled: !panel.musicMode; onWheel: event => { BarState.moveMonth(event.angleDelta.y > 0 ? -1 : 1); event.accepted = true; } }
    }
    SystemClock { id: clock; precision: SystemClock.Minutes }
}

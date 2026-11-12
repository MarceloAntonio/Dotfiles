pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import ".." as Shell
import "../widgets" as Widgets

PanelWindow {
    id: panel
    required property string outputName
    visible: Settings.opened && (Settings.screenName === outputName || !!Settings.pending)
    color: "transparent"
    implicitWidth: Math.min(1020, screen.width - 40)
    implicitHeight: Math.min(600, screen.height - 72)
    anchors.top: true
    margins.top: Math.max(20, Math.round((screen.height - implicitHeight)/2))
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "qs-monitors"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    mask: Region { item: surface; radius: 18 }
    BackgroundEffect.blurRegion: Region { item: surface; radius: 18 }
    onVisibleChanged: { if (visible) focusDelay.restart(); else grab.active = false; }
    Timer { id: focusDelay; interval: 100; onTriggered: if (panel.visible) { grab.active = true; keys.forceActiveFocus(); } }
    HyprlandFocusGrab {
        id: grab
        windows: [panel]
        onCleared: if (panel.visible && !Settings.pending && !Settings.busy && !focusDelay.running) Settings.close()
    }
    IpcHandler {
        target: "monitors-ui-" + panel.outputName
        function capture(path: string): void { if (panel.visible) surface.grabToImage(result => result.saveToFile(path)); }
    }
    component Select: ComboBox {
        id: select
        implicitHeight: 38
        font.family: Shell.Theme.font
        font.pixelSize: 13
        contentItem: Shell.GlassText { text: select.displayText; leftPadding: 12; rightPadding: 24; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
        indicator: Shell.GlassText { x: select.width - width - 10; y: (select.height-height)/2; text: "⌄"; color: Shell.Theme.muted; font.pixelSize: 16 }
        background: Rectangle { radius: 10; color: Shell.Theme.card; border.color: select.activeFocus ? Shell.Theme.selected : Shell.Theme.border }
        delegate: ItemDelegate {
            required property var modelData
            width: select.width
            text: String(modelData)
            contentItem: Shell.GlassText { text: parent.text; verticalAlignment: Text.AlignVCenter }
            background: Rectangle { color: highlighted ? Shell.Theme.selected : "transparent"; radius: 6 }
        }
        popup: Popup {
            y: select.height + 4
            width: select.width
            implicitHeight: Math.min(260, contentItem.implicitHeight + 12)
            padding: 6
            background: Rectangle { radius: 12; color: Shell.Theme.tooltip; border.color: Shell.Theme.border }
            contentItem: ListView { clip: true; implicitHeight: contentHeight; model: select.popup.visible ? select.delegateModel : null; currentIndex: select.highlightedIndex; ScrollBar.vertical: Widgets.GlassScrollBar {} }
        }
    }
    Rectangle {
        id: surface
        anchors.fill: parent
        radius: 18
        color: Qt.rgba(Shell.Theme.background.r, Shell.Theme.background.g, Shell.Theme.background.b, 0.94)
        border.color: Shell.Theme.border
        clip: true
        FocusScope {
            id: keys
            anchors.fill: parent
            Keys.onEscapePressed: { if (Settings.pending) Settings.revert(); else Settings.close(); }
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 22; spacing: 14
                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        Layout.fillWidth: true
                        Shell.GlassText { text: "Monitores"; font.pixelSize: 23; font.weight: Font.DemiBold }
                        Shell.GlassText { text: "Arraste as telas para organizar sua posição."; color: Shell.Theme.muted; font.pixelSize: 12 }
                    }
                    Item { Layout.fillWidth: true }
                    Shell.ActionButton { text: "󰑐"; font.family: Shell.Theme.icons; enabled: !Settings.busy && !Settings.pending; onClicked: Settings.refresh(); tooltipText: "Atualizar monitores" }
                    Shell.ActionButton { text: "×"; enabled: !Settings.pending && !Settings.busy; onClicked: Settings.close(); tooltipText: "Fechar · Esc" }
                }
                Rectangle {
                    id: map
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(170, Math.min(240, panel.height * 0.32))
                    radius: 14
                    color: Shell.Theme.card
                    clip: true
                    readonly property real minX: Math.min(0,...Settings.draft.map(m=>m.x))
                    readonly property real minY: Math.min(0,...Settings.draft.map(m=>m.y))
                    readonly property real totalWidth: Math.max(1,...Settings.draft.map(m=>m.x+Settings.dimensions(m).width))-minX
                    readonly property real totalHeight: Math.max(1,...Settings.draft.map(m=>m.y+Settings.dimensions(m).height))-minY
                    readonly property real ratio: Math.min((width-64)/totalWidth,(height-40)/totalHeight)
                    readonly property real offsetX: (width-totalWidth*ratio)/2
                    readonly property real offsetY: (height-totalHeight*ratio)/2
                    Repeater {
                        model: Settings.draft
                        delegate: Rectangle {
                            id: monitorTile
                            required property var modelData
                            readonly property var size: Settings.dimensions(modelData)
                            x: map.offsetX+(modelData.x-map.minX)*map.ratio
                            y: map.offsetY+(modelData.y-map.minY)*map.ratio
                            width: size.width*map.ratio
                            height: size.height*map.ratio
                            radius: 8
                            color: Settings.selectedName === modelData.name ? Shell.Theme.selected : Shell.Theme.card
                            border.width: 2
                            border.color: Settings.selectedName === modelData.name ? Shell.Theme.accent : Shell.Theme.border
                            Column {
                                anchors.centerIn: parent
                                width: parent.width - 12
                                spacing: 6
                                Shell.GlassText { width: parent.width; text: (Settings.primary === monitorTile.modelData.name ? "★  " : "") + monitorTile.modelData.name; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 14; font.weight: Font.DemiBold; elide: Text.ElideRight }
                                Shell.GlassText { width: parent.width; text: monitorTile.modelData.mode.replace("@"," · ") + " Hz"; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 11; color: Shell.Theme.muted; elide: Text.ElideRight }
                            }
                            MouseArea {
                                anchors.fill: parent
                                enabled: !Settings.busy && !Settings.pending
                                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                                drag.target: monitorTile
                                property real startX: 0
                                property real startY: 0
                                property bool adjusting: false
                                onPositionChanged: {
                                    if (!drag.active || adjusting) return;
                                    const logicalX = (monitorTile.x-map.offsetX)/map.ratio+map.minX;
                                    const logicalY = (monitorTile.y-map.offsetY)/map.ratio+map.minY;
                                    const position = Settings.constrain(monitorTile.modelData.name,logicalX,logicalY);
                                    adjusting = true;
                                    monitorTile.x = map.offsetX+(position.x-map.minX)*map.ratio;
                                    monitorTile.y = map.offsetY+(position.y-map.minY)*map.ratio;
                                    adjusting = false;
                                }
                                onPressed: { startX = monitorTile.x; startY = monitorTile.y; Settings.selectedName = monitorTile.modelData.name; }
                                onReleased: {
                                    if (Math.abs(monitorTile.x-startX)>1 || Math.abs(monitorTile.y-startY)>1) Settings.move(monitorTile.modelData.name,(monitorTile.x-map.offsetX)/map.ratio+map.minX,(monitorTile.y-map.offsetY)/map.ratio+map.minY);
                                }
                            }
                        }
                    }
                    Shell.GlassText { anchors.centerIn: parent; visible: !Settings.draft.length; text: Settings.busy ? "Carregando telas…" : "Nenhum monitor encontrado"; color: Shell.Theme.muted }
                }
                Flickable {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    contentWidth: width; contentHeight: details.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: Widgets.GlassScrollBar {}
                    ColumnLayout {
                        id: details
                        width: parent.width - 16
                        spacing: 12
                        enabled: !Settings.busy && !Settings.pending
                        RowLayout {
                            Layout.fillWidth: true
                            Select {
                                Layout.fillWidth: true
                                model: Settings.draft.map(m=>m.name)
                                currentIndex: model.indexOf(Settings.selectedName)
                                onActivated: Settings.selectedName = model[index]
                                Accessible.name: "Monitor selecionado"
                            }
                            Shell.ActionButton { text: Settings.selectedName === Settings.primary ? "★ Principal" : "Definir como principal"; selected: Settings.selectedName === Settings.primary; enabled: !!Settings.selected; onClicked: Settings.primary = Settings.selectedName }
                        }
                        Shell.GlassText { text: Settings.original?.description || ""; color: Shell.Theme.muted; Layout.fillWidth: true; elide: Text.ElideRight }
                        RowLayout {
                            Layout.fillWidth: true; spacing: 12
                            ColumnLayout {
                                Layout.fillWidth: true
                                Shell.GlassText { text: "Resolução"; color: Shell.Theme.muted; font.pixelSize: 12 }
                                Select { Layout.fillWidth: true; model: Settings.resolutions; currentIndex: model.indexOf(Settings.resolution); onActivated: Settings.changeResolution(model[index]); Accessible.name: "Resolução" }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                Shell.GlassText { text: "Frequência"; color: Shell.Theme.muted; font.pixelSize: 12 }
                                Select { Layout.fillWidth: true; model: Settings.rates.map(m=>m.refreshRate.toFixed(2)+" Hz"); currentIndex: Settings.rates.findIndex(m=>m.id===Settings.selected?.mode); onActivated: Settings.update({mode:Settings.rates[index].id}); Accessible.name: "Frequência em Hz" }
                            }
                            ColumnLayout {
                                Layout.preferredWidth: 110
                                Shell.GlassText { text: "Escala"; color: Shell.Theme.muted; font.pixelSize: 12 }
                                Select { Layout.fillWidth: true; model: ["100%","125%","150%","175%","200%"]; currentIndex: [1,1.25,1.5,1.75,2].indexOf(Settings.selected?.scale ?? 1); onActivated: Settings.update({scale:[1,1.25,1.5,1.75,2][index]}); Accessible.name: "Escala" }
                            }
                        }

                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: statusText.implicitHeight + 22
                    radius: 12
                    color: Settings.pending ? Shell.Theme.selected : Shell.Theme.card
                    visible: !!Settings.message || !!Settings.pending
                    Shell.GlassText { id: statusText; anchors { top: parent.top; left: parent.left; right: parent.right; margins: 11 } wrapMode: Text.Wrap; text: Settings.pending ? "Manter esta configuração? Reversão automática em " + Settings.secondsLeft + " s." : Settings.message; color: Settings.failed ? Shell.Theme.danger : Shell.Theme.text; font.pixelSize: 13 }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Shell.GlassText { Layout.fillWidth: true; text: Settings.pending ? "Confira a imagem nas telas." : "As alterações só são salvas após sua confirmação."; color: Shell.Theme.muted; font.pixelSize: 11; wrapMode: Text.Wrap }
                    Shell.ActionButton { visible: !!Settings.pending; text: "Reverter"; enabled: !Settings.busy; onClicked: Settings.revert() }
                    Shell.ActionButton { visible: !!Settings.pending; text: "Manter"; selected: true; enabled: !Settings.busy && Settings.secondsLeft>0; onClicked: Settings.confirm() }
                    Shell.ActionButton { visible: !Settings.pending; text: "Testar alterações"; selected: true; enabled: Settings.dirty && !Settings.busy && Settings.draft.length>0; onClicked: Settings.apply() }
                }
            }
        }
    }
}

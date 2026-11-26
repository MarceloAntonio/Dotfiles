pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import ".." as Shell
import "../widgets" as Widgets

PanelWindow {
    id: panel
    required property string outputName
    property bool initialFocusPending: false
    function focusGallery() {
        if (!gallery.count) { search.forceActiveFocus(); return; }
        const selectedIndex = Settings.filteredItems.findIndex(i => i.id === Settings.selectedId);
        gallery.currentIndex = selectedIndex >= 0 ? selectedIndex : 0;
        gallery.forceActiveFocus();
        Settings.selectedId = Settings.filteredItems[gallery.currentIndex].id;
        gallery.positionViewAtIndex(gallery.currentIndex, GridView.Contain);
    }
    function focusCategory(index) {
        const button = categoryButtons.itemAt(Math.max(0, Math.min(categoryButtons.count - 1, index)));
        if (button?.enabled) button.forceActiveFocus();
    }
    function focusCurrentCategory() {
        focusCategory(Settings.groups.findIndex(g => g.id === Settings.category));
    }
    function settleInitialFocus() {
        if (!visible || Settings.loading || !initialFocusPending) return;
        initialFocusPending = false;
        focusGallery();
    }
    visible: Settings.opened && !Settings.authenticating && Settings.screenName === outputName
    implicitWidth: Math.min(960, screen.width - 64)
    implicitHeight: Math.min(690, screen.height - 96)
    anchors.top: true
    margins.top: Math.round((screen.height - implicitHeight) / 2)
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "qs-personalize"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    BackgroundEffect.blurRegion: Region { item: surface; radius: 18 }
    onVisibleChanged: {
        if (!visible) grab.active = false;
        else {
            initialFocusPending = true;
            entrance.restart();
            Qt.callLater(() => { if (panel.visible) { grab.active = true; settleInitialFocus(); } });
        }
    }
    Connections {
        target: Settings
        function onOpenRequested() { panel.initialFocusPending = true; Qt.callLater(panel.settleInitialFocus); }
        function onLoadingChanged() { if (!Settings.loading) Qt.callLater(panel.settleInitialFocus); }
    }
    HyprlandFocusGrab {
        id: grab
        windows: [panel]
        onCleared: Qt.callLater(() => { if (panel.visible && !grab.active && !Settings.authenticating) Settings.close(); })
    }
    NumberAnimation { id: entrance; target: surface; property: "opacity"; from: 0; to: 1; duration: 150 }
    Rectangle {
        id: surface
        anchors.fill: parent
        anchors.margins: 3
        radius: 18
        color: Shell.Theme.background
        border.color: Shell.Theme.dark ? "transparent" : ("#28ffffff")
        clip: true
        FocusScope {
            anchors.fill: parent
            focus: true
            Keys.onPressed: event => {
                if (!(event.modifiers & Qt.ControlModifier)) return;
                if (event.key === Qt.Key_F) {
                    search.forceActiveFocus(); search.selectAll(); event.accepted = true;
                } else if (event.key === Qt.Key_R) {
                    Settings.refresh(); event.accepted = true;
                } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                    const direction = event.modifiers & Qt.ShiftModifier ? -1 : 1;
                    const index = Settings.groups.findIndex(g => g.id === Settings.category);
                    panel.focusCategory((index + direction + Settings.groups.length) % Settings.groups.length);
                    panel.focusGallery(); event.accepted = true;
                }
            }
            Keys.onEscapePressed: {
                if (search.text.length > 0) Settings.query = "";
                else Settings.close();
            }
            RowLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 20
                ColumnLayout {
                    Layout.preferredWidth: 190
                    Layout.minimumWidth: 190
                    Layout.maximumWidth: 190
                    Layout.fillHeight: true
                    spacing: 10
                    Shell.GlassText {
                        text: "󰏘   " + Shell.Theme.tr("Personalizar", "Customize")
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                        Layout.bottomMargin: 16
                    }
                    Shell.GlassText { text: Shell.Theme.tr("Tema da interface", "Interface theme"); color: Shell.Theme.muted; font.pixelSize: 12 }
                    RowLayout {
                        Layout.fillWidth: true
                        Shell.ActionButton { Layout.fillWidth: true; text: Shell.Theme.tr("Claro", "Light"); selected: Shell.Theme.mode === "light"; onClicked: Shell.Theme.setMode("light") }
                        Shell.ActionButton { Layout.fillWidth: true; text: Shell.Theme.tr("Escuro", "Dark"); selected: Shell.Theme.mode === "dark"; onClicked: Shell.Theme.setMode("dark") }
        Shell.ActionButton { text: Shell.Theme.tr("Adaptativo", "Adaptive"); selected: Shell.Theme.adaptive; onClicked: Shell.Theme.setMode("wallpaper") }
                    }
                    Repeater {
                        id: categoryButtons
                        model: Settings.groups
                        delegate: Button {
                            id: categoryButton
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            implicitHeight: 74
                            padding: 12
                            enabled: !Settings.busy && modelData.available
                            hoverEnabled: true
                            onClicked: Settings.selectCategory(modelData.id)
                            onActiveFocusChanged: if (activeFocus && Settings.category !== modelData.id) Settings.selectCategory(modelData.id)
                            Keys.onUpPressed: panel.focusCategory(index - 1)
                            Keys.onDownPressed: panel.focusCategory(index + 1)
                            Keys.onRightPressed: panel.focusGallery()
                            Keys.onReturnPressed: panel.focusGallery()
                            Keys.onSpacePressed: panel.focusGallery()
                            background: Rectangle {
                                radius: 12
                                color: Settings.category === categoryButton.modelData.id ? Shell.Theme.selected : categoryButton.hovered ? Shell.Theme.hover : "transparent"
                                border.color: Shell.Theme.dark ? "transparent" : (categoryButton.activeFocus ? "#a0ffffff" : Settings.category === categoryButton.modelData.id ? "#30ffffff" : "transparent")
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }
                            contentItem: RowLayout {
                                spacing: 10
                                Shell.GlassText { text: categoryButton.modelData.icon; font.family: Shell.Theme.icons; font.pixelSize: 20 }
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 5
                                    Shell.GlassText { Layout.fillWidth: true; text: categoryButton.modelData.title; font.weight: Font.DemiBold }
                                    Shell.GlassText { Layout.fillWidth: true; text: categoryButton.modelData.currentName; font.pixelSize: 11; color: Shell.Theme.muted }
                                }
                            }
                        }
                    }
                    Item { Layout.fillHeight: true }
                    Shell.GlassText {
                        Layout.fillWidth: true
                        text: Shell.Theme.tr("Setas · Navegar\nEnter · Aplicar\nTab · Alternar áreas\nCtrl + F · Pesquisar", "Arrows · Navigate\nEnter · Apply\nTab · Switch areas\nCtrl + F · Search")
                        font.pixelSize: 11
                        lineHeight: 1.5
                        color: "#70ffffff"
                    }
                }
                Rectangle { Layout.fillHeight: true; implicitWidth: 1; color: Shell.Theme.border }
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    Layout.fillHeight: true
                    spacing: 14
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            spacing: 4
                            Shell.GlassText { text: Settings.group?.title ?? Shell.Theme.tr("Personalizar", "Customize"); font.pixelSize: 22; font.weight: Font.DemiBold }
                            Shell.GlassText { Layout.fillWidth: true; text: Settings.group?.description ?? Shell.Theme.tr("Carregando…", "Loading…"); font.pixelSize: 12; color: Shell.Theme.muted }
                        }
                        Shell.ActionButton {
                            text: "󰑐"
                            font.family: Shell.Theme.icons
                            font.pixelSize: 22
                            implicitWidth: 40
                            implicitHeight: 40
                            enabled: !Settings.busy && !Settings.loading
                            onClicked: Settings.refresh()
                            tooltipText: Shell.Theme.tr("Atualizar lista · Ctrl + R", "Refresh list · Ctrl + R")
                        }
                        Shell.ActionButton {
                            text: "×"
                            font.pixelSize: 22
                            implicitWidth: 40
                            implicitHeight: 40
                            onClicked: Settings.close()
                            tooltipText: Shell.Theme.tr("Fechar · Esc", "Close · Esc")
                        }
                    }
                    TextField {
                        id: search
                        Layout.fillWidth: true
                        placeholderText: Shell.Theme.tr("Pesquisar em ", "Search in ") + (Settings.group?.title.toLowerCase() ?? Shell.Theme.tr("personalização", "customization")) + "…"
                        color: Shell.Theme.text
                        placeholderTextColor: Shell.Theme.muted
                        font.family: Shell.Theme.font
                        font.pixelSize: 14
                        padding: 12
                        selectByMouse: true
                        enabled: !Settings.busy
                        text: Settings.query
                        onTextEdited: Settings.query = text
                        background: Rectangle { color: Shell.Theme.card; radius: 10; border.color: Shell.Theme.dark ? "transparent" : (search.activeFocus ? "#50ffffff" : Shell.Theme.border)}
                        onAccepted: {
                            panel.focusGallery();
                        }
                        Keys.onDownPressed: panel.focusGallery()
                    }
                    GridView {
                        id: gallery
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        cellWidth: Math.floor((width - (galleryScrollBar.visible ? 16 : 0)) / 3)
                        cellHeight: Settings.category === "kitty" ? 172 : 150
                        cacheBuffer: cellHeight
                        boundsBehavior: Flickable.StopAtBounds
                        model: Settings.filteredItems
                        currentIndex: -1
                        keyNavigationEnabled: true
                        activeFocusOnTab: true
                        highlightFollowsCurrentItem: true
                        ScrollBar.vertical: Widgets.GlassScrollBar { id: galleryScrollBar }
                        onCurrentIndexChanged: {
                            if (activeFocus && currentIndex >= 0) Settings.selectedId = Settings.filteredItems[currentIndex]?.id ?? "";
                        }
                        Keys.onReturnPressed: Settings.applySelection()
                        Keys.onSpacePressed: Settings.applySelection()
                        Keys.onLeftPressed: event => {
                            if (currentIndex <= 0 || currentIndex % 3 === 0) panel.focusCurrentCategory();
                            else event.accepted = false;
                        }
                        Keys.onPressed: event => {
                            let next = currentIndex;
                            if (event.key === Qt.Key_Home) next = 0;
                            else if (event.key === Qt.Key_End) next = count - 1;
                            else if (event.key === Qt.Key_PageDown) next += Math.max(1, Math.floor(height / cellHeight)) * 3;
                            else if (event.key === Qt.Key_PageUp) next -= Math.max(1, Math.floor(height / cellHeight)) * 3;
                            else return;
                            currentIndex = Math.max(0, Math.min(count - 1, next));
                            positionViewAtIndex(currentIndex, GridView.Contain);
                            event.accepted = true;
                        }
                        delegate: Item {
                            id: tile
                            required property var modelData
                            required property int index
                            width: gallery.cellWidth
                            height: gallery.cellHeight
                            readonly property bool selected: Settings.selectedId === modelData.id
                            readonly property bool applied: Settings.group?.current === modelData.id
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 4
                                radius: 12
                                color: tile.selected ? Shell.Theme.selected : hover.hovered ? Shell.Theme.hover : Shell.Theme.card
                                border.color: Shell.Theme.dark ? "transparent" : (tile.selected ? (gallery.activeFocus ? "#e0ffffff" : "#80ffffff") : Shell.Theme.border)
                                border.width: tile.selected ? 2 : 1
                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 7
                                    spacing: 7
                                    Preview { Layout.fillWidth: true; Layout.fillHeight: true; entry: tile.modelData }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Shell.GlassText { Layout.fillWidth: true; text: tile.modelData.name; font.pixelSize: 11 }
                                        Shell.GlassText { text: "✓"; visible: tile.applied; font.pixelSize: 12 }
                                    }
                                }
                                HoverHandler { id: hover }
                                TapHandler {
                                    enabled: !Settings.busy
                                    onTapped: { Settings.selectedId = tile.modelData.id; gallery.currentIndex = tile.index; gallery.forceActiveFocus(); }
                                    onDoubleTapped: {
                                        Settings.selectedId = tile.modelData.id;
                                        gallery.currentIndex = tile.index;
                                        gallery.forceActiveFocus();
                                        Settings.applySelection();
                                    }
                                }
                                Widgets.HoverTip {
                                    visible: hover.hovered
                                    delay: 800
                                    text: tile.modelData.name + (tile.applied ? Shell.Theme.tr(" · Aplicado", " · Applied") : "")
                                }
                            }
                        }
                        Shell.GlassText {
                            anchors.centerIn: parent
                            visible: gallery.count === 0
                            text: Settings.loading ? Shell.Theme.tr("Carregando…", "Loading…") : Settings.query ? Shell.Theme.tr("Nenhum resultado para essa busca", "No results for this search") : Shell.Theme.tr("Nenhuma opção disponível", "No options available")
                            color: Shell.Theme.muted
                        }
                    }
                    Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Shell.Theme.border }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        spacing: 12
                        Preview {
                            Layout.preferredWidth: 110
                            Layout.preferredHeight: 70
                            entry: Settings.selected
                            visible: !!Settings.selected
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            spacing: 6
                            Shell.GlassText { Layout.fillWidth: true; text: Settings.selected?.name ?? Shell.Theme.tr("Selecione uma opção", "Select an option"); font.weight: Font.DemiBold }
                            Shell.GlassText {
                                Layout.fillWidth: true
                                text: Settings.message || (Settings.selectedId === Settings.group?.current ? Shell.Theme.tr("Aplicado atualmente", "Currently applied") : Settings.category === "sddm" ? Shell.Theme.tr("Será usado na próxima tela de login", "Will be used on the next login screen") : Shell.Theme.tr("Selecione e clique em Aplicar", "Select and click Apply"))
                                color: Settings.failed ? Shell.Theme.danger : Shell.Theme.muted
                                font.pixelSize: 12
                                wrapMode: Text.Wrap
                                maximumLineCount: 3
                            }
                        }
                        Shell.ActionButton {
                            text: Settings.busy ? Shell.Theme.tr("Aplicando…", "Applying…") : Settings.selectedId === Settings.group?.current ? Shell.Theme.tr("Aplicado  ✓", "Applied  ✓") : Shell.Theme.tr("Aplicar", "Apply")
                            selected: true
                            enabled: !!Settings.selected && !Settings.busy && Settings.selectedId !== Settings.group?.current
                            implicitHeight: 42
                            onClicked: Settings.applySelection()
                        }
                    }
                }
            }
        }
    }
}

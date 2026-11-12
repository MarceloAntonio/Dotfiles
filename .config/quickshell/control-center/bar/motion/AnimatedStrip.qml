pragma ComponentBehavior: Bound
import QtQuick
import QtQml.Models
import ".." as DesktopBar
import "../.." as Shell

Item {
    id: strip
    required property string kind
    required property string outputName
    property var entries: []
    readonly property int duration: 420
    property string lastSignature: ""
    property bool initialized: false
    implicitWidth: row.implicitWidth
    implicitHeight: 24

    // Animate toward the final layout once per selection change. Following a
    // slot's animated x/width restarted the highlight animation every frame,
    // causing a visible pause followed by a slow chase of the selected item.
    readonly property var selection: {
        let offset = 0;
        for (const entry of entries) {
            if (entry.active) return { x: offset + 1, width: Math.max(0, entry.span - 2) };
            offset += entry.span;
        }
        return null;
    }
    Rectangle {
        id: activeHighlight
        x: strip.selection ? strip.selection.x : 0
        width: strip.selection ? strip.selection.width : 0
        height: 24
        radius: 9
        color: Shell.Theme.barSelected
        opacity: strip.selection ? 1 : 0
        Behavior on x {
            enabled: activeHighlight.opacity > 0.99
            NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
        }
        Behavior on width {
            enabled: activeHighlight.opacity > 0.99
            NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
        }
        Behavior on opacity { NumberAnimation { duration: 160 } }
    }

    // Keep delegates by key, including a disappearing item's visual snapshot.
    // A closed window may already have destroyed its live QObject at this point.
    function sync() {
        const signature = JSON.stringify(entries);
        if (signature === lastSignature) return;
        lastSignature = signature;
        const keys = entries.map(e => e.key);
        for (let i = 0; i < entriesModel.count; i++) {
            entriesModel.setProperty(i, "leaving", !keys.includes(entriesModel.get(i).key));
        }
        let position = 0;
        for (const entry of entries) {
            while (position < entriesModel.count && entriesModel.get(position).leaving) position++;
            let existing = -1;
            for (let i = 0; i < entriesModel.count; i++) {
                if (entriesModel.get(i).key === entry.key) { existing = i; break; }
            }
            if (existing < 0) entriesModel.insert(position, {key: entry.key, entry: entry, span: entry.span, leaving: false});
            else {
                if (existing !== position) entriesModel.move(existing, position, 1);
                entriesModel.set(position, {key: entry.key, entry: entry, span: entry.span, leaving: false});
            }
            position++;
        }
    }
    function forget(key) {
        for (let i = 0; i < entriesModel.count; i++) {
            if (entriesModel.get(i).key === key && entriesModel.get(i).leaving) { entriesModel.remove(i); return; }
        }
    }
    onEntriesChanged: if (initialized) sync()
    Component.onCompleted: { initialized = true; sync(); }
    ListModel { id: entriesModel }
    Row {
        id: row
        spacing: 0
        Repeater {
            id: items
            model: entriesModel
            delegate: Item {
                id: slot
                required property string key
                required property var entry
                required property real span
                required property bool leaving
                property bool ready: false
                width: ready && !leaving ? span : 0
                height: 24
                opacity: ready && !leaving ? 1 : 0
                clip: true
                Component.onCompleted: ready = true
                Behavior on width {
                    NumberAnimation { duration: strip.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.4, 0, 0.2, 1, 1, 1] }
                }
                Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.InOutQuad } }
                Timer {
                    interval: strip.duration + 30
                    running: slot.leaving
                    onTriggered: strip.forget(slot.key)
                }
                Loader {
                    anchors.fill: parent
                    property var entry: slot.entry
                    property bool leaving: slot.leaving
                    opacity: slot.opacity > 0 ? 1 : 0
                    scale: 0.94 + 0.06 * slot.opacity
                    sourceComponent: strip.kind === "workspaces" ? workspaceDelegate : taskDelegate
                }
            }
        }
    }
    Component {
        id: workspaceDelegate
        DesktopBar.BarButton {
            readonly property var snapshot: parent.entry
            width: Math.max(0, parent.width - 2)
            anchors.centerIn: parent
            opacity: 1
            enabled: !parent.leaving
            text: String(snapshot.id)
            selected: false
            urgent: snapshot.urgent
            textColor: snapshot.active ? "#ffffff" : "#73ffffff"
            tooltipText: "Workspace " + snapshot.id + " · " + strip.outputName
            onClicked: DesktopBar.BarState.activateWorkspace(strip.outputName, snapshot.id)
        }
    }
    Component {
        id: taskDelegate
        DesktopBar.BarButton {
            id: taskButton
            readonly property var snapshot: parent.entry
            width: Math.max(0, parent.width - 2)
            anchors.centerIn: parent
            opacity: 1
            enabled: !parent.leaving
            selected: false
            tooltipText: snapshot.title
            onClicked: {
                const window = DesktopBar.BarState.tasks(strip.outputName).find(w => String(w.address) === snapshot.key);
                DesktopBar.BarState.closePanels();
                if (window?.wayland) window.wayland.activate();
            }
            onMiddleClicked: {
                const window = DesktopBar.BarState.tasks(strip.outputName).find(w => String(w.address) === snapshot.key);
                DesktopBar.BarState.closePanels();
                if (window?.wayland) window.wayland.close();
            }
            contentItem: Item {
                implicitWidth: 18
                implicitHeight: 18
                Image {
                    id: appIcon
                    anchors.centerIn: parent
                    width: 18; height: 18
                    source: taskButton.snapshot.icon
                    asynchronous: true
                    sourceSize: Qt.size(36, 36)
                    fillMode: Image.PreserveAspectFit
                }
                Shell.GlassText {
                    anchors.centerIn: parent
                    visible: !taskButton.snapshot.icon || appIcon.status !== Image.Ready
                    text: "󰣆"
                    font.family: Shell.Theme.icons
                    font.pixelSize: 17
                }
            }
        }
    }
}

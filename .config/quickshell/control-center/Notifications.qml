pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Hyprland
import "bar" as DesktopBar

Scope {
    id: root
    property alias dnd: settings.dnd
    property var popupIds: []
    property string popupScreen: ""
    readonly property var items: server.trackedNotifications.values.slice().sort((a, b) => b.id - a.id)
    readonly property int count: items.length
    readonly property var popups: items.filter(n => popupIds.includes(n.id)).slice(0, 3)
    PersistentProperties {
        id: settings
        reloadableId: "notification-settings"
        property bool dnd: false
    }

    function hidePopup(notification) {
        popupIds = popupIds.filter(id => id !== notification.id);
        if (notification.transient) notification.expire();
    }
    function dismiss(notification) {
        popupIds = popupIds.filter(id => id !== notification.id);
        notification.dismiss();
    }
    function clear() {
        popupIds = [];
        items.slice().forEach(n => n.dismiss());
    }
    function invoke(notification, action) {
        popupIds = popupIds.filter(id => id !== notification.id);
        action.invoke();
    }
    function primaryAction(notification) {
        const actions = notification.actions;
        return actions.find(a => a.identifier === "default")
            || actions.find(a => ["activate", "open"].includes(a.identifier.toLowerCase()))
            || actions.find(a => ["activate", "active", "ativar", "open", "abrir"].includes(a.text.trim().toLowerCase()))
            || null;
    }
    function normalizeApp(name) { return String(name || "").toLowerCase().replace(/\.desktop$/, ""); }
    function applicationEntry(notification) {
        if (notification.desktopEntry) return DesktopEntries.heuristicLookup(notification.desktopEntry);
        const name = normalizeApp(notification.appName);
        return DesktopEntries.applications.values.find(e => normalizeApp(e.name) === name || normalizeApp(e.id) === name) ?? null;
    }
    function applicationWindow(notification) {
        const entry = applicationEntry(notification);
        const names = [notification.desktopEntry, notification.appName, entry?.id, entry?.name].filter(Boolean).map(normalizeApp);
        return Hyprland.toplevels.values.find(window => {
            const appId = window.wayland?.appId || window.lastIpcObject?.class || "";
            const desktop = DesktopEntries.heuristicLookup(appId);
            return [appId, desktop?.id, desktop?.name].some(name => name && names.includes(normalizeApp(name)));
        }) ?? null;
    }
    function activate(notification, popup) {
        const action = primaryAction(notification);
        if (action) {
            DesktopBar.BarState.closePanels();
            invoke(notification, action);
            return;
        }
        const window = applicationWindow(notification);
        const entry = applicationEntry(notification);
        if (window?.wayland || entry) {
            DesktopBar.BarState.closePanels();
            if (window?.wayland) window.wayland.activate();
            else entry.execute();
            dismiss(notification);
        } else if (popup) Service.open("notificacoes");
    }
    onDndChanged: if (dnd) popupIds = []
    Connections {
        target: Service
        function onOpenedChanged() { if (Service.opened) root.popupIds = []; }
    }
    NotificationServer {
        id: server
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        actionsSupported: true
        imageSupported: true
        onNotification: notification => {
            notification.tracked = true;
            if (!notification.lastGeneration && !root.dnd && !Service.opened) {
                root.popupScreen = Service.focusedScreen();
                root.popupIds = [notification.id, ...root.popupIds.filter(id => id !== notification.id)].slice(0, 3);
            }
            // Bound the session history while retaining live action objects.
            Qt.callLater(() => root.items.slice(100).forEach(n => n.dismiss()));
        }
    }
    IpcHandler {
        target: "notifications"
        function toggleDnd(): void { root.dnd = !root.dnd; }
        function clear(): void { root.clear(); }
        function status(): string {
            return JSON.stringify({ count: root.count, dnd: root.dnd, popups: root.popups.map(n => ({id: n.id, timeout: n.expireTimeout})) });
        }
    }
}

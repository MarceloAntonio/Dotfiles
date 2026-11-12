pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Networking
import ".." as Shell
import "../personalize" as Personalize

Scope {
    id: root
    property bool overviewOpened: false
    property string overviewScreen: ""
    property bool commandsOpened: false
    property string commandsScreen: ""
    property bool enabled: true
    property var bars: ({})
    property var calendars: ({})
    function registerCalendar(output, window) { calendars = Object.assign({}, calendars, {[output]: window}); }
    function unregisterCalendar(output, window) {
        if (calendars[output] !== window) return;
        const next = Object.assign({}, calendars);
        delete next[output];
        calendars = next;
    }
    function registerBar(output, window) { bars = Object.assign({}, bars, {[output]: window}); }
    function unregisterBar(output, window) {
        if (bars[output] !== window) return;
        const next = Object.assign({}, bars);
        delete next[output];
        bars = next;
    }
    property bool calendarOpened: false
    property string calendarScreen: ""
    property date selectedDate: new Date()
    property int month: new Date().getMonth()
    property int year: new Date().getFullYear()
    property var resolvedIcons: ({})
    property var taskOrder: []
    property string lastIconRequest: ""
    readonly property string iconNames: JSON.stringify([...new Set(Hyprland.toplevels.values.map(t => iconName(t)))].sort())
    readonly property string windowAddresses: JSON.stringify(Hyprland.toplevels.values.map(t => t.address))
    readonly property var wired: Networking.devices.values.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property var wifiNetwork: Shell.Service.networks.find(n => n.connected) ?? null
    readonly property string networkIcon: wired ? "󰈀" : wifiNetwork ? "" : "󰤮"
    readonly property string audioIcon: Shell.Service.sink?.audio?.muted ? ""
        : Shell.Service.sink?.name?.startsWith("bluez") ? ""
        : ["headphone", "headset"].includes(Shell.Service.sink?.properties["device.form-factor"]) ? "" : ""
    readonly property string networkDescription: wired ? "Ethernet · " + wired.name : wifiNetwork ? wifiNetwork.name + " · " + Math.round(wifiNetwork.signalStrength * 100) + "%" : "Rede desconectada"
    property string ethernetAddress: ""
    onWiredChanged: {
        ethernetAddress = "";
        if (wired) Qt.callLater(readEthernetAddress);
    }
    function readEthernetAddress() {
        if (wired && !ethernetProcess.running) ethernetProcess.exec(["nmcli", "-g", "IP4.ADDRESS", "device", "show", wired.name]);
    }
    Timer { interval: 30000; running: !!root.wired; repeat: true; onTriggered: root.readEthernetAddress() }
    Process {
        id: ethernetProcess
        stdout: StdioCollector { onStreamFinished: root.ethernetAddress = text.trim().split("\n")[0].split("/")[0] }
    }

    function monitor(name) { return Hyprland.monitors.values.find(m => m.name === name) ?? null; }
    function workspaceIds(name) {
        const outputs = Quickshell.screens.map(s => s.name);
        let ids;
        if (outputs.length === 1) ids = Array.from({length: 10}, (_, i) => i + 1);
        else if (name === "HDMI-A-1") ids = [1, 2, 3, 4, 5];
        else if (name === "eDP-1") ids = [6, 7, 8, 9, 10];
        else ids = Hyprland.workspaces.values.filter(w => w.monitor?.name === name && w.id > 0).map(w => w.id);
        // Preserve access to additional workspaces beyond the configured ranges.
        const extra = Hyprland.workspaces.values.filter(w => w.monitor?.name === name && w.id > 10).map(w => w.id);
        return [...new Set([...ids, ...extra])].sort((a, b) => a - b);
    }
    function workspace(id) { return Hyprland.workspaces.values.find(w => w.id === id) ?? null; }
    function visibleWorkspaces(name) { return workspaceIds(name).filter(id => workspace(id) || monitor(name)?.activeWorkspace?.id === id); }
    function tasks(name) {
        return Hyprland.toplevels.values.filter(t => t.monitor?.name === name).slice().sort((a, b) => {
            const ai = taskOrder.indexOf(String(a.address).toLowerCase().replace(/^0x/, ""));
            const bi = taskOrder.indexOf(String(b.address).toLowerCase().replace(/^0x/, ""));
            return (ai < 0 ? 10000 : ai) - (bi < 0 ? 10000 : bi);
        });
    }
    function activateWorkspace(name, id) {
        if (!workspaceIds(name).includes(id)) return;
        closePanels();
        Hyprland.dispatch(Hyprland.usingLua ? "hl.dsp.focus({ workspace = " + id + " })" : "workspace " + id);
    }
    function iconName(toplevel) {
        const appId = toplevel.wayland?.appId || toplevel.lastIpcObject?.class || "";
        const entry = DesktopEntries.heuristicLookup(appId);
        return entry?.icon || appId;
    }
    function iconFor(toplevel) {
        const icon = iconName(toplevel);
        if (!icon) return "";
        if (resolvedIcons[icon]) return resolvedIcons[icon];
        if (icon.startsWith("/")) return "file://" + icon;
        if (icon.startsWith("file:")) return icon;
        return Quickshell.hasThemeIcon(icon) ? Quickshell.iconPath(icon) : "";
    }
    onIconNamesChanged: iconRefresh.restart()
    onWindowAddressesChanged: iconRefresh.restart()
    Timer {
        id: iconRefresh
        interval: 100
        onTriggered: {
            const signature = root.iconNames + "|" + root.windowAddresses;
            if (signature === root.lastIconRequest) return;
            if (iconProcess.running) { restart(); return; }
            root.lastIconRequest = signature;
            iconProcess.exec(["python", Quickshell.shellDir + "/bar/icons.py", root.iconNames]);
        }
    }
    Process {
        id: iconProcess
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    root.resolvedIcons = Object.assign({}, root.resolvedIcons, data.icons);
                    const known = root.taskOrder.filter(id => data.order.includes(id));
                    root.taskOrder = [...known, ...data.order.filter(id => !known.includes(id))];
                }
                catch (e) { console.warn("Taskbar icons:", e); }
            }
        }
    }
    function openControl(tab, output, source) {
        closeCalendar();
        const bar = bars[output];
        const same = Shell.Service.opened && Shell.Service.screenName === output && bar?.controlSource === source;
        if (bar && source) bar.controlSource = source;
        if (same) Shell.Service.close();
        else Shell.Service.open(tab);
        if (Shell.Service.opened) Shell.Service.screenName = output;
    }
    function power(action, output) {
        closeCalendar();
        Shell.Service.open("energia");
        Shell.Service.screenName = output;
        Shell.Service.confirmation = action;
    }
    function toggleCalendar(output) {
        if (calendarOpened && calendarScreen === output) { closeCalendar(); return; }
        Shell.Service.close();
        Personalize.Settings.close();
        calendarScreen = Quickshell.screens.some(s => s.name === output) ? output : Shell.Service.focusedScreen();
        today();
        calendarOpened = true;
    }
    function closeCalendar() { calendarOpened = false; }
    function closePanels() { Shell.Service.powerOpened = false; closeCalendar(); Shell.Service.close(); Personalize.Settings.close(); }
    function today() {
        const now = new Date();
        selectedDate = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 12);
        month = selectedDate.getMonth();
        year = selectedDate.getFullYear();
    }
    function selectDate(date) {
        selectedDate = date;
        month = date.getMonth();
        year = date.getFullYear();
    }
    function moveMonth(delta) {
        const next = new Date(year, month + delta, 1, 12);
        const last = new Date(next.getFullYear(), next.getMonth() + 1, 0, 12).getDate();
        selectDate(new Date(next.getFullYear(), next.getMonth(), Math.min(selectedDate.getDate(), last), 12));
    }
    function moveDay(delta) {
        selectDate(new Date(selectedDate.getFullYear(), selectedDate.getMonth(), selectedDate.getDate() + delta, 12));
    }
    function cells(todayDate) {
        const first = new Date(year, month, 1, 12);
        const offset = (first.getDay() + 6) % 7;
        return Array.from({length: 42}, (_, i) => {
            const date = new Date(year, month, i - offset + 1, 12);
            return {date: date, day: date.getDate(), currentMonth: date.getMonth() === month,
                today: sameDate(date, todayDate), selected: sameDate(date, selectedDate)};
        });
    }
    function sameDate(a, b) { return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate(); }
    Connections {
        target: Shell.Service
        function onOpenedChanged() { if (Shell.Service.opened) root.closeCalendar(); }
    }
    Connections {
        target: Personalize.Settings
        function onOpenedChanged() { if (Personalize.Settings.opened) root.closeCalendar(); }
    }
    Connections {
        target: Quickshell
        function onScreensChanged() { if (!Quickshell.screens.some(s => s.name === root.calendarScreen)) root.closeCalendar(); }
    }
    IpcHandler {
        target: "bar"
        function enable(): void { root.enabled = true; }
        function disable(): void { root.enabled = false; root.closeCalendar(); }
        function activate(output: string, workspace: int): void { root.activateWorkspace(output, workspace); }
        function status(): string {
            return JSON.stringify({ enabled: root.enabled, iconsReady: Object.keys(root.resolvedIcons).length, monitors: Quickshell.screens.map(s => ({name: s.name,
                workspaces: root.workspaceIds(s.name), visibleWorkspaces: root.visibleWorkspaces(s.name), active: root.monitor(s.name)?.activeWorkspace?.id ?? 0,
                tasks: root.tasks(s.name).length, tasksWithHandles: root.tasks(s.name).filter(t => !!t.wayland).length,
                workspaceWidth: root.bars[s.name]?.workspaceExtent ?? 0, taskWidth: root.bars[s.name]?.taskExtent ?? 0})), calendar: root.calendarOpened });
        }
    }
    IpcHandler {
        target: "calendar"
        function toggle(output: string): void { root.toggleCalendar(output); }
        function close(): void { root.closeCalendar(); }
        function music(): void {
            const output = root.calendarScreen || Shell.Service.focusedScreen();
            if (!root.calendarOpened) root.toggleCalendar(output);
            if (root.calendars[output]) root.calendars[output].musicMode = true;
        }
        function shift(delta: int): void { root.moveMonth(delta); }
        function today(): void { root.today(); }
        function status(): string {
            return JSON.stringify({opened: root.calendarOpened, screen: root.calendarScreen, month: root.month + 1,
                year: root.year, selected: root.selectedDate.toLocaleDateString(Qt.locale("pt_BR"), "yyyy-MM-dd"), cells: root.cells(new Date()).length,
                daysInMonth: new Date(root.year, root.month + 1, 0, 12).getDate(),
                progress: root.calendars[root.calendarScreen]?.progress ?? 0, presented: root.calendars[root.calendarScreen]?.visible ?? false});
        }
    }
}

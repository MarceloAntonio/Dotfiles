pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import ".." as Shell

Scope {
    id: root
    property bool opened: false
    property string screenName: ""
    property string category: "wallpaper"
    property string query: ""
    property string selectedId: ""
    property var groups: []
    property string message: ""
    property bool failed: false
    property bool authenticating: false
    property var result: null
    readonly property bool loading: catalogProcess.running
    readonly property bool busy: applyProcess.running || authenticating
    readonly property var group: groups.find(g => g.id === category) ?? null
    readonly property var items: group?.items ?? []
    readonly property var filteredItems: items.filter(i => i.name.toLocaleLowerCase().includes(query.toLocaleLowerCase()))
    readonly property var selected: items.find(i => i.id === selectedId) ?? null
    signal openRequested()

    function open(tab) {
        Shell.Service.close();
        screenName = Shell.Service.focusedScreen();
        if (["wallpaper", "sddm", "fastfetch", "kitty"].includes(tab)) selectCategory(tab);
        message = "";
        opened = true;
        refresh();
        openRequested();
    }
    function close() { opened = false; }
    function selectCategory(tab) {
        if (busy) return;
        category = tab;
        query = "";
        selectedId = group?.current ?? "";
        message = "";
    }
    function refresh() {
        if (!catalogProcess.running && !busy) catalogProcess.exec(["python", Quickshell.shellDir + "/personalize/backend.py", "catalog"]);
    }
    function applySelection() {
        if (!selected || busy || selectedId === group.current) return;
        result = null;
        failed = false;
        message = category === "sddm" ? "Aguardando autenticação…" : "Aplicando…";
        authenticating = category === "sddm";
        applyProcess.exec(["python", Quickshell.shellDir + "/personalize/backend.py", "apply", category, selectedId]);
    }
    Process {
        id: catalogProcess
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    if (!data.groups) throw new Error(data.message || "Não foi possível listar suas configurações.");
                    root.groups = data.groups;
                    if (!root.items.some(i => i.id === root.selectedId)) root.selectedId = root.group?.current || root.items[0]?.id || "";
                } catch (e) { root.failed = true; root.message = String(e); }
            }
        }
    }
    Process {
        id: applyProcess
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.result = JSON.parse(text); }
                catch (e) { root.result = {ok: false, message: "Não foi possível concluir a alteração."}; }
            }
        }
        onExited: code => {
            root.authenticating = false;
            root.failed = code !== 0 || !root.result?.ok;
            root.message = root.result?.message || "Não foi possível concluir a alteração.";
            Qt.callLater(() => root.refresh());
        }
    }
    IpcHandler {
        target: "personalize"
        function open(category: string): void { root.open(category); }
        function close(): void { root.close(); }
        function status(): string {
            return JSON.stringify({opened: root.opened, category: root.category, screen: root.screenName,
                groups: root.groups.length, items: root.items.length, results: root.filteredItems.length, loading: root.loading, busy: root.busy, failed: root.failed,
                current: root.group?.currentName ?? "", selected: root.selected?.name ?? "", message: root.message});
        }
    }
}

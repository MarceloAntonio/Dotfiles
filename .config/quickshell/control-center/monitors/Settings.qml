pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import ".." as Shell
import "../bar" as DesktopBar
import "../personalize" as Personalize

Scope {
    id: root
    property bool opened: false
    property string screenName: ""
    property var monitors: []
    property var draft: []
    property string primary: ""
    property string selectedName: ""
    property string referenceName: ""
    property string message: ""
    property bool failed: false
    property var pending: null
    property double now: Date.now() / 1000
    property string operation: ""
    property var result: null
    readonly property bool busy: reader.running || writer.running
    readonly property int secondsLeft: pending ? Math.max(0, Math.ceil(pending.expiresAt - now)) : 0
    readonly property var selected: draft.find(m => m.name === selectedName) ?? null
    readonly property var original: monitors.find(m => m.name === selectedName) ?? null
    readonly property var resolutions: [...new Set((original?.modes ?? []).map(m => m.width + "×" + m.height))]
    readonly property string resolution: selected ? selected.mode.split("@")[0].replace("x", "×") : ""
    readonly property var rates: (original?.modes ?? []).filter(m => m.width + "×" + m.height === resolution)
    readonly property var references: draft.filter(m => m.name !== selectedName)
    readonly property bool dirty: JSON.stringify(draft) !== JSON.stringify(monitors.map(root.toDraft)) || primary !== (monitors.find(m => m.primary)?.name ?? "")
    function toDraft(m) { return {name:m.name, mode:m.mode, x:m.x, y:m.y, scale:m.scale, transform:m.transform ?? 0, disabled:m.disabled ?? false}; }
    function open() {
        DesktopBar.BarState.closePanels();
        DesktopBar.BarState.commandsOpened = false;
        DesktopBar.BarState.overviewOpened = false;
        Personalize.Settings.close();
        screenName = Shell.Service.focusedScreen();
        opened = true; message = ""; failed = false;
        refresh();
    }
    function close() { if (!pending && !busy) opened = false; }
    function refresh() {
        if (!busy) reader.exec(["python", Quickshell.shellDir + "/monitors/backend.py", "catalog"]);
    }
    function load(data) {
        monitors = data.monitors ?? [];
        draft = monitors.map(toDraft);
        primary = data.primary || monitors[0]?.name || "";
        if (!draft.some(m => m.name === selectedName)) selectedName = primary || draft[0]?.name || "";
        chooseReference();
        pending = data.pending ?? null;
        now = Date.now()/1000;
    }
    function chooseReference() {
        if (!references.some(m => m.name === referenceName)) referenceName = references[0]?.name || "";
    }
    onSelectedNameChanged: chooseReference()
    function update(values) {
        if (busy || pending || !selected) return;
        const next = Object.assign({},selected,values);
        const position = constrain(next.name,next.x,next.y,next);
        draft = draft.map(m => m.name === selectedName ? Object.assign({},next,position) : m);
    }
    function dimensions(m) {
        const size = m.mode.split("@")[0].split("x").map(Number);
        const rotated = [1,3,5,7].includes(m.transform ?? 0);
        return {width:Math.round(size[rotated?1:0]/m.scale),height:Math.round(size[rotated?0:1]/m.scale)};
    }
    function constrain(name,x,y,replacement) {
        const own = dimensions(replacement || draft.find(m=>m.name===name));
        const others = draft.filter(m=>m.name!==name && !m.disabled);
        const xs = [Math.round(x)], ys = [Math.round(y)];
        for (const other of others) {
            const size = dimensions(other);
            xs.push(other.x-own.width,other.x+size.width);
            ys.push(other.y-own.height,other.y+size.height);
        }
        let best = null, score = Infinity;
        for (const cx of xs) for (const cy of ys) {
            const overlap = others.some(other => {
                const size = dimensions(other);
                return cx < other.x+size.width && cx+own.width > other.x && cy < other.y+size.height && cy+own.height > other.y;
            });
            const distance = (cx-x)**2+(cy-y)**2;
            if (!overlap && distance<score) { best={x:cx,y:cy}; score=distance; }
        }
        return best || {x:selected?.x ?? 0,y:selected?.y ?? 0};
    }
    function move(name,x,y) {
        if (busy || pending) return;
        selectedName = name;
        const own = dimensions(selected);
        let nextX = Math.round(x/10)*10, nextY = Math.round(y/10)*10;
        for (const other of draft.filter(m=>m.name !== name)) {
            const size = dimensions(other);
            for (const edge of [other.x + size.width, other.x - own.width]) if (Math.abs(nextX-edge)<80) nextX=edge;
            for (const edge of [other.y + size.height, other.y - own.height, other.y, other.y+size.height-own.height]) if (Math.abs(nextY-edge)<60) nextY=edge;
        }
        update({x:nextX,y:nextY});
    }
    function place(side) {
        const other = draft.find(m => m.name === referenceName);
        if (!other || !selected) return;
        const own = dimensions(selected), ref = dimensions(other);
        const positions = {left:{x:other.x-own.width,y:other.y}, right:{x:other.x+ref.width,y:other.y}, above:{x:other.x,y:other.y-own.height}, below:{x:other.x,y:other.y+ref.height}};
        update(positions[side]);
    }
    function changeResolution(label) {
        const matching = (original?.modes ?? []).filter(m => m.width+"×"+m.height === label);
        if (matching.length) update({mode: matching.reduce((a,b) => a.refreshRate>b.refreshRate?a:b).id});
    }
    function run(action,args) {
        if (busy) return;
        operation = action; result = null; failed = false;
        writer.exec(["python",Quickshell.shellDir+"/monitors/backend.py",action,...args]);
    }
    function apply() { if (dirty && !pending) run("apply",[JSON.stringify({monitors:draft,primary:primary})]); }
    function confirm() { if (pending) run("confirm",[pending.token]); }
    function revert() { if (pending) run("revert",[pending.token]); }
    Process {
        id: reader
        stdout: StdioCollector {
            onStreamFinished: {
                try { const data = JSON.parse(text); if (!data.ok) throw new Error(data.message || data.error); root.load(data); }
                catch(e) { root.failed = true; root.message = String(e); }
            }
        }
    }
    Process {
        id: writer
        stdout: StdioCollector { onStreamFinished: { try { root.result = JSON.parse(text); } catch(e) { root.result = {ok:false,message:Shell.Theme.tr("Resposta inválida do configurador.", "Invalid response from the configurator.")}; } } }
        onExited: code => {
            const data = root.result;
            if (code !== 0 || !data?.ok) { root.failed = true; root.message = data?.message || data?.error || Shell.Theme.tr("Não foi possível aplicar a configuração.", "Could not apply the setup."); return; }
            if (root.operation === "apply") { root.pending = {token:data.token,expiresAt:data.expiresAt}; root.now = Date.now()/1000; root.message = Shell.Theme.tr("Confira todas as telas antes de manter.", "Check all displays before keeping."); }
            else { root.pending = null; root.message = root.operation === "confirm" ? Shell.Theme.tr("Configuração salva.", "Setup saved.") : Shell.Theme.tr("Configuração anterior restaurada.", "Previous setup restored."); Qt.callLater(root.refresh); }
        }
    }
    Timer {
        interval: 250; repeat: true; running: !!root.pending
        onTriggered: {
            root.now = Date.now()/1000;
            if (!root.secondsLeft && !root.busy) { root.pending = null; root.message = Shell.Theme.tr("Tempo esgotado. Restaurando a configuração anterior…", "Time's up. Restoring the previous setup…"); refreshDelay.restart(); }
        }
    }
    Connections {
        target: Hyprland.monitors
        function onValuesChanged() {
            if (!root.opened || root.pending) return;
            if (!root.busy && !root.dirty) refreshDelay.restart();
            else root.message = Shell.Theme.tr("As telas conectadas mudaram. Atualize a lista antes de testar.", "Connected displays changed. Refresh the list before testing.");
        }
    }
    Timer { id: refreshDelay; interval: 1500; onTriggered: root.refresh() }
    IpcHandler {
        target: "monitors"
        function open(): void { root.open(); }
        function close(): void { root.close(); }
        function status(): string { return JSON.stringify({opened:root.opened,count:root.monitors.length,primary:root.primary,pending:!!root.pending,busy:root.busy}); }
    }
}

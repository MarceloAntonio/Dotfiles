import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: preview
    property var activeFace: null
    property var appearance: ({wallpaper:"", accent:"#b2c5e0", mode:"dark"})
    property bool authenticated: false
    readonly property bool busy: false
    readonly property bool responseVisible: false
    readonly property string prompt: preview.tr("Senha", "Password")
    property bool failed: false
    property string message: preview.tr("Prévia visual · Esc para fechar", "Visual preview · Esc to close")
    signal clearInputs()
    property bool en: false
    function tr(pt, english) { return en ? english : pt; }
    FileView { path: "/etc/locale.conf"; onLoaded: preview.en = /^LANG=en/m.test(text()) }
    function authenticate(value) { clearInputs(); message = tr("Prévia: autenticação desativada.", "Preview: authentication disabled."); }
    Process {
        running: true
        command: ["python", Quickshell.shellDir + "/prepare.py"]
        stdout: StdioCollector { onStreamFinished: { try { preview.appearance = JSON.parse(text); } catch(e) {} } }
    }
    FloatingWindow {
        visible: true
        implicitWidth: 1000; implicitHeight: 700
        title: preview.tr("Prévia do bloqueador Quickshell", "Lock screen preview")
        color: "#10151e"
        LockFace { id: previewFace; anchors.fill: parent; controller: preview }
        Shortcut { sequence: "Escape"; onActivated: Qt.quit() }
    }
    IpcHandler {
        target: "preview"
        function capture(path: string): void { previewFace.grabToImage(result => result.saveToFile(path)); }
        function interact(): void { previewFace.wake(); }
        function rest(): void { previewFace.engaged = false; }
        function failure(): void { previewFace.wake(); preview.failed = false; preview.failed = true; preview.message = preview.tr("Prévia de senha incorreta", "Preview password was incorrect"); }
        function success(): void { preview.authenticated = true; }
        function reset(): void { preview.authenticated = false; preview.failed = false; preview.message = preview.tr("Prévia visual · Esc para fechar", "Visual preview · Esc to close"); preview.clearInputs(); }
        function status(): string { return JSON.stringify({ engaged: previewFace.engaged, interaction: previewFace.interaction, departure: previewFace.departure, failed: preview.failed }); }
    }
}

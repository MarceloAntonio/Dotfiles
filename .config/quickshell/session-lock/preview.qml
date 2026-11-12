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
    readonly property string prompt: "Senha"
    property bool failed: false
    property string message: "Prévia visual · Esc para fechar"
    signal clearInputs()
    function authenticate(value) { clearInputs(); message = "Prévia: autenticação desativada."; }
    Process {
        running: true
        command: ["python", Quickshell.shellDir + "/prepare.py"]
        stdout: StdioCollector { onStreamFinished: { try { preview.appearance = JSON.parse(text); } catch(e) {} } }
    }
    FloatingWindow {
        visible: true
        implicitWidth: 1000; implicitHeight: 700
        title: "Prévia do bloqueador Quickshell"
        color: "#10151e"
        LockFace { id: previewFace; anchors.fill: parent; controller: preview }
        Shortcut { sequence: "Escape"; onActivated: Qt.quit() }
    }
    IpcHandler {
        target: "preview"
        function capture(path: string): void { previewFace.grabToImage(result => result.saveToFile(path)); }
        function interact(): void { previewFace.wake(); }
        function rest(): void { previewFace.engaged = false; }
        function failure(): void { previewFace.wake(); preview.failed = false; preview.failed = true; preview.message = "Prévia de senha incorreta"; }
        function success(): void { preview.authenticated = true; }
        function reset(): void { preview.authenticated = false; preview.failed = false; preview.message = "Prévia visual · Esc para fechar"; preview.clearInputs(); }
        function status(): string { return JSON.stringify({ engaged: previewFace.engaged, interaction: previewFace.interaction, departure: previewFace.departure, failed: preview.failed }); }
    }
}

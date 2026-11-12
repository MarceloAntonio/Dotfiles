import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam

ShellRoot {
    id: root
    property var activeFace: null
    property string pending: ""
    property bool firstResponse: false
    property bool authenticated: false
    property string message: ""
    property bool failed: false
    readonly property bool busy: authenticated || (pam.active && !pam.responseRequired)
    readonly property bool responseVisible: pam.responseVisible
    readonly property string prompt: pam.active && pam.responseRequired ? pam.message : "Senha"
    property var appearance: ({wallpaper:"", accent:"#e5eaf2", mode:"dark"})
    property bool ready: false
    signal clearInputs()
    Component.onCompleted: Quickshell.watchFiles = false
    function authenticate(value) {
        if (!lock.secure || busy || authenticated) return;
        failed = false; message = "";
        if (pam.active && pam.responseRequired) { pam.respond(value); clearInputs(); return; }
        pending = value; firstResponse = true;
        clearInputs();
        if (!pam.start()) { pending = ""; firstResponse = false; failed = true; message = "Não foi possível iniciar a autenticação."; }
    }
    Process {
        running: true
        command: ["python", Quickshell.shellDir + "/prepare.py"]
        stdout: StdioCollector { onStreamFinished: { try { root.appearance = JSON.parse(text); } catch(e) {} root.ready = true; lock.locked = true; } }
    }
    PamContext {
        id: pam
        config: "hyprlock"
        onPamMessage: {
            if (responseRequired && root.firstResponse && !responseVisible) {
                const value = root.pending;
                root.pending = ""; root.firstResponse = false;
                respond(value);
            } else if (responseRequired) { root.pending = ""; root.firstResponse = false; }
            if (messageIsError) { root.failed = true; root.message = "Autenticação não concluída."; }
        }
        onCompleted: result => {
            root.pending = ""; root.firstResponse = false; root.clearInputs();
            if (result === PamResult.Success && lock.secure) { root.authenticated = true; unlockDelay.start(); }
            else { root.failed = true; root.message = result === PamResult.MaxTries ? "Limite de tentativas. Aguarde antes de tentar novamente." : "Não foi possível autenticar. Tente novamente."; }
        }
        onError: { root.pending = ""; root.firstResponse = false; root.failed = true; root.message = "Serviço de autenticação indisponível."; }
    }
    Timer {
        id: unlockDelay
        interval: 650
        onTriggered: if (root.authenticated && lock.secure) { lock.locked = false; Qt.callLater(() => Qt.quit()); }
    }
    WlSessionLock {
        id: lock
        locked: false
        WlSessionLockSurface {
            id: surface
            color: "#10151e"
            LockFace { anchors.fill: parent; controller: root }
        }
    }
    IpcHandler {
        target: "lock"
        function status(): string { return JSON.stringify({ requested: lock.locked, secure: lock.secure, ready: root.ready }); }
    }
}

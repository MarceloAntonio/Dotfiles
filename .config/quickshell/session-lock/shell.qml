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
    readonly property string prompt: pam.active && pam.responseRequired ? pam.message : root.tr("Senha", "Password")
    property var appearance: ({wallpaper:"", accent:"#e5eaf2", mode:"dark"})
    property bool ready: false
    signal clearInputs()
    Component.onCompleted: Quickshell.watchFiles = false
    property bool en: false
    function tr(pt, english) { return en ? english : pt; }
    FileView { path: "/etc/locale.conf"; onLoaded: root.en = /^LANG=en/m.test(text()) }
    function authenticate(value) {
        if (!lock.secure || busy || authenticated) return;
        failed = false; message = "";
        if (pam.active && pam.responseRequired) { pam.respond(value); clearInputs(); return; }
        pending = value; firstResponse = true;
        clearInputs();
        if (!pam.start()) { pending = ""; firstResponse = false; failed = true; message = root.tr("Não foi possível iniciar a autenticação.", "Could not start authentication."); }
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
            if (messageIsError) { root.failed = true; root.message = root.tr("Autenticação não concluída.", "Authentication not completed."); }
        }
        onCompleted: result => {
            root.pending = ""; root.firstResponse = false; root.clearInputs();
            if (result === PamResult.Success && lock.secure) { root.authenticated = true; unlockDelay.start(); }
            else { root.failed = true; root.message = result === PamResult.MaxTries ? root.tr("Limite de tentativas. Aguarde antes de tentar novamente.", "Too many attempts. Wait before trying again.") : root.tr("Não foi possível autenticar. Tente novamente.", "Could not authenticate. Try again."); }
        }
        onError: { root.pending = ""; root.firstResponse = false; root.failed = true; root.message = root.tr("Serviço de autenticação indisponível.", "Authentication service unavailable."); }
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

pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import QtQml.Models
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import Quickshell.Networking
import Quickshell.Bluetooth
import "personalize" as Personalize

Scope {
    id: service
    property bool powerOpened: false
    property string powerScreen: ""
    property bool opened: false
    property var panels: ({})
    function registerPanel(output, window) { panels = Object.assign({}, panels, {[output]: window}); }
    function unregisterPanel(output, window) {
        if (panels[output] !== window) return;
        const next = Object.assign({}, panels);
        delete next[output];
        panels = next;
    }
    property string section: "geral"
    property string screenName: ""
    property string error: ""
    property string confirmation: ""
    property var passwordNetwork: null
    property var pairing: null
    property bool osdVisible: false
    property string osdKind: "volume"
    property string osdScreen: ""
    property real brightness: 0
    property bool hasBrightness: false
    property bool initialized: false
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var battery: UPower.displayDevice
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
    readonly property real volume: sink?.audio ? sink.audio.volume * 100 : 0
    readonly property real micVolume: source?.audio ? source.audio.volume * 100 : 0
    readonly property var outputs: Pipewire.nodes.values.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var appStreams: Pipewire.nodes.values.filter(n => n.isStream && n.isSink && n.audio)
    readonly property var inputs: Pipewire.nodes.values.filter(n => n.audio && !n.isSink && !n.isStream)
    readonly property var networks: wifi ? wifi.networks.values.slice().filter(n => n.name.length > 0).sort((a, b) => Number(b.connected) - Number(a.connected) || b.signalStrength - a.signalStrength) : []
    readonly property var devices: adapter ? adapter.devices.values.slice().sort((a, b) => Number(b.connected) - Number(a.connected) || Number(b.paired) - Number(a.paired) || a.name.localeCompare(b.name)) : []

    function focusedScreen() {
        return Hyprland.focusedMonitor?.name ?? Quickshell.screens[0]?.name ?? "";
    }
    function open(tab) {
        powerOpened = false;
        Personalize.Settings.close();
        screenName = focusedScreen();
        section = ["geral", "som", "wifi", "bluetooth", "energia", "notificacoes"].includes(tab) ? tab : "geral";
        confirmation = "";
        error = "";
        opened = true;
        osdVisible = false;
        readBrightness();
    }
    function toggle(tab) {
        if (opened && (tab === "geral" || (section === tab && screenName === focusedScreen()))) close();
        else open(tab);
    }
    function close() {
        opened = false;
        passwordNetwork = null;
        confirmation = "";
        if (pairing) pairingReply(false, "");
    }
    function fail(message) {
        error = message;
        errorTimer.restart();
    }
    function showOsd(kind) {
        if (!initialized || opened) return;
        if (kind === "brightness") {
            readBrightness();
            if (!hasBrightness) return;
        }
        if (kind === "volume" && !sink?.audio) return;
        if (kind === "mic" && !source?.audio) return;
        osdKind = kind;
        osdScreen = focusedScreen();
        osdVisible = true;
        osdTimer.restart();
    }
    function setVolume(value, microphone) {
        const node = microphone ? source : sink;
        if (!node?.audio) return;
        node.audio.volume = Math.max(0, Math.min(1, value / 100));
    }
    function mute(microphone) {
        const node = microphone ? source : sink;
        if (node?.audio) node.audio.muted = !node.audio.muted;
    }
    function readBrightness() {
        if (!brightnessRead.running) brightnessRead.exec(["brightnessctl", "-m"]);
    }
    function setBrightness(value) {
        brightness = Math.max(1, Math.round(value));
        brightnessWriteTimer.restart();
    }
    function connectNetwork(network, password) {
        error = "";
        if (password !== undefined) network.connectWithPsk(password);
        else if (network.known || network.security === WifiSecurityType.Open || network.security === WifiSecurityType.Owe) network.connect();
        else if ([WifiSecurityType.Wpa2Psk, WifiSecurityType.WpaPsk, WifiSecurityType.Sae].includes(network.security)) passwordNetwork = network;
        else fail("Esta rede exige configuração avançada. Use o editor de conexões.");
    }
    function bluetoothAction(device, action) {
        if (!bluetoothAgent.running) {
            fail("O serviço de pareamento está indisponível.");
            return;
        }
        error = "";
        bluetoothAgent.write(JSON.stringify({ action: action, path: device.dbusPath }) + "\n");
    }
    function pairingReply(accept, value) {
        bluetoothAgent.write(JSON.stringify({ action: "reply", accept: accept, value: value }) + "\n");
        pairing = null;
    }
    function executePower(action) {
        // Called only after the user confirms an action in the panel.
        close();
        if (action === "sair") Hyprland.dispatch("hl.dsp.exit()");
        else if (action === "suspender") Quickshell.execDetached(["systemctl", "suspend"]);
        else if (action === "reiniciar") Quickshell.execDetached(["systemctl", "reboot"]);
        else if (action === "desligar") Quickshell.execDetached(["systemctl", "poweroff"]);
    }

    Component.onCompleted: readBrightness()
    Timer { interval: 1800; running: true; onTriggered: service.initialized = true }
    Timer { id: osdTimer; interval: 1800; onTriggered: service.osdVisible = false }
    Timer { id: errorTimer; interval: 12000; onTriggered: service.error = "" }
    Timer { interval: 2500; running: service.opened && (service.section === "geral" || service.section === "energia"); repeat: true; onTriggered: service.readBrightness() }
    Timer {
        id: brightnessWriteTimer
        interval: 50
        onTriggered: {
            if (brightnessWrite.running) restart();
            else brightnessWrite.exec(["brightnessctl", "set", service.brightness + "%"]);
        }
    }
    Process {
        id: brightnessRead
        stdout: StdioCollector {
            onStreamFinished: {
                const fields = text.trim().split(",");
                const percent = parseFloat(fields[3]);
                service.hasBrightness = Number.isFinite(percent);
                if (service.hasBrightness && !brightnessWrite.running && !brightnessWriteTimer.running) service.brightness = percent;
            }
        }
    }
    Process {
        id: brightnessWrite
        onExited: (code) => { if (code !== 0) service.fail("Não foi possível alterar o brilho."); }
    }
    PwObjectTracker { objects: [service.sink, service.source, ...service.outputs, ...service.inputs, ...(service.opened && service.section === "som" ? service.appStreams : [])].filter(n => n !== null) }
    Connections {
        target: service.sink?.audio ?? null
        function onVolumeChanged() { service.showOsd("volume"); }
        function onMutedChanged() { service.showOsd("volume"); }
    }
    Connections {
        target: service.source?.audio ?? null
        function onVolumeChanged() { service.showOsd("mic"); }
        function onMutedChanged() { service.showOsd("mic"); }
    }
    Binding {
        target: service.wifi
        property: "scannerEnabled"
        value: service.opened && service.section === "wifi" && Networking.wifiEnabled
        when: service.wifi !== null
    }
    Binding {
        target: service.adapter
        property: "discovering"
        value: service.opened && service.section === "bluetooth" && service.adapter.enabled
        when: service.adapter !== null
    }
    Instantiator {
        model: service.networks
        delegate: Connections {
            required property var modelData
            target: modelData
            function onConnectionFailed(reason) {
                if (reason === ConnectionFailReason.NoSecrets || reason === ConnectionFailReason.WifiAuthTimeout) service.passwordNetwork = modelData;
                service.fail(reason === ConnectionFailReason.NoSecrets || reason === ConnectionFailReason.WifiAuthTimeout
                    ? "Não foi possível autenticar. Confira a senha da rede."
                    : "Falha na conexão: " + ConnectionFailReason.toString(reason));
            }
        }
    }
    Process {
        id: bluetoothAgent
        command: ["python", "-u", Quickshell.shellDir + "/bluetooth-agent.py"]
        running: true
        stdinEnabled: true
        stderr: SplitParser { onRead: data => console.warn("Bluetooth agent:", data) }
        onExited: (code) => { if (code !== 0) service.fail("O agente Bluetooth não iniciou. Consulte o log do Quickshell."); }
        stdout: SplitParser {
            onRead: data => {
                try {
                    const message = JSON.parse(data);
                    if (message.type === "error") service.fail(message.message);
                    else if (message.type === "request") {
                        service.open("bluetooth");
                        service.pairing = message;
                    } else if (message.type === "cancel") service.pairing = null;
                } catch (e) { console.warn("Bluetooth:", e); }
            }
        }
    }
    IpcHandler {
        target: "control"
        function powerMenu(): void { service.close(); service.powerScreen = service.focusedScreen(); service.powerOpened = true; }
        function toggle(section: string): void { service.toggle(section); }
        function open(section: string): void { service.open(section); }
        function close(): void { service.close(); }
        function status(): string {
            return JSON.stringify({ opened: service.opened, section: service.section, screen: service.screenName,
                progress: service.panels[service.screenName]?.progress ?? 0, presented: service.panels[service.screenName]?.visible ?? false,
                audio: !!service.sink?.audio, microphone: !!service.source?.audio, brightness: service.hasBrightness,
                wifi: !!service.wifi, bluetooth: !!service.adapter, battery: !!service.battery?.isPresent,
                outputs: service.outputs.length, inputs: service.inputs.length, agent: bluetoothAgent.running,
                osd: service.osdVisible, osdKind: service.osdKind, osdScreen: service.osdScreen,
                notifications: Notifications.count, notificationPopups: Notifications.popups.length, dnd: Notifications.dnd });
        }
    }
    IpcHandler {
        target: "osd"
        function display(kind: string): void { service.showOsd(kind); }
    }
}

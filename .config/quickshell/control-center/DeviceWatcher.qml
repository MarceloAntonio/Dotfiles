import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

// Notifica conexão/desconexão de dispositivos USB (um aviso por aparelho físico),
// pendrives/HDs (com botão "Abrir pasta"), teclados/mouses Bluetooth, carregador,
// monitores e bateria do notebook.
Scope {
    id: root
    property var names: ({})   // DEVPATH -> nome, caso o evento de remoção venha sem propriedades
    property string charger: ""  // último POWER_SUPPLY_ONLINE do carregador
    property var recent: ({})  // dedup de dispositivos BT com várias interfaces input

    // [rótulo, categoria]; a categoria vira o ícone no NotificationCard
    function kind(p) {
        const i = p.ID_USB_INTERFACES || "";
        if (i.match(/:0301\d1:/) || p.ID_INPUT_KEYBOARD === "1") return [Theme.tr("Teclado", "Keyboard"), "device"];
        if (i.match(/:0301\d2:/) || p.ID_INPUT_MOUSE === "1") return ["Mouse", "device"];
        if (i.includes(":08")) return [Theme.tr("Pendrive / HD", "USB drive / HD"), "device.storage"];
        if (i.includes(":01")) return [Theme.tr("Dispositivo de áudio", "Audio device"), "device.audio"];
        if (i.includes(":0e")) return [Theme.tr("Câmera", "Camera"), "device"];
        if (i.includes(":e0")) return [Theme.tr("Adaptador Bluetooth", "Bluetooth adapter"), "device"];
        return [Theme.tr("Dispositivo USB", "USB device"), "device"];
    }

    function notify(category, title, body, urgency) {
        Quickshell.execDetached(["notify-send", "-a", Theme.tr("Dispositivos", "Devices"), "-c", category, "-u", urgency || "normal", title, body || ""]);
    }

    // Notificação com um botão; se clicado, roda `script` com bash ($1 = arg).
    // ponytail: notify-send -w fica esperando até a notificação ser fechada; um processo bash parado por aviso.
    function notifyAction(category, title, body, label, script, arg) {
        Quickshell.execDetached(["bash", "-c",
            `[ "$(notify-send -a ${Theme.tr("Dispositivos", "Devices")} -c "$2" -w -A "go=$5" "$3" "$4")" = go ] || exit 0\n${script}`,
            "_", arg, category, title, body, label]);
    }

    function handle(p) {
        if (p.SUBSYSTEM === "power_supply") {
            if (p.POWER_SUPPLY_TYPE !== "Mains" || p.POWER_SUPPLY_ONLINE === charger) return;
            charger = p.POWER_SUPPLY_ONLINE;
            notify("power", charger === "1" ? Theme.tr("Carregador conectado", "Charger connected") : Theme.tr("Carregador desconectado", "Charger disconnected"));
            return;
        }
        if (p.ACTION !== "add" && p.ACTION !== "remove") return;
        let name;
        if (p.SUBSYSTEM === "block") {
            // um aviso por partição montável do pendrive/HD, com botão para montar e abrir
            if (p.ACTION !== "add" || p.ID_BUS !== "usb" || p.ID_FS_USAGE !== "filesystem") return;
            notifyAction("device.storage", Theme.tr("Pendrive / HD conectado", "USB drive / HD connected"),
                p.ID_FS_LABEL || (p.ID_MODEL || "").replace(/_/g, " "), Theme.tr("Abrir pasta", "Open folder"),
                `mnt=$(lsblk -no MOUNTPOINT "$1" | head -1)
                 [ -n "$mnt" ] || { udisksctl mount -b "$1" >/dev/null && mnt=$(lsblk -no MOUNTPOINT "$1" | head -1); }
                 [ -n "$mnt" ] && exec nautilus --new-window "$mnt"`, p.DEVNAME);
            return;
        }
        if (p.SUBSYSTEM === "usb") {
            if (p.DEVTYPE !== "usb_device" || (p.ID_USB_INTERFACES || "").startsWith(":09")) return; // ignora hubs
            if (p.ACTION === "add" && (p.ID_USB_INTERFACES || "").includes(":08")) return; // aviso vem pelo block
            name = p.ID_MODEL_FROM_DATABASE && p.ID_VENDOR_FROM_DATABASE
                ? `${p.ID_VENDOR_FROM_DATABASE} ${p.ID_MODEL_FROM_DATABASE}`
                : (p.ID_MODEL || "").replace(/_/g, " ");
        } else if (p.SUBSYSTEM === "input") {
            if (p.ID_BUS !== "bluetooth" || !p.NAME || !(p.ID_INPUT_KEYBOARD || p.ID_INPUT_MOUSE)) return;
            const key = p.ACTION + (p.UNIQ || p.NAME);
            if (Date.now() - (recent[key] || 0) < 3000) return;
            recent[key] = Date.now();
            name = p.NAME.replace(/^"|"$/g, "");
        } else return;

        if (p.ACTION === "add") names[p.DEVPATH] = name;
        else { name = name || names[p.DEVPATH]; delete names[p.DEVPATH]; }
        const [label, category] = kind(p);
        notify(category, `${label} ${p.ACTION === "add" ? Theme.tr("conectado", "connected") : Theme.tr("desconectado", "disconnected")}`, name || "");
    }

    Process {
        running: true
        command: ["udevadm", "monitor", "--udev", "--property", "--subsystem-match=usb", "--subsystem-match=input",
            "--subsystem-match=power_supply", "--subsystem-match=block"]
        stdout: SplitParser {
            splitMarker: "\n\n"
            onRead: block => {
                const p = {};
                for (const line of block.split("\n")) {
                    const eq = line.indexOf("=");
                    if (eq > 0) p[line.slice(0, eq)] = line.slice(eq + 1);
                }
                root.handle(p);
            }
        }
    }

    // Monitores: compara a lista de telas antes/depois de cada mudança.
    property var screens: ({})  // nome -> rótulo
    function screenMap() {
        const m = {};
        for (const s of Quickshell.screens) m[s.name] = [s.manufacturer, s.model].filter(Boolean).join(" ") || s.name;
        return m;
    }
    Component.onCompleted: { screens = screenMap(); checkBattery(true); }
    Connections {
        target: Quickshell
        function onScreensChanged() {
            const now = root.screenMap();
            for (const n in now) if (!(n in root.screens))
                root.notifyAction("display", Theme.tr("Monitor conectado", "Monitor connected"), `${now[n]} (${n})`, Theme.tr("Configurar", "Configure"),
                    "exec qs -c control-center ipc call monitors open", n);
            for (const n in root.screens) if (!(n in now))
                root.notify("display", Theme.tr("Monitor desconectado", "Monitor disconnected"), `${root.screens[n]} (${n})`);
            root.screens = now;
        }
    }

    // Bateria: avisa uma vez em 20% e outra em 10% enquanto descarrega.
    readonly property var battery: UPower.displayDevice
    property int warned: 101   // menor limite já avisado nesta descarga
    function checkBattery(silent) {
        if (!battery?.isPresent) return;
        const pct = Math.round(battery.percentage * 100);
        if (!UPower.onBattery) { warned = 101; return; }
        for (const limit of [10, 20]) if (pct <= limit && limit < warned) {
            warned = limit;
            if (!silent) notify("battery", limit === 10 ? Theme.tr("Bateria crítica", "Critical battery") : Theme.tr("Bateria fraca", "Low battery"),
                Theme.tr(`${pct}% restantes — conecte o carregador`, `${pct}% remaining — connect the charger`), limit === 10 ? "critical" : "normal");
            break;
        }
    }
    Connections {
        target: root.battery
        function onPercentageChanged() { root.checkBattery(false); }
    }
    Connections {
        target: UPower
        function onOnBatteryChanged() { root.checkBattery(false); }
    }
}

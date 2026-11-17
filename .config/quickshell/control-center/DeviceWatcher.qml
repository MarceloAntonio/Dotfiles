import QtQuick
import Quickshell
import Quickshell.Io

// Notifica conexão/desconexão de dispositivos USB (um aviso por aparelho físico)
// de teclados/mouses Bluetooth e do carregador, lendo os eventos do udev.
Scope {
    id: root
    property var names: ({})   // DEVPATH -> nome, caso o evento de remoção venha sem propriedades
    property string charger: ""  // último POWER_SUPPLY_ONLINE do carregador
    property var recent: ({})  // dedup de dispositivos BT com várias interfaces input

    // [rótulo, categoria]; a categoria vira o ícone no NotificationCard
    function kind(p) {
        const i = p.ID_USB_INTERFACES || "";
        if (i.match(/:0301\d1:/) || p.ID_INPUT_KEYBOARD === "1") return ["Teclado", "device"];
        if (i.match(/:0301\d2:/) || p.ID_INPUT_MOUSE === "1") return ["Mouse", "device"];
        if (i.includes(":08")) return ["Pendrive / HD", "device.storage"];
        if (i.includes(":01")) return ["Dispositivo de áudio", "device.audio"];
        if (i.includes(":0e")) return ["Câmera", "device"];
        if (i.includes(":e0")) return ["Adaptador Bluetooth", "device"];
        return ["Dispositivo USB", "device"];
    }

    function notify(category, title, body) {
        Quickshell.execDetached(["notify-send", "-a", "Dispositivos", "-c", category, title, body]);
    }

    function handle(p) {
        if (p.SUBSYSTEM === "power_supply") {
            if (p.POWER_SUPPLY_TYPE !== "Mains" || p.POWER_SUPPLY_ONLINE === charger) return;
            charger = p.POWER_SUPPLY_ONLINE;
            notify("power", charger === "1" ? "Carregador conectado" : "Carregador desconectado", "");
            return;
        }
        if (p.ACTION !== "add" && p.ACTION !== "remove") return;
        let name;
        if (p.SUBSYSTEM === "usb") {
            if (p.DEVTYPE !== "usb_device" || (p.ID_USB_INTERFACES || "").startsWith(":09")) return; // ignora hubs
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
        notify(category, `${label} ${p.ACTION === "add" ? "conectado" : "desconectado"}`, name || "");
    }

    Process {
        running: true
        command: ["udevadm", "monitor", "--udev", "--property", "--subsystem-match=usb", "--subsystem-match=input", "--subsystem-match=power_supply"]
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
}

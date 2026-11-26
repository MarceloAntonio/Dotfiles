#!/usr/bin/env python3
"""BlueZ pairing agent. JSON lines connect the D-Bus agent to the QML dialog."""
import json
import os
import sys

import dbus
import dbus.service
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from lang import tr


def emit(kind, **fields):
    print(json.dumps({"type": kind, **fields}, ensure_ascii=False), flush=True)


class Rejected(dbus.DBusException):
    _dbus_error_name = "org.bluez.Error.Rejected"


class Agent(dbus.service.Object):
    def __init__(self, bus):
        self.bus = bus
        self.pending = None
        self.timeout = None
        super().__init__(bus, "/local/quickshell/control_center")

    def finish(self, accept=False, value=""):
        if self.timeout:
            GLib.source_remove(self.timeout)
            self.timeout = None
        if self.pending:
            reply, error, kind = self.pending
            self.pending = None
            if not accept:
                error(Rejected(tr("Pareamento cancelado", "Pairing canceled")))
            elif kind == "pin":
                if not value or len(value) > 16:
                    error(Rejected(tr("PIN inválido", "Invalid PIN")))
                else:
                    reply(value)
            elif kind == "passkey":
                if not value.isdigit() or len(value) > 6:
                    error(Rejected(tr("Código inválido", "Invalid code")))
                else:
                    reply(dbus.UInt32(int(value)))
            else:
                reply()
        emit("cancel")

    def request(self, device, kind, reply, error, code=""):
        self.finish()
        try:
            props = dbus.Interface(self.bus.get_object("org.bluez", device), "org.freedesktop.DBus.Properties")
            name = str(props.Get("org.bluez.Device1", "Alias"))
        except dbus.DBusException:
            name = tr("Dispositivo Bluetooth", "Bluetooth device")
        self.pending = (reply, error, kind)
        self.timeout = GLib.timeout_add_seconds(60, self.expire)
        emit("request", kind=kind, name=name, code=code)

    def expire(self):
        self.timeout = None
        self.finish()
        return False

    @dbus.service.method("org.bluez.Agent1", in_signature="", out_signature="")
    def Release(self):
        self.finish()

    @dbus.service.method("org.bluez.Agent1", in_signature="o", out_signature="s", async_callbacks=("reply", "error"))
    def RequestPinCode(self, device, reply, error):
        self.request(device, "pin", reply, error)

    @dbus.service.method("org.bluez.Agent1", in_signature="o", out_signature="u", async_callbacks=("reply", "error"))
    def RequestPasskey(self, device, reply, error):
        self.request(device, "passkey", reply, error)

    @dbus.service.method("org.bluez.Agent1", in_signature="ou", out_signature="", async_callbacks=("reply", "error"))
    def RequestConfirmation(self, device, passkey, reply, error):
        self.request(device, "confirm", reply, error, f"{int(passkey):06d}")

    @dbus.service.method("org.bluez.Agent1", in_signature="o", out_signature="", async_callbacks=("reply", "error"))
    def RequestAuthorization(self, device, reply, error):
        self.request(device, "authorize", reply, error)

    @dbus.service.method("org.bluez.Agent1", in_signature="os", out_signature="", async_callbacks=("reply", "error"))
    def AuthorizeService(self, device, uuid, reply, error):
        self.request(device, "authorize", reply, error)

    @dbus.service.method("org.bluez.Agent1", in_signature="os", out_signature="")
    def DisplayPinCode(self, device, pincode):
        emit("request", kind="display", name=tr("Digite o PIN no dispositivo", "Enter the PIN on the device"), code=str(pincode))

    @dbus.service.method("org.bluez.Agent1", in_signature="ouq", out_signature="")
    def DisplayPasskey(self, device, passkey, entered):
        emit("request", kind="display", name=tr("Digite o código no dispositivo", "Enter the code on the device"), code=f"{int(passkey):06d}")

    @dbus.service.method("org.bluez.Agent1", in_signature="", out_signature="")
    def Cancel(self):
        self.finish()


DBusGMainLoop(set_as_default=True)
bus = dbus.SystemBus()
agent = Agent(bus)
loop = GLib.MainLoop()


def register():
    try:
        manager = dbus.Interface(bus.get_object("org.bluez", "/org/bluez"), "org.bluez.AgentManager1")
        manager.RegisterAgent(agent.__dbus_object_path__, "KeyboardDisplay")
        # This session's control center handles incoming pairing requests too.
        manager.RequestDefaultAgent(agent.__dbus_object_path__)
    except dbus.DBusException as exc:
        emit("error", message=tr("Agente Bluetooth: ", "Bluetooth agent: ") + str(exc))


def failed(exc):
    emit("error", message="Bluetooth: " + str(exc).split(": ", 1)[-1])


def action(message):
    cmd = message.get("action")
    if cmd == "reply":
        agent.finish(bool(message.get("accept")), str(message.get("value", "")))
        return
    path = message.get("path", "")
    if not path.startswith("/org/bluez/") or cmd not in ("pair", "connect", "disconnect", "forget"):
        return
    device = dbus.Interface(bus.get_object("org.bluez", path), "org.bluez.Device1")
    if cmd == "pair":
        def paired():
            agent.finish()
            props = dbus.Interface(bus.get_object("org.bluez", path), "org.freedesktop.DBus.Properties")
            props.Set("org.bluez.Device1", "Trusted", dbus.Boolean(True))
            device.Connect(reply_handler=lambda: None, error_handler=failed, timeout=30)
        def pairing_failed(exc):
            agent.finish()
            failed(exc)
        device.Pair(reply_handler=paired, error_handler=pairing_failed, timeout=65)
    elif cmd == "connect":
        device.Connect(reply_handler=lambda: None, error_handler=failed, timeout=30)
    elif cmd == "disconnect":
        device.Disconnect(reply_handler=lambda: None, error_handler=failed, timeout=20)
    else:
        adapter_path = path.rsplit("/", 1)[0]
        adapter = dbus.Interface(bus.get_object("org.bluez", adapter_path), "org.bluez.Adapter1")
        adapter.RemoveDevice(dbus.ObjectPath(path), reply_handler=lambda: None, error_handler=failed)


buffer = b""


def read_input(source, condition):
    global buffer
    data = os.read(sys.stdin.fileno(), 65536)
    if not data:
        agent.finish()
        loop.quit()
        return False
    buffer += data
    while b"\n" in buffer:
        line, buffer = buffer.split(b"\n", 1)
        try:
            action(json.loads(line))
        except (ValueError, dbus.DBusException) as exc:
            failed(exc)
    return True


bus.add_signal_receiver(lambda name, old, new: register() if new else None,
                        signal_name="NameOwnerChanged", dbus_interface="org.freedesktop.DBus",
                        arg0="org.bluez")
GLib.io_add_watch(sys.stdin.fileno(), GLib.IO_IN | GLib.IO_HUP, read_input)
register()
loop.run()

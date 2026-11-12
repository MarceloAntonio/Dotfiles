#!/usr/bin/env python3
"""Route logind Lock and PrepareForSleep to the standalone locker."""
import os, pathlib, subprocess
import dbus
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib
DBusGMainLoop(set_as_default=True)
bus=dbus.SystemBus()
manager=dbus.Interface(bus.get_object('org.freedesktop.login1','/org/freedesktop/login1'),'org.freedesktop.login1.Manager')
session = os.environ.get('XDG_SESSION_ID')
if session:
    path = manager.GetSession(session)
else:
    path = None
    for sid, uid, user, seat, candidate in manager.ListSessions():
        if int(uid) != os.getuid(): continue
        props = dbus.Interface(bus.get_object('org.freedesktop.login1',candidate),'org.freedesktop.DBus.Properties')
        if props.Get('org.freedesktop.login1.Session','Type') == 'wayland' and props.Get('org.freedesktop.login1.Session','Active'):
            path = candidate; break
    if path is None: raise RuntimeError('Sessão Wayland ativa não encontrada')
locker=str(pathlib.Path.home()/'.local/bin/rice-lock')
inhibitor=None

def acquire():
    global inhibitor
    if inhibitor is None:
        inhibitor=manager.Inhibit('sleep','Quickshell lock','Bloquear antes de suspender','delay').take()

def lock():
    subprocess.Popen([locker],start_new_session=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)

def sleep_signal(sleeping):
    global inhibitor
    if sleeping:
        result=subprocess.run([locker,'--ensure-secure'],timeout=9)
        if result.returncode != 0:
            print('Bloqueio não confirmado antes da suspensão; mantendo inibidor até o limite do logind.',flush=True)
            return
        if inhibitor is not None: os.close(inhibitor);inhibitor=None
    else: acquire()

bus.add_signal_receiver(lambda: lock(),signal_name='Lock',dbus_interface='org.freedesktop.login1.Session',path=str(path))
bus.add_signal_receiver(sleep_signal,signal_name='PrepareForSleep',dbus_interface='org.freedesktop.login1.Manager')
# Unlock signals deliberately do not dismiss the lock: PAM is the only unlock path.
acquire()
GLib.MainLoop().run()

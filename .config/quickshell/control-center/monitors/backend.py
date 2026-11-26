#!/usr/bin/env python3
"""Validated Hyprland monitor previews with an independent rollback watchdog."""
from __future__ import annotations

import fcntl
import json
import math
import os
from pathlib import Path
import re
import secrets
import subprocess
import sys
import tempfile
import time

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from lang import tr

HOME = Path.home()
STATE = HOME / '.local/state/quickshell-monitors'
SAVED = STATE / 'layout.json'
MANAGED = HOME / '.config/hypr/configs/monitors-managed.lua'
RUNTIME = Path(os.environ.get('XDG_RUNTIME_DIR', f'/run/user/{os.getuid()}')) / 'quickshell-monitors'
PENDING = RUNTIME / 'pending.json'
MODE = re.compile(r'^(\d{3,5})x(\d{3,5})@(\d{1,3}(?:\.\d{1,5})?)$')
OUTPUT = re.compile(r'^[A-Za-z0-9_.:-]{1,100}$')
TIMEOUT = 20


def read_json(path, default=None):
    try:
        return json.loads(path.read_text())
    except (OSError, ValueError):
        return default


def atomic(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temp = tempfile.mkstemp(dir=path.parent, prefix='.' + path.name + '-')
    try:
        with os.fdopen(fd, 'w') as stream:
            stream.write(text)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temp, path)
    finally:
        Path(temp).unlink(missing_ok=True)


def call(*args, json_result=False):
    result = subprocess.run(['hyprctl', *args], capture_output=True, text=True, timeout=8)
    output = result.stdout.strip()
    if (result.returncode or re.search(r'(?im)^(?:error|invalid|lua error)\b', output)
            or (args and args[0] == 'eval' and output != 'ok')):
        raise RuntimeError(result.stderr.strip() or output or tr('Hyprland não respondeu.', 'Hyprland did not respond.'))
    return json.loads(output) if json_result else output


def monitors():
    return call('-j', 'monitors', 'all', json_result=True)


def mode_parts(value):
    match = MODE.fullmatch(value.removesuffix('Hz'))
    if not match:
        raise ValueError(tr('Modo de vídeo inválido.', 'Invalid video mode.'))
    width, height, refresh = int(match[1]), int(match[2]), float(match[3])
    if not 10 <= refresh <= 1000:
        raise ValueError(tr('Frequência inválida.', 'Invalid refresh rate.'))
    return width, height, refresh


def mode_string(width, height, refresh):
    return f'{width}x{height}@{refresh:.2f}'


def modes_for(monitor):
    values = []
    for value in monitor.get('availableModes', []):
        try:
            width, height, refresh = mode_parts(value)
        except ValueError:
            continue
        mode = mode_string(width, height, refresh)
        if mode not in values:
            values.append(mode)
    return values


def current_mode(monitor):
    available = modes_for(monitor)
    # Reported active refresh can differ by a few thousandths of a Hz.
    candidates = [m for m in available if mode_parts(m)[:2] == (monitor['width'], monitor['height'])]
    if candidates:
        return min(candidates, key=lambda m: abs(mode_parts(m)[2] - monitor.get('refreshRate', 60)))
    return mode_string(monitor.get('width') or 1920, monitor.get('height') or 1080,
                       monitor.get('refreshRate') or 60)


def snapshot(data):
    return [dict(name=m['name'], mode=current_mode(m), x=m.get('x', 0), y=m.get('y', 0),
                 scale=m.get('scale') or 1, transform=m.get('transform', 0),
                 disabled=bool(m.get('disabled', False))) for m in data]


def primary_for(data):
    saved = read_json(SAVED, {}) or {}
    names = [m['name'] for m in data if not m.get('disabled')]
    preferred = saved.get('primary')
    if preferred in names:
        return preferred
    focused = next((m['name'] for m in data if m.get('focused') and not m.get('disabled')), '')
    return focused or (names[0] if names else '')


def catalog():
    data = monitors()
    primary = primary_for(data)
    result = []
    for monitor in data:
        item = dict(monitor)
        item['label'] = monitor.get('description') or monitor['name']
        item['mode'] = current_mode(monitor)
        item['availableModes'] = modes_for(monitor)
        item['modes'] = [dict(id=m, width=mode_parts(m)[0], height=mode_parts(m)[1],
                              refreshRate=mode_parts(m)[2], label=m + ' Hz') for m in item['availableModes']]
        item['primary'] = monitor['name'] == primary
        result.append(item)
    pending = read_json(PENDING)
    if pending:
        pending = dict(token=pending['token'], deadline=pending['deadline'],
                       expiresAt=pending['deadline'], secondsLeft=max(0, math.ceil(pending['deadline'] - time.time())))
    return dict(ok=True, monitors=result, primary=primary, pending=pending)


def finite_number(value, name, low, high, integer=False):
    if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value):
        raise ValueError(tr(f'{name} inválido.', f'Invalid {name}.'))
    if not low <= value <= high or (integer and int(value) != value):
        raise ValueError(tr(f'{name} fora do intervalo permitido.', f'{name} is outside the allowed range.'))
    return int(value) if integer else float(value)


def validate(payload, available):
    if not isinstance(payload, dict) or not isinstance(payload.get('monitors'), list):
        raise ValueError(tr('Layout inválido.', 'Invalid layout.'))
    by_name = {m['name']: m for m in available}
    supplied = payload['monitors']
    if not supplied or len(supplied) != len(by_name):
        raise ValueError(tr('O layout deve incluir todos os monitores conectados. Atualize a lista.', 'The layout must include all connected monitors. Refresh the list.'))
    seen, result = set(), []
    for item in supplied:
        if not isinstance(item, dict):
            raise ValueError(tr('Monitor inválido.', 'Invalid monitor.'))
        name = item.get('name', '')
        if not isinstance(name, str) or not OUTPUT.fullmatch(name) or name not in by_name or name in seen:
            raise ValueError(tr('Monitor desconhecido ou duplicado. Atualize a lista.', 'Unknown or duplicate monitor. Refresh the list.'))
        seen.add(name)
        monitor = by_name[name]
        mode = item.get('mode', '')
        if not isinstance(mode, str):
            raise ValueError(tr('Modo de vídeo inválido.', 'Invalid video mode.'))
        width, height, refresh = mode_parts(mode)
        mode = mode_string(width, height, refresh)
        disabled = item.get('disabled', bool(monitor.get('disabled', False)))
        if not isinstance(disabled, bool):
            raise ValueError(tr('Estado do monitor inválido.', 'Invalid monitor state.'))
        allowed = modes_for(monitor)
        if not disabled and mode not in allowed and mode != current_mode(monitor):
            raise ValueError(tr(f'O modo {mode} não está disponível em {name}.', f'Mode {mode} is not available on {name}.'))
        x = finite_number(item.get('x'), tr('Posição X', 'X position'), -32768, 32768, True)
        y = finite_number(item.get('y'), tr('Posição Y', 'Y position'), -32768, 32768, True)
        scale = finite_number(item.get('scale', monitor.get('scale', 1)), tr('Escala', 'Scale'), .5, 4)
        transform = finite_number(item.get('transform', monitor.get('transform', 0)), tr('Rotação', 'Rotation'), 0, 7, True)
        result.append(dict(name=name, mode=mode, x=x, y=y, scale=scale, transform=transform, disabled=disabled))
    active = [m for m in result if not m['disabled']]
    if not active:
        raise ValueError(tr('Mantenha pelo menos um monitor ligado.', 'Keep at least one monitor on.'))
    primary = payload.get('primary')
    if primary not in [m['name'] for m in active]:
        raise ValueError(tr('Escolha um monitor principal que esteja ligado.', 'Choose a primary monitor that is on.'))
    # Mirror/overlap is intentionally outside this editor's scope.
    boxes = []
    for item in active:
        w, h, _ = mode_parts(item['mode'])
        if item['transform'] % 2:
            w, h = h, w
        box = (item['x'], item['y'], item['x'] + w / item['scale'], item['y'] + h / item['scale'])
        for other in boxes:
            if min(box[2], other[2]) - max(box[0], other[0]) > 1 and min(box[3], other[3]) - max(box[1], other[1]) > 1:
                raise ValueError(tr('Os monitores estão sobrepostos. Separe as telas no diagrama.', 'The monitors overlap. Separate the screens in the diagram.'))
        boxes.append(box)
    return dict(monitors=result, primary=primary)


def lua_string(value):
    # Connector names are restricted above; JSON quoting is valid for this ASCII subset.
    if not OUTPUT.fullmatch(value):
        raise ValueError(tr('Nome de monitor inválido.', 'Invalid monitor name.'))
    return json.dumps(value)


def lua_layout(layout, include_primary=False):
    lines = []
    # Enable/configure outputs before disabling any, avoiding an empty desktop.
    for item in sorted(layout['monitors'], key=lambda m: bool(m.get('disabled'))):
        name = lua_string(item['name'])
        if item.get('disabled'):
            lines.append(f'hl.monitor({{output={name}, disabled=true}})')
        else:
            lines.append('hl.monitor({output=%s,mode=%s,position=%s,scale=%s,transform=%d})' % (
                name, json.dumps(item['mode']), json.dumps(f'{item["x"]}x{item["y"]}'),
                format(item['scale'], '.6g'), item['transform']))
    if include_primary:
        lines.append('hl.config({cursor={default_monitor=%s}})' % lua_string(layout['primary']))
    return '\n'.join(lines) + '\n'


def runtime_apply(layout):
    names = {m['name'] for m in monitors()}
    connected = [m for m in layout['monitors'] if m['name'] in names]
    if not connected:
        raise RuntimeError(tr('Nenhum monitor do layout está conectado.', 'No monitor in the layout is connected.'))
    if not any(not m['disabled'] for m in connected):
        raise RuntimeError(tr('Não é seguro aplicar um layout sem tela ativa.', 'It is not safe to apply a layout with no active screen.'))
    call('eval', lua_layout(dict(monitors=connected)))


def pending_for(token):
    pending = read_json(PENDING)
    if not pending or not isinstance(token, str) or not secrets.compare_digest(pending['token'], token):
        raise ValueError(tr('Esta prévia já terminou. Atualize a lista de monitores.', 'This preview has already ended. Refresh the monitor list.'))
    return pending


def apply(payload):
    if read_json(PENDING):
        raise ValueError(tr('Confirme ou reverta a prévia atual antes de aplicar outra.', 'Confirm or revert the current preview before applying another.'))
    available = monitors()
    layout = validate(payload, available)
    original = dict(monitors=snapshot(available), primary=primary_for(available))
    token = secrets.token_urlsafe(24)
    deadline = time.time() + TIMEOUT
    pending = dict(token=token, deadline=deadline, original=original, proposed=layout)
    atomic(PENDING, json.dumps(pending))
    # Spawn before touching monitors: the QML process may disappear after a mode switch.
    subprocess.Popen([sys.executable, str(Path(__file__).resolve()), '_watch', token],
                     stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                     start_new_session=True, close_fds=True)
    try:
        runtime_apply(layout)
    except Exception:
        try:
            runtime_apply(original)
            PENDING.unlink(missing_ok=True)
        except Exception:
            pass  # watchdog remains armed if immediate rollback failed
        raise
    return dict(ok=True, token=token, deadline=deadline, expiresAt=deadline, seconds=TIMEOUT,
                message=tr('Prévia aplicada. Confirme para salvar.', 'Preview applied. Confirm to save.'))


def confirm(token):
    pending = pending_for(token)
    if time.time() >= pending['deadline']:
        runtime_apply(pending['original'])
        PENDING.unlink(missing_ok=True)
        raise ValueError(tr('A prévia expirou e a configuração anterior foi restaurada.', 'The preview expired and the previous configuration was restored.'))
    current_names = {m['name'] for m in monitors()}
    if current_names != {m['name'] for m in pending['proposed']['monitors']}:
        raise ValueError(tr('As telas conectadas mudaram. Reverta e atualize a lista.', 'The connected screens changed. Revert and refresh the list.'))
    layout = pending['proposed']
    # No focus change here; principal is an initial cursor preference.
    content = '-- Gerenciado pelo configurador de monitores Quickshell.\n' + lua_layout(layout, include_primary=True)
    previous = MANAGED.read_text() if MANAGED.exists() else None
    previous_saved = SAVED.read_text() if SAVED.exists() else None
    try:
        atomic(MANAGED, content)
        atomic(SAVED, json.dumps(layout, ensure_ascii=False, indent=2) + '\n')
        call('eval', 'hl.config({cursor={default_monitor=%s}})' % lua_string(layout['primary']))
    except Exception:
        if previous_saved is None:
            SAVED.unlink(missing_ok=True)
        else:
            atomic(SAVED, previous_saved)
        if previous is None:
            MANAGED.unlink(missing_ok=True)
        else:
            atomic(MANAGED, previous)
        raise
    PENDING.unlink(missing_ok=True)
    return dict(ok=True, primary=layout['primary'], message=tr('Configuração salva.', 'Configuration saved.'))


def revert(token):
    pending = pending_for(token)
    runtime_apply(pending['original'])
    PENDING.unlink(missing_ok=True)
    return dict(ok=True, message=tr('Configuração anterior restaurada.', 'Previous configuration restored.'))


def watch(token):
    # Separate process, separate lock; persists after a shell reload or crash.
    while True:
        pending = read_json(PENDING)
        if not pending or pending.get('token') != token:
            return
        remaining = pending['deadline'] - time.time()
        if remaining > 0:
            time.sleep(min(.5, remaining))
            continue
        with (RUNTIME / 'transaction.lock').open('a') as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            pending = read_json(PENDING)
            if not pending or pending.get('token') != token:
                return
            try:
                runtime_apply(pending['original'])
                PENDING.unlink(missing_ok=True)
                return
            except Exception:
                # Hotplug/transient IPC failures must not silently disarm rollback.
                time.sleep(1)


def main():
    RUNTIME.mkdir(parents=True, exist_ok=True, mode=0o700)
    if len(sys.argv) == 3 and sys.argv[1] == '_watch':
        watch(sys.argv[2])
        return
    try:
        with (RUNTIME / 'transaction.lock').open('a') as lock:
            fcntl.flock(lock, fcntl.LOCK_EX)
            command = sys.argv[1] if len(sys.argv) > 1 else ''
            if command == 'catalog':
                result = catalog()
            elif command == 'validate' and len(sys.argv) == 3:
                result = dict(ok=True, layout=validate(json.loads(sys.argv[2]), monitors()))
            elif command == 'apply' and len(sys.argv) == 3:
                result = apply(json.loads(sys.argv[2]))
            elif command == 'confirm' and len(sys.argv) == 3:
                result = confirm(sys.argv[2])
            elif command == 'revert' and len(sys.argv) == 3:
                result = revert(sys.argv[2])
            else:
                raise ValueError(tr('Uso: backend.py catalog | validate/apply JSON | confirm/revert TOKEN', 'Usage: backend.py catalog | validate/apply JSON | confirm/revert TOKEN'))
        print(json.dumps(result, ensure_ascii=False))
    except (OSError, ValueError, RuntimeError, KeyError, TypeError, subprocess.TimeoutExpired) as error:
        print(json.dumps(dict(ok=False, message=str(error)), ensure_ascii=False))
        raise SystemExit(1)


if __name__ == '__main__':
    main()

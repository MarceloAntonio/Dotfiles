"""Pure backend tests: no Hyprland calls and no real monitor changes."""
import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('monitor_backend', Path(__file__).with_name('backend.py'))
backend = importlib.util.module_from_spec(spec)
spec.loader.exec_module(backend)

MONITORS = [dict(name='eDP-1',width=1920,height=1080,refreshRate=59.999,x=0,y=0,scale=1,transform=0,
                 disabled=False,availableModes=['1920x1080@60.00Hz']),
            dict(name='HDMI-A-1',width=1920,height=1080,refreshRate=144,x=1920,y=0,scale=1,transform=0,
                 disabled=False,availableModes=['1920x1080@144.00Hz','1920x1080@60.00Hz'])]
LAYOUT = dict(monitors=backend.snapshot(MONITORS),primary='HDMI-A-1')

class BackendTests(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory()
        root=Path(self.temp.name)
        self.patches=[patch.object(backend,'RUNTIME',root),patch.object(backend,'PENDING',root/'pending.json'),
                      patch.object(backend,'SAVED',root/'layout.json'),patch.object(backend,'MANAGED',root/'generated.lua'),
                      patch.object(backend,'monitors',return_value=copy.deepcopy(MONITORS))]
        for p in self.patches:p.start()
        self.addCleanup(self.temp.cleanup)
        for p in self.patches:self.addCleanup(p.stop)

    def test_mode_tolerance_and_catalog(self):
        self.assertEqual(backend.current_mode(MONITORS[0]),'1920x1080@60.00')
        self.assertEqual(len(backend.catalog()['monitors']),2)

    def test_reject_invalid_layouts_before_any_mutation(self):
        invalid=[]
        x=copy.deepcopy(LAYOUT);x['monitors'][1]['mode']='3840x2160@144.00';invalid.append(x)
        x=copy.deepcopy(LAYOUT);x['monitors'][1]['x']=100;invalid.append(x)
        x=copy.deepcopy(LAYOUT);x['monitors'][1]['scale']=float('nan');invalid.append(x)
        x=copy.deepcopy(LAYOUT);x['monitors'][1]['name']='eDP-1';invalid.append(x)
        x=copy.deepcopy(LAYOUT);x['primary']='unknown';invalid.append(x)
        x=copy.deepcopy(LAYOUT)
        for m in x['monitors']:m['disabled']=True
        invalid.append(x)
        for payload in invalid:
            with self.assertRaises(ValueError):backend.validate(payload,MONITORS)

    def test_arm_watchdog_before_preview_and_revert(self):
        events=[]
        with patch.object(backend.subprocess,'Popen',side_effect=lambda *a,**k:events.append('watchdog')), \
             patch.object(backend,'runtime_apply',side_effect=lambda layout:events.append('apply')):
            result=backend.apply(copy.deepcopy(LAYOUT))
            self.assertEqual(events,['watchdog','apply'])
            self.assertTrue(backend.PENDING.exists())
            backend.revert(result['token'])
            self.assertFalse(backend.PENDING.exists())
        self.assertFalse(backend.MANAGED.exists())

    def test_confirmation_persists_only_with_matching_token(self):
        with patch.object(backend.subprocess,'Popen'),patch.object(backend,'runtime_apply'),patch.object(backend,'call',return_value='ok'):
            result=backend.apply(copy.deepcopy(LAYOUT))
            with self.assertRaises(ValueError):backend.confirm('incorrect')
            self.assertFalse(backend.MANAGED.exists())
            backend.confirm(result['token'])
            self.assertEqual(json.loads(backend.SAVED.read_text())['primary'],'HDMI-A-1')
            self.assertIn('hl.monitor',backend.MANAGED.read_text())
            self.assertFalse(backend.PENDING.exists())

    def test_expired_confirmation_rolls_back(self):
        with patch.object(backend.subprocess,'Popen'),patch.object(backend,'runtime_apply') as apply:
            result=backend.apply(copy.deepcopy(LAYOUT))
            pending=json.loads(backend.PENDING.read_text());pending['deadline']=0
            backend.PENDING.write_text(json.dumps(pending))
            with self.assertRaises(ValueError):backend.confirm(result['token'])
            self.assertEqual(apply.call_count,2)
            self.assertFalse(backend.PENDING.exists())
            self.assertFalse(backend.MANAGED.exists())

    def test_failed_save_keeps_watchdog_and_restores_persistent_files(self):
        backend.MANAGED.write_text('original lua')
        backend.SAVED.write_text('{"primary":"eDP-1"}')
        with patch.object(backend.subprocess,'Popen'),patch.object(backend,'runtime_apply'):
            result=backend.apply(copy.deepcopy(LAYOUT))
        with patch.object(backend,'call',side_effect=RuntimeError('IPC unavailable')):
            with self.assertRaises(RuntimeError):backend.confirm(result['token'])
        self.assertEqual(backend.MANAGED.read_text(),'original lua')
        self.assertEqual(json.loads(backend.SAVED.read_text())['primary'],'eDP-1')
        self.assertTrue(backend.PENDING.exists())

if __name__=='__main__':unittest.main()

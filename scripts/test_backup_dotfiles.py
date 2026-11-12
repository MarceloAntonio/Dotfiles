"""Backup boundaries and portable normalization, isolated from the real HOME."""
import contextlib
import importlib.util
import io
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location('backup_dotfiles', Path(__file__).with_name('backup_dotfiles.py'))
backup = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(backup)


class BackupTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.base = Path(self.temporary.name)
        self.home = self.base / 'home'
        self.repo = self.base / 'clone-with-another-name'
        self.home.mkdir(); self.repo.mkdir()
        subprocess.run(['git','init','-q',str(self.repo)],check=True)
        for name, value in [('HOME',self.home),('DOTFILES_DIR',self.repo)]:
            patcher = patch.object(backup,name,value); patcher.start(); self.addCleanup(patcher.stop)

    def write(self, root, name, value='test\n'):
        path=root/name; path.parent.mkdir(parents=True,exist_ok=True); path.write_text(value)
        return path

    def paths(self):
        return [dst.relative_to(self.repo).as_posix() for _,dst in backup.find_all_changes()]

    def copy(self):
        with contextlib.redirect_stdout(io.StringIO()):
            backup.copy_files(backup.find_all_changes())

    def test_local_allowlist_does_not_copy_unrelated_launchers_or_desktops(self):
        for name in backup.LOCAL_FILES:
            self.write(self.home,name)
        for name in ['.local/bin/personal-tool','.local/share/applications/private.desktop',
                     '.local/share/dbus-1/services/private.service','.config/systemd/user/private.service']:
            self.write(self.home,name,'secret\n')
            self.write(self.repo,name,'old\n')
        self.assertEqual(set(self.paths()),backup.LOCAL_FILES)

    def test_owned_shell_discovers_new_components_but_not_cache_or_logs(self):
        for name in ['.config/quickshell/control-center/New.qml','.config/quickshell/session-lock/new.py',
                     '.config/quickshell/control-center/widgets/qmldir']:
            self.write(self.home,name)
        for name in ['.config/quickshell/control-center/__pycache__/secret.py',
                     '.config/quickshell/control-center/foo.qml.bak','.config/quickshell/session-lock/password.log']:
            self.write(self.home,name,'private')
        self.assertEqual(len(self.paths()),3)

    def test_state_and_obsolete_files_never_reintroduced(self):
        for name in [*backup.EXCLUDED_FILES,'.config/waybar/config','.config/swaync/config.json',
                     '.config/pulsar/theme.toml','.config/hypr/hyprlock/wallpaper',
                     '.config/systemd/user/graphical-session.target.wants/rice-lock-bridge.service']:
            self.write(self.home,name,'new')
            self.write(self.repo,name,'old')
        self.assertEqual(self.paths(),[])

    def test_normalization_happens_before_compare_so_backups_are_idempotent(self):
        fixtures = {
            '.local/share/applications/rice-monitors.desktop':
                '[Desktop Entry]\nExec='+str(self.home)+'/.local/bin/rice-monitors\n',
            '.config/rofi/config.rasi':
                '@import "'+str(self.home)+'/.config/rofi/themes/shell-palette.rasi"\n',
            '.config/hypr/configs/autostart.lua':
                'hl.on("hyprland.start", function()\n    hl.exec_cmd("nm-applet --indicator &")\n    hl.exec_cmd("qs -c control-center")\nend)\n',
            '.config/hypr/configs/windowrules.lua':
                'hl.layer_rule({\n    name = "blur-waybar",\n    blur = true,\n})\n\n'
                'hl.layer_rule({\n    name = "blur-quickshell-controls",\n    match = { namespace = "^qs-(bar|calendar|control-center|osd|notifications|personalize)$" },\n})\n',
        }
        for name, value in fixtures.items():
            self.write(self.home,name,value)
            self.write(self.repo,name,'old\n')
        self.copy()
        desktop=(self.repo/'.local/share/applications/rice-monitors.desktop').read_text()
        self.assertIn('@HOME@/.local/bin/rice-monitors',desktop)
        self.assertEqual((self.repo/'.config/rofi/config.rasi').read_text(),'@import "themes/shell-palette.rasi"\n')
        self.assertNotIn('nm-applet',(self.repo/'.config/hypr/configs/autostart.lua').read_text())
        rules=(self.repo/'.config/hypr/configs/windowrules.lua').read_text()
        self.assertNotIn('blur-waybar',rules); self.assertIn('|commands|power|monitors|workspace-overview)',rules)
        self.assertEqual(self.paths(),[])

    def test_relative_symlink_preserved_and_absolute_symlink_rejected(self):
        self.write(self.home,'.config/kitty/Adaptativo.conf')
        self.write(self.repo,'.config/kitty/Adaptativo.conf')
        current=self.home/'.config/kitty/current-theme.conf'; current.symlink_to('Adaptativo.conf')
        self.write(self.repo,'.config/kitty/current-theme.conf','old')
        absolute=self.home/'.config/kitty/private.conf'; absolute.symlink_to(self.home/'secret')
        self.write(self.repo,'.config/kitty/private.conf','old')
        self.copy()
        self.assertTrue((self.repo/'.config/kitty/current-theme.conf').is_symlink())
        self.assertEqual((self.repo/'.config/kitty/current-theme.conf').readlink(),Path('Adaptativo.conf'))
        self.assertEqual((self.repo/'.config/kitty/private.conf').read_text(),'old')
        self.assertEqual(self.paths(),[])

    def test_gitignore_and_dry_run_do_not_write(self):
        self.write(self.repo,'.gitignore','*.local.qml\n')
        self.write(self.home,'.config/quickshell/control-center/private.local.qml')
        self.write(self.home,'.config/quickshell/control-center/Public.qml')
        self.assertEqual(self.paths(),['.config/quickshell/control-center/Public.qml'])
        with contextlib.redirect_stdout(io.StringIO()):
            backup.copy_files(backup.find_all_changes(),dry_run=True)
        self.assertFalse((self.repo/'.config/quickshell/control-center/Public.qml').exists())

    def test_cli_locates_repository_from_script_not_home_dotfiles(self):
        script=self.repo/'scripts/backup_dotfiles.py'; script.parent.mkdir()
        shutil.copy2(Path(backup.__file__),script)
        self.write(self.repo,'.zshrc','old\n'); self.write(self.home,'.zshrc','new\n')
        env=os.environ.copy(); env['HOME']=str(self.home)
        result=subprocess.run(['python',str(script),'--dry'],cwd=self.base,env=env,capture_output=True,text=True,check=True)
        self.assertIn('.zshrc',result.stdout)
        self.assertEqual((self.repo/'.zshrc').read_text(),'old\n')


if __name__=='__main__': unittest.main()

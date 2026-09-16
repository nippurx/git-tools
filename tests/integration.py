"""Real Git integration tests; isolated config and local bare remotes only."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SH = shutil.which('sh') or r'C:\Program Files\Git\bin\sh.exe'


class GitToolsTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='git-tools-')
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.work = self.base / 'project with spaces'
        self.work.mkdir()
        self.env = os.environ.copy()
        for key in list(self.env):
            if key.startswith('GIT_'):
                del self.env[key]
        self.env.update(GIT_CONFIG_GLOBAL=str(self.base / 'gitconfig'),
                        GIT_CONFIG_NOSYSTEM='1', GIT_TERMINAL_PROMPT='0',
                        HOME=str(self.base), GIT_AUTHOR_NAME='Test',
                        GIT_AUTHOR_EMAIL='test@example.invalid',
                        GIT_COMMITTER_NAME='Test', GIT_COMMITTER_EMAIL='test@example.invalid')
        self.run_cmd([SH, str(ROOT / 'install.sh')])

    def run_cmd(self, args, ok=True, cwd=None):
        p = subprocess.run(args, cwd=cwd or self.work, env=self.env,
                           input='', capture_output=True, encoding='utf-8', errors='replace')
        if ok:
            self.assertEqual(p.returncode, 0, p.stdout + p.stderr)
        else:
            self.assertNotEqual(p.returncode, 0, p.stdout + p.stderr)
        return p.stdout.strip()

    def git(self, *args, **kwargs):
        return self.run_cmd(['git', *args], **kwargs)

    def write(self, text, name='file.txt'):
        (self.work / name).write_text(text, encoding='utf-8')

    def test_local_workflow(self):
        self.write('initial')
        self.git('start', 'inicio con espacios')
        self.git('switch', '-c', 'feature/test')
        self.git('release', 'estable')
        release = self.git('tag')
        self.write('changed')
        self.write('new', 'new.txt')
        self.git('backup')
        before = self.git('rev-parse', 'HEAD')
        self.git('rollback-release')
        self.assertEqual((self.work / 'file.txt').read_text(), 'initial')
        self.assertFalse((self.work / 'new.txt').exists())
        self.assertEqual(self.git('rev-parse', 'HEAD^'), before)
        self.assertEqual(self.git('branch', '--show-current'), 'feature/test')
        self.git('release')
        self.assertIn(release + '.1', self.git('tag').splitlines())
        self.write('unsaved')
        head = self.git('rev-parse', 'HEAD')
        self.git('rollback', release, ok=False)
        self.assertEqual(self.git('rev-parse', 'HEAD'), head)
        self.assertEqual((self.work / 'file.txt').read_text(), 'unsaved')

    def test_remote_and_subdirectory(self):
        remote = self.base / 'remote.git'
        self.git('init', '--bare', str(remote))
        self.write('one')
        self.git('start', 'initial', remote.as_uri())
        self.git('switch', '-c', 'topic')
        sub = self.work / 'sub'
        sub.mkdir()
        self.write('two')
        self.git('release', 'publish', cwd=sub)
        tag = self.git('tag')
        self.write('three')
        self.git('backup', cwd=sub)
        self.git('rollback', tag, cwd=sub)
        self.assertEqual((self.work / 'file.txt').read_text(), 'two')
        self.assertEqual(self.git('rev-parse', 'HEAD'), self.git('--git-dir', str(remote), 'rev-parse', 'refs/heads/topic'))
        self.git('rollback', 'missing-tag', ok=False)
        backup = next(t for t in self.git('tag').splitlines() if t.startswith('backup-'))
        self.git('rollback-release', backup, ok=False)

    def test_hook_failure_and_detached_head(self):
        self.git('start')
        hook = self.work / '.git/hooks/pre-commit'
        hook.write_text('#!/bin/sh\nexit 1\n')
        hook.chmod(0o755)
        self.write('must not be tagged')
        head = self.git('rev-parse', 'HEAD')
        self.git('release', ok=False)
        self.assertEqual(self.git('tag'), '')
        self.assertEqual(self.git('rev-parse', 'HEAD'), head)
        hook.unlink()
        self.git('reset', '--hard')
        self.git('checkout', '--detach')
        self.git('backup', ok=False)

    def test_installers_and_idempotence(self):
        aliases = {name: self.git('config', '--global', '--get', 'alias.' + name)
                   for name in ('start', 'backup', 'release', 'rollback', 'rollback-release')}
        self.git('config', '--global', 'alias.custom', 'status -sb')
        self.run_cmd([SH, str(ROOT / 'install.sh')])
        self.run_cmd([SH, str(ROOT / 'install.sh'), 'invalid/user'], ok=False)
        if os.name == 'nt':
            self.run_cmd(['powershell', '-NoProfile', '-ExecutionPolicy', 'Bypass',
                          '-File', str(ROOT / 'install.ps1'), '-NonInteractive'])
            self.run_cmd(['cmd', '/c', str(ROOT / 'install.bat'), '--no-pause'])
        for name, value in aliases.items():
            self.assertEqual(self.git('config', '--global', '--get', 'alias.' + name), value)
            self.assertEqual(self.git('config', '--global', '--get-all', 'alias.' + name), value)
        self.assertEqual(self.git('config', '--global', '--get', 'alias.custom'), 'status -sb')
        self.git('start')
        self.git('backup')
        self.git('release', 'quote " dollar $ backtick ` apostrophe \'')
        self.git('rollback-release')

    def test_rejected_push_is_atomic(self):
        remote = self.base / 'remote.git'
        self.git('init', '--bare', str(remote))
        self.git('start', remote.as_uri())
        remote_head = self.git('--git-dir', str(remote), 'rev-parse', 'main')
        hook = remote / 'hooks/pre-receive'
        hook.write_text('#!/bin/sh\nexit 1\n')
        hook.chmod(0o755)
        self.write('local only')
        self.git('release', ok=False)
        self.assertNotEqual(self.git('rev-parse', 'HEAD'), remote_head)
        self.assertTrue(self.git('tag'))
        self.assertEqual(self.git('--git-dir', str(remote), 'tag'), '')
        self.assertEqual(self.git('--git-dir', str(remote), 'rev-parse', 'main'), remote_head)

    def test_empty_restore_and_existing_origin(self):
        self.git('start')
        self.git('release')
        empty_tag = self.git('tag')
        self.write('later')
        self.git('backup')
        self.git('rollback', empty_tag)
        self.assertFalse((self.work / 'file.txt').exists())
        self.git('remote', 'add', 'origin', 'file:///does-not-exist.git')
        before = self.git('rev-parse', 'HEAD')
        self.git('start', 'file:///another.git', ok=False)
        self.assertEqual(self.git('remote', 'get-url', 'origin'), 'file:///does-not-exist.git')
        self.write('unsaved')
        self.git('backup', ok=False)
        self.assertEqual(self.git('rev-parse', 'HEAD'), before)
        self.assertEqual((self.work / 'file.txt').read_text(), 'unsaved')

    def test_numeric_tag_collisions_and_latest_release(self):
        self.git('start')
        self.git('release')
        base = self.git('tag')
        # Reserve versions with the same timestamp to exercise numeric tie-breaking.
        for n in range(1, 11):
            self.git('tag', '-a', base + '.' + str(n), '-m', 'reserved')
        self.write('latest')
        self.git('release')
        self.assertIn(base + '.11', self.git('tag').splitlines())
        self.write('later')
        self.git('backup')
        self.git('rollback-release')
        self.assertEqual((self.work / 'file.txt').read_text(), 'latest')


if __name__ == '__main__':
    unittest.main(verbosity=2)

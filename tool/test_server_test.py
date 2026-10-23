"""Offline regression checks for the isolated local integration entrypoint."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

SOURCE_ROOT = Path(__file__).resolve().parents[1]


class ServerTestEntrypointTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="server-entrypoint-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve() / "worktree with spaces"
        self.root.mkdir()
        for name in ("scripts", "tool", "apps/auravibes_server", "bin"):
            (self.root / name).mkdir(parents=True)
        for name in ("test_server.sh", "serverpod_worktree_env.sh"):
            shutil.copy(SOURCE_ROOT / "scripts" / name, self.root / "scripts" / name)
        subprocess.run(["git", "init", "-q", str(self.root)], check=True)
        self.log = self.root / "calls.jsonl"
        self.env = {
            **os.environ,
            "PATH": f"{self.root / 'bin'}:{os.environ['PATH']}",
            "CALL_LOG": str(self.log),
        }
        self.write_executable("docker", '''#!/usr/bin/env python3
import os,sys
print('docker-private-detail', file=sys.stderr)
if sys.argv[1] == 'info': sys.exit(int(os.environ.get('DOCKER_EXIT', '0')))
assert sys.argv[1:3] == ['compose', '--project-name']
assert sys.argv[3] == os.environ['AURAVIBES_SERVER_PROJECT']
assert 'postgres_test' in sys.argv
if 'pg_isready' in sys.argv: sys.exit(int(os.environ.get('DATABASE_EXIT', '0')))
if 'port' in sys.argv:
 print(os.environ.get('PORT_OVERRIDE', '127.0.0.1:' + os.environ['AURAVIBES_SERVER_TEST_POSTGRES_PORT']))
 sys.exit(0)
raise SystemExit(9)
''')
        self.write_executable("fvm", '''#!/usr/bin/env python3
import json,os,sys
with open(os.environ['CALL_LOG'], 'a') as f:
 f.write(json.dumps({'args':sys.argv[1:], 'cwd':os.getcwd(), 'port':os.environ['SERVERPOD_DATABASE_PORT'], 'expected':os.environ['AURAVIBES_SERVER_TEST_POSTGRES_PORT'], 'host':os.environ['SERVERPOD_DATABASE_HOST']})+'\\n')
if 'check_test_credentials.dart' in ' '.join(sys.argv): sys.exit(int(os.environ.get('CREDENTIAL_EXIT', '0')))
sys.exit(int(os.environ.get('TEST_EXIT', '0')))
''')
        (self.root / "tool/validation_lease.py").write_text('''import os,sys
assert sys.argv[1:4] == ['--label', 'server-integration', '--']
os.execvp(sys.argv[4], sys.argv[4:])
''')

    def write_executable(self, name, content):
        path = self.root / "bin" / name
        path.write_text(content)
        path.chmod(0o755)

    def run_script(self, *args, cwd=None):
        return subprocess.run(
            ["bash", str(self.root / "scripts/test_server.sh"), *args],
            cwd=cwd or self.root, env=self.env, capture_output=True, text=True,
        )

    def calls(self):
        return [json.loads(line) for line in self.log.read_text().splitlines()]

    def test_runs_from_root_and_package_with_isolated_port(self):
        ports = []
        for cwd in (self.root, self.root / "apps/auravibes_server"):
            result = self.run_script(cwd=cwd)
            self.assertEqual(result.returncode, 0, result.stderr)
            call = self.calls()[-1]
            self.assertEqual(call["cwd"], str(self.root / "apps/auravibes_server"))
            self.assertEqual(call["args"], ["dart", "test", "test/integration", "--reporter=compact"])
            self.assertEqual(call["port"], call["expected"])
            self.assertEqual(call["host"], "localhost")
            ports.append(call["port"])
        self.assertEqual(ports[0], ports[1])

    def test_preserves_arguments_and_test_exit(self):
        self.env["TEST_EXIT"] = "17"
        result = self.run_script("test/integration/a test.dart", "--name", "some test", "--reporter=expanded")
        self.assertEqual(result.returncode, 17)
        self.assertEqual(self.calls()[-1]["args"], ["dart", "test", "test/integration/a test.dart", "--name", "some test", "--reporter=expanded"])

    def test_flags_only_keep_default_test_directory(self):
        self.assertEqual(self.run_script("--name", "some test").returncode, 0)
        self.assertEqual(self.calls()[-1]["args"], ["dart", "test", "test/integration", "--name", "some test"])

    def test_options_before_path_do_not_expand_selection(self):
        result = self.run_script("--name", "some test", "test/integration/only.dart")
        self.assertEqual(result.returncode, 0)
        self.assertEqual(self.calls()[-1]["args"], ["dart", "test", "--name", "some test", "test/integration/only.dart"])

    def test_value_options_do_not_become_test_paths(self):
        result = self.run_script("--coverage-path", "coverage.lcov", "--suite-load-timeout", "2m", "-c", "kernel")
        self.assertEqual(result.returncode, 0)
        self.assertEqual(self.calls()[-1]["args"], ["dart", "test", "test/integration", "--coverage-path", "coverage.lcov", "--suite-load-timeout", "2m", "-c", "kernel"])

    def test_credential_failure_does_not_start_tests(self):
        self.env["CREDENTIAL_EXIT"] = "2"
        self.assertEqual(self.run_script().returncode, 2)
        self.assertEqual(len(self.calls()), 1)

    def test_unavailable_docker_database_and_wrong_port_stop_before_dart(self):
        for variable, value in (("DOCKER_EXIT", "1"), ("DATABASE_EXIT", "1"), ("PORT_OVERRIDE", "127.0.0.1:1")):
            with self.subTest(variable=variable):
                self.env[variable] = value
                result = self.run_script()
                self.assertEqual(result.returncode, 2)
                self.assertFalse(self.log.exists())
                self.assertNotIn("docker-private-detail", result.stdout + result.stderr)
                self.env.pop(variable)

    def test_wrong_invocation_location_fails(self):
        with tempfile.TemporaryDirectory() as outside:
            result = self.run_script(cwd=outside)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.log.exists())

    def test_two_worktrees_use_distinct_compose_identity_and_scoped_ports(self):
        def identity(path):
            result = subprocess.run(
                ["bash", "-c", f'source "{SOURCE_ROOT}/scripts/serverpod_worktree_env.sh"; echo "$AURAVIBES_SERVER_PROJECT $AURAVIBES_SERVER_TEST_POSTGRES_PORT"'],
                cwd=path, capture_output=True, text=True, check=True,
            )
            return result.stdout.split()
        with tempfile.TemporaryDirectory() as other:
            subprocess.run(["git", "init", "-q", other], check=True)
            first, second = identity(self.root), identity(other)
        self.assertNotEqual(first[0], second[0])
        # The existing hash allocator has a finite port range, not uniqueness guarantees.
        for port in (first[1], second[1]):
            self.assertTrue(10000 <= int(port) < 20000)


if __name__ == "__main__":
    unittest.main()

"""Regression checks for read-only agent worktree tooling."""

from contextlib import redirect_stdout
import io
import json
import os
from pathlib import Path
import stat
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

import agent_worktree
from agent_worktree import _issue_conflicts, _mentions_issue, _parse_worktrees
from agent_worktree import _readiness_checks, _worktree_status


class AgentWorktreeTest(unittest.TestCase):
    @staticmethod
    def _doctor_fixture(root):
        root.mkdir(parents=True, exist_ok=True)
        (root / ".fvmrc").write_text(json.dumps({"flutter": "3.47.9"}))
        (root / "pubspec.yaml").write_text(
            "name: auravibes_workspace\n"
            "melos:\n"
            "  sdkPath: .fvm/flutter_sdk\n"
            "  command:\n"
            "    bootstrap:\n"
            "      runPubGetInParallel: true\n"
        )
        return root

    @staticmethod
    def _doctor_sdk(root, *, metadata_version="3.47.9", link=True):
        sdk = root.parent / "shared-sdk" / "3.47.9"
        sdk.mkdir(parents=True, exist_ok=True)
        if metadata_version is not None:
            metadata = sdk / "bin" / "cache" / "flutter.version.json"
            metadata.parent.mkdir(parents=True, exist_ok=True)
            metadata.write_text(
                json.dumps({"frameworkVersion": metadata_version})
            )
        if link:
            fvm_dir = root / ".fvm"
            fvm_dir.mkdir(parents=True, exist_ok=True)
            (fvm_dir / "flutter_sdk").symlink_to(sdk, target_is_directory=True)
        return sdk

    @staticmethod
    def _doctor_package_config(root, root_uri="../apps/auravibes_app"):
        package_config = root / ".dart_tool" / "package_config.json"
        package_config.parent.mkdir(parents=True, exist_ok=True)
        package_config.write_text(
            json.dumps(
                {
                    "configVersion": 2,
                    "packages": [
                        {"name": "auravibes_app", "rootUri": root_uri}
                    ],
                }
            )
        )
        return package_config

    def _doctor_checks(self, root, *, pub_cache=None):
        checks = getattr(agent_worktree, "_toolchain_checks", None)
        self.assertTrue(
            callable(checks), "toolchain doctor check helper has not been added"
        )
        if pub_cache is None:
            pub_cache = root / "pub-cache"
        return checks(root, pub_cache=pub_cache)

    def _doctor_check(self, root, name, *, pub_cache=None):
        checks = self._doctor_checks(root, pub_cache=pub_cache)
        return next(check for check in checks if check["name"] == name)

    @staticmethod
    def _snapshot_tree(root):
        snapshot = {}
        for current, directories, files in os.walk(root, followlinks=False):
            current_path = Path(current)
            for name in [*directories, *files]:
                path = current_path / name
                relative = path.relative_to(root).as_posix()
                if path.is_symlink():
                    snapshot[relative] = ("symlink", os.readlink(path))
                elif path.is_dir():
                    snapshot[relative] = (
                        "directory",
                        stat.S_IMODE(path.stat().st_mode),
                    )
                else:
                    snapshot[relative] = ("file", path.read_bytes())
        return snapshot

    def test_parses_linked_and_prunable_worktrees(self):
        parsed = _parse_worktrees(
            "worktree /repo\n"
            "HEAD abc123\n"
            "branch refs/heads/main\n\n"
            "worktree /repo/issue\n"
            "HEAD def456\n"
            "branch refs/heads/issue-123-fix\n"
            "locked in progress\n\n"
            "worktree /repo/old\n"
            "HEAD fedcba\n"
            "prunable gitdir file missing\n"
        )

        self.assertEqual(len(parsed), 3)
        self.assertEqual(parsed[0]["branch"], "main")
        self.assertEqual(parsed[1]["branch"], "issue-123-fix")
        self.assertEqual(parsed[1]["locked"], "in progress")
        self.assertIn("prunable", parsed[2])

    def test_issue_matching_respects_number_boundaries(self):
        self.assertTrue(_mentions_issue("chore/issue-12-preflight", 12))
        self.assertTrue(_mentions_issue("fix #12", 12))
        self.assertFalse(_mentions_issue("issue-123-preflight", 12))
        self.assertFalse(_mentions_issue("ticket-120", 12))
        self.assertFalse(_mentions_issue(None, 12))

    def test_readiness_checks_validate_pinned_sdk_workspace_and_devtools(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            sdk = root / "3.47.7"
            sdk.mkdir()
            (root / ".fvmrc").write_text(json.dumps({"flutter": "3.47.7"}))
            fvm = root / ".fvm"
            fvm.mkdir()
            sdk_link = fvm / "flutter_sdk"
            sdk_link.symlink_to(sdk, target_is_directory=True)

            package_config = root / ".dart_tool" / "package_config.json"
            package_config.parent.mkdir()
            valid_config = {
                "packages": [
                    {"name": "auravibes_app", "rootUri": "../apps/auravibes_app"}
                ]
            }
            package_config.write_text(json.dumps(valid_config))
            devtools = root / "apps" / "auravibes_app" / "devtools_options.yaml"
            devtools.parent.mkdir(parents=True)
            devtools.write_text("extensions: []\\n")

            self.assertTrue(all(check["ok"] for check in _readiness_checks(root)))

            package_config.write_text(
                json.dumps(
                    {"packages": [{"name": "auravibes_app", "rootUri": "../../outside"}]}
                )
            )
            checks = _readiness_checks(root)
            self.assertEqual(
                [check["name"] for check in checks if not check["ok"]],
                ["resolved Pub workspace config"],
            )
            package_config.write_text(json.dumps(valid_config))

            wrong_sdk = root / "3.47.6"
            wrong_sdk.mkdir()
            sdk_link.unlink()
            sdk_link.symlink_to(wrong_sdk, target_is_directory=True)
            checks = _readiness_checks(root)
            self.assertEqual(
                [check["name"] for check in checks if not check["ok"]],
                ["pinned Flutter SDK"],
            )

            sdk_link.unlink()
            sdk_link.symlink_to(sdk, target_is_directory=True)

            devtools.unlink()
            checks = _readiness_checks(root)
            self.assertEqual(
                [check["name"] for check in checks if not check["ok"]],
                ["app DevTools configuration"],
            )

    def test_doctor_reports_missing_fvm_cli(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = self._doctor_fixture(Path(temp_dir) / "checkout")
            with patch("shutil.which", return_value=None):
                check = self._doctor_check(root, "FVM CLI")

        self.assertEqual(check["status"], "mismatch")
        self.assertEqual(check["expected"], "fvm available in PATH")
        self.assertEqual(check["observed"], "not found in PATH")
        self.assertEqual(check["next_step"], "dart pub global activate fvm")

    def test_doctor_reports_missing_fvm_link_with_available_fvm(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = self._doctor_fixture(Path(temp_dir) / "checkout")
            with patch("shutil.which", return_value="/usr/local/bin/fvm"):
                check = self._doctor_check(root, "pinned Flutter SDK")

        self.assertEqual(check["status"], "mismatch")
        self.assertEqual(check["expected"], "Flutter 3.47.9")
        self.assertEqual(check["observed"], "missing .fvm/flutter_sdk link")
        self.assertEqual(
            check["next_step"],
            'fvm use "$(python3 -c \'import json; '
            'print(json.load(open(".fvmrc"))["flutter"])\')" --skip-pub-get',
        )

    def test_doctor_recommends_fvm_install_before_link_repair(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = self._doctor_fixture(Path(temp_dir) / "checkout")
            with patch("shutil.which", return_value=None):
                check = self._doctor_check(root, "pinned Flutter SDK")

        self.assertEqual(check["status"], "mismatch")
        self.assertEqual(check["next_step"], "dart pub global activate fvm")

    def test_doctor_reports_sdk_version_mismatch(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = self._doctor_fixture(Path(temp_dir) / "checkout")
            sdk = self._doctor_sdk(root, metadata_version="3.47.8")
            with patch("shutil.which", return_value="/usr/local/bin/fvm"):
                check = self._doctor_check(root, "pinned Flutter SDK")

        self.assertEqual(sdk.name, "3.47.9")
        self.assertEqual(check["status"], "mismatch")
        self.assertEqual(check["expected"], "Flutter 3.47.9")
        self.assertEqual(
            check["observed"],
            "flutter.version.json reports Flutter 3.47.8",
        )

    def test_doctor_reports_dangling_fvm_link(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = self._doctor_fixture(Path(temp_dir) / "checkout")
            fvm_dir = root / ".fvm"
            fvm_dir.mkdir()
            (fvm_dir / "flutter_sdk").symlink_to(
                Path(temp_dir) / "missing-sdk", target_is_directory=True
            )
            with patch("shutil.which", return_value="/usr/local/bin/fvm"):
                check = self._doctor_check(root, "pinned Flutter SDK")

        self.assertEqual(check["status"], "mismatch")
        self.assertEqual(check["observed"], "dangling .fvm/flutter_sdk link")

    def test_doctor_reports_non_symlink_fvm_sdk_path(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = self._doctor_fixture(Path(temp_dir) / "checkout")
            sdk_link = root / ".fvm" / "flutter_sdk"
            sdk_link.mkdir(parents=True)
            with patch("shutil.which", return_value="/usr/local/bin/fvm"):
                check = self._doctor_check(root, "pinned Flutter SDK")

        self.assertEqual(check["status"], "mismatch")
        self.assertEqual(check["observed"], "not an FVM symlink")

    def test_doctor_marks_sdk_version_unknown_when_metadata_is_missing(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = self._doctor_fixture(Path(temp_dir) / "checkout")
            self._doctor_sdk(root, metadata_version=None)
            with patch("shutil.which", return_value="/usr/local/bin/fvm"):
                check = self._doctor_check(root, "pinned Flutter SDK")

        self.assertEqual(check["status"], "unknown")
        self.assertIn("version metadata unavailable", check["observed"])

    def test_doctor_marks_malformed_fvmrc_version_unknown(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = self._doctor_fixture(Path(temp_dir) / "checkout")
            (root / ".fvmrc").write_text("{")
            with patch("shutil.which", return_value="/usr/local/bin/fvm"):
                check = self._doctor_check(root, "pinned Flutter SDK")

        self.assertEqual(check["status"], "unknown")
        self.assertEqual(check["expected"], "Flutter version from .fvmrc")
        self.assertIn("could not read", check["observed"])

    def test_doctor_marks_missing_fvmrc_version_unknown(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = self._doctor_fixture(Path(temp_dir) / "checkout")
            (root / ".fvmrc").write_text(json.dumps({"channel": "stable"}))
            with patch("shutil.which", return_value="/usr/local/bin/fvm"):
                check = self._doctor_check(root, "pinned Flutter SDK")

        self.assertEqual(check["status"], "unknown")
        self.assertEqual(check["expected"], "Flutter version from .fvmrc")
        self.assertIn("flutter", check["observed"])

    def test_doctor_reports_missing_melos_bootstrap_configuration(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = self._doctor_fixture(Path(temp_dir) / "checkout")
            (root / "pubspec.yaml").write_text(
                "name: auravibes_workspace\nmelos:\n  sdkPath: .fvm/flutter_sdk\n"
            )
            check = self._doctor_check(root, "Melos bootstrap configuration")

        self.assertEqual(check["status"], "mismatch")
        self.assertIn("command.bootstrap", check["expected"])
        self.assertIn("missing", check["observed"])
        self.assertEqual(check["next_step"], "git diff -- pubspec.yaml")

    def test_doctor_reports_missing_pub_package_configuration_in_order(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = self._doctor_fixture(Path(temp_dir) / "checkout")
            with patch("shutil.which", return_value=None):
                check = self._doctor_check(
                    root, "resolved Pub workspace config"
                )

        self.assertEqual(check["status"], "mismatch")
        self.assertIn("bootstrap history unknown", check["observed"])
        steps = check["next_step"]
        activate = "dart pub global activate fvm"
        link_sdk = (
            'fvm use "$(python3 -c \'import json; '
            'print(json.load(open(".fvmrc"))["flutter"])\')" --skip-pub-get'
        )
        bootstrap = (
            "python3 tool/validation_lease.py -- fvm dart run melos bootstrap"
        )
        positions = [steps.index(command) for command in (activate, link_sdk, bootstrap)]
        self.assertEqual(positions, sorted(positions))

    def test_doctor_recommends_only_bootstrap_when_setup_is_ready(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = self._doctor_fixture(Path(temp_dir) / "checkout")
            self._doctor_sdk(root)
            with patch("shutil.which", return_value="/usr/local/bin/fvm"):
                check = self._doctor_check(
                    root, "resolved Pub workspace config"
                )

        self.assertEqual(check["status"], "mismatch")
        self.assertEqual(
            check["next_step"],
            "python3 tool/validation_lease.py -- fvm dart run melos bootstrap",
        )

    def test_doctor_reports_stale_package_configuration(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            base = Path(temp_dir)
            root = self._doctor_fixture(base / "checkout")
            other = base / "other-worktree"
            (other / "apps" / "auravibes_app").mkdir(parents=True)
            self._doctor_package_config(
                root, "../../other-worktree/apps/auravibes_app"
            )
            with patch("shutil.which", return_value=None):
                check = self._doctor_check(
                    root, "resolved Pub workspace config"
                )

        self.assertEqual(check["status"], "mismatch")
        self.assertIn(str(other / "apps" / "auravibes_app"), check["observed"])
        self.assertLess(
            check["next_step"].index("dart pub global activate fvm"),
            check["next_step"].index(
                "python3 tool/validation_lease.py -- fvm dart run melos bootstrap"
            ),
        )

    def test_doctor_reports_unwritable_shared_cache_without_mutating_it(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            base = Path(temp_dir)
            root = self._doctor_fixture(base / "checkout")
            cache = base / "pub-cache"
            cache.mkdir()
            entries_before = list(cache.iterdir())
            mode_before = stat.S_IMODE(cache.stat().st_mode)
            with (
                patch("shutil.which", return_value="/usr/local/bin/fvm"),
                patch("os.access", return_value=False),
            ):
                check = self._doctor_check(root, "Pub cache", pub_cache=cache)
            entries_after = list(cache.iterdir())
            mode_after = stat.S_IMODE(cache.stat().st_mode)

        self.assertEqual(check["status"], "mismatch")
        self.assertIn(str(cache), check["observed"])
        self.assertIn("not writable", check["observed"])
        self.assertEqual(entries_after, entries_before)
        self.assertEqual(mode_after, mode_before)

    def test_doctor_reports_shared_cache_as_unverified_warning(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            base = Path(temp_dir)
            root = self._doctor_fixture(base / "checkout")
            cache = base / "pub-cache"
            cache.mkdir()
            with (
                patch("shutil.which", return_value="/usr/local/bin/fvm"),
                patch("os.access", return_value=True),
            ):
                check = self._doctor_check(root, "Pub cache", pub_cache=cache)

        self.assertEqual(check["status"], "warning")
        self.assertIn("shared", check["observed"])
        self.assertNotIn("corrupt", check["observed"].lower())
        self.assertIn("ls -ld", check["next_step"])

    def test_doctor_marks_missing_cache_state_unknown(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = self._doctor_fixture(Path(temp_dir) / "checkout")
            cache = root.parent / "not-created-cache"
            with patch("shutil.which", return_value="/usr/local/bin/fvm"):
                check = self._doctor_check(root, "Pub cache", pub_cache=cache)

        self.assertEqual(check["status"], "unknown")
        self.assertIn("does not exist", check["observed"])
        self.assertIn("ls -ld", check["next_step"])

    def test_doctor_does_not_mutate_external_sdk_or_other_worktree(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            base = Path(temp_dir)
            root = self._doctor_fixture(base / "checkout")
            sdk = self._doctor_sdk(root)
            other = base / "other-worktree"
            (other / "apps" / "auravibes_app").mkdir(parents=True)
            (other / "sentinel.txt").write_text("leave unchanged")
            self._doctor_package_config(
                root, "../../other-worktree/apps/auravibes_app"
            )
            cache = base / "shared-cache"
            cache.mkdir()
            (cache / "sentinel.txt").write_text("shared state")
            snapshots = {
                path: self._snapshot_tree(path)
                for path in (root, sdk, other, cache)
            }
            with (
                patch("shutil.which", return_value="/usr/local/bin/fvm"),
                patch(
                    "agent_worktree.subprocess.run",
                    side_effect=AssertionError("diagnostic ran a subprocess"),
                ),
            ):
                self._doctor_checks(root, pub_cache=cache)

            for path, snapshot in snapshots.items():
                self.assertEqual(self._snapshot_tree(path), snapshot)

    def test_doctor_parser_accepts_json_output(self):
        build_parser = getattr(agent_worktree, "_build_parser", None)
        self.assertTrue(callable(build_parser), "doctor parser has not been added")

        args = build_parser().parse_args(["doctor", "--json"])

        self.assertEqual(args.command, "doctor")
        self.assertTrue(args.json)

    def test_doctor_text_output_distinguishes_certainty_and_evidence(self):
        format_doctor = getattr(agent_worktree, "_format_doctor", None)
        self.assertTrue(callable(format_doctor), "doctor formatter has not been added")
        checks = [
            {
                "name": "pinned Flutter SDK",
                "status": "mismatch",
                "expected": "Flutter 3.47.9",
                "observed": "Flutter 3.47.8",
                "next_step": "1. dart pub global activate fvm\n"
                "2. fvm use <pinned-version>",
            },
            {
                "name": "Pub cache",
                "status": "warning",
                "expected": "shared cache may be used",
                "observed": "external cache; other-worktree state unknown",
                "next_step": "ls -ld /shared/cache",
            },
            {
                "name": "SDK version metadata",
                "status": "unknown",
                "expected": "Flutter 3.47.9",
                "observed": "version metadata unavailable",
                "next_step": "cat .fvm/flutter_sdk/bin/cache/flutter.version.json",
            },
        ]

        output = format_doctor(checks)

        self.assertIn("CONFIRMED MISMATCH", output)
        self.assertIn("UNVERIFIED WARNING", output)
        self.assertIn("UNKNOWN", output)
        self.assertIn(
            "  Next steps:\n"
            "    1. dart pub global activate fvm\n"
            "    2. fvm use <pinned-version>",
            output,
        )
        for field in ("expected", "observed"):
            for check in checks:
                self.assertIn(check[field], output)
        for check in checks:
            for step in check["next_step"].splitlines():
                self.assertIn(step, output)

    def test_doctor_json_output_preserves_all_check_fields(self):
        format_doctor = getattr(agent_worktree, "_format_doctor", None)
        self.assertTrue(callable(format_doctor), "doctor formatter has not been added")
        checks = [
            {
                "name": "Pub cache",
                "status": "warning",
                "expected": "shared cache may be used",
                "observed": "external cache; other-worktree state unknown",
                "next_step": "ls -ld /shared/cache",
            }
        ]

        output = format_doctor(checks, as_json=True)

        self.assertEqual(json.loads(output), checks)

    def test_doctor_main_dispatches_and_returns_failure_for_confirmed_mismatch(self):
        build_parser = getattr(agent_worktree, "_build_parser", None)
        self.assertTrue(callable(build_parser), "doctor parser has not been added")
        self.assertEqual(
            build_parser().parse_args(["doctor"]).command,
            "doctor",
        )
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir) / "checkout"
            checks = [
                {
                    "name": "pinned Flutter SDK",
                    "status": "mismatch",
                    "expected": "Flutter 3.47.9",
                    "observed": "missing .fvm/flutter_sdk link",
                    "next_step": "fvm use <pinned-version>",
                }
            ]
            output = io.StringIO()
            with (
                patch("agent_worktree._repo_root", return_value=root),
                patch("agent_worktree._toolchain_checks", return_value=checks) as run,
                redirect_stdout(output),
            ):
                result = agent_worktree.main(["doctor", "--json"])

        run.assert_called_once_with(root)
        self.assertEqual(result, 1)
        self.assertEqual(json.loads(output.getvalue()), checks)

    def test_doctor_main_keeps_unknown_and_warning_nonfatal(self):
        build_parser = getattr(agent_worktree, "_build_parser", None)
        self.assertTrue(callable(build_parser), "doctor parser has not been added")
        self.assertEqual(
            build_parser().parse_args(["doctor"]).command,
            "doctor",
        )
        checks = [
            {
                "name": "Pub cache",
                "status": "warning",
                "expected": "shared cache may be used",
                "observed": "external cache state unverified",
                "next_step": "ls -ld /shared/cache",
            },
            {
                "name": "Flutter version metadata",
                "status": "unknown",
                "expected": "Flutter 3.47.9",
                "observed": "not available",
                "next_step": "cat .fvm/flutter_sdk/bin/cache/flutter.version.json",
            },
        ]
        output = io.StringIO()
        with (
            patch("agent_worktree._repo_root", return_value=Path("/repo")),
            patch("agent_worktree._toolchain_checks", return_value=checks),
            redirect_stdout(output),
        ):
            result = agent_worktree.main(["doctor"])

        self.assertEqual(result, 0)
        self.assertIn("UNVERIFIED WARNING", output.getvalue())
        self.assertIn("UNKNOWN", output.getvalue())

    def test_worktree_status_requires_git_status(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            listing = SimpleNamespace(
                stdout=f"worktree {root}\nbranch refs/heads/main\n\n"
            )
            with (
                patch(
                    "agent_worktree._run",
                    side_effect=[listing, RuntimeError("status failed")],
                ),
                patch(
                    "agent_worktree._readiness_checks",
                    return_value=[{"name": "checks", "ok": True}],
                ),
            ):
                status = _worktree_status(root)[0]

        self.assertEqual(status["state"], "error")
        self.assertFalse(status["ready"])
        self.assertEqual(status["blocked"], ["git status unavailable"])

    def test_issue_preflight_reports_other_worktrees_and_open_prs(self):
        worktree_output = (
            "worktree /repo\nbranch refs/heads/main\n\n"
            "worktree /tmp/issue\nbranch refs/heads/issue-12-two\n"
        )
        results = [
            SimpleNamespace(stdout="chore/issue-12-one\nissue-123-other\n"),
            SimpleNamespace(stdout="main\n"),
            SimpleNamespace(stdout=worktree_output),
            SimpleNamespace(
                stdout='[{"number": 99, "title": "Intermittent failure", '
                '"body": "Closes #12", "headRefName": "fix-99", '
                '"url": "https://example.test/99"}]'
            ),
        ]
        with patch("agent_worktree._run", side_effect=results):
            conflicts = _issue_conflicts(Path("/repo"), 12, {"number": 12})

        self.assertEqual(conflicts["branches"], ["chore/issue-12-one"])
        self.assertEqual(conflicts["worktrees"][0]["branch"], "issue-12-two")
        self.assertEqual(conflicts["pull_requests"][0]["number"], 99)


if __name__ == "__main__":
    unittest.main()

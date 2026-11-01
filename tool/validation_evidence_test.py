"""Regression tests for source-bound local validation evidence."""

from contextlib import closing
import json
import os
from pathlib import Path
import stat
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

import validation_evidence


class ValidationEvidenceTest(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.root = Path(self.temp_dir.name)
        _git(self.root, "init", "-q")
        _git(self.root, "config", "user.name", "Test User")
        _git(self.root, "config", "user.email", "test@example.invalid")
        (self.root / "tracked.txt").write_text("original\n")
        (self.root / "rename-from.txt").write_text("rename me\n")
        (self.root / "delete-me.txt").write_text("delete me\n")
        _git(self.root, "add", ".")
        _git(self.root, "commit", "-qm", "fixture")

    def tearDown(self):
        self.temp_dir.cleanup()

    def test_unchanged_source_has_a_stable_fingerprint(self):
        first = validation_evidence.repository_context(self.root)
        second = validation_evidence.repository_context(self.root)

        self.assertEqual(first["head"], second["head"])
        self.assertEqual(first["fingerprint"], second["fingerprint"])

    def test_local_store_is_private(self):
        database = self.root / "state.sqlite3"
        with closing(validation_evidence.open_store(database)):
            if sys.platform != "win32":
                self.assertEqual(stat.S_IMODE(database.parent.stat().st_mode), 0o700)
                self.assertEqual(stat.S_IMODE(database.stat().st_mode), 0o600)

    def test_store_falls_back_to_git_metadata_if_state_path_is_in_repo(self):
        with patch.dict(
            os.environ,
            {
                "XDG_STATE_HOME": str(self.root / "local-state"),
                "LOCALAPPDATA": str(self.root / "local-state"),
            },
        ):
            path = validation_evidence.default_store_path(self.root)

        try:
            path.resolve().relative_to((self.root / ".git").resolve())
        except ValueError:
            self.fail("default evidence path must stay outside tracked source")

    def test_untracked_renamed_and_deleted_files_change_the_fingerprint(self):
        baseline = validation_evidence.repository_context(self.root)["fingerprint"]

        untracked = self.root / "new-untracked.txt"
        untracked.write_text("new source\n")
        untracked_fingerprint = validation_evidence.repository_context(self.root)[
            "fingerprint"
        ]
        self.assertNotEqual(baseline, untracked_fingerprint)
        self.assertEqual(
            untracked_fingerprint,
            validation_evidence.repository_context(self.root)["fingerprint"],
        )
        untracked.unlink()

        _git(self.root, "mv", "rename-from.txt", "rename-to.txt")
        rename_fingerprint = validation_evidence.repository_context(self.root)[
            "fingerprint"
        ]
        self.assertNotEqual(baseline, rename_fingerprint)
        self.assertEqual(
            rename_fingerprint,
            validation_evidence.repository_context(self.root)["fingerprint"],
        )
        _git(self.root, "reset", "--hard", "-q", "HEAD")

        (self.root / "delete-me.txt").unlink()
        deleted_fingerprint = validation_evidence.repository_context(self.root)[
            "fingerprint"
        ]
        self.assertNotEqual(baseline, deleted_fingerprint)
        self.assertEqual(
            deleted_fingerprint,
            validation_evidence.repository_context(self.root)["fingerprint"],
        )

    def test_reusable_success_requires_the_same_source_snapshot(self):
        source = validation_evidence.repository_context(self.root)
        command = ["python3", "-m", "unittest"]
        with closing(validation_evidence.open_store(self.root / "state.sqlite3")) as db:
            record = validation_evidence.start_record(
                db,
                command=command,
                cwd=".",
                package=".",
                head=source["head"],
                fingerprint=source["fingerprint"],
                toolchain="Python 3.x",
            )
            validation_evidence.finish_record(
                db, record["id"], status="success", exit_code=0, duration_ms=20
            )

            reusable = validation_evidence.find_reusable_record(
                db,
                command=command,
                cwd=".",
                package=".",
                head=source["head"],
                fingerprint=source["fingerprint"],
                toolchain="Python 3.x",
            )
            self.assertIsNotNone(reusable)
            self.assertEqual(reusable["id"], record["id"])

            (self.root / "tracked.txt").write_text("changed source\n")
            changed = validation_evidence.repository_context(self.root)
            self.assertIsNone(
                validation_evidence.find_reusable_record(
                    db,
                    command=command,
                    cwd=".",
                    package=".",
                    head=changed["head"],
                    fingerprint=changed["fingerprint"],
                    toolchain="Python 3.x",
                )
            )

    def test_success_with_redacted_arguments_is_not_reusable(self):
        source = validation_evidence.repository_context(self.root)
        command = ["python3", "check.py", "--token", "<redacted>"]
        with closing(validation_evidence.open_store(self.root / "state.sqlite3")) as db:
            record = validation_evidence.start_record(
                db,
                command=command,
                cwd=".",
                package=".",
                head=source["head"],
                fingerprint=source["fingerprint"],
                toolchain="Python 3.x",
                reuse_allowed=False,
            )
            validation_evidence.finish_record(
                db, record["id"], status="success", exit_code=0, duration_ms=20
            )

            self.assertIsNone(
                validation_evidence.find_reusable_record(
                    db,
                    command=command,
                    cwd=".",
                    package=".",
                    head=source["head"],
                    fingerprint=source["fingerprint"],
                    toolchain="Python 3.x",
                )
            )

    def test_unfinished_record_stays_incomplete_without_an_exit_code(self):
        source = validation_evidence.repository_context(self.root)
        with closing(validation_evidence.open_store(self.root / "state.sqlite3")) as db:
            record = validation_evidence.start_record(
                db,
                command=["python3", "-m", "unittest"],
                cwd=".",
                package=".",
                head=source["head"],
                fingerprint=source["fingerprint"],
                toolchain="Python 3.x",
            )
            unfinished = db.execute(
                "SELECT status, exit_code FROM validation_evidence WHERE id = ?",
                (record["id"],),
            ).fetchone()
            self.assertEqual(unfinished["status"], "incomplete")
            self.assertIsNone(unfinished["exit_code"])

            result = validation_evidence.finish_record(
                db, record["id"], status="success", exit_code=None
            )
            self.assertEqual(result["status"], "incomplete")
            self.assertIsNone(result["exit_code"])

    def test_timeout_without_an_exit_code_is_incomplete(self):
        class TimedOutProcess:
            def __init__(self):
                self.return_code = None

            def wait(self, timeout=None):
                if self.return_code is None:
                    raise subprocess.TimeoutExpired("test-command", timeout)
                return self.return_code

            def poll(self):
                return self.return_code

            def terminate(self):
                self.return_code = -15

            def kill(self):
                self.return_code = -9

        with patch(
            "validation_evidence.subprocess.Popen", return_value=TimedOutProcess()
        ):
            status, exit_code, detail, duration = validation_evidence.execute_command(
                ["fake-validation-command"], self.root, 0.01
            )

        self.assertEqual(status, "incomplete")
        self.assertIsNone(exit_code)
        self.assertIn("timed out", detail)
        self.assertGreaterEqual(duration, 0)

    def test_keyboard_cancellation_is_never_success(self):
        class InterruptedProcess:
            def __init__(self):
                self.return_code = None

            def wait(self, timeout=None):
                if self.return_code is None:
                    raise KeyboardInterrupt
                return self.return_code

            def poll(self):
                return self.return_code

            def terminate(self):
                self.return_code = -2

            def kill(self):
                self.return_code = -9

        with patch(
            "validation_evidence.subprocess.Popen", return_value=InterruptedProcess()
        ):
            status, exit_code, detail, _ = validation_evidence.execute_command(
                ["fake-validation-command"], self.root, None
            )

        self.assertEqual(status, "cancelled")
        self.assertIsNone(exit_code)
        self.assertEqual(detail, "cancelled by user")

    def test_cancelled_status_stays_distinct_when_stored(self):
        source = validation_evidence.repository_context(self.root)
        with closing(validation_evidence.open_store(self.root / "state.sqlite3")) as db:
            record = validation_evidence.start_record(
                db,
                command=["python3", "check.py"],
                cwd=".",
                package=".",
                head=source["head"],
                fingerprint=source["fingerprint"],
                toolchain="Python 3.x",
            )
            result = validation_evidence.finish_record(
                db,
                record["id"],
                status="cancelled",
                detail="cancelled by user",
                duration_ms=3,
            )

        self.assertEqual(result["status"], "cancelled")
        self.assertIsNone(result["exit_code"])

    def test_skip_is_recorded_without_a_passing_exit_code(self):
        source = validation_evidence.repository_context(self.root)
        with closing(validation_evidence.open_store(self.root / "state.sqlite3")) as db:
            record = validation_evidence.record_skip(
                db,
                command=["fvm", "flutter", "test"],
                cwd=".",
                package="apps/example",
                head=source["head"],
                fingerprint=source["fingerprint"],
                toolchain="Flutter 3.x",
                reason="not applicable to this change",
            )

        self.assertEqual(record["status"], "skipped")
        self.assertIsNone(record["exit_code"])

    def test_only_known_exit_codes_complete_as_success_or_failure(self):
        self.assertEqual(validation_evidence.status_for_exit_code(None), "incomplete")
        self.assertEqual(validation_evidence.status_for_exit_code(0), "success")
        self.assertEqual(validation_evidence.status_for_exit_code(1), "failure")

    def test_command_summary_redacts_secrets_and_never_keeps_process_output(self):
        command = validation_evidence.sanitize_command(
            [
                "python3",
                "check.py",
                "--token",
                "private-token-value",
                "--dart-define=API_KEY=private-api-key",
                "--key=private-generic-key",
                "https://example.invalid/check?access_token=private-url-token",
                "Authorization: Bearer private-header-token",
                '{"apiKey":"private-json-token","mode":"safe"}',
                "DB_PASSWORD=private-password",
            ]
        )
        summary = " ".join(command)

        for secret in [
            "private-token-value",
            "private-api-key",
            "private-generic-key",
            "private-url-token",
            "private-header-token",
            "private-json-token",
            "private-password",
        ]:
            self.assertNotIn(secret, summary)
        self.assertIn("<redacted>", summary)
        with closing(validation_evidence.open_store(self.root / "state.sqlite3")) as db:
            columns = {
                row["name"]
                for row in db.execute("PRAGMA table_info(validation_evidence)")
            }
        self.assertNotIn("stdout", columns)
        self.assertNotIn("stderr", columns)

    def test_command_summary_redacts_url_userinfo_and_preserves_safe_url_parts(self):
        command = validation_evidence.sanitize_command(
            [
                "https://private-user:private-url-password"
                + "@example.invalid/api?mode=safe",
                "postgresql://db-user:private-dsn-password"
                + "@db.example.invalid/app?sslmode=require",
                "ssh://private-username@example.invalid/repository.git",
                "https://example.invalid/public?mode=safe",
            ]
        )
        summary = " ".join(command)

        for secret in [
            "private-user",
            "private-url-password",
            "db-user",
            "private-dsn-password",
            "private-username",
        ]:
            self.assertNotIn(secret, summary)

        self.assertIn("https://<redacted>@example.invalid/api?mode=safe", summary)
        self.assertIn(
            "postgresql://<redacted>@db.example.invalid/"
            "app?sslmode=require",
            summary,
        )
        self.assertIn("ssh://<redacted>@example.invalid/repository.git", summary)
        self.assertIn("https://example.invalid/public?mode=safe", summary)

    def test_toolchain_detection_is_limited_to_known_version_commands(self):
        with patch(
            "validation_evidence._tool_version",
            side_effect=["FVM 3.2.1", "Flutter 3.35.0", "Dart 3.9.0"],
        ):
            value = validation_evidence.detect_toolchain_version(
                ["fvm", "flutter", "test"], self.root
            )
        self.assertIn("Flutter 3.35.0", value)
        self.assertIn("Dart 3.9.0", value)

        with self.assertRaises(ValueError):
            validation_evidence.detect_toolchain_version(
                ["custom-runner", "validate"], self.root
            )

    def test_machine_summary_preserves_stale_and_status_fields(self):
        source = validation_evidence.repository_context(self.root)
        record = {
            "id": "record-id",
            "started_at": "2026-01-01T00:00:00+00:00",
            "ended_at": "2026-01-01T00:00:01+00:00",
            "duration_ms": 1000,
            "command_json": json.dumps(["python3", "-m", "unittest"]),
            "working_directory": ".",
            "package": ".",
            "head": source["head"],
            "fingerprint": source["fingerprint"],
            "toolchain_version": "Python 3.x",
            "status": "success",
            "exit_code": 0,
            "detail": None,
            "reused_from": None,
        }
        machine = validation_evidence.current_snapshot(
            record, source["head"], source["fingerprint"]
        )
        self.assertFalse(machine["stale"])
        self.assertEqual(machine["status"], "success")
        readable = validation_evidence.machine_record(machine)
        self.assertEqual(readable["command"], ["python3", "-m", "unittest"])
        self.assertNotIn("command_json", readable)

        stale = validation_evidence.current_snapshot(
            record, source["head"], "changed-source-fingerprint"
        )
        self.assertTrue(stale["stale"])


def _git(root, *arguments):
    return subprocess.run(
        ["git", "-C", str(root), *arguments],
        check=True,
        capture_output=True,
        text=True,
    )


if __name__ == "__main__":
    unittest.main()

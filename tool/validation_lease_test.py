"""Regression checks for cross-process validation lease behavior."""

import fcntl
from contextlib import redirect_stderr
import io
import os
from pathlib import Path
import subprocess
import sys
import tempfile
from types import SimpleNamespace
from unittest.mock import patch
import unittest

from validation_lease import LOCK_NAME, MINIMUM_AVAILABLE_BYTES, _lock_path_for_remote
from validation_lease import _owner_summary, _parse_arguments, _temp_directory_usage
from validation_lease import _validation_lock_paths, _validation_preflight, _write_owner
from validation_lease import read_active_owner, try_acquire


class ValidationLeaseTest(unittest.TestCase):
    def test_arguments_accept_safe_label(self):
        self.assertEqual(
            _parse_arguments(
                ["--label", "validate:pr", "--", "fvm", "dart", "run"]
            ),
            ("validate:pr", ["fvm", "dart", "run"]),
        )

    def test_arguments_reject_unsafe_label(self):
        with self.assertRaises(ValueError):
            _parse_arguments(["--label", "run secret", "--", "fvm"])

    def test_arguments_keep_legacy_command_syntax(self):
        self.assertEqual(
            _parse_arguments(["--", "fvm", "dart"]),
            (None, ["fvm", "dart"]),
        )

    def test_owner_summary_includes_label(self):
        summary = _owner_summary(
            {
                "label": "validate:pr",
                "pid": 1,
                "host": "host",
                "cwd": "/repo",
                "started_at": "now",
            }
        )

        self.assertTrue(summary.startswith("label=validate:pr pid=1"))

    def test_preflight_allows_volume_at_reserve(self):
        volume = _volume_usage(Path.cwd(), MINIMUM_AVAILABLE_BYTES)
        temp_usage = {
            "path": "/tmp",
            "used_bytes": 0,
            "entries": [],
        }
        output = io.StringIO()

        with (
            patch("validation_lease._volume_usage", return_value=volume),
            patch(
                "validation_lease._temp_directory_usage",
                return_value=temp_usage,
            ),
            redirect_stderr(output),
        ):
            self.assertTrue(_validation_preflight())

        self.assertIn("available", output.getvalue())
        self.assertIn("temp directory /tmp: 0 B used", output.getvalue())

    def test_preflight_blocks_below_reserve_and_reports_temp_entries(self):
        volume = _volume_usage(Path.cwd(), MINIMUM_AVAILABLE_BYTES - 1)
        temp_usage = {
            "path": "/tmp",
            "used_bytes": 3 * 1024**3,
            "entries": [
                {"path": "/tmp/flutter_tools", "bytes": 2 * 1024**3},
            ],
        }
        output = io.StringIO()

        with (
            patch("validation_lease._volume_usage", return_value=volume),
            patch(
                "validation_lease._temp_directory_usage",
                return_value=temp_usage,
            ),
            redirect_stderr(output),
        ):
            self.assertFalse(_validation_preflight())

        self.assertIn("Validation blocked", output.getvalue())
        self.assertIn("No files were deleted", output.getvalue())
        self.assertIn("largest temp entry: 2.0 GiB flutter_tools", output.getvalue())

    def test_temp_usage_sorts_entries_largest_first(self):
        result = SimpleNamespace(
            returncode=0,
            stdout=(
                "3072\t/tmp\n"
                "1024\t/tmp/smaller\n"
                "2048\t/tmp/larger\n"
            ),
            stderr="",
        )

        with patch("validation_lease.subprocess.run", return_value=result):
            usage = _temp_directory_usage(Path("/tmp"))

        self.assertEqual(usage["used_bytes"], 3072 * 1024)
        self.assertEqual(
            [entry["path"] for entry in usage["entries"]],
            ["/tmp/larger", "/tmp/smaller"],
        )

    def test_lock_is_exclusive_until_released(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            lock_path = Path(temp_dir) / "lease"
            first_fd = os.open(lock_path, os.O_CREAT | os.O_RDWR, 0o600)
            try:
                self.assertTrue(try_acquire(first_fd))
                self.assertFalse(_try_acquire_in_child(lock_path))
                fcntl.flock(first_fd, fcntl.LOCK_UN)
                self.assertTrue(_try_acquire_in_child(lock_path))
            finally:
                fcntl.flock(first_fd, fcntl.LOCK_UN)
                os.close(first_fd)

    def test_remote_lock_path_is_shared_across_clones_and_url_styles(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            shared_dir = Path(temp_dir) / "leases"
            first_path = _lock_path_for_remote(
                "git@github.com:auravibes-apps/auravibes.git",
                Path(temp_dir) / "clone-one" / ".git",
                shared_dir,
            )
            second_path = _lock_path_for_remote(
                "https://github.com/auravibes-apps/auravibes.git",
                Path(temp_dir) / "clone-two" / ".git",
                shared_dir,
            )
            other_path = _lock_path_for_remote(
                "https://github.com/auravibes-apps/other.git",
                Path(temp_dir) / "clone-three" / ".git",
                shared_dir,
            )

            self.assertEqual(first_path, second_path)
            self.assertNotEqual(first_path, other_path)
            first_path.parent.mkdir(mode=0o700)
            first_fd = os.open(first_path, os.O_CREAT | os.O_RDWR, 0o600)
            try:
                self.assertTrue(try_acquire(first_fd))
                self.assertFalse(_try_acquire_in_child(second_path))
            finally:
                fcntl.flock(first_fd, fcntl.LOCK_UN)
                os.close(first_fd)

    def test_lock_paths_preserve_linked_worktrees_and_coordinate_clones(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            common_git_dir = Path(temp_dir) / "common"
            common_git_dir.mkdir()
            shared_dir = Path(temp_dir) / "shared"
            remote_url = "git@github.com:auravibes-apps/auravibes.git"
            with (
                patch("validation_lease._common_git_dir", return_value=common_git_dir),
                patch("validation_lease._origin_remote_url", return_value=remote_url),
                patch("validation_lease._shared_lock_directory", return_value=shared_dir),
            ):
                paths = _validation_lock_paths()

            remote_path = _lock_path_for_remote(
                remote_url, common_git_dir, shared_dir
            )
            self.assertEqual(
                paths,
                sorted({common_git_dir / LOCK_NAME, remote_path}, key=str),
            )

    def test_read_active_owner_ignores_stale_metadata(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            lock_path = Path(temp_dir) / "lease"
            fd = os.open(lock_path, os.O_CREAT | os.O_RDWR, 0o600)
            owner = {"pid": 1, "host": "host", "cwd": "/repo", "started_at": "now"}
            try:
                self.assertTrue(try_acquire(fd))
                _write_owner(fd, owner)
                self.assertEqual(read_active_owner(lock_path), owner)
                fcntl.flock(fd, fcntl.LOCK_UN)
                self.assertIsNone(read_active_owner(lock_path))
            finally:
                fcntl.flock(fd, fcntl.LOCK_UN)
                os.close(fd)


def _volume_usage(path, available_bytes):
    return {
        "path": str(path),
        "device": 1,
        "total_bytes": 20 * 1024**3,
        "used_bytes": 20 * 1024**3 - available_bytes,
        "available_bytes": available_bytes,
        "free_inodes": 100,
    }


def _try_acquire_in_child(lock_path):
    tool_dir = Path(__file__).resolve().parent
    code = (
        "import os, sys; "
        "sys.path.insert(0, sys.argv[2]); "
        "from validation_lease import try_acquire; "
        "fd = os.open(sys.argv[1], os.O_RDWR); "
        "print(try_acquire(fd)); "
        "os.close(fd)"
    )
    result = subprocess.run(
        [sys.executable, "-c", code, str(lock_path), str(tool_dir)],
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout.strip() == "True"


if __name__ == "__main__":
    unittest.main()

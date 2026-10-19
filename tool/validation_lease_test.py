"""Regression checks for cross-process validation lease behavior."""

import fcntl
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from validation_lease import try_acquire


class ValidationLeaseTest(unittest.TestCase):
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

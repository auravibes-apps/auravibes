#!/usr/bin/env python3
"""Serialize validation commands within one worktree."""

# shortcut: shared caches remain unlocked, add scoped locks if races recur.
from datetime import datetime, timezone
import fcntl
import json
import os
from pathlib import Path
import socket
import subprocess
import sys
import tempfile


LOCK_NAME = "codex-validation.lock"
# Keep headroom for compiler temp growth; prior run hit ENOSPC with 7 GiB free.
MINIMUM_AVAILABLE_BYTES = 20 * 1024**3
TEMP_DIRECTORY_SCAN_TIMEOUT_SECONDS = 10
MAX_TEMP_ENTRIES = 5


def try_acquire(fd):
    try:
        fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        return False
    return True


def _volume_usage(path):
    try:
        stats = os.statvfs(path)
        device = os.stat(path).st_dev
    except OSError as error:
        return {"path": str(path), "error": str(error)}

    block_size = stats.f_frsize or stats.f_bsize
    total_bytes = stats.f_blocks * block_size
    return {
        "path": str(path),
        "device": device,
        "total_bytes": total_bytes,
        "used_bytes": total_bytes - stats.f_bfree * block_size,
        "available_bytes": stats.f_bavail * block_size,
        "free_inodes": stats.f_favail,
    }


def _temp_volume_usage():
    return _volume_usage(Path(tempfile.gettempdir()))


def _temp_directory_usage(temp_dir):
    try:
        result = subprocess.run(
            ["du", "-k", "-d", "1", str(temp_dir)],
            capture_output=True,
            text=True,
            timeout=TEMP_DIRECTORY_SCAN_TIMEOUT_SECONDS,
        )
    except (OSError, subprocess.TimeoutExpired) as error:
        return {"path": str(temp_dir), "error": str(error)}

    used_bytes = None
    entries = []
    for line in result.stdout.splitlines():
        try:
            size_kib, entry_path = line.split(maxsplit=1)
            size_bytes = int(size_kib) * 1024
        except (ValueError, TypeError):
            continue

        if os.path.abspath(entry_path) == os.path.abspath(temp_dir):
            used_bytes = size_bytes
        else:
            entries.append({"path": entry_path, "bytes": size_bytes})

    if used_bytes is None:
        return {
            "path": str(temp_dir),
            "error": result.stderr.strip()
            or f"du exited with status {result.returncode}",
        }

    return {
        "path": str(temp_dir),
        "used_bytes": used_bytes,
        "entries": sorted(entries, key=lambda entry: entry["bytes"], reverse=True),
    }


def _format_bytes(value):
    for unit in ("B", "KiB", "MiB", "GiB", "TiB"):
        if value < 1024 or unit == "TiB":
            return f"{value:.1f} {unit}" if unit != "B" else f"{value} B"
        value /= 1024


def _format_temp_usage(usage):
    if "error" in usage:
        return f"temp volume {usage['path']}: unavailable ({usage['error']})"
    return (
        f"temp volume {usage['path']}: "
        f"{_format_bytes(usage['used_bytes'])} used / "
        f"{_format_bytes(usage['total_bytes'])} total, "
        f"{_format_bytes(usage['available_bytes'])} available, "
        f"{usage['free_inodes']} free inodes"
    )


def _validation_preflight():
    paths = [Path.cwd(), Path(tempfile.gettempdir())]
    usages = []
    seen_devices = set()
    for path in paths:
        usage = _volume_usage(path)
        if "error" in usage:
            print(
                f"Validation blocked: cannot inspect volume {usage['path']}: "
                f"{usage['error']}",
                file=sys.stderr,
                flush=True,
            )
            return False
        if usage["device"] in seen_devices:
            continue
        seen_devices.add(usage["device"])
        usages.append(usage)
        print(
            f"validation volume {usage['path']}: "
            f"{_format_bytes(usage['used_bytes'])} used / "
            f"{_format_bytes(usage['total_bytes'])} total, "
            f"{_format_bytes(usage['available_bytes'])} available",
            file=sys.stderr,
            flush=True,
        )

    temp_dir = Path(tempfile.gettempdir())
    temp_usage = _temp_directory_usage(temp_dir)
    if "error" in temp_usage:
        print(
            f"temp directory {temp_usage['path']}: usage unavailable "
            f"({temp_usage['error']})",
            file=sys.stderr,
            flush=True,
        )
    else:
        print(
            f"temp directory {temp_usage['path']}: "
            f"{_format_bytes(temp_usage['used_bytes'])} used",
            file=sys.stderr,
            flush=True,
        )

    low_volumes = [
        usage
        for usage in usages
        if usage["available_bytes"] < MINIMUM_AVAILABLE_BYTES
    ]
    if not low_volumes:
        return True

    for usage in low_volumes:
        print(
            f"Validation blocked: {usage['path']} has "
            f"{_format_bytes(usage['available_bytes'])} available; "
            f"reserve is {_format_bytes(MINIMUM_AVAILABLE_BYTES)}. "
            "No files were deleted.",
            file=sys.stderr,
            flush=True,
        )
    if "error" not in temp_usage:
        for entry in temp_usage["entries"][:MAX_TEMP_ENTRIES]:
            entry_name = Path(entry["path"]).name
            print(
                f"largest temp entry: {_format_bytes(entry['bytes'])} "
                f"{entry_name}",
                file=sys.stderr,
                flush=True,
            )
    return False


def _write_owner(fd, owner):
    payload = json.dumps(owner, indent=2).encode()
    os.ftruncate(fd, 0)
    os.lseek(fd, 0, os.SEEK_SET)
    written = 0
    while written < len(payload):
        count = os.write(fd, payload[written:])
        if count == 0:
            raise OSError("could not write validation lease owner")
        written += count
    os.fsync(fd)


def _read_owner(fd):
    try:
        return json.loads(os.pread(fd, 8192, 0))
    except (OSError, json.JSONDecodeError):
        return None


def _owner_summary(owner):
    if owner is None:
        return "owner metadata unavailable"
    label = owner.get("label")
    label_summary = f"label={label} " if label else ""
    return (
        f"{label_summary}pid={owner.get('pid')} host={owner.get('host')} "
        f"cwd={owner.get('cwd')} started={owner.get('started_at')}"
    )


def read_active_owner(lock_path):
    try:
        fd = os.open(lock_path, os.O_RDONLY | getattr(os, "O_NOFOLLOW", 0))
    except FileNotFoundError:
        return None
    try:
        try:
            fcntl.flock(fd, fcntl.LOCK_SH | fcntl.LOCK_NB)
        except BlockingIOError:
            return _read_owner(fd) or {"metadata_unavailable": True}
        fcntl.flock(fd, fcntl.LOCK_UN)
        return None
    finally:
        os.close(fd)


def _worktree_git_dir():
    result = subprocess.run(
        ["git", "rev-parse", "--absolute-git-dir"],
        check=True,
        capture_output=True,
        text=True,
    )
    return Path(result.stdout.strip()).resolve()


def _validation_lock_path():
    return _worktree_git_dir() / LOCK_NAME


def _prepend_pinned_sdk_bin(environment, working_directory):
    current_directory = Path(working_directory).resolve()
    for repository_root in (current_directory, *current_directory.parents):
        sdk_bin = repository_root / ".fvm" / "flutter_sdk" / "bin"
        if sdk_bin.is_dir():
            environment["PATH"] = (
                f"{sdk_bin}{os.pathsep}{environment.get('PATH', '')}"
            )
            return


def _close_lock_fd(fd, *, release=False):
    if release:
        fcntl.flock(fd, fcntl.LOCK_UN)
    os.close(fd)


def _wait_for_lease(fd):
    if try_acquire(fd):
        return
    owner = _read_owner(fd)
    print(
        f"Validation lease occupied by {_owner_summary(owner)}; waiting.",
        file=sys.stderr,
        flush=True,
    )
    fcntl.flock(fd, fcntl.LOCK_EX)


def _is_safe_label(label):
    return (
        isinstance(label, str)
        and 1 <= len(label) <= 48
        and label[0].isascii()
        and label[0].islower()
        and all(
            character.isascii()
            and (character.islower() or character.isdigit() or character in "_:-")
            for character in label
        )
    )


def _parse_arguments(argv):
    try:
        separator = argv.index("--")
    except ValueError as error:
        raise ValueError from error

    options = argv[:separator]
    command = argv[separator + 1 :]
    label = None
    if options:
        if len(options) != 2 or options[0] != "--label" or not _is_safe_label(
            options[1]
        ):
            raise ValueError
        label = options[1]
    if not command:
        raise ValueError
    return label, command


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    try:
        label, command = _parse_arguments(argv)
    except ValueError:
        print(
            "Usage: python3 tool/validation_lease.py [--label <safe-label>] "
            "-- <command> [args...]",
            file=sys.stderr,
        )
        return 2

    try:
        lock_path = _validation_lock_path()
        flags = os.O_CREAT | os.O_RDWR | getattr(os, "O_NOFOLLOW", 0)
        lock_fd = os.open(lock_path, flags, 0o600)
    except (OSError, subprocess.CalledProcessError) as error:
        print(f"Cannot open repository validation lease: {error}", file=sys.stderr)
        return 2

    try:
        _wait_for_lease(lock_fd)
    except KeyboardInterrupt:
        _close_lock_fd(lock_fd)
        return 130
    except OSError as error:
        _close_lock_fd(lock_fd)
        print(f"Cannot acquire repository validation lease: {error}", file=sys.stderr)
        return 2

    if not _validation_preflight():
        _close_lock_fd(lock_fd, release=True)
        return 3

    owner = {
        "pid": os.getpid(),
        "host": socket.gethostname(),
        "cwd": os.getcwd(),
        "started_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
    }
    if label is not None:
        owner["label"] = label
    _write_owner(lock_fd, owner)
    temp_usage = _temp_volume_usage()
    print(
        f"Validation lease acquired by {_owner_summary(owner)}.",
        file=sys.stderr,
        flush=True,
    )
    print(_format_temp_usage(temp_usage), file=sys.stderr, flush=True)

    try:
        os.set_inheritable(lock_fd, True)
        environment = os.environ.copy()
        _prepend_pinned_sdk_bin(environment, Path.cwd())
        os.execvpe(command[0], command, environment)
    except OSError as error:
        print(f"Cannot start validation command: {error}", file=sys.stderr)
        _close_lock_fd(lock_fd, release=True)
        return 127


if __name__ == "__main__":
    raise SystemExit(main())

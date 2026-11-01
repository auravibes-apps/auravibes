#!/usr/bin/env python3
"""Record local validation results against the source snapshot they checked."""

import argparse
from contextlib import closing
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import shlex
import sqlite3
import stat
import subprocess
import sys
import time
import uuid


STATUSES = ("success", "failure", "skipped", "cancelled", "incomplete")
SENSITIVE_NAME = re.compile(
    r"(?:password|passwd|passphrase|secret|token|api[-_]?key|"
    r"access[-_]?(?:key|token)|credential|authorization|auth|cookie|"
    r"private[-_]?key|(?:^|[-_])key(?:$|[-_]))",
    re.IGNORECASE,
)
SENSITIVE_QUERY = re.compile(
    r"(?i)([?&](?:password|passwd|passphrase|secret|client[-_]?secret|token|"
    r"api[-_]?key|access[-_]?(?:key|token)|credential|authorization|auth|"
    r"cookie|key)=)[^&#\s]*"
)
URL_USERINFO = re.compile(r"([A-Za-z][A-Za-z0-9+.-]*://)[^/\s?#@]*@")
SENSITIVE_HEADER = re.compile(
    r"(?i)((?:[a-z0-9-]*(?:authorization|token|secret|api[-_]?key|cookie)"
    r"[a-z0-9-]*)\s*:\s*)(?:(?:bearer|basic)\s+)?[^,\s;]+"
)
AUTH_SCHEME = re.compile(r"(?i)\b(bearer|basic)\s+[A-Za-z0-9._~+/=-]+")
ASSIGNMENT = re.compile(r"^([A-Za-z_][A-Za-z0-9_-]*)=(.*)$", re.DOTALL)
SNAPSHOT_VERSION = b"auravibes-validation-snapshot-v1\0"


def _git(root, *arguments, binary=False):
    result = subprocess.run(
        ["git", "-C", str(root), *arguments],
        check=False,
        capture_output=True,
        text=not binary,
    )
    if result.returncode != 0:
        raise RuntimeError("could not inspect the Git source snapshot")
    return result.stdout


def repository_context(directory):
    """Return the repository root, HEAD, and a privacy-safe dirty-tree digest."""
    root = Path(_git(directory, "rev-parse", "--show-toplevel").strip()).resolve()
    head = _git(root, "rev-parse", "HEAD").strip()
    status = _git(
        root,
        "status",
        "--porcelain=v1",
        "-z",
        "--untracked-files=all",
        "--renames",
        binary=True,
    )
    diff = _git(
        root,
        "diff",
        "--binary",
        "--no-ext-diff",
        "--no-textconv",
        "HEAD",
        "--",
        binary=True,
    )
    untracked = _git(
        root,
        "ls-files",
        "--others",
        "--exclude-standard",
        "-z",
        binary=True,
    )

    digest = hashlib.sha256()
    digest.update(SNAPSHOT_VERSION)
    _hash_part(digest, head.encode())
    _hash_part(digest, status)
    _hash_part(digest, diff)
    for encoded_path in sorted(filter(None, untracked.split(b"\0"))):
        path = root / os.fsdecode(encoded_path)
        _hash_part(digest, encoded_path)
        try:
            if path.is_symlink():
                content = b"symlink\0" + os.fsencode(os.readlink(path))
            elif path.is_file():
                content = b"file\0" + path.read_bytes()
            else:
                content = b"missing\0"
        except OSError:
            content = b"unreadable\0"
        _hash_part(digest, content)

    return {
        "root": root,
        "head": head,
        "fingerprint": digest.hexdigest(),
    }


def _hash_part(digest, value):
    digest.update(len(value).to_bytes(8, "big"))
    digest.update(value)


def _repo_relative(root, path):
    resolved = Path(path).resolve()
    try:
        return resolved.relative_to(root).as_posix() or "."
    except ValueError as error:
        raise ValueError(
            "working directory and package must be inside the Git repo"
        ) from error


def _git_common_directory(root):
    value = Path(_git(root, "rev-parse", "--git-common-dir").strip())
    return value.resolve() if value.is_absolute() else (root / value).resolve()


def default_store_path(root):
    common_directory = _git_common_directory(root)
    if os.name == "nt":
        state_root = Path(
            os.environ.get("LOCALAPPDATA") or Path.home() / "AppData" / "Local"
        )
    else:
        state_root = Path(
            os.environ.get("XDG_STATE_HOME") or Path.home() / ".local" / "state"
        )
    try:
        state_root.resolve().relative_to(root)
    except ValueError:
        pass
    else:
        state_root = common_directory / "auravibes-validation-evidence"
    repo_key = hashlib.sha256(os.fsencode(common_directory)).hexdigest()[:24]
    return state_root / "auravibes" / "validation-evidence" / f"{repo_key}.sqlite3"


def open_store(path):
    path = Path(path)
    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    try:
        os.chmod(path.parent, 0o700)
    except OSError as error:
        if os.name != "nt":
            raise PermissionError(
                "could not protect the local evidence directory"
            ) from error
    if os.name != "nt" and stat.S_IMODE(path.parent.stat().st_mode) & 0o077:
        raise PermissionError("local evidence directory must be private")
    previous_umask = os.umask(0o077) if os.name != "nt" else None
    try:
        connection = sqlite3.connect(path, timeout=30)
    finally:
        if previous_umask is not None:
            os.umask(previous_umask)
    connection.row_factory = sqlite3.Row
    connection.execute("PRAGMA journal_mode=DELETE")
    connection.execute(
        """
        CREATE TABLE IF NOT EXISTS validation_evidence (
            id TEXT PRIMARY KEY,
            started_at TEXT NOT NULL,
            ended_at TEXT,
            duration_ms INTEGER,
            command_json TEXT NOT NULL,
            working_directory TEXT NOT NULL,
            package TEXT NOT NULL,
            head TEXT NOT NULL,
            fingerprint TEXT NOT NULL,
            toolchain_version TEXT NOT NULL,
            status TEXT NOT NULL CHECK (
                status IN ('success', 'failure', 'skipped', 'cancelled', 'incomplete')
            ),
            exit_code INTEGER,
            detail TEXT,
            reused_from TEXT,
            reuse_allowed INTEGER NOT NULL DEFAULT 1
        )
        """
    )
    columns = {
        row["name"] for row in connection.execute("PRAGMA table_info(validation_evidence)")
    }
    if "reuse_allowed" not in columns:
        connection.execute(
            "ALTER TABLE validation_evidence "
            "ADD COLUMN reuse_allowed INTEGER NOT NULL DEFAULT 1"
        )
    connection.commit()
    try:
        os.chmod(path, 0o600)
    except OSError as error:
        connection.close()
        if os.name != "nt":
            raise PermissionError(
                "could not protect the local evidence database"
            ) from error
    if os.name != "nt" and stat.S_IMODE(path.stat().st_mode) & 0o077:
        connection.close()
        raise PermissionError("local evidence database must be private")
    return connection


def _now():
    return datetime.now(timezone.utc).isoformat(timespec="milliseconds")


def _tool_version(command, cwd):
    try:
        result = subprocess.run(
            command,
            cwd=cwd,
            check=False,
            capture_output=True,
            text=True,
            timeout=4,
        )
    except (OSError, subprocess.TimeoutExpired):
        return None
    if result.returncode != 0:
        return None
    value = (result.stdout or result.stderr).strip().splitlines()
    if not value:
        return None
    return _safe_summary(value[0])[:200]


def detect_toolchain_version(command, cwd):
    """Query only well-known version switches; unknown tools require an override."""
    executable = Path(command[0]).stem.lower()
    if executable == "fvm":
        fvm = _tool_version([command[0], "--version"], cwd)
        flutter = _tool_version([command[0], "flutter", "--version"], cwd)
        dart = _tool_version([command[0], "dart", "--version"], cwd)
        versions = [f"FVM {fvm}" if fvm else None, flutter, dart]
        versions = [value for value in versions if value]
        if versions:
            return "; ".join(versions)
    elif executable in {
        "flutter",
        "dart",
        "python",
        "python2",
        "python3",
        "node",
        "npm",
        "go",
        "cargo",
        "pytest",
    } or re.fullmatch(r"python(?:2|3)?(?:\.\d+)*", executable):
        version = _tool_version([command[0], "--version"], cwd)
        if version:
            return version
    raise ValueError(
        "could not safely detect this toolchain; pass --toolchain-version explicitly"
    )


def _safe_summary(value):
    value = URL_USERINFO.sub(r"\1<redacted>@", value)
    value = SENSITIVE_QUERY.sub(r"\1<redacted>", value)
    value = SENSITIVE_HEADER.sub(r"\1<redacted>", value)
    value = AUTH_SCHEME.sub(r"\1 <redacted>", value)
    value = re.sub(r"\b([A-Za-z_][A-Za-z0-9_-]*=)[^\s]+", _redact_assignment, value)
    return " ".join(value.replace("\x00", "").split())


def _redact_assignment(match):
    key = match.group(1)[:-1]
    if SENSITIVE_NAME.search(key):
        return f"{key}=<redacted>"
    return match.group(0)


def _redact_json_argument(argument):
    try:
        value = json.loads(argument)
    except (json.JSONDecodeError, TypeError):
        return argument

    def redact(value):
        if isinstance(value, dict):
            return {
                key: "<redacted>" if SENSITIVE_NAME.search(str(key)) else redact(item)
                for key, item in value.items()
            }
        if isinstance(value, list):
            return [redact(item) for item in value]
        return value

    sanitized = redact(value)
    return json.dumps(sanitized, separators=(",", ":"), ensure_ascii=False)


def sanitize_command(command, redact_indices=()):
    sanitized = []
    redact_next = False
    explicit = set(redact_indices)
    for index, argument in enumerate(command):
        argument = str(argument)
        if redact_next or index in explicit:
            sanitized.append("<redacted>")
            redact_next = False
            continue

        if (
            argument.startswith("-")
            and "=" not in argument
            and SENSITIVE_NAME.search(argument)
        ):
            sanitized.append(argument)
            redact_next = True
            continue

        if "=" in argument:
            prefix, value = argument.split("=", 1)
            key = prefix.rsplit(".", 1)[-1].lstrip("-")
            if SENSITIVE_NAME.search(key):
                sanitized.append(f"{prefix}=<redacted>")
                continue
            nested_assignment = ASSIGNMENT.match(value)
            if nested_assignment and SENSITIVE_NAME.search(nested_assignment.group(1)):
                sanitized.append(f"{prefix}={nested_assignment.group(1)}=<redacted>")
                continue

        argument = _safe_summary(argument)
        assignment = ASSIGNMENT.match(argument)
        if assignment and SENSITIVE_NAME.search(assignment.group(1)):
            argument = f"{assignment.group(1)}=<redacted>"
        sanitized.append(_redact_json_argument(argument))
    return sanitized


def status_for_exit_code(exit_code):
    if exit_code is None:
        return "incomplete"
    return "success" if exit_code == 0 else "failure"


def insert_record(connection, record):
    columns = (
        "id, started_at, ended_at, duration_ms, command_json, working_directory, "
        "package, head, fingerprint, toolchain_version, status, exit_code, detail, "
        "reused_from, reuse_allowed"
    )
    placeholders = ", ".join("?" for _ in columns.split(", "))
    values = [record.get(column) for column in columns.split(", ")]
    connection.execute(
        f"INSERT INTO validation_evidence ({columns}) VALUES ({placeholders})",
        values,
    )
    connection.commit()


def start_record(
    connection,
    *,
    command,
    cwd,
    package,
    head,
    fingerprint,
    toolchain,
    reuse_allowed=True,
):
    record = {
        "id": uuid.uuid4().hex,
        "started_at": _now(),
        "ended_at": None,
        "duration_ms": None,
        "command_json": json.dumps(command, ensure_ascii=False),
        "working_directory": cwd,
        "package": package,
        "head": head,
        "fingerprint": fingerprint,
        "toolchain_version": toolchain,
        "status": "incomplete",
        "exit_code": None,
        "detail": "started; no command exit code has been recorded",
        "reused_from": None,
        "reuse_allowed": int(reuse_allowed),
    }
    insert_record(connection, record)
    return record


def finish_record(
    connection,
    record_id,
    *,
    status,
    exit_code=None,
    detail=None,
    duration_ms=None,
):
    if status not in STATUSES:
        raise ValueError(f"unsupported result status: {status}")
    if status in {"success", "failure"} and exit_code is None:
        status, detail = "incomplete", detail or "no command exit code was recorded"
    if status == "success" and exit_code != 0:
        status = "failure"
    if status == "failure" and exit_code == 0:
        status = "success"
    connection.execute(
        """
        UPDATE validation_evidence
        SET ended_at = ?, duration_ms = ?, status = ?, exit_code = ?, detail = ?
        WHERE id = ?
        """,
        (_now(), duration_ms, status, exit_code, detail, record_id),
    )
    connection.commit()
    return connection.execute(
        "SELECT * FROM validation_evidence WHERE id = ?", (record_id,)
    ).fetchone()


def execute_command(command, cwd, timeout):
    """Run without capturing output and distinguish cancellation/timeouts."""
    try:
        process = subprocess.Popen(command, cwd=cwd)
    except OSError:
        return "incomplete", None, "process could not be started", 0

    started = time.monotonic()
    try:
        exit_code = process.wait(timeout=timeout)
    except subprocess.TimeoutExpired:
        _stop_process(process)
        duration_ms = int((time.monotonic() - started) * 1000)
        return "incomplete", None, "timed out without a command exit code", duration_ms
    except KeyboardInterrupt:
        _stop_process(process)
        duration_ms = int((time.monotonic() - started) * 1000)
        return "cancelled", None, "cancelled by user", duration_ms
    duration_ms = int((time.monotonic() - started) * 1000)
    return status_for_exit_code(exit_code), exit_code, None, duration_ms


def _stop_process(process):
    if process.poll() is not None:
        return
    try:
        process.terminate()
    except OSError:
        pass
    try:
        process.wait(timeout=2)
    except subprocess.TimeoutExpired:
        try:
            process.kill()
        except OSError:
            pass
        process.wait()


def record_skip(
    connection,
    *,
    command,
    cwd,
    package,
    head,
    fingerprint,
    toolchain,
    reason,
):
    now = _now()
    record = {
        "id": uuid.uuid4().hex,
        "started_at": now,
        "ended_at": now,
        "duration_ms": 0,
        "command_json": json.dumps(command, ensure_ascii=False),
        "working_directory": cwd,
        "package": package,
        "head": head,
        "fingerprint": fingerprint,
        "toolchain_version": toolchain,
        "status": "skipped",
        "exit_code": None,
        "detail": _safe_summary(reason)[:300],
        "reused_from": None,
        "reuse_allowed": 0,
    }
    insert_record(connection, record)
    return record


def find_reusable_record(
    connection,
    *,
    command,
    cwd,
    package,
    head,
    fingerprint,
    toolchain,
):
    row = connection.execute(
        """
        SELECT * FROM validation_evidence
        WHERE status = 'success' AND exit_code = 0 AND reuse_allowed = 1
          AND command_json = ? AND working_directory = ? AND package = ?
          AND head = ? AND fingerprint = ? AND toolchain_version = ?
        ORDER BY ended_at DESC LIMIT 1
        """,
        (
            json.dumps(command, ensure_ascii=False),
            cwd,
            package,
            head,
            fingerprint,
            toolchain,
        ),
    ).fetchone()
    return dict(row) if row else None


def current_snapshot(record, head, fingerprint):
    value = dict(record)
    value["stale"] = value["head"] != head or value["fingerprint"] != fingerprint
    return value


def summarize_record(record, *, reused=False):
    status = record["status"].upper()
    prefix = "REUSED " if reused else ""
    command = shlex.join(json.loads(record["command_json"]))
    stale = " (stale for current source)" if record.get("stale") else ""
    detail = f" — {record['detail']}" if record.get("detail") else ""
    code = f"; exit {record['exit_code']}" if record.get("exit_code") is not None else ""
    duration = (
        f"; {record['duration_ms']} ms" if record.get("duration_ms") is not None else ""
    )
    return (
        f"{prefix}{status}{stale}{code}{duration}; "
        f"{record['toolchain_version']}: {command}{detail} [evidence {record['id']}]"
    )


def machine_record(record, *, reused=False):
    value = dict(record)
    value["command"] = json.loads(value.pop("command_json"))
    if reused:
        value["reused"] = True
    return value


def emit_record(record, *, as_json=False, reused=False):
    if as_json:
        print(
            json.dumps(
                machine_record(record, reused=reused), indent=2, ensure_ascii=False
            )
        )
    else:
        print(summarize_record(record, reused=reused))


def _prepare_context(args, command):
    working_directory = Path.cwd().resolve()
    source = repository_context(working_directory)
    root = source["root"]
    package_path = (
        (working_directory / args.package).resolve()
        if args.package
        else working_directory
    )
    package = _repo_relative(root, package_path)
    cwd = _repo_relative(root, working_directory)
    redact_indices = args.redact_arg if hasattr(args, "redact_arg") else ()
    sanitized = sanitize_command(command, redact_indices)
    redacted = sanitized != command or bool(redact_indices)
    if not sanitized:
        raise ValueError("provide a command after --")
    toolchain = args.toolchain_version or detect_toolchain_version(
        command, working_directory
    )
    return source, cwd, package, sanitized, _safe_summary(toolchain)[:200], redacted


def _parser():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="action", required=True)

    run = commands.add_parser("run", help="execute and record a validation command")
    _add_context_arguments(run)
    run.add_argument(
        "--timeout", type=float, help="seconds before marking the run incomplete"
    )
    run.add_argument(
        "--reuse", action="store_true", help="reuse matching successful evidence"
    )
    run.add_argument("--redact-arg", type=int, action="append", default=[])
    run.add_argument("--json", action="store_true", dest="as_json")
    run.add_argument("command", nargs=argparse.REMAINDER)

    skip = commands.add_parser("skip", help="record that a validation was skipped")
    _add_context_arguments(skip)
    skip.add_argument("--reason", required=True)
    skip.add_argument("--redact-arg", type=int, action="append", default=[])
    skip.add_argument("--json", action="store_true", dest="as_json")
    skip.add_argument("command", nargs=argparse.REMAINDER)

    listing = commands.add_parser(
        "list", help="summarize recent validation evidence"
    )
    listing.add_argument("--limit", type=int, default=20)
    listing.add_argument("--json", action="store_true", dest="as_json")

    show = commands.add_parser("show", help="show one validation record")
    show.add_argument("id")
    show.add_argument("--json", action="store_true", dest="as_json")
    return parser


def _add_context_arguments(parser):
    parser.add_argument(
        "--package", help="package path relative to the current working directory"
    )
    parser.add_argument("--toolchain-version", help="explicit version string for the toolchain")


def main(argv=None):
    args = _parser().parse_args(argv)
    try:
        directory = Path.cwd().resolve()
        source = repository_context(directory)
        store_path = default_store_path(source["root"])
        with closing(open_store(store_path)) as connection:
            if args.action == "list":
                if args.limit < 1:
                    raise ValueError("--limit must be at least 1")
                rows = connection.execute(
                    "SELECT * FROM validation_evidence ORDER BY started_at DESC LIMIT ?",
                    (args.limit,),
                ).fetchall()
                records = [
                    current_snapshot(row, source["head"], source["fingerprint"])
                    for row in rows
                ]
                if args.as_json:
                    print(
                        json.dumps(
                            [machine_record(record) for record in records],
                            indent=2,
                            ensure_ascii=False,
                        )
                    )
                else:
                    for record in records:
                        print(summarize_record(record))
                    if not records:
                        print("No validation evidence recorded for this repository.")
                return 0

            if args.action == "show":
                row = connection.execute(
                    "SELECT * FROM validation_evidence WHERE id = ?", (args.id,)
                ).fetchone()
                if row is None:
                    raise ValueError("validation evidence id was not found")
                record = current_snapshot(row, source["head"], source["fingerprint"])
                emit_record(record, as_json=args.as_json)
                return 0

            command = args.command
            if command and command[0] == "--":
                command = command[1:]
            run_source, cwd, package, sanitized, toolchain, has_redactions = (
                _prepare_context(args, command)
            )
            if args.action == "skip":
                record = record_skip(
                    connection,
                    command=sanitized,
                    cwd=cwd,
                    package=package,
                    head=run_source["head"],
                    fingerprint=run_source["fingerprint"],
                    toolchain=toolchain,
                    reason=args.reason,
                )
                emit_record(record, as_json=args.as_json)
                return 0

            if args.timeout is not None and args.timeout <= 0:
                raise ValueError("--timeout must be greater than zero")

            if args.reuse and not has_redactions:
                reusable = find_reusable_record(
                    connection,
                    command=sanitized,
                    cwd=cwd,
                    package=package,
                    head=run_source["head"],
                    fingerprint=run_source["fingerprint"],
                    toolchain=toolchain,
                )
                if reusable is not None:
                    emit_record(reusable, as_json=args.as_json, reused=True)
                    return 0

            record = start_record(
                connection,
                command=sanitized,
                cwd=cwd,
                package=package,
                head=run_source["head"],
                fingerprint=run_source["fingerprint"],
                toolchain=toolchain,
                reuse_allowed=not has_redactions,
            )
            status, exit_code, detail, duration_ms = execute_command(
                command, directory, args.timeout
            )
            result = finish_record(
                connection,
                record["id"],
                status=status,
                exit_code=exit_code,
                detail=detail,
                duration_ms=duration_ms,
            )
            emit_record(result, as_json=args.as_json)
            if status == "cancelled":
                return 130
            if detail == "timed out without a command exit code":
                return 124
            if exit_code is None:
                return 127
            return min(exit_code, 255) if exit_code >= 0 else 128 + abs(exit_code)
    except (OSError, RuntimeError, ValueError) as error:
        print(f"validation evidence: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())

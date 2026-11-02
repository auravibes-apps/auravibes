#!/usr/bin/env python3
"""Read-only preflight and status for AuraVibes agent worktrees."""

import argparse
import json
import os
import re
import shlex
import shutil
import subprocess
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit

from validation_lease import _validation_lock_path, read_active_owner


def _run(command, cwd, *, check=True):
    result = subprocess.run(command, cwd=cwd, capture_output=True, text=True)
    if check and result.returncode:
        detail = result.stderr.strip() or result.stdout.strip()
        raise RuntimeError(detail or f"command failed: {command[0]}")
    return result


def _repo_root(path):
    result = _run(["git", "rev-parse", "--show-toplevel"], path)
    return Path(result.stdout.strip()).resolve()


def _parse_worktrees(output):
    worktrees = []
    current = {}
    for line in [*output.splitlines(), ""]:
        if not line:
            if current:
                worktrees.append(current)
                current = {}
        elif line.startswith("worktree "):
            current["path"] = line.removeprefix("worktree ")
        elif line.startswith("branch "):
            current["branch"] = line.removeprefix("branch refs/heads/")
        elif line == "detached":
            current["branch"] = "(detached)"
        elif line.startswith("locked"):
            current["locked"] = line.removeprefix("locked").strip() or True
        elif line.startswith("prunable"):
            current["prunable"] = line.removeprefix("prunable").strip() or True
    return worktrees


def _worktree_status(repo_root):
    result = _run(["git", "worktree", "list", "--porcelain"], repo_root)
    worktrees = []
    for item in _parse_worktrees(result.stdout):
        path = Path(item["path"])
        record = {
            "path": str(path),
            "branch": item.get("branch", "(unknown)"),
            "locked": item.get("locked", False),
        }
        if item.get("prunable") or not path.is_dir():
            record["state"] = "prunable" if item.get("prunable") else "missing"
            record["changed_files"] = 0
            record["ready"] = False
            record["blocked"] = ["worktree is missing"]
        else:
            try:
                status = _run(
                    ["git", "status", "--porcelain", "--untracked-files=normal"], path
                )
                record["changed_files"] = len(status.stdout.splitlines())
                record["state"] = "dirty" if record["changed_files"] else "clean"
            except (OSError, RuntimeError) as error:
                record["state"] = "error"
                record["error"] = str(error)
                record["changed_files"] = 0
            checks = _readiness_checks(path)
            record["blocked"] = [
                check["name"] for check in checks if not check["ok"]
            ]
            if record["state"] == "error":
                record["blocked"].insert(0, "git status unavailable")
            record["ready"] = not record["blocked"]
        worktrees.append(record)
    return worktrees


def _status(repo_root):
    return {
        "repository": str(repo_root),
        "worktrees": _worktree_status(repo_root),
        "validation_lease": read_active_owner(_validation_lock_path()),
    }


def _package_config_check(path):
    try:
        config = json.loads(path.read_text())
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
        return False, f"unreadable or invalid: {error}"
    if not isinstance(config, dict) or not isinstance(config.get("packages"), list):
        return False, "invalid workspace package list"
    app_package = next(
        (
            package
            for package in config["packages"]
            if isinstance(package, dict) and package.get("name") == "auravibes_app"
        ),
        None,
    )
    if app_package is None:
        return False, "does not contain workspace package auravibes_app"

    root_uri = app_package.get("rootUri")
    if not isinstance(root_uri, str):
        return False, "workspace package is missing rootUri"
    parsed = urlsplit(root_uri)
    if parsed.scheme == "file" and parsed.netloc in ("", "localhost"):
        package_root = Path(unquote(parsed.path))
    elif parsed.scheme:
        return False, f"unsupported workspace URI scheme: {parsed.scheme}"
    else:
        package_root = path.parent / unquote(parsed.path)
    expected_root = path.parent.parent / "apps" / "auravibes_app"
    if package_root.resolve() != expected_root.resolve():
        return False, "workspace package resolves outside this worktree"
    return True, "resolved to current worktree"


def _readiness_checks(repo_root):
    sdk_link = repo_root / ".fvm" / "flutter_sdk"
    package_config = repo_root / ".dart_tool" / "package_config.json"
    config_ok, config_detail = _package_config_check(package_config)
    devtools_options = repo_root / "apps" / "auravibes_app" / "devtools_options.yaml"
    try:
        fvm_config = json.loads((repo_root / ".fvmrc").read_text())
    except (OSError, UnicodeDecodeError, json.JSONDecodeError):
        fvm_config = {}
    pinned_version = (
        fvm_config.get("flutter") if isinstance(fvm_config, dict) else None
    )
    sdk_ok = (
        isinstance(pinned_version, str)
        and sdk_link.is_symlink()
        and sdk_link.exists()
        and sdk_link.resolve().name == pinned_version
    )
    return [
        {
            "name": "pinned Flutter SDK",
            "ok": sdk_ok,
            "path": str(sdk_link),
            "detail": None if sdk_ok else "link does not match .fvmrc",
        },
        {
            "name": "resolved Pub workspace config",
            "ok": config_ok,
            "path": str(package_config),
            "detail": config_detail,
        },
        {
            "name": "app DevTools configuration",
            "ok": devtools_options.is_file(),
            "path": str(devtools_options),
        },
    ]


_FVM_USE_COMMAND = (
    "fvm use \"$(python3 -c 'import json; "
    "print(json.load(open(\".fvmrc\"))[\"flutter\"])')\" --skip-pub-get"
)
_MELOS_BOOTSTRAP_COMMAND = (
    "python3 tool/validation_lease.py -- fvm dart run melos bootstrap"
)


def _check(name, status, expected, observed, next_step):
    return {
        "name": name,
        "status": status,
        "expected": expected,
        "observed": observed,
        "next_step": next_step,
    }


def _read_flutter_pin(repo_root):
    path = repo_root / ".fvmrc"
    try:
        config = json.loads(path.read_text())
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
        return None, f"could not read .fvmrc: {error}"
    if not isinstance(config, dict) or not isinstance(config.get("flutter"), str):
        return None, ".fvmrc is missing a valid flutter version"
    version = config["flutter"].strip()
    if not version:
        return None, ".fvmrc has an empty flutter version"
    return version, None


def _fvm_cli_check(fvm_path):
    if fvm_path:
        return _check(
            "FVM CLI",
            "pass",
            "fvm available in PATH",
            f"found at {fvm_path}",
            "No action required.",
        )
    return _check(
        "FVM CLI",
        "mismatch",
        "fvm available in PATH",
        "not found in PATH",
        "dart pub global activate fvm",
    )


def _sdk_repair_step(fvm_available, pinned_version):
    if pinned_version is None:
        return "git diff -- .fvmrc"
    if not fvm_available:
        return "dart pub global activate fvm"
    return _FVM_USE_COMMAND


def _pinned_sdk_check(repo_root, pinned_version, fvm_available):
    if pinned_version is None:
        return (
            _check(
                "pinned Flutter SDK",
                "unknown",
                "Flutter version from .fvmrc",
                "could not establish the pinned version",
                "git diff -- .fvmrc",
            ),
            "unknown",
        )

    expected = f"Flutter {pinned_version}"
    sdk_link = repo_root / ".fvm" / "flutter_sdk"
    if not sdk_link.is_symlink():
        observed = (
            "not an FVM symlink"
            if sdk_link.exists()
            else "missing .fvm/flutter_sdk link"
        )
        return (
            _check(
                "pinned Flutter SDK",
                "mismatch",
                expected,
                observed,
                _sdk_repair_step(fvm_available, pinned_version),
            ),
            "mismatch",
        )

    if not sdk_link.exists():
        return (
            _check(
                "pinned Flutter SDK",
                "mismatch",
                expected,
                "dangling .fvm/flutter_sdk link",
                _sdk_repair_step(fvm_available, pinned_version),
            ),
            "mismatch",
        )

    try:
        sdk_path = sdk_link.resolve(strict=True)
    except (OSError, RuntimeError) as error:
        return (
            _check(
                "pinned Flutter SDK",
                "mismatch",
                expected,
                f"could not resolve .fvm/flutter_sdk: {error}",
                _sdk_repair_step(fvm_available, pinned_version),
            ),
            "mismatch",
        )
    if not sdk_path.is_dir():
        return (
            _check(
                "pinned Flutter SDK",
                "mismatch",
                expected,
                f"SDK link target is not a directory: {sdk_path}",
                _sdk_repair_step(fvm_available, pinned_version),
            ),
            "mismatch",
        )
    if sdk_path.name != pinned_version:
        return (
            _check(
                "pinned Flutter SDK",
                "mismatch",
                expected,
                f"SDK link resolves to directory {sdk_path.name}: {sdk_path}",
                _sdk_repair_step(fvm_available, pinned_version),
            ),
            "mismatch",
        )

    metadata = sdk_path / "bin" / "cache" / "flutter.version.json"
    try:
        metadata_value = json.loads(metadata.read_text())
    except FileNotFoundError:
        metadata_detail = f"version metadata unavailable at {metadata}"
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as error:
        metadata_detail = f"version metadata unreadable at {metadata}: {error}"
    else:
        framework_version = (
            metadata_value.get("frameworkVersion")
            if isinstance(metadata_value, dict)
            else None
        )
        if not isinstance(framework_version, str) or not framework_version:
            metadata_detail = f"frameworkVersion unavailable in {metadata}"
        elif framework_version != pinned_version:
            return (
                _check(
                    "pinned Flutter SDK",
                    "mismatch",
                    expected,
                    f"flutter.version.json reports Flutter {framework_version}",
                    _sdk_repair_step(fvm_available, pinned_version),
                ),
                "mismatch",
            )
        else:
            return (
                _check(
                    "pinned Flutter SDK",
                    "pass",
                    expected,
                    f"Flutter {framework_version} at {sdk_path}",
                    "No action required.",
                ),
                "pass",
            )

    return (
        _check(
            "pinned Flutter SDK",
            "unknown",
            expected,
            f"SDK link target is named {pinned_version}; {metadata_detail}",
            f"cat {shlex.quote(str(metadata))}",
        ),
        "unknown",
    )


def _melos_bootstrap_check(repo_root):
    path = repo_root / "pubspec.yaml"
    expected = "melos.sdkPath=.fvm/flutter_sdk and melos.command.bootstrap configured"
    try:
        lines = path.read_text().splitlines()
    except (OSError, UnicodeDecodeError) as error:
        return (
            _check(
                "Melos bootstrap configuration",
                "unknown",
                expected,
                f"could not read pubspec.yaml: {error}",
                "git diff -- pubspec.yaml",
            ),
            False,
        )

    melos_start = next(
        (
            index
            for index, line in enumerate(lines)
            if line.strip() == "melos:" and not line[:1].isspace()
        ),
        None,
    )
    if melos_start is None:
        return (
            _check(
                "Melos bootstrap configuration",
                "mismatch",
                expected,
                "melos configuration missing",
                "git diff -- pubspec.yaml",
            ),
            False,
        )

    melos_lines = []
    for line in lines[melos_start + 1 :]:
        if line.strip() and not line[:1].isspace() and not line.lstrip().startswith("#"):
            break
        melos_lines.append(line)

    sdk_path = None
    command_found = False
    bootstrap_found = False
    in_command = False
    for line in melos_lines:
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        indent = len(line) - len(line.lstrip(" "))
        if indent == 2 and stripped.startswith("sdkPath:"):
            sdk_path = stripped.split(":", maxsplit=1)[1].split("#", maxsplit=1)[0]
            sdk_path = sdk_path.strip().strip("\"'")
        elif indent == 2 and stripped == "command:":
            command_found = True
            in_command = True
        elif in_command and indent <= 2:
            in_command = False
        elif in_command and indent == 4 and stripped.startswith("bootstrap:"):
            bootstrap_found = True

    observed_parts = [
        f"melos.sdkPath={sdk_path}" if sdk_path else "melos.sdkPath missing",
        "melos.command.bootstrap configured"
        if bootstrap_found
        else "melos.command.bootstrap missing",
    ]
    observed = "; ".join(observed_parts)
    if sdk_path == ".fvm/flutter_sdk" and command_found and bootstrap_found:
        return (
            _check(
                "Melos bootstrap configuration",
                "pass",
                expected,
                observed,
                "No action required.",
            ),
            True,
        )
    return (
        _check(
            "Melos bootstrap configuration",
            "mismatch",
            expected,
            observed,
            "git diff -- pubspec.yaml",
        ),
        False,
    )


def _bootstrap_next_step(fvm_available, pinned_version, sdk_status, melos_ready):
    if not melos_ready:
        return "git diff -- pubspec.yaml"
    if pinned_version is None:
        return "git diff -- .fvmrc"

    steps = []
    if not fvm_available:
        steps.append("dart pub global activate fvm")
    if sdk_status != "pass":
        steps.append(_FVM_USE_COMMAND)
    steps.append(_MELOS_BOOTSTRAP_COMMAND)
    if len(steps) == 1:
        return steps[0]
    return "\n".join(
        f"{index}. {step}" for index, step in enumerate(steps, start=1)
    )


def _package_root_from_uri(package_config_path, root_uri):
    parsed = urlsplit(root_uri)
    if parsed.scheme == "file" and parsed.netloc in ("", "localhost"):
        return Path(unquote(parsed.path)), None
    if parsed.scheme:
        return None, f"unsupported workspace URI scheme: {parsed.scheme}"
    return package_config_path.parent / unquote(parsed.path), None


def _pub_workspace_check(
    repo_root, fvm_available, pinned_version, sdk_status, melos_ready
):
    path = repo_root / ".dart_tool" / "package_config.json"
    expected_root = (repo_root / "apps" / "auravibes_app").resolve()
    expected = f"auravibes_app resolves to {expected_root}"
    next_step = _bootstrap_next_step(
        fvm_available, pinned_version, sdk_status, melos_ready
    )
    try:
        config = json.loads(path.read_text())
    except FileNotFoundError:
        return _check(
            "resolved Pub workspace config",
            "mismatch",
            expected,
            "missing package configuration; bootstrap history unknown",
            next_step,
        )
    except json.JSONDecodeError as error:
        return _check(
            "resolved Pub workspace config",
            "mismatch",
            expected,
            f"invalid package configuration JSON: {error}",
            next_step,
        )
    except (OSError, UnicodeDecodeError) as error:
        return _check(
            "resolved Pub workspace config",
            "unknown",
            expected,
            f"could not read package configuration: {error}",
            f"cat {shlex.quote(str(path))}",
        )

    packages = config.get("packages") if isinstance(config, dict) else None
    if not isinstance(packages, list):
        return _check(
            "resolved Pub workspace config",
            "mismatch",
            expected,
            "invalid package configuration package list",
            next_step,
        )
    app_package = next(
        (
            package
            for package in packages
            if isinstance(package, dict) and package.get("name") == "auravibes_app"
        ),
        None,
    )
    if app_package is None:
        return _check(
            "resolved Pub workspace config",
            "mismatch",
            expected,
            "missing auravibes_app package entry",
            next_step,
        )

    root_uri = app_package.get("rootUri")
    if not isinstance(root_uri, str):
        return _check(
            "resolved Pub workspace config",
            "mismatch",
            expected,
            "auravibes_app entry has no rootUri",
            next_step,
        )
    package_root, error = _package_root_from_uri(path, root_uri)
    if error:
        return _check(
            "resolved Pub workspace config",
            "unknown",
            expected,
            error,
            f"cat {shlex.quote(str(path))}",
        )
    try:
        observed_root = package_root.resolve()
    except (OSError, RuntimeError) as error:
        return _check(
            "resolved Pub workspace config",
            "unknown",
            expected,
            f"could not resolve auravibes_app rootUri: {error}",
            f"cat {shlex.quote(str(path))}",
        )
    if observed_root != expected_root:
        scope = (
            "outside this worktree"
            if not observed_root.is_relative_to(repo_root.resolve())
            else "not the expected app package directory"
        )
        return _check(
            "resolved Pub workspace config",
            "mismatch",
            expected,
            f"auravibes_app rootUri resolves to {observed_root} ({scope})",
            next_step,
        )
    if not observed_root.is_dir():
        return _check(
            "resolved Pub workspace config",
            "mismatch",
            expected,
            f"auravibes_app package directory is missing at {observed_root}",
            next_step,
        )
    return _check(
        "resolved Pub workspace config",
        "pass",
        expected,
        f"auravibes_app resolves to {observed_root} in this worktree",
        "No action required.",
    )


def _pub_cache_check(repo_root, pub_cache):
    if pub_cache is None:
        configured = os.environ.get("PUB_CACHE")
        cache_path = (
            Path(configured).expanduser()
            if configured
            else Path.home() / ".pub-cache"
        )
        if not cache_path.is_absolute():
            cache_path = Path.cwd() / cache_path
    else:
        cache_path = Path(pub_cache).expanduser()
        if not cache_path.is_absolute():
            cache_path = repo_root / cache_path

    try:
        resolved_path = cache_path.resolve()
        resolved_root = repo_root.resolve()
    except (OSError, RuntimeError) as error:
        observed = f"could not resolve configured cache path {cache_path}: {error}"
        return _check(
            "Pub cache",
            "unknown",
            "existing cache with verified write access",
            observed,
            f"ls -ld {shlex.quote(str(cache_path))}",
        )

    shared = not resolved_path.is_relative_to(resolved_root)
    scope = "outside this worktree (shared scope unverified)" if shared else "worktree-local"
    if not cache_path.exists():
        return _check(
            "Pub cache",
            "unknown",
            "existing cache with verified write access",
            f"configured cache does not exist: {resolved_path} ({scope})",
            f"ls -ld {shlex.quote(str(cache_path))}",
        )
    if not cache_path.is_dir():
        return _check(
            "Pub cache",
            "mismatch",
            "cache path is a writable directory",
            f"configured cache is not a directory: {resolved_path}",
            f"ls -ld {shlex.quote(str(cache_path))}",
        )
    try:
        writable = os.access(cache_path, os.W_OK)
    except OSError as error:
        return _check(
            "Pub cache",
            "unknown",
            "existing cache with verified write access",
            f"could not inspect write access for {resolved_path}: {error}",
            f"ls -ld {shlex.quote(str(cache_path))}",
        )
    if not writable:
        return _check(
            "Pub cache",
            "mismatch",
            "cache writable by this process",
            f"not writable by this process: {resolved_path} ({scope})",
            f"ls -ld {shlex.quote(str(cache_path))}",
        )
    if shared:
        return _check(
            "Pub cache",
            "warning",
            "shared cache may be used; cross-worktree state remains unverified",
            f"writable by this process at {resolved_path}; {scope}",
            f"ls -ld {shlex.quote(str(cache_path))}",
        )
    return _check(
        "Pub cache",
        "pass",
        "cache writable by this process",
        f"writable by this process at {resolved_path} ({scope})",
        "No action required.",
    )


def _toolchain_checks(
    repo_root: Path, *, pub_cache: Path | None = None
) -> list[dict[str, str]]:
    """Inspect local Flutter/Melos setup without running or writing setup tools."""
    fvm_path = shutil.which("fvm")
    fvm_available = fvm_path is not None
    pinned_version, pin_error = _read_flutter_pin(repo_root)
    sdk_check, sdk_status = _pinned_sdk_check(
        repo_root, pinned_version, fvm_available
    )
    melos_check, melos_ready = _melos_bootstrap_check(repo_root)
    pub_check = _pub_workspace_check(
        repo_root,
        fvm_available,
        pinned_version,
        sdk_status,
        melos_ready,
    )

    checks = [
        _fvm_cli_check(fvm_path),
        sdk_check,
        melos_check,
        pub_check,
        _pub_cache_check(repo_root, pub_cache),
    ]
    if pin_error and sdk_check["status"] == "unknown":
        sdk_check["observed"] = pin_error
    return checks


def _mentions_issue(value, issue_number):
    if not isinstance(value, str):
        return False
    return re.search(
        rf"(?<![A-Za-z0-9])(?:issue[-_/]?)?{issue_number}(?![A-Za-z0-9])",
        value,
        re.IGNORECASE,
    ) is not None


def _github_target(repo_root, issue_number):
    fields = "number,title,state,url,labels"
    issue = _run(
        ["gh", "issue", "view", str(issue_number), "--json", fields],
        repo_root,
        check=False,
    )
    if issue.returncode == 0:
        return {"kind": "issue", **json.loads(issue.stdout)}
    pull_request = _run(
        [
            "gh",
            "pr",
            "view",
            str(issue_number),
            "--json",
            f"{fields},headRefName",
        ],
        repo_root,
        check=False,
    )
    if pull_request.returncode == 0:
        return {"kind": "pull request", **json.loads(pull_request.stdout)}
    errors = "; ".join(
        message
        for message in (issue.stderr.strip(), pull_request.stderr.strip())
        if message
    )
    raise RuntimeError(errors or f"cannot read issue or pull request #{issue_number}")


def _issue_conflicts(repo_root, issue_number, target):
    branches = _run(
        ["git", "for-each-ref", "--format=%(refname:short)", "refs/heads"],
        repo_root,
    ).stdout.splitlines()
    current_branch = _run(
        ["git", "branch", "--show-current"], repo_root
    ).stdout.strip()
    branch_matches = [
        branch
        for branch in branches
        if branch != current_branch and _mentions_issue(branch, issue_number)
    ]

    worktrees = [
        item
        for item in _parse_worktrees(
            _run(["git", "worktree", "list", "--porcelain"], repo_root).stdout
        )
        if Path(item["path"]).resolve() != repo_root
        and _mentions_issue(item.get("branch", ""), issue_number)
    ]
    # ponytail: scans up to 1,000 open PRs; larger repos need paginated issue search.
    pull_requests = json.loads(
        _run(
            [
                "gh",
                "pr",
                "list",
                "--state",
                "open",
                "--limit",
                "1000",
                "--json",
                "number,title,body,headRefName,url",
            ],
            repo_root,
        ).stdout
    )
    pull_request_matches = [
        pull_request
        for pull_request in pull_requests
        if pull_request.get("number") != target.get("number")
        and any(
            _mentions_issue(pull_request.get(field), issue_number)
            for field in ("title", "body", "headRefName")
        )
    ]
    return {
        "branches": branch_matches,
        "worktrees": worktrees,
        "pull_requests": pull_request_matches,
    }


def _preflight(repo_root, issue_number=None):
    result = {"repository": str(repo_root), "checks": _readiness_checks(repo_root)}
    if issue_number is not None:
        target = _github_target(repo_root, issue_number)
        result["target"] = target
        result["target_open"] = str(target.get("state", "")).upper() == "OPEN"
        result["conflicts"] = _issue_conflicts(repo_root, issue_number, target)
    return result


def _print_status(result):
    worktrees = result["worktrees"]
    dirty = sum(item["state"] == "dirty" for item in worktrees)
    prunable = sum(item["state"] in ("missing", "prunable") for item in worktrees)
    blocked = sum(not item["ready"] for item in worktrees)
    print(f"Repository: {result['repository']}")
    print(
        f"Worktrees: {len(worktrees)} total, {dirty} dirty, "
        f"{blocked} not ready, {prunable} missing/prunable"
    )
    for item in worktrees:
        locked = " locked" if item["locked"] else ""
        changed = f" ({item['changed_files']} changed)" if item["changed_files"] else ""
        readiness = "ready" if item["ready"] else "blocked: " + ", ".join(item["blocked"])
        print(
            f"  {item['state']}/{readiness}{locked}: "
            f"{item['branch']} — {item['path']}{changed}"
        )
    owner = result["validation_lease"]
    if owner is None:
        print("Current worktree validation lease: free")
    elif owner.get("metadata_unavailable"):
        print("Current worktree validation lease: active; owner metadata unavailable")
    else:
        label = f" label={owner.get('label')}" if owner.get("label") else ""
        print(
            "Current worktree validation lease: held by"
            f"{label} pid={owner.get('pid')} host={owner.get('host')}"
            f" cwd={owner.get('cwd')} started={owner.get('started_at')}"
        )


def _print_preflight(result):
    print(f"Repository: {result['repository']}")
    for check in result["checks"]:
        state = "ready" if check["ok"] else "BLOCKED"
        detail = f" ({check['detail']})" if check.get("detail") else ""
        print(f"{state}: {check['name']} — {check['path']}{detail}")
    if any(not check["ok"] for check in result["checks"]):
        if not result["checks"][0]["ok"] or not result["checks"][1]["ok"]:
            print(
                'Setup: fvm use "$(python3 -c \'import json; '
                'print(json.load(open(\".fvmrc\"))[\"flutter\"])\')" '
                "--skip-pub-get"
            )
            print("Then: python3 tool/validation_lease.py -- fvm dart run melos bootstrap")
        if not result["checks"][2]["ok"]:
            print("Place DevTools config at apps/auravibes_app/devtools_options.yaml")
    if "target" in result:
        target = result["target"]
        print(
            f"Target: {target['kind']} #{target['number']} {target['title']} "
            f"({target.get('state', 'unknown')})"
        )
        if not result["target_open"]:
            print("Stop: target is not open.")
        conflicts = result["conflicts"]
        for kind, matches in conflicts.items():
            print(f"{kind.replace('_', ' ')}: {len(matches)} possible match(es)")
            for match in matches:
                if kind == "pull_requests":
                    branch = f" ({match['headRefName']})" if match.get("headRefName") else ""
                    print(f"  #{match.get('number')} {match.get('title')}{branch}")
                elif isinstance(match, dict):
                    print(f"  {match.get('branch', 'unknown branch')} — {match.get('path')}")
                else:
                    print(f"  {match}")
        if any(conflicts.values()):
            print("Stop: coordinate with matching worktree or open PR before claiming.")


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    status_parser = subparsers.add_parser(
        "status", help="summarize linked worktrees and current validation lease"
    )
    status_parser.add_argument("--json", action="store_true", help="print JSON")
    preflight_parser = subparsers.add_parser(
        "preflight", help="check worktree readiness and optional ticket collisions"
    )
    preflight_parser.add_argument(
        "--issue", type=int, help="GitHub issue or pull request number"
    )
    preflight_parser.add_argument("--json", action="store_true", help="print JSON")
    doctor_parser = subparsers.add_parser(
        "doctor", help="diagnose local Flutter and Melos setup without changes"
    )
    doctor_parser.add_argument("--json", action="store_true", help="print JSON")
    return parser


def _format_doctor(checks, *, as_json=False) -> str:
    if as_json:
        return json.dumps(checks, indent=2)

    labels = {
        "pass": "PASS",
        "mismatch": "CONFIRMED MISMATCH",
        "warning": "UNVERIFIED WARNING",
        "unknown": "UNKNOWN",
    }
    lines = []
    for check in checks:
        label = labels.get(check["status"], check["status"].upper())
        lines.extend(
            (
                f"{label}: {check['name']}",
                f"  Expected: {check['expected']}",
                f"  Observed: {check['observed']}",
            )
        )
        steps = check["next_step"].splitlines()
        if len(steps) == 1:
            lines.append(f"  Next step: {steps[0]}")
        else:
            lines.append("  Next steps:")
            lines.extend(f"    {step}" for step in steps)
    return "\n".join(lines)


def main(argv=None):
    parser = _build_parser()
    args = parser.parse_args(argv)
    if args.command == "preflight" and args.issue is not None and args.issue < 1:
        parser.error("--issue must be a positive number")

    try:
        repo_root = _repo_root(Path.cwd())
        if args.command == "status":
            result = _status(repo_root)
            if args.json:
                print(json.dumps(result, indent=2))
            else:
                _print_status(result)
            return 0

        if args.command == "doctor":
            checks = _toolchain_checks(repo_root)
            output = _format_doctor(checks, as_json=args.json)
            if not args.json:
                print(f"Repository: {repo_root}")
            print(output)
            return 1 if any(check["status"] == "mismatch" for check in checks) else 0

        result = _preflight(repo_root, args.issue)
        if args.json:
            print(json.dumps(result, indent=2))
        else:
            _print_preflight(result)
        blocked = any(not check["ok"] for check in result["checks"])
        conflicts = result.get("conflicts", {})
        target_closed = "target_open" in result and not result["target_open"]
        return 1 if blocked or any(conflicts.values()) or target_closed else 0
    except (OSError, RuntimeError, subprocess.SubprocessError, json.JSONDecodeError) as error:
        failure = "Doctor failed" if args.command == "doctor" else "Preflight failed"
        print(f"{failure}: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())

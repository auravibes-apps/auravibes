#!/usr/bin/env python3
"""Read-only preflight and status for AuraVibes agent worktrees."""

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit

from validation_lease import _validation_lock_paths, read_active_owner


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
    owners = [
        read_active_owner(path)
        for path in _validation_lock_paths(create_directories=False)
    ]
    lease_owner = next((owner for owner in owners if owner is not None), None)
    return {
        "repository": str(repo_root),
        "worktrees": _worktree_status(repo_root),
        "validation_lease": lease_owner,
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
        print("Validation lease: free")
    elif owner.get("metadata_unavailable"):
        print("Validation lease: active; owner metadata unavailable")
    else:
        label = f" label={owner.get('label')}" if owner.get("label") else ""
        print(
            "Validation lease: held by"
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


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)
    status_parser = subparsers.add_parser(
        "status", help="summarize linked worktrees and validation lease"
    )
    status_parser.add_argument("--json", action="store_true", help="print JSON")
    preflight_parser = subparsers.add_parser(
        "preflight", help="check worktree readiness and optional ticket collisions"
    )
    preflight_parser.add_argument(
        "--issue", type=int, help="GitHub issue or pull request number"
    )
    preflight_parser.add_argument("--json", action="store_true", help="print JSON")
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
        print(f"Preflight failed: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())

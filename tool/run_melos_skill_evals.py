#!/usr/bin/env python3
"""Check behavior-backed repository facts for the Melos setup skill evals."""

from dataclasses import dataclass
import json
from pathlib import Path
import re
import sys
from typing import Callable


@dataclass(frozen=True)
class ScenarioResult:
    case_id: int
    passed: bool
    failures: tuple[str, ...]


BehaviorCheck = Callable[[Path], list[str]]


def _read_text(root: Path, relative_path: str) -> str | None:
    path = root / relative_path
    try:
        return path.read_text()
    except OSError:
        return None


def _documented_command(root: Path, command: str) -> bool:
    for path in ("AGENTS.md", ".agents/skills/melos-7/SKILL.md"):
        content = _read_text(root, path)
        if content is not None and command in content:
            return True
    return False


def _formatting_check(root: Path) -> list[str]:
    failures = []
    pubspec = _read_text(root, "pubspec.yaml")
    workflow = _read_text(root, ".github/workflows/ci.yml")
    if pubspec is None:
        failures.append("Root pubspec.yaml is missing.")
    else:
        lines = pubspec.splitlines()
        start = next(
            (
                index
                for index, line in enumerate(lines)
                if line == "    format:check:"
            ),
            None,
        )
        block = []
        if start is not None:
            for line in lines[start + 1 :]:
                if line.strip() and len(line) - len(line.lstrip()) < 6:
                    break
                block.append(line)
        script = "\n".join(block)
        if not all(
            marker in script
            for marker in ("dart format", "-o none", "--set-exit-if-changed")
        ):
            failures.append(
                "The root Melos format:check script is missing its non-mutating Dart formatter behavior."
            )

    if not _documented_command(root, "fvm dart run melos run format:check"):
        failures.append(
            "The pinned format:check command is not documented for contributors."
        )
    if not _documented_command(root, "fvm dart format"):
        failures.append("The pinned Dart formatting command is not documented.")
    if workflow is None or "melos run format:check" not in workflow:
        failures.append("CI does not run the Melos format:check script.")
    return failures


def _fvm_pub_resolution(root: Path) -> list[str]:
    failures = []
    config_path = root / ".fvmrc"
    try:
        config = json.loads(config_path.read_text())
    except (OSError, json.JSONDecodeError):
        config = None
    if not isinstance(config, dict) or config.get("runPubGetOnSdkChanges") is not True:
        failures.append(".fvmrc does not enable Pub resolution when the SDK changes.")

    skill = _read_text(root, ".agents/skills/melos-7/SKILL.md")
    if (
        skill is None
        or ".fvmrc" not in skill
        or "--skip-pub-get" not in skill
    ):
        failures.append(
            "Melos setup guidance does not explain default Pub resolution and the skip flag."
        )
    return failures


def _melos_bootstrap(root: Path) -> list[str]:
    failures = []
    pubspec = _read_text(root, "pubspec.yaml")
    if pubspec is None or not re.search(r"(?m)^  melos:\s*\S+", pubspec):
        failures.append("The root package does not declare Melos as a dependency.")
    if pubspec is None or not re.search(r"(?m)^workspace:\s*$", pubspec):
        failures.append("The root Pub workspace declaration is missing.")

    action = _read_text(root, ".github/actions/setup-workspace/action.yml")
    workflow = _read_text(root, ".github/workflows/ci.yml")
    if (
        action is None
        or not re.search(r"(?m)^\s*run-bootstrap:\s*true\s*$", action)
        or workflow is None
        or "./.github/actions/setup-workspace" not in workflow
    ):
        failures.append("The CI setup path does not run Melos bootstrap.")

    if not _documented_command(root, "fvm dart run melos bootstrap"):
        failures.append("The pinned Melos bootstrap command is not documented.")
    return failures


_CHECKS: dict[str, BehaviorCheck] = {
    "formatting": _formatting_check,
    "fvm_pub_resolution": _fvm_pub_resolution,
    "melos_bootstrap": _melos_bootstrap,
}


def evaluate_skill_evals(root: Path) -> list[ScenarioResult]:
    eval_path = root / ".agents/skills/melos-7/evals/evals.json"
    try:
        data = json.loads(eval_path.read_text())
    except (OSError, json.JSONDecodeError) as error:
        raise ValueError(f"Cannot read {eval_path}: {error}") from error
    if not isinstance(data, dict) or data.get("skill_name") != "melos-7":
        raise ValueError("The eval file must describe the melos-7 skill.")
    cases = data.get("evals")
    if not isinstance(cases, list):
        raise ValueError("The eval file must contain an evals list.")

    results = []
    seen_ids = set()
    for case in cases:
        if not isinstance(case, dict) or "checks" not in case:
            continue
        case_id = case.get("id")
        if type(case_id) is not int or case_id in seen_ids:
            raise ValueError("Behavior eval IDs must be unique integers.")
        seen_ids.add(case_id)
        checks = case["checks"]
        if not isinstance(checks, list) or not checks:
            raise ValueError(f"Eval {case_id} must have one or more behavior checks.")

        failures = []
        for check_name in checks:
            check = _CHECKS.get(check_name) if isinstance(check_name, str) else None
            if check is None:
                failures.append(f"Unknown behavior check: {check_name!r}.")
                continue
            failures.extend(check(root))
        results.append(
            ScenarioResult(
                case_id=case_id,
                passed=not failures,
                failures=tuple(failures),
            )
        )

    if not results:
        raise ValueError("The eval file contains no runnable behavior scenarios.")
    return results


def main() -> int:
    root = Path(__file__).resolve().parent.parent
    try:
        results = evaluate_skill_evals(root)
    except ValueError as error:
        print(f"ERROR {error}", file=sys.stderr)
        return 2

    failures = 0
    for result in results:
        outcome = "PASS" if result.passed else "FAIL"
        print(f"{outcome} Melos setup scenario #{result.case_id}")
        for failure in result.failures:
            failures += 1
            print(f"  - {failure}")
    failed_scenarios = sum(not item.passed for item in results)
    print(
        f"Melos setup evals: {len(results) - failed_scenarios} passed, "
        f"{failed_scenarios} failed."
    )
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())

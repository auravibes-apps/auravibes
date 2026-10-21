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


BehaviorCheck = Callable[[Path, str], list[str]]


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


def _matches_any(content: str, patterns: tuple[str, ...]) -> bool:
    content = content.replace("`", "")
    return any(
        re.search(pattern, content, re.IGNORECASE | re.DOTALL)
        for pattern in patterns
    )


def _formatting_check(root: Path, expected_output: str) -> list[str]:
    failures = []
    pubspec = _read_text(root, "pubspec.yaml")
    workflow = _read_text(root, ".github/workflows/ci.yml")
    skill = _read_text(root, ".agents/skills/melos-7/SKILL.md")
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
    if skill is None or not _matches_any(
        skill,
        (
            r"\bformatting changes are allowed\b",
            r"\b(?:contributors|developers|agents) may format (?:source )?files\b",
            r"\bformatting (?:is|remains) permitted\b",
        ),
    ) or _matches_any(
        skill,
        (
            r"\b(?:do not|don't|must not|never|should not|avoid)\s+(?:run|use|apply)\s+(?:the )?(?:dart )?formatter\b",
            r"\bformatting changes are not allowed\b",
            r"\bdo not run formatting commands\b",
        ),
    ):
        failures.append("Melos guidance must allow contributors to format source files.")
    if workflow is None or "melos run format:check" not in workflow:
        failures.append("CI does not run the Melos format:check script.")
    if (
        not _matches_any(
            expected_output,
            (
                r"\bformatting (?:changes )?(?:are|is) (?:allowed|permitted)\b",
                r"\b(?:may|can) format (?:source )?files\b",
                r"\bformat (?:source )?files (?:is|are) (?:allowed|permitted)\b",
            ),
        )
        or "fvm dart run melos run format:check" not in expected_output
        or _matches_any(
            expected_output,
            (
                r"\b(?:do not|don't|must not|never|should not|avoid)\s+(?:run|use|apply)\s+(?:the )?(?:dart )?formatter\b",
                r"\bformatting (?:changes )?are not allowed\b",
                r"\bdo not run formatting commands\b",
            ),
        )
    ):
        failures.append(
            "The expected output must allow formatting and recommend the pinned format:check command."
        )
    return failures


def _fvm_pub_resolution(root: Path, expected_output: str) -> list[str]:
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
        or not _matches_any(
            skill,
            (
                r"\.fvmrc.{0,100}enables? (?:flutter )?pub (?:get|resolution) by default",
                r"\bfvm.{0,80}switch(?:es|ing)? .{0,80}pub (?:get|resolution) runs? (?:by default|unless)",
            ),
        )
        or _matches_any(
            skill,
            (
                r"\bfvm (?:does not|doesn't|never|will not|won't) run (?:flutter )?pub (?:get|resolution) by default",
                r"\.fvmrc.{0,80}disables? (?:flutter )?pub (?:get|resolution)",
            ),
        )
    ):
        failures.append(
            "Melos setup guidance does not explain default Pub resolution and the skip flag."
        )
    if (
        ".fvmrc" not in expected_output
        or not _matches_any(
            expected_output,
            (
                r"\bfvm.{0,100}runs? pub (?:get|resolution) by default.{0,100}(?:switch|change).{0,40}sdk",
                r"\bwhen fvm (?:switches|changes).{0,100}sdk.{0,100}pub (?:get|resolution).{0,40}by default",
                r"\bpub (?:get|resolution).{0,80}by default.{0,100}fvm.{0,60}(?:switch|change).{0,40}sdk",
                r"\.fvmrc.{0,80}(?:makes|enables?|sets?).{0,60}pub (?:get|resolution).{0,60}run(?:s|ning)? when fvm (?:switches|changes).{0,40}sdk",
            ),
        )
        or not _matches_any(
            expected_output,
            (
                r"--skip-pub-get.{0,80}\b(?:skip(?:s)?|bypass(?:es)?|disable(?:s|d)?|avoid(?:s)?)\b.{0,40}(?:pub (?:get|resolution)|that resolution)",
                r"\b(?:skip(?:s)?|bypass(?:es)?|disable(?:s|d)?|avoid(?:s)?).{0,60}pub (?:get|resolution).{0,60}--skip-pub-get",
            ),
        )
        or _matches_any(
            expected_output,
            (
                r"\.fvmrc.{0,80}(?:disables?|turns off) pub (?:get|resolution)",
                r"fvm.{0,80}(?:does not|doesn't|never|will not|won't) run pub (?:get|resolution) by default",
            ),
        )
    ):
        failures.append(
            "The expected output must explain .fvmrc default Pub resolution and how --skip-pub-get skips it."
        )
    return failures


def _melos_bootstrap(root: Path, expected_output: str) -> list[str]:
    failures = []
    pubspec = _read_text(root, "pubspec.yaml")
    skill = _read_text(root, ".agents/skills/melos-7/SKILL.md")
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
    if skill is None or not _matches_any(
        skill,
        (
            r"pub workspace membership does not replace (?:that step|(?:melos )?bootstrap)",
            r"pub workspace alone is not a substitute for (?:the )?(?:repository's )?melos bootstrap",
            r"(?:melos )?bootstrap is still (?:required|needed)",
        ),
    ) or _matches_any(
        skill,
        (
            r"pub workspace membership makes (?:melos )?bootstrap redundant",
            r"(?:melos )?bootstrap (?:is )?(?:redundant|unnecessary|not needed|can be skipped)",
        ),
    ):
        failures.append("Melos guidance must keep bootstrap distinct from Pub workspace setup.")
    use_index = expected_output.find("fvm use")
    bootstrap_index = expected_output.find("fvm dart run melos bootstrap")
    if (
        not _matches_any(
            expected_output,
            (
                r"pub workspace.{0,100}(?:does not|doesn't|cannot|can't|is not|isn't).{0,80}(?:replace|substitute for).{0,40}(?:melos )?bootstrap",
                r"(?:melos )?bootstrap.{0,80}(?:is |remains )?(?:still )?(?:required|needed)",
            ),
        )
        or not _matches_any(
            expected_output,
            (
                r"\bci.{0,80}(?:runs?|uses?).{0,60}(?:melos )?bootstrap",
                r"(?:melos )?bootstrap.{0,80}(?:runs?|is used).{0,60}\bci\b",
            ),
        )
        or _matches_any(
            expected_output,
            (
                r"pub workspace membership makes (?:melos )?bootstrap redundant",
                r"(?:melos )?bootstrap (?:is )?(?:redundant|unnecessary|not needed|can be skipped)",
            ),
        )
        or use_index == -1
        or bootstrap_index <= use_index
    ):
        failures.append(
            "The expected output must distinguish Pub workspace from CI bootstrap and recommend fvm use before Melos bootstrap."
        )
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
    check_counts = {check_name: 0 for check_name in _CHECKS}
    for case in cases:
        if not isinstance(case, dict) or "checks" not in case:
            continue
        case_id = case.get("id")
        if type(case_id) is not int or case_id in seen_ids:
            raise ValueError("Behavior eval IDs must be unique integers.")
        seen_ids.add(case_id)
        checks = case["checks"]
        if not isinstance(checks, list) or not checks:
            raise ValueError(
                f"The eval file must exercise all behavior checks; eval {case_id} "
                "has no behavior checks."
            )

        failures = []
        expected_output = case.get("expected_output")
        if not isinstance(expected_output, str) or not expected_output.strip():
            failures.append("The behavior eval must define expected_output.")
            expected_output = ""
        for check_name in checks:
            check = _CHECKS.get(check_name) if isinstance(check_name, str) else None
            if check is None:
                failures.append(f"Unknown behavior check: {check_name!r}.")
                continue
            check_counts[check_name] += 1
            failures.extend(check(root, expected_output))
        results.append(
            ScenarioResult(
                case_id=case_id,
                passed=not failures,
                failures=tuple(failures),
            )
        )

    incomplete_checks = [
        f"{check_name} ({count} scenarios)"
        for check_name, count in check_counts.items()
        if count != 1
    ]
    if incomplete_checks:
        raise ValueError(
            "The eval file must exercise all behavior checks exactly once; "
            f"missing or repeated: {', '.join(incomplete_checks)}."
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

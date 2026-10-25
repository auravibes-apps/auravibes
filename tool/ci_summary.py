#!/usr/bin/env python3
"""Write CI summaries from routing outputs and test plan artifacts."""

import argparse
import html
import json
import os
from pathlib import Path
import shlex
import sys

from classify_ci_changes import _is_skill_metadata, _requires_code_checks


def text(value):
    return "".join(
        f"&#{ord(character)};" if character in "`[]*_!|#~\\" else character
        for character in html.escape(str(value)).replace("\n", " ")
    )


def path_list(paths):
    shown = paths[:40]
    lines = ["<ul>"] + [f"<li><code>{text(path)}</code></li>" for path in shown]
    lines.append("</ul>")
    if len(paths) > len(shown):
        lines.append(f"{len(paths) - len(shown)} more paths. See full artifact below.")
    return "\n".join(lines)


def artifact_link(url, label):
    if not url:
        return f"{label}: artifact URL unavailable."
    return f'<a href="{html.escape(url, quote=True)}">{label}</a>'


def routing_summary(paths, outputs, event, unknown_range):
    categories = set()
    for path in paths:
        if _is_skill_metadata(path):
            categories.add("Skill metadata")
        elif path == "renovate.json":
            categories.add("Renovate configuration")
        elif _requires_code_checks(path):
            categories.add("Code, build, or executable configuration")
        else:
            categories.add("Documentation or non-executable metadata")
    reason = (
        "Missing or invalid comparison range. Use conservative full checks."
        if unknown_range
        else f"Event: {text(event)}. Decisions use changed paths and event policy."
    )
    detected = ", ".join(sorted(categories)) or (
        "not determined" if unknown_range else "No changed paths"
    )
    lines = [
        "## CI routing",
        reason,
        f"Detected categories: {detected}",
        "",
        "| Category | Decision | Reason |",
        "| --- | --- | --- |",
    ]
    skip = "Skipped. Did not run"
    code = outputs["run_code_checks"] == "true"
    server = outputs["run_server_integration"] == "true"
    platforms = json.loads(outputs["platforms"])
    renovate = outputs["renovate_config_changes"] == "true"
    goldens = outputs["run_ui_goldens"] == "true"
    generated = outputs["run_generated_checks"] == "true"
    lines += [
        f'| Code checks | {"Scheduled" if code else skip} | {"Conservative or code-check policy applies" if code else "Only documentation, metadata, Renovate configuration, or no changed paths"} |',
        f'| Server integration | {"Scheduled" if server else skip} | {"Server integration policy applies" if server else "No server, engine, or shared integration inputs changed"} |',
        f'| Platform builds | {text(", ".join(platforms)) if platforms else skip} | {"Full event/range policy or platform build inputs" if platforms else "No platform build inputs changed"} |',
        f'| Renovate validation | {"Scheduled" if renovate else skip} | {"renovate.json changed" if renovate else "Comparison unavailable. Configuration changes not determined" if unknown_range else "renovate.json did not change"} |',
        f'| UI golden tests | {"Scheduled" if goldens else skip} | {"UI implementation, assets, or golden tests changed" if goldens else "No UI golden inputs changed"} |',
        f'| Generated artifact checks | {"Scheduled" if generated else skip} | {"Generator inputs or generated sources changed" if generated else "No generator inputs changed"} |',
        "",
        "Scheduled checks do not yet have results. Skipped validators did not validate anything.",
    ]
    return "\n".join(lines) + "\n"


def plan_summary(manifest, matrix, timing_source, artifact_url):
    mode = manifest["mode"]
    reason = manifest.get("reason", "")
    lines = [
        "## Test plan",
        f"Mode: {text(mode)}",
        f"Reason: {text(reason)}",
        f"Timing source: {text(timing_source)}",
    ]
    if mode == "full":
        intent = (
            "Intentional full run" if reason == "non-PR run" else "Selector fallback"
        )
        lines.append(f"{intent}. The full applicable test suite will run.")
    elif mode == "none":
        lines.append("No tests were scheduled.")
    else:
        for package, paths in manifest.get("packages", {}).items():
            lines += [f"### Package: <code>{text(package)}</code>", path_list(paths)]
    for row in matrix["include"]:
        lines.append(
            f'- Package: <code>{text(row["package"])}</code>. '
            f'Shard mode: {text(row["shardMode"])}. '
            f'Shard: {text(row["shardIndex"])}/{text(row["totalShards"])}.'
        )
    lines += ["", artifact_link(artifact_url, "Full test-plan artifact")]
    return "\n".join(lines) + "\n"


def replay_command(command):
    arguments = [
        arg for arg in command["arguments"] if not arg.startswith("--file-reporter=")
    ]
    return f'(cd {shlex.quote(command["package"])} && fvm {shlex.join([command["tool"], *arguments])})'


def shard_summary(manifest, row, timing_source, commands, failed, artifact_url):
    lines = [
        "## Test shard",
        f'Mode: {text(manifest["mode"])}',
        f'Reason: {text(manifest.get("reason", ""))}',
        f"Timing source: {text(timing_source)}",
        f'Package: <code>{text(row["package"])}</code>',
        f'Shard mode: {text(row["shardMode"])}. '
        f'Shard: {text(row["shardIndex"])}/{text(row["totalShards"])}.',
    ]
    paths = (
        row.get("paths", [])
        if row["shardMode"] == "timed"
        else manifest.get("packages", {}).get(row["package"], [])
    )
    if manifest["mode"] == "full" and row["shardMode"] != "timed":
        lines.append("The full applicable package test suite uses native sharding.")
    else:
        label = (
            "Timed shard paths:"
            if row["shardMode"] == "timed"
            else "Selected paths (native sharding divides this selection):"
        )
        lines += [label, path_list(paths)]
    if failed:
        lines += [
            "### Failed shard replay",
            "Run from repository root. Package directory appears in each command.",
            "Runner-only file reporter output is omitted.",
        ]
        for command in commands:
            replay = replay_command(command)
            lines.append("<pre>" + html.escape(replay[:12000]) + "</pre>")
            if len(replay) > 12000:
                lines.append(
                    "Command truncated. Copy full command from shard report artifact."
                )
    lines += ["", artifact_link(artifact_url, "Full shard report artifact")]
    return "\n".join(lines) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("kind", choices=["routing", "plan", "shard", "replay"])
    parser.add_argument("--outputs")
    parser.add_argument("--plan-dir")
    parser.add_argument("--report-dir")
    args = parser.parse_args()
    if args.kind == "replay":
        report_dir = Path(args.report_dir)
        commands = [
            json.loads(path.read_text())
            for path in sorted(report_dir.glob("command-*.json"))
        ]
        (report_dir / "local-replay.txt").write_text(
            "\n".join(replay_command(command) for command in commands) + "\n"
        )
        return
    if args.kind == "routing":
        outputs = dict(
            line.split("=", 1)
            for line in Path(args.outputs).read_text().splitlines()
            if "=" in line
        )
        summary = routing_summary(
            sys.stdin.read().splitlines(),
            outputs,
            os.environ["EVENT_NAME"],
            os.environ["UNKNOWN_RANGE"] == "true",
        )
    else:
        plan_dir = Path(args.plan_dir)
        manifest = json.loads((plan_dir / "changed-tests.json").read_text())
        timing_source = (plan_dir / "timing-source.txt").read_text().strip()
        if args.kind == "plan":
            summary = plan_summary(
                manifest,
                json.loads((plan_dir / "matrix.json").read_text()),
                timing_source,
                os.environ.get("ARTIFACT_URL", ""),
            )
        else:
            row = json.loads(os.environ["MATRIX_ROW"])
            report_dir = Path(args.report_dir)
            commands = [
                json.loads(path.read_text())
                for path in sorted(report_dir.glob("command-*.json"))
            ]
            summary = shard_summary(
                manifest,
                row,
                timing_source,
                commands,
                os.environ["TEST_OUTCOME"] == "failure",
                os.environ.get("ARTIFACT_URL", ""),
            )
            summary += (
                artifact_link(
                    os.environ.get("PLAN_ARTIFACT_URL", ""), "Full test-plan artifact"
                )
                + "\n"
            )
    with open(os.environ["GITHUB_STEP_SUMMARY"], "a") as output:
        output.write(summary)


if __name__ == "__main__":
    main()

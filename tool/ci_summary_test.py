import unittest
import html
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import tempfile

import ci_summary


class CiSummaryTest(unittest.TestCase):
    def test_routing_explains_metadata_skips_without_validation_success(self):
        summary = ci_summary.routing_summary(
            [".agents/skills/example/evals/evals.json", "README.md"],
            {
                "platforms": "[]",
                "run_code_checks": "false",
                "run_server_integration": "false",
                "renovate_config_changes": "false",
                "run_ui_goldens": "false",
                "run_generated_checks": "false",
            },
            "pull_request",
            False,
        )
        self.assertIn("Skill metadata", summary)
        self.assertIn("Documentation", summary)
        self.assertIn("Skipped. Did not run", summary)
        self.assertIn("renovate.json did not change", summary)
        self.assertIn("No UI golden inputs changed", summary)
        self.assertIn("No generator inputs changed", summary)
        self.assertNotIn("passed", summary)

    def test_unknown_range_explains_conservative_checks(self):
        summary = ci_summary.routing_summary(
            [],
            {
                "platforms": '["android","ios"]',
                "run_code_checks": "true",
                "run_server_integration": "true",
                "renovate_config_changes": "false",
                "run_ui_goldens": "true",
                "run_generated_checks": "true",
            },
            "push",
            True,
        )
        self.assertIn("Missing or invalid comparison range", summary)
        self.assertIn("conservative full checks", summary)
        self.assertIn("not determined", summary)

    def test_affected_lists_packages_paths_and_native_shards(self):
        summary = ci_summary.plan_summary(
            {
                "mode": "affected",
                "reason": "reverse import impact",
                "packages": {
                    "apps/app": ["test/a_test.dart"],
                    "packages/core": ["test/b_test.dart"],
                },
            },
            {
                "include": [
                    {
                        "package": "apps/app",
                        "shardMode": "native",
                        "shardIndex": 0,
                        "totalShards": 3,
                    }
                ]
            },
            "fixed shard fallback",
            "https://example.test/plan",
        )
        for text in [
            "apps/app",
            "test/a_test.dart",
            "packages/core",
            "test/b_test.dart",
            "native",
            "fixed shard fallback",
            "https://example.test/plan",
        ]:
            self.assertIn(text, html.unescape(summary))

    def test_full_and_none_explain_intent_and_fallback(self):
        for mode, reason, expected in [
            ("full", "non-PR run", "Intentional full run"),
            ("full", "selector failed", "Selector fallback"),
            ("full", "Global input changed: pubspec.yaml", "Selector fallback"),
            ("none", "No executable test input.", "No tests were scheduled"),
        ]:
            with self.subTest(mode=mode, reason=reason):
                summary = ci_summary.plan_summary(
                    {"mode": mode, "reason": reason, "packages": {}},
                    {"include": []},
                    "fixed shard fallback",
                    "",
                )
                self.assertIn(expected, summary)
                self.assertIn(reason, summary)
                if mode == "full":
                    self.assertIn("full applicable test suite", summary)

    def test_paths_are_bounded_and_html_escaped(self):
        paths = ["test/<script>`evil</script>_test.dart"] + [
            f"test/{i}_test.dart" for i in range(60)
        ]
        summary = ci_summary.plan_summary(
            {"mode": "affected", "reason": "<unsafe>", "packages": {"app": paths}},
            {"include": []},
            "fixed",
            "https://example.test/full",
        )
        self.assertNotIn("<script>", summary)
        self.assertIn("&lt;script&gt;", summary)
        self.assertIn("more paths", summary)
        self.assertIn("https://example.test/full", summary)
        self.assertNotIn("test/59_test.dart", summary)

    def test_replay_preserves_exact_arguments_and_quotes_paths(self):
        for arguments in [
            [
                "test",
                "--coverage",
                "--total-shards=3",
                "--shard-index=1",
                "test/a_test.dart",
            ],
            ["test", "--coverage", "test/a test.dart", "test/quote's_test.dart"],
        ]:
            with self.subTest(arguments=arguments):
                command = ci_summary.replay_command(
                    {
                        "package": "apps/app",
                        "tool": "flutter",
                        "arguments": arguments
                        + ["--file-reporter=json:/runner/temp/report.json"],
                    }
                )
                self.assertTrue(command.startswith("(cd apps/app && fvm flutter test "))
                self.assertNotIn("/runner", command)
                self.assertEqual(shlex.split(command[1:-1])[5:], arguments)

    def test_failed_native_and_timed_shards_show_exact_replay(self):
        for mode in ["fixed", "timed"]:
            with self.subTest(mode=mode):
                args = ["test", "--coverage", "test/a_test.dart"]
                if mode == "fixed":
                    args += ["--total-shards=3", "--shard-index=1"]
                command = {"package": "app", "tool": "flutter", "arguments": args}
                summary = ci_summary.shard_summary(
                    {
                        "mode": "affected",
                        "reason": "reverse import impact",
                        "packages": {"app": ["test/a_test.dart"]},
                    },
                    {
                        "package": "app",
                        "shardMode": mode,
                        "shardIndex": 1,
                        "totalShards": 3,
                        "paths": ["test/a_test.dart"],
                    },
                    "main run 123",
                    [command],
                    True,
                    "https://example.test/report",
                )
                self.assertIn(
                    ci_summary.replay_command(command), html.unescape(summary)
                )
                self.assertIn("Failed shard replay", summary)
                self.assertIn("main run 123", summary)
                self.assertIn("https://example.test/report", summary)

    def test_replay_cli_writes_complete_command_without_summary_environment(self):
        with tempfile.TemporaryDirectory() as directory:
            report = Path(directory)
            command = {
                "package": "packages/core",
                "tool": "dart",
                "arguments": ["test", "--coverage=coverage", "test/a_test.dart"],
            }
            (report / "command-core.json").write_text(json.dumps(command))
            subprocess.run(
                [
                    "python3",
                    str(Path(ci_summary.__file__)),
                    "replay",
                    "--report-dir",
                    directory,
                ],
                check=True,
            )
            self.assertEqual(
                (report / "local-replay.txt").read_text(),
                ci_summary.replay_command(command) + "\n",
            )

    def test_routing_cli_accepts_large_path_lists_without_environment_transport(self):
        root = Path(__file__).resolve().parent.parent
        workflow = (root / ".github/workflows/ci.yml").read_text()
        self.assertNotIn('ROUTING_PATHS="$changed_files"', workflow)
        paths = "\n".join(f"docs/{i:04d}_{'a' * 100}.md" for i in range(1500))
        self.assertGreater(len(paths), 128 * 1024)
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "outputs"
            output.write_text(
                "platforms=[]\nrun_code_checks=false\n"
                "run_server_integration=false\nrenovate_config_changes=false\n"
                "run_ui_goldens=false\nrun_generated_checks=false\n"
            )
            summary = Path(directory) / "summary"
            subprocess.run(
                [
                    "python3",
                    str(Path(ci_summary.__file__)),
                    "routing",
                    "--outputs",
                    str(output),
                ],
                input=paths,
                text=True,
                env=dict(
                    os.environ,
                    EVENT_NAME="pull_request",
                    UNKNOWN_RANGE="false",
                    GITHUB_STEP_SUMMARY=str(summary),
                ),
                check=True,
            )
            self.assertIn("Documentation", summary.read_text())
            self.assertIn("Skipped. Did not run", summary.read_text())

    def test_workflow_routing_outputs_classify_optional_checks(self):
        root = Path(__file__).resolve().parent.parent
        workflow = (root / ".github/workflows/ci.yml").read_text()
        block = workflow.split("      - name: Determine changed platforms\n", 1)[1]
        script = block.split("        run: |\n", 1)[1].split(
            "\n  renovate-validation:", 1
        )[0]
        script = "\n".join(line[10:] for line in script.splitlines())
        all_platforms = '["android","ios","macos","linux","windows","web"]'
        cases = [
            ("README.md", "pull_request", False, "[]", "false", "false", "false"),
            (
                ".agents/skills/a/evals/evals.json",
                "pull_request",
                False,
                "[]",
                "false",
                "false",
                "false",
            ),
            ("renovate.json", "pull_request", False, "[]", "false", "false", "true"),
            (
                "apps/auravibes_app/test/a_test.dart",
                "pull_request",
                False,
                "[]",
                "true",
                "false",
                "false",
            ),
            (
                "apps/auravibes_app/test/widgets/responsive_shell_test.dart",
                "pull_request",
                False,
                "[]",
                "true",
                "false",
                "false",
            ),
            (
                "apps/auravibes_app/lib/features/models/generated_input.dart",
                "pull_request",
                False,
                all_platforms,
                "true",
                "false",
                "false",
            ),
            (
                "apps/auravibes_app/ios/Runner/a",
                "pull_request",
                False,
                '["ios"]',
                "true",
                "false",
                "false",
            ),
            (
                "pubspec.yaml",
                "pull_request",
                False,
                all_platforms,
                "true",
                "true",
                "false",
            ),
            ("README.md", "push", True, all_platforms, "true", "true", "false"),
            (
                "README.md",
                "merge_group",
                False,
                all_platforms,
                "true",
                "false",
                "false",
            ),
            (
                "renovate.json",
                "workflow_dispatch",
                False,
                all_platforms,
                "true",
                "true",
                "true",
            ),
            (
                "README.md",
                "workflow_dispatch",
                False,
                all_platforms,
                "true",
                "true",
                "false",
            ),
            (
                "renovate.json",
                "workflow_dispatch",
                True,
                all_platforms,
                "true",
                "true",
                "false",
            ),
        ]
        with tempfile.TemporaryDirectory() as directory:
            repo = Path(directory)
            (repo / "tool").mkdir()
            for name in ["ci_summary.py", "classify_ci_changes.py"]:
                shutil.copy(root / "tool" / name, repo / "tool" / name)

            def git(*args):
                return subprocess.check_output(
                    ["git", *args], cwd=repo, text=True
                ).strip()

            git("init", "-q")
            git("config", "user.name", "CI summary test")
            git("config", "user.email", "ci-summary@example.test")
            git("commit", "-qm", "base", "--allow-empty")
            base = git("rev-parse", "HEAD")
            git("update-ref", "refs/remotes/origin/main", base)
            generated_source = "apps/auravibes_app/lib/features/models/generated_input.dart"
            golden_source = "apps/auravibes_app/test/widgets/responsive_shell_test.dart"
            for path, event, unknown, platforms, code, server, renovate in cases:
                with self.subTest(path=path, event=event, unknown=unknown):
                    if event == "workflow_dispatch":
                        if unknown:
                            git("update-ref", "-d", "refs/remotes/origin/main")
                        else:
                            git("update-ref", "refs/remotes/origin/main", base)
                    git("reset", "--soft", base)
                    git("read-tree", base)
                    changed = repo / path
                    changed.parent.mkdir(parents=True, exist_ok=True)
                    changed.write_text(
                        "part 'generated_input.g.dart';\n"
                        if path == generated_source
                        else "changed\n"
                    )
                    git("add", path)
                    git("commit", "-qm", "changed")
                    head = git("rev-parse", "HEAD")
                    comparison = "0" * 40 if unknown else base
                    payload = {
                        "before": comparison,
                        "pull_request": {
                            "base": {"sha": comparison},
                            "head": {"sha": head},
                        },
                        "merge_group": {"base_sha": comparison, "head_sha": head},
                    }
                    event_file = repo / "event.json"
                    event_file.write_text(json.dumps(payload))
                    output = repo / "outputs"
                    output.write_text("")
                    summary = repo / "summary"
                    summary.write_text("")
                    env = dict(
                        os.environ,
                        EVENT_NAME=event,
                        EVENT_PATH=str(event_file),
                        GITHUB_SHA=head,
                        GITHUB_OUTPUT=str(output),
                        GITHUB_STEP_SUMMARY=str(summary),
                    )
                    subprocess.run(
                        ["bash", "-c", script], cwd=repo, env=env, check=True
                    )
                    self.assertEqual(
                        dict(
                            line.split("=", 1)
                            for line in output.read_text().splitlines()
                        ),
                        {
                            "platforms": platforms,
                            "run_code_checks": code,
                            "run_server_integration": server,
                            "renovate_config_changes": renovate,
                            "run_ui_goldens": str(
                                unknown
                                or event in {"merge_group", "workflow_dispatch"}
                                or path == golden_source
                            ).lower(),
                            "run_generated_checks": str(
                                unknown
                                or event in {"merge_group", "workflow_dispatch"}
                                or path in {"pubspec.yaml", generated_source}
                            ).lower(),
                        },
                    )
                    routing = summary.read_text()
                    self.assertIn("CI routing", routing)
                    if event == "workflow_dispatch" and unknown:
                        self.assertIn(
                            "Comparison unavailable. Configuration changes not determined",
                            routing,
                        )
                        self.assertIn("Skipped. Did not run", routing)
                        self.assertNotIn("| Renovate validation | Scheduled", routing)
                    elif event == "workflow_dispatch":
                        self.assertNotIn(
                            "Comparison unavailable. Configuration changes not determined",
                            routing,
                        )


if __name__ == "__main__":
    unittest.main()

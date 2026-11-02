import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
import zipfile


ROOT = Path(__file__).resolve().parent.parent

# Exercise the real Bash orchestration, jq filters, and zip handling. Dart owns
# timing schema validation; this stand-in controls its acceptance result.
FAKE_TOOL = r'''#!/usr/bin/env python3
import json
import os
from pathlib import Path
import subprocess
import sys

fixture = Path(os.environ["PLAN_FIXTURE"])
state = json.loads((fixture / "state.json").read_text())
args = sys.argv[1:]
with (fixture / "calls.jsonl").open("a") as calls:
    calls.write(json.dumps([Path(sys.argv[0]).name, *args]) + "\n")

def emit(value):
    query = args[args.index("--jq") + 1]
    subprocess.run(["jq", "-r", query], input=json.dumps(value), text=True, check=True)

if Path(sys.argv[0]).name == "dart":
    if state.get("planner_failure"):
        sys.exit(1)
    manifest = json.loads(Path(args[args.index("--manifest") + 1]).read_text())
    packages = manifest.get("packages", {})
    if manifest.get("mode") == "full":
        packages = {
            "apps/auravibes_app": ["test/app_test.dart"],
            "packages/auravibes_engine": ["test/engine_test.dart"],
        }
    rows = []
    for package in packages:
        if package == "apps/auravibes_app":
            rows.extend(
                {
                    "package": package,
                    "shardMode": "fixed",
                    "shardIndex": index,
                }
                for index in range(3)
            )
        else:
            rows.append({"package": package, "shardMode": "fixed"})
    matrix = {"include": rows}
    if "--timings" in args:
        path = Path(args[args.index("--timings") + 1])
        try:
            timing = json.loads(path.read_text())
        except ValueError:
            timing = {}
        if timing.get("planner_failure"):
            sys.exit(1)
        if timing.get("usable"):
            for row in matrix["include"]:
                if row["package"] == "apps/auravibes_app":
                    row["shardMode"] = "timed"
        else:
            print("changed-test-selector: ignoring stale timing database", file=sys.stderr)
    print(json.dumps(matrix))
elif "/actions/artifacts?" in args[1]:
    if state.get("listing_failure"):
        sys.exit(1)
    artifacts = []
    for index, run in enumerate(state["runs"]):
        if run.get("missing"):
            continue
        artifacts.append(
            {
                "id": run["id"],
                "expired": run.get("expired", False),
                "created_at": run.get(
                    "created_at",
                    f"2026-01-01T00:00:{len(state['runs']) - index:02d}Z",
                ),
                "workflow_run": {
                    "id": run["id"],
                    "head_branch": run.get("branch", "main"),
                },
            }
        )
    emit({"artifacts": artifacts})
else:
    artifact_id = int(args[1].split("/artifacts/")[1].split("/")[0])
    run = next(run for run in state["runs"] if run["id"] == artifact_id)
    if run.get("download_failure"):
        sys.exit(1)
    sys.stdout.buffer.write((fixture / f"{artifact_id}.zip").read_bytes())
'''


class PlanTestShardsTest(unittest.TestCase):
    def run_plan(self, runs, *, app=True, full=False, **options):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        fixture = Path(directory.name)
        binary = fixture / "bin"
        binary.mkdir()
        for name in ("dart", "gh"):
            executable = binary / name
            executable.write_text(FAKE_TOOL)
            executable.chmod(0o755)
        (fixture / "state.json").write_text(json.dumps({"runs": runs, **options}))
        for run in runs:
            archive = fixture / f"{run['id']}.zip"
            if run.get("corrupt_zip"):
                archive.write_text("not a zip")
            else:
                with zipfile.ZipFile(archive, "w") as output:
                    output.writestr(
                        run.get("filename", "test_timings.json"),
                        run.get("contents", '{"usable": true}'),
                    )
        if full:
            manifest_value = {"mode": "full", "reason": "fixture"}
        else:
            packages = {"packages/auravibes_engine": ["test/engine_test.dart"]}
            if app:
                packages["apps/auravibes_app"] = ["test/app_test.dart"]
            manifest_value = {
                "mode": "affected",
                "reason": "fixture",
                "packages": packages,
            }
        manifest = fixture / "manifest.json"
        manifest.write_text(json.dumps(manifest_value))
        plan = fixture / "plan"
        result = subprocess.run(
            ["bash", str(ROOT / "tool/plan_test_shards.sh"), str(manifest), str(plan)],
            cwd=ROOT,
            env=dict(os.environ, PATH=f"{binary}:{os.environ['PATH']}",
                     GITHUB_REPOSITORY="auravibes-apps/auravibes", PLAN_FIXTURE=str(fixture)),
            capture_output=True,
            text=True,
        )
        return result, plan, fixture

    def test_tries_older_artifact_when_newest_is_rejected(self):
        result, plan, fixture = self.run_plan([
            {"id": 2, "contents": '{"usable": false}'},
            {"id": 1, "conclusion": "failure"},
        ])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((plan / "timing-source.txt").read_text().strip(), "main run 1")
        self.assertIn("planner rejected timings", (plan / "timing-lookup.txt").read_text())
        self.assertIn("ignoring stale timing database", (plan / "timing-lookup.txt").read_text())
        matrix = json.loads((plan / "matrix.json").read_text())
        self.assertEqual(len(matrix["include"]), 4)
        self.assertEqual(matrix["include"][0]["shardMode"], "fixed")
        self.assertTrue(all(row["shardMode"] == "timed" for row in matrix["include"][1:]))
        calls = [json.loads(line) for line in (fixture / "calls.jsonl").read_text().splitlines()]
        listing = next(
            call
            for call in calls
            if call[0:2] == ["gh", "api"] and "/actions/artifacts?" in call[2]
        )
        self.assertIn("name=test-timings", listing[2])
        self.assertIn("per_page=100", listing[2])
        metrics = (plan / "timing-lookup.txt").read_text().splitlines()[-1]
        self.assertRegex(
            metrics,
            r"Lookup metrics: duration_ms=\d+ main_runs_examined=2 "
            r"artifact_list_requests=1 artifact_download_requests=2$",
        )

    def test_accepts_newest_main_artifact_without_downloading_older_runs(self):
        result, plan, fixture = self.run_plan([
            {"id": 1, "created_at": "2026-01-01T00:00:01Z"},
            {"id": 2, "created_at": "2026-01-01T00:00:02Z"},
            {
                "id": 3,
                "branch": "feature/other",
                "created_at": "2026-01-01T00:00:03Z",
            },
        ])
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((plan / "timing-source.txt").read_text().strip(), "main run 2")
        calls = [
            json.loads(line)
            for line in (fixture / "calls.jsonl").read_text().splitlines()
        ]
        downloads = [
            call[2]
            for call in calls
            if call[0:2] == ["gh", "api"] and "/zip" in call[2]
        ]
        self.assertEqual(
            downloads,
            ["repos/auravibes-apps/auravibes/actions/artifacts/2/zip"],
        )
        selector_runs = [
            call
            for call in calls
            if call[0] == "dart" and "matrix" in call
        ]
        self.assertEqual(len(selector_runs), 1)
        metrics = (plan / "timing-lookup.txt").read_text().splitlines()[-1]
        self.assertRegex(
            metrics,
            r"Lookup metrics: duration_ms=\d+ main_runs_examined=1 "
            r"artifact_list_requests=1 artifact_download_requests=1$",
        )

    def test_full_selection_still_uses_timing_artifact(self):
        result, plan, fixture = self.run_plan([{"id": 1}], full=True)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((plan / "timing-source.txt").read_text().strip(), "main run 1")
        calls = [
            json.loads(line)
            for line in (fixture / "calls.jsonl").read_text().splitlines()
        ]
        selector_runs = [
            call
            for call in calls
            if call[0] == "dart" and "matrix" in call
        ]
        self.assertEqual(len(selector_runs), 1)

    def test_download_and_validation_failures_continue_to_older_runs(self):
        cases = [
            ({"download_failure": True}, "download failed"),
            ({"corrupt_zip": True}, "missing or unreadable"),
            ({"filename": "wrong.json"}, "missing or unreadable"),
            ({"contents": ""}, "missing or unreadable"),
            ({"contents": "invalid json"}, "planner rejected timings"),
            ({"contents": '{"planner_failure": true}'}, "shard planner failed"),
        ]
        for failure, message in cases:
            with self.subTest(failure=failure):
                result, plan, _ = self.run_plan([{"id": 2, **failure}, {"id": 1}])
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual((plan / "timing-source.txt").read_text().strip(), "main run 1")
                self.assertIn(message, (plan / "timing-lookup.txt").read_text())

    def test_lookup_outage_preserves_full_fixed_matrix(self):
        for runs, options in [
            ([], {"listing_failure": True}),
            ([{"id": 1, "missing": True}], {}),
            ([{"id": 1, "expired": True}], {}),
        ]:
            with self.subTest(options=options):
                result, plan, fixture = self.run_plan(runs, **options)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual((plan / "timing-source.txt").read_text().strip(), "fixed shard fallback")
                rows = json.loads((plan / "matrix.json").read_text())["include"]
                self.assertEqual(len(rows), 4)
                self.assertTrue(all(row["shardMode"] == "fixed" for row in rows))
                self.assertIn("::warning::", (plan / "timing-lookup.txt").read_text())
                calls = [
                    json.loads(line)
                    for line in (fixture / "calls.jsonl").read_text().splitlines()
                ]
                selector_runs = [
                    call
                    for call in calls
                    if call[0] == "dart" and "matrix" in call
                ]
                self.assertEqual(len(selector_runs), 1)
                self.assertRegex(
                    (plan / "timing-lookup.txt").read_text().splitlines()[-1],
                    r"Lookup metrics: duration_ms=\d+ main_runs_examined=0 "
                    r"artifact_list_requests=1 artifact_download_requests=0$",
                )

    def test_skips_network_when_no_app_tests_selected(self):
        result, plan, fixture = self.run_plan([], app=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("not needed", (plan / "timing-source.txt").read_text())
        self.assertNotIn('"gh"', (fixture / "calls.jsonl").read_text())
        self.assertIn(
            "Lookup metrics: duration_ms=0 main_runs_examined=0 "
            "artifact_list_requests=0 artifact_download_requests=0",
            (plan / "timing-lookup.txt").read_text(),
        )

    def test_initial_planner_failure_does_not_publish_matrix(self):
        result, plan, _ = self.run_plan([], planner_failure=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((plan / "matrix.json").exists())


if __name__ == "__main__":
    unittest.main()

"""Behavior checks for the Melos setup skill's offline evaluation runner."""

import json
from pathlib import Path
import tempfile
import unittest

from run_melos_skill_evals import evaluate_skill_evals


class MelosSkillEvalTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self._write_repository_facts()

    def test_reports_pass_per_behavior_scenario_with_equivalent_expected_output(self):
        cases_path = self.root / ".agents/skills/melos-7/evals/evals.json"
        cases = json.loads(cases_path.read_text())
        cases["evals"][0]["expected_output"] = (
            "Formatting is permitted. Apply it with `fvm dart format`; the pinned "
            "check is `fvm dart run melos run format:check`."
        )
        cases["evals"][1]["expected_output"] = (
            "This repo's `.fvmrc` makes Pub resolution run when FVM switches SDKs. "
            "`--skip-pub-get` bypasses that resolution."
        )
        cases["evals"][2]["expected_output"] = (
            "CI still uses bootstrap. A Pub workspace alone cannot replace Melos "
            "bootstrap. Run `fvm use`, then "
            "`fvm dart run melos bootstrap`."
        )
        cases_path.write_text(json.dumps(cases))

        results = evaluate_skill_evals(self.root)

        self.assertEqual(
            [(result.case_id, result.passed) for result in results],
            [(1, True), (2, True), (3, True)],
        )

    def test_rejects_expected_output_that_contradicts_repository_behavior(self):
        cases_path = self.root / ".agents/skills/melos-7/evals/evals.json"
        cases = json.loads(cases_path.read_text())
        cases["evals"][0]["expected_output"] = (
            "Never format source files; run the format check only."
        )
        cases["evals"][1]["expected_output"] = (
            "FVM runs Pub resolution by default when switching SDKs, but this "
            "repository's `.fvmrc` does not enable Pub resolution. "
            "`--skip-pub-get` skips that resolution."
        )
        cases["evals"][2]["expected_output"] = (
            "CI still runs Melos bootstrap. Pub workspace membership does not "
            "replace Melos bootstrap, but bootstrap is redundant. Run `fvm use`, "
            "then `fvm dart run melos bootstrap`."
        )
        cases_path.write_text(json.dumps(cases))

        results = evaluate_skill_evals(self.root)

        self.assertEqual(
            [(result.case_id, result.passed) for result in results],
            [(1, False), (2, False), (3, False)],
        )

    def test_requires_expected_output_to_distinguish_workspace_from_bootstrap(self):
        cases_path = self.root / ".agents/skills/melos-7/evals/evals.json"
        cases = json.loads(cases_path.read_text())
        cases["evals"][2]["expected_output"] = (
            "CI still runs Melos bootstrap, which remains required. Run `fvm use`, "
            "then `fvm dart run melos bootstrap`."
        )
        cases_path.write_text(json.dumps(cases))

        results = evaluate_skill_evals(self.root)

        self.assertTrue(results[0].passed)
        self.assertTrue(results[1].passed)
        self.assertFalse(results[2].passed)

    def test_requires_expected_output_for_behavior_scenarios(self):
        cases_path = self.root / ".agents/skills/melos-7/evals/evals.json"
        cases = json.loads(cases_path.read_text())
        del cases["evals"][1]["expected_output"]
        cases_path.write_text(json.dumps(cases))

        results = evaluate_skill_evals(self.root)

        self.assertTrue(results[0].passed)
        self.assertFalse(results[1].passed)
        self.assertIn("expected_output", " ".join(results[1].failures))
        self.assertTrue(results[2].passed)

    def test_reports_each_scenario_failure_with_its_missing_behavior(self):
        config_path = self.root / ".fvmrc"
        config = json.loads(config_path.read_text())
        config["runPubGetOnSdkChanges"] = False
        config_path.write_text(json.dumps(config))

        pubspec_path = self.root / "pubspec.yaml"
        pubspec_path.write_text(
            pubspec_path.read_text().replace("--set-exit-if-changed", "")
        )

        action_path = self.root / ".github/actions/setup-workspace/action.yml"
        action_path.write_text(action_path.read_text().replace("true", "false"))

        results = evaluate_skill_evals(self.root)

        self.assertEqual([result.case_id for result in results], [1, 2, 3])
        self.assertTrue(all(not result.passed for result in results))
        self.assertIn("format:check", " ".join(results[0].failures).lower())
        self.assertIn("pub resolution", " ".join(results[1].failures).lower())
        self.assertIn("bootstrap", " ".join(results[2].failures).lower())

    def test_rejects_guidance_that_contradicts_behavior_scenarios(self):
        skill_path = self.root / ".agents/skills/melos-7/SKILL.md"
        skill = skill_path.read_text()
        skill = skill.replace(
            "Formatting changes are allowed",
            "Do not run formatting commands",
        )
        skill = skill.replace(
            "Pub workspace membership does not replace that step.",
            "Pub workspace membership makes Melos bootstrap redundant.",
        )
        skill = skill.replace(
            "The repository's `.fvmrc` enables Pub resolution by default when FVM changes SDKs.",
            "FVM does not run Pub resolution by default when switching SDKs.",
        )
        skill_path.write_text(skill)

        results = evaluate_skill_evals(self.root)

        self.assertFalse(results[0].passed)
        self.assertFalse(results[1].passed)
        self.assertFalse(results[2].passed)

    def test_requires_every_behavior_scenario_to_run(self):
        cases_path = self.root / ".agents/skills/melos-7/evals/evals.json"
        cases = json.loads(cases_path.read_text())
        cases["evals"][2]["checks"] = []
        cases_path.write_text(json.dumps(cases))

        with self.assertRaisesRegex(ValueError, "all behavior checks"):
            evaluate_skill_evals(self.root)

    def test_accepts_equivalent_setup_guidance_wording(self):
        skill_path = self.root / ".agents/skills/melos-7/SKILL.md"
        skill = skill_path.read_text()
        skill = skill.replace(
            "Formatting changes are allowed",
            "Contributors may format source files",
        )
        skill = skill.replace(
            "Pub workspace membership does not replace that step.",
            "A Pub workspace alone is not a substitute for Melos bootstrap.",
        )
        skill = skill.replace(
            "The repository's `.fvmrc` enables Pub resolution by default when FVM changes SDKs.",
            "When FVM switches SDKs, Pub resolution runs by default; the repository's `.fvmrc` enables Pub resolution by default.",
        )
        skill_path.write_text(skill)

        results = evaluate_skill_evals(self.root)

        self.assertEqual(
            [(result.case_id, result.passed) for result in results],
            [(1, True), (2, True), (3, True)],
        )

    def _write_repository_facts(self):
        self._write(
            ".agents/skills/melos-7/evals/evals.json",
            json.dumps(
                {
                    "skill_name": "melos-7",
                    "evals": [
                        {
                            "id": 1,
                            "prompt": "How do I check formatting?",
                            "expected_output": (
                                "Formatting changes are allowed. Use `fvm dart run "
                                "melos run format:check`."
                            ),
                            "files": [],
                            "checks": ["formatting"],
                        },
                        {
                            "id": 2,
                            "prompt": "What does FVM do with Pub?",
                            "expected_output": (
                                "This repo's `.fvmrc` enables Pub resolution by "
                                "default when FVM switches SDKs. "
                                "`--skip-pub-get` skips that resolution."
                            ),
                            "files": [],
                            "checks": ["fvm_pub_resolution"],
                        },
                        {
                            "id": 3,
                            "prompt": "Is Melos bootstrap still needed?",
                            "expected_output": (
                                "CI still runs Melos bootstrap. Pub workspace "
                                "membership does not replace Melos bootstrap. Run `fvm "
                                "use`, then `fvm dart run melos bootstrap`."
                            ),
                            "files": [],
                            "checks": ["melos_bootstrap"],
                        },
                        {
                            "id": 4,
                            "prompt": "A separate task scenario.",
                            "expected_output": "This scenario is not in the setup suite.",
                            "files": [],
                        },
                    ],
                }
            ),
        )
        self._write(
            ".fvmrc",
            json.dumps({"flutter": "3.47.7", "runPubGetOnSdkChanges": True}),
        )
        self._write(
            "pubspec.yaml",
            """dev_dependencies:
  melos: ^8.7.0
workspace:
  - apps/app
melos:
  scripts:
    format:check:
      run: dart run tool/run_quiet.dart -- dart format -o none --set-exit-if-changed .
""",
        )
        self._write(
            "AGENTS.md",
            "Run `fvm dart run melos run format:check` for the formatting gate.\n"
            "Apply formatting with `fvm dart format <paths>`.\n"
            "Run `python3 tool/validation_lease.py -- fvm dart run melos bootstrap` from root.\n",
        )
        self._write(
            ".agents/skills/melos-7/SKILL.md",
            "The repository's `.fvmrc` enables Pub resolution by default when FVM changes SDKs.\n"
            "Use `--skip-pub-get` to skip that resolution.\n"
            "Pub workspace membership does not replace that step.\n"
            "Run `fvm dart run melos bootstrap` from the root.\n"
            "Formatting changes are allowed; apply them with `fvm dart format <paths>`.\n",
        )
        self._write(
            ".github/workflows/ci.yml",
            "- uses: ./.github/actions/setup-workspace\n"
            "  run: fvm dart run melos run format:check\n",
        )
        self._write(
            ".github/actions/setup-workspace/action.yml",
            "- name: Bootstrap workspace\n"
            "  uses: bluefireteam/melos-action@0123456789abcdef0123456789abcdef01234567\n"
            "  with:\n"
            "    run-bootstrap: true\n",
        )

    def _write(self, path, content):
        destination = self.root / path
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(content)


if __name__ == "__main__":
    unittest.main()

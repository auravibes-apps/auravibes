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

    def test_reports_pass_per_behavior_scenario_without_matching_prose(self):
        cases_path = self.root / ".agents/skills/melos-7/evals/evals.json"
        cases = json.loads(cases_path.read_text())
        for case in cases["evals"][:3]:
            case["expected_output"] = "A different explanation with the same intent."
        cases_path.write_text(json.dumps(cases))

        results = evaluate_skill_evals(self.root)

        self.assertEqual(
            [(result.case_id, result.passed) for result in results],
            [(1, True), (2, True), (3, True)],
        )

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
                            "expected_output": "A behavior-based format outcome.",
                            "files": [],
                            "checks": ["formatting"],
                        },
                        {
                            "id": 2,
                            "prompt": "What does FVM do with Pub?",
                            "expected_output": "A behavior-based FVM outcome.",
                            "files": [],
                            "checks": ["fvm_pub_resolution"],
                        },
                        {
                            "id": 3,
                            "prompt": "Is Melos bootstrap still needed?",
                            "expected_output": "A behavior-based bootstrap outcome.",
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
            "Pub workspace membership does not replace Melos bootstrap.\n"
            "Run `fvm dart run melos bootstrap` from the root.\n",
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

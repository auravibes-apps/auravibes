import unittest

from classify_ci_changes import classify_paths


class ClassifyCiChangesTest(unittest.TestCase):
    def test_skill_metadata_alone_skips_dart_checks(self):
        result = classify_paths(
            [
                ".agents/skills/example/SKILL.md",
                ".agents/skills/example/evals/evals.json",
                ".agents/skills/example/references/usage.md",
            ]
        )

        self.assertEqual(
            result,
            {"run_code_checks": False, "renovate_config_changes": False},
        )

    def test_skill_scripts_and_non_eval_json_keep_code_checks(self):
        for path in (
            ".agents/skills/example/scripts/validate.py",
            ".agents/skills/example/evals/runner.json",
        ):
            with self.subTest(path=path):
                result = classify_paths([path])
                self.assertTrue(result["run_code_checks"])

    def test_renovate_config_alone_skips_dart_checks_and_requests_validation(self):
        result = classify_paths(["renovate.json"])

        self.assertEqual(
            result,
            {"run_code_checks": False, "renovate_config_changes": True},
        )

    def test_code_changes_keep_existing_checks_with_metadata(self):
        result = classify_paths(
            [".agents/skills/example/evals/evals.json", "packages/core/lib/core.dart"]
        )

        self.assertEqual(
            result,
            {"run_code_checks": True, "renovate_config_changes": False},
        )

    def test_renovate_validation_runs_with_code_changes_too(self):
        result = classify_paths(["renovate.json", "apps/auravibes_app/lib/main.dart"])

        self.assertEqual(
            result,
            {"run_code_checks": True, "renovate_config_changes": True},
        )

    def test_source_dependency_toolchain_and_workflow_changes_keep_checks(self):
        for path in (
            "apps/auravibes_app/lib/main.dart",
            "packages/core/pubspec.lock",
            ".fvmrc",
            ".github/actions/setup-workspace/action.yml",
            ".github/workflows/ci.yml",
        ):
            with self.subTest(path=path):
                result = classify_paths([path])
                self.assertTrue(result["run_code_checks"])

    def test_documentation_only_changes_still_skip_dart_checks(self):
        result = classify_paths(["README.md", "docs/testing/ci.md"])

        self.assertFalse(result["run_code_checks"])


if __name__ == "__main__":
    unittest.main()

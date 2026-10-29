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
            {
                "run_code_checks": False,
                "run_server_integration": False,
                "run_ci_tool_checks": False,
                "run_ci_selector_checks": False,
                "renovate_config_changes": False,
                "run_ui_goldens": False,
                "run_generated_checks": False,
                "run_dependency_preflight": False,
            },
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
            {
                "run_code_checks": False,
                "run_server_integration": False,
                "run_ci_tool_checks": False,
                "run_ci_selector_checks": False,
                "renovate_config_changes": True,
                "run_ui_goldens": False,
                "run_generated_checks": False,
                "run_dependency_preflight": False,
            },
        )

    def test_code_changes_keep_existing_checks_with_metadata(self):
        result = classify_paths(
            [".agents/skills/example/evals/evals.json", "packages/core/lib/core.dart"]
        )

        self.assertEqual(
            result,
            {
                "run_code_checks": True,
                "run_server_integration": False,
                "run_ci_tool_checks": False,
                "run_ci_selector_checks": False,
                "renovate_config_changes": False,
                "run_ui_goldens": False,
                "run_generated_checks": False,
                "run_dependency_preflight": False,
            },
        )

    def test_renovate_validation_runs_with_code_changes_too(self):
        result = classify_paths(["renovate.json", "apps/auravibes_app/lib/main.dart"])

        self.assertEqual(
            result,
            {
                "run_code_checks": True,
                "run_server_integration": False,
                "run_ci_tool_checks": False,
                "run_ci_selector_checks": False,
                "renovate_config_changes": True,
                "run_ui_goldens": True,
                "run_generated_checks": False,
                "run_dependency_preflight": False,
            },
        )

    def test_source_dependency_toolchain_and_workflow_changes_keep_checks(self):
        for path in (
            "apps/auravibes_app/lib/main.dart",
            "packages/core/pubspec.lock",
            ".fvmrc",
            ".github/actions/setup-workspace/action.yml",
            ".github/workflows/build-matrix.yml",
        ):
            with self.subTest(path=path):
                result = classify_paths([path])
                self.assertTrue(result["run_code_checks"])

    def test_documentation_only_changes_still_skip_dart_checks(self):
        result = classify_paths(["README.md", "docs/testing/ci.md"])

        self.assertFalse(result["run_code_checks"])
        self.assertFalse(result["run_server_integration"])


    def test_dependency_changes_request_resolution_preflight(self):
        for path in (
            ".fvmrc",
            "melos.yaml",
            "pubspec.yaml",
            "apps/auravibes_app/pubspec.yaml",
            "packages/auravibes_engine/pubspec.lock",
            "apps/auravibes_server/pubspec_overrides.yaml",
            ".github/actions/setup-workspace/action.yml",
        ):
            with self.subTest(path=path):
                self.assertTrue(classify_paths([path])["run_dependency_preflight"])

        for path in (
            "README.md",
            "apps/auravibes_app/lib/main.dart",
            "packages/auravibes_engine/lib/engine.dart",
        ):
            with self.subTest(path=path):
                self.assertFalse(classify_paths([path])["run_dependency_preflight"])

    def test_server_integration_runs_for_server_engine_and_shared_ci_inputs(self):
        for path in (
            "apps/auravibes_server/test/integration/conversations_test.dart",
            "apps/auravibes_server/config/test.yaml",
            "packages/auravibes_engine/lib/engine.dart",
            "pubspec.lock",
            ".fvmrc",
            ".github/actions/setup-workspace/action.yml",
            ".github/workflows/build-matrix.yml",
        ):
            with self.subTest(path=path):
                self.assertTrue(classify_paths([path])["run_server_integration"])

    def test_server_integration_skips_frontend_only_and_backend_documentation(self):
        for path in (
            "apps/auravibes_app/lib/main.dart",
            "packages/auravibes_ui/lib/button.dart",
            "apps/auravibes_server/README.md",
            ".github/workflows/ci.yml",
            "tool/classify_ci_changes.py",
            "README.md",
        ):
            with self.subTest(path=path):
                self.assertFalse(
                    classify_paths([path])["run_server_integration"]
                )

    def test_ci_routing_changes_only_request_routing_tests(self):
        for path in (
            ".github/workflows/ci.yml",
            "tool/classify_ci_changes.py",
            "tool/classify_ci_changes_test.py",
            "tool/ci_summary.py",
            "tool/ci_summary_test.py",
            "tool/sonar_workflow_test.py",
        ):
            with self.subTest(path=path):
                result = classify_paths([path])
                self.assertFalse(result["run_code_checks"])
                self.assertFalse(result["run_server_integration"])
                self.assertTrue(result["run_ci_tool_checks"])
                self.assertFalse(result["run_ci_selector_checks"])

        mixed = classify_paths(
            ["tool/classify_ci_changes.py", "apps/auravibes_app/lib/main.dart"]
        )
        self.assertTrue(mixed["run_code_checks"])
        self.assertTrue(mixed["run_ci_tool_checks"])

    def test_changed_test_selector_uses_focused_ci_checks(self):
        for path in (
            "tool/changed_test_selector.dart",
            "tool/changed_test_selector_test.dart",
        ):
            with self.subTest(path=path):
                result = classify_paths([path])
                self.assertFalse(result["run_code_checks"])
                self.assertFalse(result["run_server_integration"])
                self.assertTrue(result["run_ci_tool_checks"])
                self.assertTrue(result["run_ci_selector_checks"])

        mixed = classify_paths(
            ["tool/changed_test_selector.dart", "apps/auravibes_app/lib/main.dart"]
        )
        self.assertTrue(mixed["run_code_checks"])
        self.assertTrue(mixed["run_ci_selector_checks"])

    def test_ui_goldens_only_run_for_visual_inputs(self):
        cases = {
            "apps/auravibes_app/lib/features/profile/screens/profile_screen.dart": True,
            "apps/auravibes_app/lib/features/profile/profile_model.dart": False,
            "apps/auravibes_app/test/widgets/responsive_shell_test.dart": True,
            "apps/auravibes_app/test/features/profile/profile_model_test.dart": False,
            "apps/auravibes_app/test/widgets/goldens/shell.png": True,
            "packages/auravibes_ui/lib/src/atoms/aura_button.dart": True,
            "packages/auravibes_ui/test/src/atoms/auravibes_text_test.dart": False,
            "packages/auravibes_ui/test/src/organisms/auravibes_input_test.dart": True,
        }

        for path, expected in cases.items():
            with self.subTest(path=path):
                self.assertEqual(classify_paths([path])["run_ui_goldens"], expected)

    def test_generated_checks_only_run_for_generator_inputs(self):
        for path in (
            ".fvmrc",
            "pubspec.yaml",
            "packages/auravibes_app/build.yaml",
            "apps/auravibes_server/config/generator.yaml",
            "apps/auravibes_server/config/app.spy.yaml",
            "apps/auravibes_server/lib/src/endpoints/chat_endpoint.dart",
            "apps/auravibes_server/test/integration/test_tools/serverpod_test_tools.dart",
            "packages/auravibes_server_client/lib/src/protocol/chat.dart",
            "tool/run_quiet.dart",
            "packages/core/lib/core.dart",
        ):
            with self.subTest(path=path):
                self.assertEqual(
                    classify_paths([path])["run_generated_checks"],
                    path != "packages/core/lib/core.dart",
                )

        source = "packages/core/lib/core.dart"
        self.assertTrue(
            classify_paths([source], generated_source_paths=[source])[
                "run_generated_checks"
            ]
        )


if __name__ == "__main__":
    unittest.main()

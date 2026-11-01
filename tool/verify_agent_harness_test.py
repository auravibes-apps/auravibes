"""Regression checks for harness diagnostics, independent of an agent runtime."""

import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from verify_agent_harness import markdown_links, verify


class HarnessVerificationTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        scopes = (
            "apps/auravibes_app",
            "packages/auravibes_engine",
            "packages/auravibes_ui",
            "widgetbook",
        )
        for scope in ("", *scopes):
            folder = self.root / scope
            folder.mkdir(parents=True, exist_ok=True)
            (folder / "AGENTS.md").write_text("# Instructions\n")
            (folder / "CLAUDE.md").symlink_to("AGENTS.md")
        (self.root / "AGENTS.md").write_text(
            "# Instructions\n\n"
            + "\n".join(f"[Scope]({scope}/AGENTS.md)" for scope in scopes)
            + "\n"
        )
        (self.root / "docs").mkdir()
        (self.root / "docs/ARCHITECTURE.md").write_text("# Architecture\n")
        (self.root / "docs/agents").mkdir()
        (self.root / "docs/agents/commands.md").write_text("# Agent commands\n")
        self._write_melos_scripts("test:unit", "validate:quick")
        (self.root / "README.md").write_text("# README\n")
        (self.root / "CONTRIBUTING.md").write_text("# Contributing\n")
        context_map = Path(__file__).resolve().parent.parent / "CONTEXT-MAP.md"
        (self.root / "CONTEXT-MAP.md").write_text(context_map.read_text())
        self.contexts = [
            self.root / target
            for target in markdown_links(context_map.read_text())
            if Path(target).name == "CONTEXT.md"
        ]
        for path in self.contexts:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("# Context\n\nOwns workspace state and returns typed results.\n")
        self.skill = self.root / ".agents/skills/example"
        self.skill.mkdir(parents=True)
        (self.skill / "SKILL.md").write_text(
            "---\nname: example\ndescription: Use for an example task.\n---\n"
        )

    def _write_melos_scripts(self, *names):
        scripts = "\n".join(
            f"    {name}:\n      run: echo checked" for name in names
        )
        (self.root / "pubspec.yaml").write_text(
            "name: example\nmelos:\n  scripts:\n" + scripts + "\n"
        )

    def _write_skill(self, name, description):
        skill = self.root / ".agents/skills" / name
        skill.mkdir(parents=True, exist_ok=True)
        (skill / "SKILL.md").write_text(
            f"---\nname: {name}\ndescription: {description}\n---\n"
        )

    def test_new_indexed_scope_alias_needs_no_scope_registration(self):
        instructions = self.root / "AGENTS.md"
        instructions.write_text(
            instructions.read_text() + "\n[New scope](new-scope/AGENTS.md)\n"
        )
        scope = self.root / "new-scope"
        scope.mkdir()
        (scope / "AGENTS.md").write_text("# New scope\n")

        errors = verify(self.root)

        self.assertTrue(
            any(
                "new-scope/CLAUDE.md: Expected symlink" in error
                for error in errors
            ),
            errors,
        )
        (scope / "CLAUDE.md").symlink_to("AGENTS.md")
        self.assertEqual(verify(self.root), [])

    def test_valid_harness_is_read_only(self):
        before = (self.skill / "SKILL.md").read_bytes()
        self.assertEqual(verify(self.root), [])
        self.assertEqual((self.skill / "SKILL.md").read_bytes(), before)

    def test_documented_melos_scripts_are_checked_across_guidance_files(self):
        scoped_agents = self.root / "apps/auravibes_app/AGENTS.md"
        agent_docs = self.root / "docs/agents/commands.md"
        skill = self.skill / "SKILL.md"
        for path in (self.root / "AGENTS.md", scoped_agents, agent_docs, skill):
            content = path.read_text().rstrip()
            path.write_text(content + "\nmelos run validate:quick\n")

        self.assertEqual(verify(self.root), [])

    def test_unknown_melos_scripts_report_file_line_and_script_name(self):
        scoped_agents = self.root / "apps/auravibes_app/AGENTS.md"
        agent_docs = self.root / "docs/agents/commands.md"
        skill = self.skill / "SKILL.md"
        sources = (self.root / "AGENTS.md", scoped_agents, agent_docs, skill)
        expected_lines = {}
        for path in sources:
            content = path.read_text().rstrip()
            line_number = len(content.splitlines()) + 1
            path.write_text(content + "\nmelos run validate:quik\n")
            expected_lines[path.relative_to(self.root)] = line_number

        errors = verify(self.root)

        for path, line_number in expected_lines.items():
            with self.subTest(path=path):
                self.assertTrue(
                    any(
                        f"{path}: line {line_number}: Unknown Melos script "
                        "'validate:quik'" in error
                        for error in errors
                    ),
                    errors,
                )
        self.assertTrue(any("melos.scripts" in error for error in errors), errors)

    def test_unrelated_commands_are_not_treated_as_melos_scripts(self):
        guidance = self.root / "docs/agents/commands.md"
        guidance.write_text(
            "Run `fvm dart run melos bootstrap` to set up the workspace.\n"
            "Run `melos exec -- flutter test` for package-local execution.\n"
            "Run `flutter test` for an individual package.\n"
            "\n"
            "Generic Melos configuration example:\n"
            "```yaml\n"
            "melos:\n"
            "  scripts:\n"
            "    test:\n"
            "      run: melos run test\n"
            "```\n"
        )

        self.assertEqual(verify(self.root), [])

    def test_mutable_action_references_report_path_and_reference(self):
        workflow = self.root / ".github/workflows/actions.yml"
        workflow.parent.mkdir(parents=True)
        workflow.write_text(
            "jobs:\n"
            "  check:\n"
            "    steps:\n"
            "      - uses: example-org/workflow-action@v4\n"
            "      - uses: ./.github/actions/local-action\n"
        )
        action = self.root / ".github/actions/example/action.yml"
        action.parent.mkdir(parents=True)
        action.write_text(
            "runs:\n"
            "  using: composite\n"
            "  steps:\n"
            "    - uses: example-org/composite-action@main\n"
        )

        errors = verify(self.root)

        self.assertEqual(len(errors), 2, errors)
        self.assertTrue(
            any(
                ".github/workflows/actions.yml" in error
                and "example-org/workflow-action@v4" in error
                for error in errors
            ),
            errors,
        )
        self.assertTrue(
            any(
                ".github/actions/example/action.yml" in error
                and "example-org/composite-action@main" in error
                for error in errors
            ),
            errors,
        )

    def test_accepts_full_sha_local_and_self_repository_action_references(self):
        workflow = self.root / ".github/workflows/actions.yml"
        workflow.parent.mkdir(parents=True)
        workflow.write_text(
            "jobs:\n"
            "  check:\n"
            "    steps:\n"
            "      - uses: example-org/action@0123456789abcdef0123456789abcdef01234567 # v1\n"
            "      - uses: ./.github/actions/local-action\n"
            "      - uses: $/.github/actions/local-action\n"
        )

        self.assertEqual(verify(self.root), [])

    def test_all_current_mapped_contexts_are_checked(self):
        self.assertEqual(len(self.contexts), 6)
        self.assertIn(self.root / "apps/auravibes_server/CONTEXT.md", self.contexts)
        self.assertIn(self.root / "packages/auravibes_server_client/CONTEXT.md", self.contexts)
        for path in self.contexts:
            with self.subTest(context=path.relative_to(self.root)):
                content = path.read_text()
                path.unlink()
                errors = verify(self.root)
                self.assertTrue(any(str(path.relative_to(self.root)) in error for error in errors), errors)
                path.write_text(content)
                path.write_text("# Context\n\nPlaceholder. Add resolved domain terms here.\n")
                errors = verify(self.root)
                self.assertTrue(any(f"{path.relative_to(self.root)}: Placeholder" in error for error in errors), errors)
                path.write_text(content)

    def test_new_mapped_context_needs_no_scope_registration(self):
        context_map = self.root / "CONTEXT-MAP.md"
        context_map.write_text(context_map.read_text() + "\n[New](new/CONTEXT.md)\n")
        path = self.root / "new/CONTEXT.md"
        path.parent.mkdir()
        path.write_text("# New context\n\n## Terms\n\n<!-- Write terms here. -->\n\n## Invariants\n- TBD\n")
        self.assertTrue(any("new/CONTEXT.md: Empty" in error for error in verify(self.root)))
        path.write_text("# New context\n\nOwns examples and returns sample output.\n")
        self.assertEqual(verify(self.root), [])

    def test_template_instructions_are_not_resolved_content(self):
        path = self.contexts[0]
        path.write_text("# Context\n## Domain terms\n- TODO: add terms\n## Invariants\n- TBD: add invariants\n")
        self.assertTrue(any(f"{path.relative_to(self.root)}: Empty" in error for error in verify(self.root)))
        path.write_text("# Context\n\nOwns workspace state.\n\n- TODO: add more terms\n")
        self.assertEqual(verify(self.root), [])

    def test_missing_or_empty_context_map_fails(self):
        path = self.root / "CONTEXT-MAP.md"
        path.unlink()
        self.assertTrue(any("CONTEXT-MAP.md: Missing" in error for error in verify(self.root)))
        path.write_text("# Context Map\n")
        self.assertTrue(any("CONTEXT-MAP.md: No local context" in error for error in verify(self.root)))

    def test_context_links_use_existing_link_checks(self):
        self.contexts[0].write_text("# Context\n\nOwns state. See [architecture](missing.md).\n")
        errors = verify(self.root)
        self.assertTrue(any("Dead reference: missing.md" in error for error in errors))

    def test_nested_reference_uses_own_directory(self):
        (self.skill / "references").mkdir()
        (self.skill / "SKILL.md").write_text(
            (self.skill / "SKILL.md").read_text() + "[steps](references/steps.md)\n"
        )
        (self.skill / "references/steps.md").write_text("[details](missing.md)\n")
        errors = verify(self.root)
        self.assertEqual(len(errors), 1)
        self.assertIn("references/steps.md: Dead reference: missing.md", errors[0])

    def test_multiple_links_and_example_code(self):
        text = '[one](a.md) [two](b.md#heading)\n`[sample](missing.md)`\n```md\n[example](missing.md)\n```\n[space](<a file.md>)\n'
        self.assertEqual(list(markdown_links(text)), ["a.md", "b.md#heading", "a file.md"])

    def test_markdown_reference_and_html_image_targets_are_found(self):
        text = (
            "[guide][guide]\n"
            "![logo][logo]\n"
            "[guide]: docs/guide.md#start\n"
            '[logo]: <images/logo mark.svg> "Logo"\n'
            '<img alt="diagram" src="images/diagram.svg">\n'
            '`<img src="inline-code.png">`\n'
            '<!-- [hidden](comment-link.md) <img src="comment-image.png"> -->\n'
            "```html\n<img src=\"fenced-code.png\">\n```\n"
        )
        self.assertEqual(
            set(markdown_links(text)),
            {
                "docs/guide.md#start",
                "images/logo mark.svg",
                "images/diagram.svg",
            },
        )

    def test_nested_list_links_are_not_discarded_as_code(self):
        text = "- Parent\n    - [guide](missing-guide.md)\n"
        self.assertEqual(set(markdown_links(text)), {"missing-guide.md"})

    def test_indented_code_and_nested_fenced_code_are_ignored(self):
        text = (
            "    [indented](missing-indented.md)\n"
            "- Parent\n"
            "    - Child\n"
            "        ```md\n"
            "        [nested](missing-fenced.md)\n"
            "        ```\n"
        )
        self.assertEqual(list(markdown_links(text)), [])

    def test_reference_destination_can_follow_definition_line(self):
        text = "[guide][guide]\n\n[guide]:\n  docs/guide.md\n"
        self.assertEqual(list(markdown_links(text)), ["docs/guide.md"])

    def test_malformed_reference_with_backslash_run_finishes(self):
        source = (
            "import sys\n"
            f"sys.path.insert(0, {str(Path(__file__).parent)!r})\n"
            "from verify_agent_harness import markdown_links\n"
            "list(markdown_links('[' + chr(92) * 64 + ']missing-colon'))\n"
        )

        try:
            result = subprocess.run(
                [sys.executable, "-c", source],
                check=False,
                capture_output=True,
                text=True,
                timeout=2,
            )
        except subprocess.TimeoutExpired:
            self.fail("malformed reference with repeated backslashes did not finish")

        self.assertEqual(result.returncode, 0, result.stderr)

    def test_indented_raw_html_images_are_not_treated_as_code(self):
        text = (
            "<p>\n"
            "    <img\n"
            '        alt="diagram"\n'
            '        src="missing-html.png"\n'
            "    >\n"
            "</p>\n"
        )
        self.assertEqual(list(markdown_links(text)), ["missing-html.png"])

    def test_inline_html_examples_do_not_hide_following_fenced_code(self):
        text = (
            "The example tag is `<div>`.\n"
            "```md\n"
            "[example](missing-example.md)\n"
            "```\n"
        )
        self.assertEqual(list(markdown_links(text)), [])

    def test_blank_line_ends_raw_html_context_before_markdown_fence(self):
        text = (
            "<details>\n\n"
            "```md\n"
            "[example](missing-example.md)\n"
            "```\n"
            "</details>\n"
        )
        self.assertEqual(list(markdown_links(text)), [])

    def test_linked_markdown_image_reports_outer_local_target(self):
        (self.root / "README.md").write_text(
            "[![badge](https://example.com/badge.svg)](missing-page.md)\n"
        )

        errors = verify(self.root)

        self.assertTrue(
            any("README.md: Dead reference: missing-page.md" in item for item in errors)
        )

    def test_escaped_inline_and_reference_destinations_resolve(self):
        target = self.root / "docs/guide(v2).md"
        target.write_text("# Guide\n")
        (self.root / "README.md").write_text(
            "[plain](docs/guide\\(v2\\).md)\n"
            "[angle](<docs/guide\\(v2\\).md>)\n"
            "[reference][guide]\n"
            "[guide]: docs/guide\\(v2\\).md\n"
        )

        self.assertEqual(verify(self.root), [])

    def test_contributor_documentation_sources_report_missing_targets(self):
        (self.root / "README.md").write_text(
            "[setup](docs/missing-setup.md)\n"
            "![diagram](assets/missing.png)\n"
            "[missing guide][guide]\n"
            "[guide]: docs/missing-reference.md\n"
            '<img alt="diagram" src="assets/missing-html.png">\n'
        )
        (self.root / "CONTRIBUTING.md").write_text(
            "[agent guide](docs/agents/missing-guide.md)\n"
        )
        (self.root / "docs/agents/domain.md").write_text(
            "[missing](../missing-domain.md)\n"
        )
        plugin_docs = self.root / ".agents/plugins/example"
        plugin_docs.mkdir(parents=True)
        (plugin_docs / "README.md").write_text(
            "[missing](missing-plugin-doc.md)\n"
        )

        errors = verify(self.root)

        self.assertTrue(
            any("README.md: Dead reference: docs/missing-setup.md" in item for item in errors)
        )
        self.assertTrue(
            any("README.md: Dead reference: assets/missing.png" in item for item in errors)
        )
        self.assertTrue(
            any(
                "README.md: Dead reference: docs/missing-reference.md" in item
                for item in errors
            )
        )
        self.assertTrue(
            any(
                "README.md: Dead reference: assets/missing-html.png" in item
                for item in errors
            )
        )
        self.assertTrue(
            any(
                "CONTRIBUTING.md: Dead reference: docs/agents/missing-guide.md" in item
                for item in errors
            )
        )
        self.assertTrue(
            any("docs/agents/domain.md: Dead reference: ../missing-domain.md" in item for item in errors)
        )
        self.assertTrue(
            any(
                ".agents/plugins/example/README.md: Dead reference: missing-plugin-doc.md" in item
                for item in errors
            )
        )

    def test_external_and_fragment_only_targets_do_not_block(self):
        (self.root / "README.md").write_text(
            "[external](https://example.com/docs)\n"
            "![remote](https://example.com/image.png)\n"
            "[section](#current-section)\n"
        )
        self.assertEqual(verify(self.root), [])

    def test_alias_and_metadata_diagnostics(self):
        (self.root / "CLAUDE.md").unlink()
        (self.root / "CLAUDE.md").write_text("duplicate rules")
        (self.skill / "SKILL.md").write_text("---\nname: wrong\n---\n")
        errors = verify(self.root)
        self.assertTrue(any("Expected symlink" in item for item in errors))
        self.assertTrue(any("Missing description" in item for item in errors))
        self.assertTrue(any("differs from directory" in item for item in errors))

    def test_skill_metadata_accepts_spec_length_boundaries(self):
        self._write_skill("a", "x")
        self._write_skill("b" * 64, "x" * 1024)
        self._write_skill(
            "folded-description-boundary",
            ">-\n  " + "x" * 512 + "\n  " + "y" * 511,
        )
        self._write_skill("literal-description-boundary", "|-\n  " + "z" * 1024)

        self.assertEqual(verify(self.root), [])

    def test_invalid_skill_name_characters_have_actionable_errors(self):
        invalid_names = (
            "Uppercase",
            "two words",
            "under_score",
            "-leading-hyphen",
            "trailing-hyphen-",
            "two--hyphens",
        )
        for name in invalid_names:
            with self.subTest(name=name):
                self._write_skill(name, "A valid description.")
                errors = verify(self.root)
                self.assertTrue(
                    any(
                        f".agents/skills/{name}/SKILL.md" in item
                        and "Skill name must use lowercase letters" in item
                        for item in errors
                    ),
                    errors,
                )

    def test_skill_name_and_description_over_limits_are_rejected(self):
        too_long_name = "a" * 65
        self._write_skill(too_long_name, "A valid description.")
        self._write_skill("long-description", "x" * 1025)
        self._write_skill("long-block-description", ">-\n  " + "x" * 1025)

        errors = verify(self.root)

        self.assertTrue(
            any(
                ".agents/skills/" + too_long_name in item
                and "Skill name must contain 1 to 64 characters (got 65)" in item
                for item in errors
            ),
            errors,
        )
        self.assertTrue(
            any(
                ".agents/skills/long-description/SKILL.md" in item
                and "Skill description must be at most 1024 characters (got 1025)"
                in item
                for item in errors
            ),
            errors,
        )
        self.assertTrue(
            any(
                ".agents/skills/long-block-description/SKILL.md" in item
                and "Skill description must be at most 1024 characters (got 1025)"
                in item
                for item in errors
            ),
            errors,
        )

    def test_empty_skill_description_is_rejected(self):
        self._write_skill("empty-description", "")
        self._write_skill("empty-block-description", ">-\n")

        errors = verify(self.root)

        self.assertTrue(
            any(
                ".agents/skills/empty-description/SKILL.md" in item
                and "Missing description" in item
                for item in errors
            ),
            errors,
        )
        self.assertTrue(
            any(
                ".agents/skills/empty-block-description/SKILL.md" in item
                and "Missing description" in item
                for item in errors
            ),
            errors,
        )

    def test_duplicate_evaluation_ids_fail(self):
        (self.skill / "evals").mkdir()
        case = {"id": 1, "prompt": "task", "expected_output": "observable outcome", "files": []}
        (self.skill / "evals/evals.json").write_text(json.dumps({
            "skill_name": "example", "evals": [case, case]
        }))
        self.assertTrue(any("unique integers" in item for item in verify(self.root)))

    def test_invalid_json_and_repository_escape_fail(self):
        (self.skill / "evals").mkdir()
        (self.skill / "evals/evals.json").write_text("{bad")
        (self.skill / "SKILL.md").write_text(
            (self.skill / "SKILL.md").read_text() + "[escape](../../../../outside.md)\n"
        )
        errors = verify(self.root)
        self.assertTrue(any("Invalid evaluation cases" in item for item in errors))
        self.assertTrue(any("escapes repository" in item for item in errors))


if __name__ == "__main__":
    unittest.main()

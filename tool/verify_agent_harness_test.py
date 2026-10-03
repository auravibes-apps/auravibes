"""Regression checks for harness diagnostics, independent of an agent runtime."""

import json
from pathlib import Path
import tempfile
import unittest

from verify_agent_harness import SCOPES, markdown_links, verify


class HarnessVerificationTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        for scope in ("", *SCOPES):
            folder = self.root / scope
            folder.mkdir(parents=True, exist_ok=True)
            (folder / "AGENTS.md").write_text("# Instructions\n")
            (folder / "CLAUDE.md").symlink_to("AGENTS.md")
        (self.root / "docs").mkdir()
        (self.root / "docs/ARCHITECTURE.md").write_text("# Architecture\n")
        self.skill = self.root / ".agents/skills/example"
        self.skill.mkdir(parents=True)
        (self.skill / "SKILL.md").write_text(
            "---\nname: example\ndescription: Use for an example task.\n---\n"
        )

    def test_valid_harness_is_read_only(self):
        before = (self.skill / "SKILL.md").read_bytes()
        self.assertEqual(verify(self.root), [])
        self.assertEqual((self.skill / "SKILL.md").read_bytes(), before)

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

    def test_alias_and_metadata_diagnostics(self):
        (self.root / "CLAUDE.md").unlink()
        (self.root / "CLAUDE.md").write_text("duplicate rules")
        (self.skill / "SKILL.md").write_text("---\nname: wrong\n---\n")
        errors = verify(self.root)
        self.assertTrue(any("Expected symlink" in item for item in errors))
        self.assertTrue(any("Missing description" in item for item in errors))
        self.assertTrue(any("differs from directory" in item for item in errors))

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

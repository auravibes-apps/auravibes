import json
from pathlib import Path
import re
import subprocess
import unittest


class OpenCodeConcurrencyTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        workflow = (
            Path(__file__).resolve().parents[1] / ".github/workflows/opencode.yml"
        )
        parsed = subprocess.check_output(
            [
                "ruby",
                "-ryaml",
                "-rjson",
                "-e",
                "puts JSON.generate(YAML.load_file(ARGV.fetch(0)))",
                str(workflow),
            ],
            text=True,
        )
        cls.concurrency = json.loads(parsed)["jobs"]["opencode"]["concurrency"]

    def group(self, event, run_id=1, repository="owner/repo", actor="collaborator"):
        context = {
            "github": {
                "event": event,
                "run_id": run_id,
                "repository": repository,
                "actor": actor,
            }
        }

        def resolve(match):
            for alternative in match[1].split("||"):
                value = context
                for part in alternative.strip().split("."):
                    value = value.get(part) if isinstance(value, dict) else None
                if value:
                    return str(value)
            self.fail(f"Unresolved concurrency expression: {match[1]}")

        return re.sub(r"\$\{\{(.*?)\}\}", resolve, self.concurrency["group"])

    def test_different_targets_have_different_groups(self):
        for key in ("issue", "pull_request"):
            with self.subTest(event=key):
                self.assertNotEqual(
                    self.group({key: {"number": 27}}),
                    self.group({key: {"number": 28}}),
                )

    def test_issue_and_review_comments_share_the_same_pr_group(self):
        issue_comment = {"issue": {"number": 27, "pull_request": {}}}
        review_comment = {"pull_request": {"number": 27}}
        self.assertEqual(
            self.group(issue_comment, run_id=1),
            self.group(review_comment, run_id=2),
        )

    def test_same_target_cancels_previous_run_for_the_same_actor(self):
        self.assertIs(self.concurrency["cancel-in-progress"], True)
        for key in ("issue", "pull_request"):
            with self.subTest(event=key):
                event = {key: {"number": 27}}
                self.assertEqual(
                    self.group(event, run_id=1), self.group(event, run_id=2)
                )

    def test_missing_target_uses_a_run_specific_fallback(self):
        for event in ({}, {"issue": {}}, {"pull_request": {}}):
            with self.subTest(event=event):
                self.assertNotEqual(
                    self.group(event, run_id=1), self.group(event, run_id=2)
                )

    def test_repository_and_actor_remain_isolated(self):
        event = {"issue": {"number": 27}}
        self.assertNotEqual(
            self.group(event), self.group(event, repository="owner/other")
        )
        self.assertNotEqual(self.group(event), self.group(event, actor="other"))


if __name__ == "__main__":
    unittest.main()

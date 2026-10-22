"""Regression checks for read-only agent worktree tooling."""

import json
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from agent_worktree import _issue_conflicts, _mentions_issue, _parse_worktrees
from agent_worktree import _readiness_checks, _worktree_status


class AgentWorktreeTest(unittest.TestCase):
    def test_parses_linked_and_prunable_worktrees(self):
        parsed = _parse_worktrees(
            "worktree /repo\n"
            "HEAD abc123\n"
            "branch refs/heads/main\n\n"
            "worktree /repo/issue\n"
            "HEAD def456\n"
            "branch refs/heads/issue-123-fix\n"
            "locked in progress\n\n"
            "worktree /repo/old\n"
            "HEAD fedcba\n"
            "prunable gitdir file missing\n"
        )

        self.assertEqual(len(parsed), 3)
        self.assertEqual(parsed[0]["branch"], "main")
        self.assertEqual(parsed[1]["branch"], "issue-123-fix")
        self.assertEqual(parsed[1]["locked"], "in progress")
        self.assertIn("prunable", parsed[2])

    def test_issue_matching_respects_number_boundaries(self):
        self.assertTrue(_mentions_issue("chore/issue-12-preflight", 12))
        self.assertTrue(_mentions_issue("fix #12", 12))
        self.assertFalse(_mentions_issue("issue-123-preflight", 12))
        self.assertFalse(_mentions_issue("ticket-120", 12))
        self.assertFalse(_mentions_issue(None, 12))

    def test_readiness_checks_validate_pinned_sdk_workspace_and_devtools(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            sdk = root / "3.47.7"
            sdk.mkdir()
            (root / ".fvmrc").write_text(json.dumps({"flutter": "3.47.7"}))
            fvm = root / ".fvm"
            fvm.mkdir()
            sdk_link = fvm / "flutter_sdk"
            sdk_link.symlink_to(sdk, target_is_directory=True)

            package_config = root / ".dart_tool" / "package_config.json"
            package_config.parent.mkdir()
            valid_config = {
                "packages": [
                    {"name": "auravibes_app", "rootUri": "../apps/auravibes_app"}
                ]
            }
            package_config.write_text(json.dumps(valid_config))
            devtools = root / "apps" / "auravibes_app" / "devtools_options.yaml"
            devtools.parent.mkdir(parents=True)
            devtools.write_text("extensions: []\\n")

            self.assertTrue(all(check["ok"] for check in _readiness_checks(root)))

            package_config.write_text(
                json.dumps(
                    {"packages": [{"name": "auravibes_app", "rootUri": "../../outside"}]}
                )
            )
            checks = _readiness_checks(root)
            self.assertEqual(
                [check["name"] for check in checks if not check["ok"]],
                ["resolved Pub workspace config"],
            )
            package_config.write_text(json.dumps(valid_config))

            wrong_sdk = root / "3.47.6"
            wrong_sdk.mkdir()
            sdk_link.unlink()
            sdk_link.symlink_to(wrong_sdk, target_is_directory=True)
            checks = _readiness_checks(root)
            self.assertEqual(
                [check["name"] for check in checks if not check["ok"]],
                ["pinned Flutter SDK"],
            )

            sdk_link.unlink()
            sdk_link.symlink_to(sdk, target_is_directory=True)

            devtools.unlink()
            checks = _readiness_checks(root)
            self.assertEqual(
                [check["name"] for check in checks if not check["ok"]],
                ["app DevTools configuration"],
            )

    def test_worktree_status_requires_git_status(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            listing = SimpleNamespace(
                stdout=f"worktree {root}\nbranch refs/heads/main\n\n"
            )
            with (
                patch(
                    "agent_worktree._run",
                    side_effect=[listing, RuntimeError("status failed")],
                ),
                patch(
                    "agent_worktree._readiness_checks",
                    return_value=[{"name": "checks", "ok": True}],
                ),
            ):
                status = _worktree_status(root)[0]

        self.assertEqual(status["state"], "error")
        self.assertFalse(status["ready"])
        self.assertEqual(status["blocked"], ["git status unavailable"])

    def test_issue_preflight_reports_other_worktrees_and_open_prs(self):
        worktree_output = (
            "worktree /repo\nbranch refs/heads/main\n\n"
            "worktree /tmp/issue\nbranch refs/heads/issue-12-two\n"
        )
        results = [
            SimpleNamespace(stdout="chore/issue-12-one\nissue-123-other\n"),
            SimpleNamespace(stdout="main\n"),
            SimpleNamespace(stdout=worktree_output),
            SimpleNamespace(
                stdout='[{"number": 99, "title": "Intermittent failure", '
                '"body": "Closes #12", "headRefName": "fix-99", '
                '"url": "https://example.test/99"}]'
            ),
        ]
        with patch("agent_worktree._run", side_effect=results):
            conflicts = _issue_conflicts(Path("/repo"), 12, {"number": 12})

        self.assertEqual(conflicts["branches"], ["chore/issue-12-one"])
        self.assertEqual(conflicts["worktrees"][0]["branch"], "issue-12-two")
        self.assertEqual(conflicts["pull_requests"][0]["number"], 99)


if __name__ == "__main__":
    unittest.main()

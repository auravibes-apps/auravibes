"""Checks the trusted PR and no-coverage Sonar workflow boundaries."""

import unittest
from pathlib import Path


class SonarWorkflowTest(unittest.TestCase):
    def test_pull_request_scans_only_trusted_heads_and_fails_without_token(self):
        workflow = (Path(__file__).resolve().parent.parent / '.github/workflows/ci.yml').read_text()
        coverage = workflow.split('\n  coverage:\n', 1)[1].split('\n  sonar-without-coverage:', 1)[0]
        fallback = workflow.split('\n  sonar-without-coverage:\n', 1)[1].split('\n  server-compose:', 1)[0]
        self.assertNotIn('pull_request_target', workflow)
        for job in (coverage, fallback):
            self.assertIn('github.event.pull_request.head.repo.full_name == github.repository', job)
            self.assertIn('SONAR_TOKEN is required for same-repository pull requests.', job)
            self.assertIn('exit 1', job)
            self.assertIn('SonarSource/sonarqube-scan-action@d209202bc7d53ff1cc128f7f907dac145c9d6ae9', job)
        self.assertIn("steps.check-sonar-token.outputs.token_available == 'true'", coverage)
        self.assertIn("needs.coverage.result == 'skipped'", fallback)
        self.assertIn("needs.change.outputs.run_code_checks == 'false'", fallback)
        self.assertIn("needs.test-plan.outputs.mode == 'none'", fallback)
        self.assertIn('sonar-without-coverage, platform-builds', workflow)


if __name__ == '__main__':
    unittest.main()

"""Checks the trusted PR and no-coverage Sonar workflow boundaries."""

import re
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
            self.assertIn('SonarSource/sonarqube-scan-action@4d1dc0c91ee400dcf8a6dddf2f705ac36542e304', job)
            self.assertIn("java-version: '25'", job)
        self.assertIn("steps.check-sonar-token.outputs.token_available == 'true'", coverage)
        self.assertIn("needs.coverage.result == 'skipped'", fallback)
        self.assertIn("needs.change.outputs.run_code_checks != 'true' ||", fallback)
        self.assertIn("needs.test-plan.outputs.mode == 'none'", fallback)
        self.assertIn('sonar-without-coverage, platform-builds', workflow)

    def test_dependency_preflight_gates_validation_fanout(self):
        workflow = (Path(__file__).resolve().parent.parent / '.github/workflows/ci.yml').read_text()
        change = workflow.split('\n  change:\n', 1)[1].split('\n  renovate-validation:', 1)[0]

        self.assertIn(
            'run_dependency_preflight: ${{ steps.platforms.outputs.run_dependency_preflight }}',
            change,
        )
        self.assertIn('run_dependency_preflight=true', change)
        self.assertIn('run_dependency_preflight="$(jq -r', change)
        self.assertIn('Resolve dependencies before validation fan-out', change)
        self.assertIn(
            'if: ${{ steps.platforms.outputs.run_dependency_preflight == \'true\' }}',
            change,
        )
        self.assertIn('uses: ./.github/actions/setup-workspace', change)
        self.assertIn('python3 tool/sonar_workflow_test.py', workflow)

    def test_every_ci_job_depends_on_change_job(self):
        workflow = (Path(__file__).resolve().parent.parent / '.github/workflows/ci.yml').read_text()
        job_source = workflow.split('\njobs:\n', 1)[1]
        job_parts = re.split(r'(?m)^  ([A-Za-z0-9_-]+):\n', job_source)
        job_bodies = dict(zip(job_parts[1::2], job_parts[2::2]))
        self.assertIn('change', job_bodies)

        dependencies = {}
        for job_name, body in job_bodies.items():
            match = re.search(r'(?m)^    needs:\s*(.*)$', body)
            raw_dependencies = match.group(1).strip() if match else ''
            dependencies[job_name] = tuple(
                re.findall(r'[A-Za-z0-9_-]+', raw_dependencies)
            )

        def depends_on_change(job_name, ancestors=()):
            if job_name == 'change':
                return True
            if job_name not in dependencies or job_name in ancestors:
                return False
            return any(
                depends_on_change(dependency, ancestors + (job_name,))
                for dependency in dependencies[job_name]
            )

        for job_name in job_bodies:
            with self.subTest(job=job_name):
                self.assertTrue(
                    depends_on_change(job_name),
                    f'{job_name} can bypass the change job',
                )


if __name__ == '__main__':
    unittest.main()

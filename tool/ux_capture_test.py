"""Tests for source-bound UX capture metadata."""

import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

import ux_capture


class UxCaptureTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name) / "repo"
        self.root.mkdir()
        self.app = self.root / "apps/auravibes_app"
        (self.app / "test").mkdir(parents=True)
        (self.app / "test/example_test.dart").write_text("// fixture\n")
        _git(self.root, "init", "-q")
        _git(self.root, "config", "user.name", "Fixture")
        _git(self.root, "config", "user.email", "fixture@example.invalid")
        _git(self.root, "add", ".")
        _git(self.root, "commit", "-qm", "base")
        self.output = Path(self.temp.name) / "captures"

    def tearDown(self):
        self.temp.cleanup()

    def test_untracked_fixture_changes_fingerprint_and_base_cannot_be_dirty(self):
        clean = ux_capture.capture_provenance(self.root, "HEAD", "base", "none")
        (self.app / "test/new_fixture.dart").write_text("fixture overlay\n")
        with self.assertRaisesRegex(ValueError, "clean"):
            ux_capture.capture_provenance(self.root, "HEAD", "base", "none")
        mixed = ux_capture.capture_provenance(
            self.root, "HEAD", "mixed", "new fixture"
        )
        self.assertTrue(mixed["dirty"])
        self.assertNotEqual(
            clean["workingTreeFingerprint"], mixed["workingTreeFingerprint"]
        )
        self.assertEqual(mixed["fixtureOverlay"], "new fixture")

    def test_mixed_capture_requires_overlay_description(self):
        with self.assertRaisesRegex(ValueError, "overlay"):
            ux_capture.capture_provenance(self.root, "HEAD", "mixed", "none")
        with self.assertRaisesRegex(ValueError, "overlay"):
            ux_capture.capture_provenance(self.root, "HEAD", "base", "test fixture")

    def test_changed_test_fixture_cannot_claim_no_overlay(self):
        test_file = self.app / "test/example_test.dart"
        test_file.write_text("// changed fixture\n")
        with self.assertRaisesRegex(ValueError, "changed fixture overlay"):
            ux_capture.capture(
                self.root, "test/example_test.dart", "example", self.output,
                "HEAD", "candidate", "none",
            )
        test_file.write_text("// fixture\n")
        helper = self.app / "test/helpers/ux_capture.dart"
        helper.parent.mkdir()
        helper.write_text("// helper overlay\n")
        with self.assertRaisesRegex(ValueError, "changed fixture overlay"):
            ux_capture.capture(
                self.root, "test/example_test.dart", "example", self.output,
                "HEAD", "candidate", "none",
            )

    def test_base_must_match_head_and_output_cannot_be_in_repo(self):
        (self.root / "second.txt").write_text("second\n")
        _git(self.root, "add", ".")
        _git(self.root, "commit", "-qm", "second")
        with self.assertRaisesRegex(ValueError, "base revision"):
            ux_capture.capture_provenance(self.root, "HEAD^", "base", "none")
        with self.assertRaisesRegex(ValueError, "outside the repository"):
            ux_capture.capture(
                self.root, "test/example_test.dart", "example",
                self.root / "captures", "HEAD", "base", "none",
            )

    def test_capture_records_verified_metadata_and_checks_pairs(self):
        def run_flutter(command, cwd):
            self.assertEqual(cwd, self.app.resolve())
            encoded = next(
                arg.removeprefix("--dart-define=UX_CAPTURE_PROVENANCE=")
                for arg in command
                if arg.startswith("--dart-define=UX_CAPTURE_PROVENANCE=")
            )
            provenance = json.loads(encoded)
            (self.output / "001-state.png").write_bytes(ux_capture.PNG_SIGNATURE)
            (self.output / "001-state.json").write_text(
                json.dumps({
                    "sourceProvenance": provenance,
                    "sourceFingerprint": provenance["workingTreeFingerprint"],
                })
            )
            return 0

        with patch.object(ux_capture, "_run_flutter", side_effect=run_flutter):
            result = ux_capture.capture(
                self.root, "test/example_test.dart", "example", self.output,
                "HEAD", "base", "none",
            )
        self.assertEqual(result["kind"], "base")
        self.assertEqual(result["baseRevision"], result["headRevision"])
        self.assertFalse(result["dirty"])
        self.assertEqual(ux_capture.verify_capture(self.output), (1, result))

    def test_capture_rejects_mismatched_sidecar(self):
        def run_flutter(_command, _cwd):
            (self.output / "001-state.png").write_bytes(ux_capture.PNG_SIGNATURE)
            (self.output / "001-state.json").write_text(
                json.dumps({"sourceProvenance": {"kind": "base"}})
            )
            return 0

        with patch.object(ux_capture, "_run_flutter", side_effect=run_flutter):
            with self.assertRaisesRegex(ValueError, "incorrect provenance"):
                ux_capture.capture(
                    self.root, "test/example_test.dart", "example", self.output,
                    "HEAD", "base", "none",
                )

    def test_capture_rejects_invalid_png(self):
        def run_flutter(_command, _cwd):
            (self.output / "001-state.png").write_bytes(b"not a PNG")
            return 0

        with patch.object(ux_capture, "_run_flutter", side_effect=run_flutter):
            with self.assertRaisesRegex(ValueError, "invalid PNG"):
                ux_capture.capture(
                    self.root, "test/example_test.dart", "example", self.output,
                    "HEAD", "base", "none",
                )

    def test_verify_rejects_legacy_unverified_metadata(self):
        self.output.mkdir()
        (self.output / "001-state.png").write_bytes(ux_capture.PNG_SIGNATURE)
        (self.output / "001-state.json").write_text(
            json.dumps({"sourceFingerprint": "declared-only"})
        )
        with self.assertRaisesRegex(ValueError, "incorrect provenance"):
            ux_capture.verify_capture(self.output)

    def test_capture_rejects_missing_sidecar_and_source_changes(self):
        def run_flutter(_command, _cwd):
            (self.output / "001-state.png").write_bytes(ux_capture.PNG_SIGNATURE)
            return 0

        with patch.object(ux_capture, "_run_flutter", side_effect=run_flutter):
            with self.assertRaisesRegex(ValueError, "sidecar"):
                ux_capture.capture(
                    self.root, "test/example_test.dart", "example", self.output,
                    "HEAD", "base", "none",
                )

        self.output.rename(self.output.with_name("old-captures"))

        def change_source(_command, _cwd):
            (self.app / "test/new_fixture.dart").write_text("changed\n")
            return 0

        with patch.object(ux_capture, "_run_flutter", side_effect=change_source):
            with self.assertRaisesRegex(ValueError, "changed during capture"):
                ux_capture.capture(
                    self.root, "test/example_test.dart", "example", self.output,
                    "HEAD", "base", "none",
                )


def _git(root, *args):
    subprocess.run(
        ["git", "-C", str(root), *args], check=True, capture_output=True
    )


if __name__ == "__main__":
    unittest.main()

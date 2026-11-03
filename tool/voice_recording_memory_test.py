import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import Mock, patch

import voice_recording_memory as probe


class VoiceMemoryRunnerTest(unittest.TestCase):
    def test_success_without_result_is_incomplete(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            process = Mock()
            process.wait.return_value = 0
            with patch.object(probe.subprocess, "Popen", return_value=process):
                result = probe.run_case(root, root, "baseline", 5, 1, False)
            self.assertEqual(result["status"], "missing-result")
            self.assertTrue((root / "baseline-5s-1-regular.run.json").exists())

    def test_failed_run_keeps_partial_samples_and_log(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            samples = root / "baseline-5s-1-regular.samples.jsonl"
            samples.write_text('{"phase":"pre-stop"}\n')
            process = Mock()
            process.wait.return_value = 1
            with patch.object(probe.subprocess, "Popen", return_value=process):
                result = probe.run_case(root, root, "baseline", 5, 1, False)
            self.assertEqual(result["status"], "failed")
            self.assertEqual(samples.read_text(), '{"phase":"pre-stop"}\n')
            self.assertTrue((root / "baseline-5s-1-regular.log").exists())

    def test_timeout_records_failure_and_terminates_only_its_process_group(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            process = Mock(pid=123)
            process.wait.side_effect = [subprocess.TimeoutExpired("flutter", 155), 0]
            with patch.object(probe.subprocess, "Popen", return_value=process), \
                    patch.object(probe.os, "killpg") as kill:
                result = probe.run_case(root, root, "baseline", 5, 1, False)
            self.assertEqual(result["status"], "timed-out")
            kill.assert_called_once_with(123, probe.signal.SIGTERM)
            saved = json.loads((root / "baseline-5s-1-regular.run.json").read_text())
            self.assertEqual(saved["status"], "timed-out")

    def test_finalization_increment_uses_only_the_finalization_peak(self):
        case = {"process_max_rss_bytes": 1000, "sampled_peak_rss_bytes": 900,
                "sampled_peak_heap_plus_external_bytes": 500,
                "finalization_peak_rss_bytes": 700, "stop_microseconds": 50,
                "phases": {"idle": {"rss_bytes": 100},
                           "pre-stop": {"rss_bytes": 600}}}
        rows = probe.summarize([{"label": "baseline", "seconds": 5,
                                 "irregular": False, "status": "passed",
                                 "result": case}])
        metrics = rows[0]["metrics"]
        self.assertEqual(metrics["idle_relative_peak_rss_bytes"]["median"], 800)
        self.assertEqual(metrics["finalization_increment_rss_bytes"]["median"], 100)


if __name__ == "__main__":
    unittest.main()

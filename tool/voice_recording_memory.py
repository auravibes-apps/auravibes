#!/usr/bin/env python3
"""Run each voice-memory case in a fresh Flutter worker and retain all evidence."""

import argparse
import hashlib
import json
import os
from pathlib import Path
import platform
import signal
import statistics
import subprocess
import sys
import time


def run_case(checkout, output, label, seconds, repetition, irregular):
    name = f"{label}-{seconds}s-{repetition}-{'irregular' if irregular else 'regular'}"
    prefix = output / name
    command = [
        "flutter", "test", "test/performance/voice_recording_memory_test.dart",
        "--no-pub", "--concurrency=1", "--reporter=expanded",
        "--dart-define=VOICE_MEMORY_PROBE=true",
        f"--dart-define=VOICE_MEMORY_SECONDS={seconds}",
        f"--dart-define=VOICE_MEMORY_IRREGULAR={str(irregular).lower()}",
    ]
    environment = {**os.environ, "VOICE_MEMORY_OUTPUT": str(prefix)}
    started = time.time()
    record = {"label": label, "seconds": seconds, "repetition": repetition,
              "irregular": irregular, "command": command, "status": "started"}
    prefix.with_suffix(".run.json").write_text(json.dumps(record, indent=2))
    print(f"Starting {name}", flush=True)
    with prefix.with_suffix(".log").open("wb") as log:
        process = subprocess.Popen(command, cwd=checkout / "apps/auravibes_app",
                                   env=environment, stdout=log,
                                   stderr=subprocess.STDOUT, start_new_session=True)
        try:
            code = process.wait(timeout=seconds + 150)
            record["status"] = "passed" if code == 0 else "failed"
            record["exit_code"] = code
        except subprocess.TimeoutExpired:
            record["status"] = "timed-out"
            os.killpg(process.pid, signal.SIGTERM)
            try:
                process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait()
    record["elapsed_seconds"] = round(time.time() - started, 3)
    result_path = Path(f"{prefix}.result.json")
    if result_path.exists():
        record["result"] = json.loads(result_path.read_text())
    elif record["status"] == "passed":
        record["status"] = "missing-result"
    prefix.with_suffix(".run.json").write_text(json.dumps(record, indent=2))
    print(f"Finished {name}: {record['status']}", flush=True)
    return record


def summarize(records):
    rows = []
    for label in sorted({record["label"] for record in records}):
        for seconds in (5, 30, 120):
            cases = [record["result"] for record in records
                     if record["label"] == label and record["seconds"] == seconds
                     and not record["irregular"] and record["status"] == "passed"]
            if not cases:
                continue
            metrics = {}
            for key in ("process_max_rss_bytes", "sampled_peak_rss_bytes",
                        "sampled_peak_heap_plus_external_bytes", "stop_microseconds"):
                values = [case[key] for case in cases]
                metrics[key] = {"median": statistics.median(values),
                                "min": min(values), "max": max(values)}
            for key, phase in (("idle_relative_peak_rss_bytes", "idle"),
                               ("finalization_increment_rss_bytes", "pre-stop")):
                peak = ("finalization_peak_rss_bytes" if phase == "pre-stop"
                        else "sampled_peak_rss_bytes")
                values = [max(0, case[peak] -
                              case["phases"][phase]["rss_bytes"]) for case in cases]
                metrics[key] = {"median": statistics.median(values),
                                "min": min(values), "max": max(values)}
            rows.append({"label": label, "seconds": seconds,
                         "successful_repetitions": len(cases), "metrics": metrics})
    return rows


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--baseline", type=Path, required=True)
    parser.add_argument("--candidate", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--repetitions", type=int, default=3)
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    roots = {"baseline": args.baseline.resolve(), "candidate": args.candidate.resolve()}
    metadata = {"host": platform.platform(), "machine": platform.machine(),
                "revisions": {}, "limitations": [
                    "Synthetic recorder; no microphone or native device allocation.",
                    "Timer samples may miss synchronous allocation peaks.",
                    "Process maximum RSS includes startup and warmup.",
                    "Materiality requires review of the raw phase evidence."]}
    for label, checkout in roots.items():
        sha = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=checkout,
                                      text=True).strip()
        source = checkout / "apps/auravibes_app/lib/features/chats/services/local_chat_attachment_service_io.dart"
        probe = checkout / "apps/auravibes_app/test/performance/voice_recording_memory_test.dart"
        metadata["revisions"][label] = {
            "sha": sha, "service_sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
            "probe_sha256": hashlib.sha256(probe.read_bytes()).hexdigest(),
            "fvm": json.loads((checkout / ".fvmrc").read_text())}
    (output / "metadata.json").write_text(json.dumps(metadata, indent=2))
    records = []
    try:
        for seconds in (5, 30, 120):
            for repetition in range(1, args.repetitions + 1):
                for label, checkout in roots.items():
                    records.append(run_case(checkout, output, label, seconds,
                                            repetition, False))
                    (output / "results.json").write_text(json.dumps(records, indent=2))
            for label, checkout in roots.items():
                if seconds == 120:
                    records.append(run_case(checkout, output, label, seconds, 1, True))
                    (output / "results.json").write_text(json.dumps(records, indent=2))
    finally:
        (output / "summary.json").write_text(json.dumps(summarize(records), indent=2))
    return 0 if records and all(record["status"] == "passed" for record in records) else 1


if __name__ == "__main__":
    sys.exit(main())

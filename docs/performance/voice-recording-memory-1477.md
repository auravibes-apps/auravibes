# Voice recording memory evidence for #1477

Status: the hosted baseline completed successfully in
[run 41686488660](https://github.com/auravibes-apps/auravibes/actions/runs/41686488660).
All twenty cases passed in twenty distinct worker processes. The results support
the proposed materiality gate. A file writer requires coordinator approval.

The approved first stage measures the current macOS IO attachment service using
generated PCM. It retains the two-minute limit and changes no product code.
The local SDK link and validation lease are blocked. All execution belongs to
hosted CI; no local bootstrap, tests, or benchmarks should run for this work.

## Pinned recording format

`pubspec.lock` pins `record` 7.1.1, `record_platform_interface` 2.1.0, and
`record_macos` 2.1.1. The pinned package archives confirm these source facts:

- [record_platform_interface 2.1.0 archive](https://pub.dev/api/archives/record_platform_interface-2.1.0.tar.gz),
  `lib/src/types/record_config.dart`, defaults `sampleRate` to 44,100.
- [record_macos 2.1.1 archive](https://pub.dev/api/archives/record_macos-2.1.1.tar.gz),
  `macos/record_macos/Sources/record_macos/delegate/AudioStreamProcessor.swift`,
  creates its PCM16 output `AVAudioFormat` at `Double(config.sampleRate)`.

The app requests `pcm16bits` and one channel. The probe asserts the actual
`RecordConfig` passed by the unchanged service, checks every WAV header field
and PCM byte, and independently decodes the output with Python's `wave` module.
The workflow records hashes and rate-related lines from the resolved packages.
This verifies the configured stream output, not a physical microphone's rate.

At this format, 5, 30, and 120 seconds contain 441,000, 2,646,000, and 10,584,000
PCM bytes. WAV adds 44 bytes. These sizes are calculations, not measurements.

## Reproduction

The scoped `Voice recording memory evidence` workflow runs on the issue PR.
The baseline is immutable commit `f00fc7b9159cc35713db498ad319200a5ed4052e`.
The candidate is the immutable PR head SHA. Both execute sequentially on one
`macos-15` runner with the same pinned Flutter SDK, lockfile, and probe hash.
Each case starts a fresh Flutter test process, warms the service, removes its
warmup draft, and then measures one recording. The runner interleaves baseline
and candidate cases to reduce ordering effects.

The completed baseline compared that reference with probe revision
`3f85acb7b69f1262ca45bc1d07e3e4aff1e4f284`. Both revisions contain identical
product recording code. The probe revision provides a repeatability check.
Flutter was 3.47.9, Dart was 3.13.7, and the hosted runner was macOS 15 arm64.

The product recording service SHA-256 was identical in both checkouts:
`6d411f89d5f5ff53fcb19ce8dddd19454ce2f6683e5125c9ec837c03dc5ea3b2`.
Both used probe SHA-256
`994169ec7a477dc05481635da664af6be11f2ee3e69950d5467265d80c1241df`
and lockfile SHA-256
`a9de2d11d5c370729a26c416ae5bf28ae4595bdbf8a51d4fd2ddca09a84acba7`.

After the workflow is registered on the default branch, a manual equivalent is:

```sh
gh workflow run voice-recording-memory.yml --ref codex/issue-1477-voice-memory \
  -f baseline=f00fc7b9159cc35713db498ad319200a5ed4052e
```

The hosted orchestration command is:

```sh
python3 tool/voice_recording_memory.py \
  --baseline baseline --candidate . --output "$RUNNER_TEMP/voice-recording-memory"
```

It runs three repetitions each at 5, 30, and 120 seconds for both revisions,
then one irregular-packet 120-second case per revision. Each invocation uses:

```sh
flutter test test/performance/voice_recording_memory_test.dart --no-pub \
  --concurrency=1 --reporter=expanded --enable-vmservice \
  --dart-define=VOICE_MEMORY_PROBE=true \
  --dart-define=VOICE_MEMORY_SECONDS=120 \
  --dart-define=VOICE_MEMORY_IRREGULAR=false
```

`VOICE_MEMORY_OUTPUT` must name the case's artifact prefix. Normal test runs skip
this opt-in probe. `--enable-vmservice` is required for runtime heap queries;
Flutter's default test worker does not expose the VM service. The simulated
stream emits fresh 20 ms PCM packets in real
time and never preloads an entire recording. Validation, byte comparison,
hashing, independent decoding, and draft deletion occur after the measured
capture/finalization interval.

## Evidence and interpretation

The artifact retains requested revisions and runner identity, resolved source
evidence, probe/service hashes, per-case commands and exit state, logs, raw JSONL
samples, results, and median/range summaries. Upload uses `if: always()`;
timeouts and failed cases retain partial evidence. Capture takes about twenty
minutes for the complete matrix, plus setup.
The matrix stops at its first failed worker and saves its partial summary,
so a runtime setup failure cannot consume the entire capture budget.
Per-case phase results and the summary also appear in the job log as
`VOICE_MEMORY_RESULT` and `VOICE_MEMORY_SUMMARY` records, so an artifact download
failure does not hide the phase evidence.

The probe samples process RSS and VM heap/external memory at roughly 10 ms,
with explicit idle, recording-started, pre-stop, and finalized snapshots. It
also records process maximum RSS before post-capture file validation. Review
raw phase evidence because timer samples can miss synchronous allocations and
process high water includes startup/warmup. Report masked peaks as inconclusive.
Heap/external samples support attribution; they do not establish a continuously
observed exact peak or bound native/plugin memory.

The proposed gate requires a repeatable source-attributed peak of at least
8 MiB above warmed idle at 120 seconds across three fresh workers. Review the
duration trend, phase samples, and whole-process high-water history before
applying it. This synthetic source measures the actual Dart finalization path;
it excludes microphone/device/native allocations. No product writer work may
start until the coordinator reviews the recorded baseline evidence.

## Completed baseline results

Each regular row contains three fresh-worker repetitions. Memory values are
MiB and use `median [minimum, maximum]`. Stop time is the median in milliseconds.
Finalization increments compare the pre-stop snapshot with the finalization
peak RSS or the finalized heap snapshot. The broader idle-relative RSS varies
more because it includes capture, VM sampling, and garbage collection.

| Revision | Seconds | Peak RSS above idle | Finalization RSS increase | Finalization heap increase | Stop ms |
| --- | ---: | --- | --- | --- | ---: |
| Reference `f00fc7b91` | 5 | 12.11 [11.44, 15.39] | 3.47 [2.33, 3.73] | 1.11 [1.08, 1.11] | 15.29 |
| Reference `f00fc7b91` | 30 | 40.28 [34.83, 42.80] | 7.67 [7.63, 10.14] | 5.30 [5.28, 5.33] | 18.24 |
| Reference `f00fc7b91` | 120 | 80.72 [55.64, 80.97] | 34.34 [34.34, 34.34] | 20.46 [20.45, 20.46] | 31.97 |
| Probe `3f85acb7b` | 5 | 14.16 [12.92, 15.33] | 3.83 [2.09, 5.08] | 1.09 [1.08, 1.12] | 10.55 |
| Probe `3f85acb7b` | 30 | 47.28 [41.14, 47.39] | 7.63 [7.63, 10.14] | 5.28 [5.28, 5.28] | 13.93 |
| Probe `3f85acb7b` | 120 | 78.63 [78.33, 81.97] | 34.33 [34.33, 34.34] | 20.45 [20.45, 20.45] | 27.64 |

At 120 seconds, finalization established a new process RSS high water in all
six regular recordings. Startup did not hide this increase. Heap growth during
finalization was about 20.45 MiB, close to the two complete 10.09 MiB PCM/WAV
payloads in the inspected source. The repeatable phase increase exceeds 8 MiB
and supports proceeding with the bounded writer, subject to coordinator review.

The two additional 120-second irregular-packet cases also passed. Both added
34.34 MiB RSS during finalization. Their WAV hashes matched every other
120-second output. All outputs decoded as 44,100 Hz, one channel, two-byte
samples. Output lengths were 441,044, 2,646,044, and 10,584,044 bytes for the
three durations. Every case left zero owned files after cleanup.

The complete per-case phase results are committed in
[voice-recording-memory-1477-baseline.json](./voice-recording-memory-1477-baseline.json).
Raw JSONL samples, worker logs, commands, revisions, resolved source evidence,
and summaries are retained in
[artifact 13257766564](https://github.com/auravibes-apps/auravibes/actions/runs/41686488660/artifacts/13257766564).
Artifact download returned HTTP 403 in the agent environment; the committed
case records were extracted from the hosted job's result log records.

Optimization results remain pending. Product recording code is unchanged.

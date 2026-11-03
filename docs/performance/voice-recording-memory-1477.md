# Voice recording memory evidence for #1477

Status: measurement preparation. No hosted measurement has completed, and no
product implementation is approved. This note must not be read as a measured
performance claim.

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
  --concurrency=1 --reporter=expanded \
  --dart-define=VOICE_MEMORY_PROBE=true \
  --dart-define=VOICE_MEMORY_SECONDS=120 \
  --dart-define=VOICE_MEMORY_IRREGULAR=false
```

`VOICE_MEMORY_OUTPUT` must name the case's artifact prefix. Normal test runs skip
this opt-in probe. The simulated stream emits fresh 20 ms PCM packets in real
time and never preloads an entire recording. Validation, byte comparison,
hashing, independent decoding, and draft deletion occur after the measured
capture/finalization interval.

## Evidence and interpretation

The artifact retains requested revisions and runner identity, resolved source
evidence, probe/service hashes, per-case commands and exit state, logs, raw JSONL
samples, results, and median/range summaries. Upload uses `if: always()`;
timeouts and failed cases retain partial evidence. Capture takes about twenty
minutes for the complete matrix, plus setup.
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

| Duration | Repetitions | Idle-relative peak RSS | Finalization RSS increase | Peak heap/external | Stop time | Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| 5 seconds | Pending | Pending | Pending | Pending | Pending | Pending |
| 30 seconds | Pending | Pending | Pending | Pending | Pending | Pending |
| 120 seconds | Pending | Pending | Pending | Pending | Pending | Pending |

Decision: pending hosted results and phase review. No optimization or memory
reduction has been claimed. Before/after results will name both immutable
revisions and the artifact URL; a future writer requires separate approval.

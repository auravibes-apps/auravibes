# Engine benchmarks

Run the deterministic tool and skill context benchmark from
`packages/auravibes_engine` with the installed SDK pinned in `.fvmrc`:

```sh
python3 ../../tool/validation_lease.py --label context-benchmark -- \
  fvm dart run benchmark/agent_context_assembly_benchmark.dart
```

The inputs are synthetic catalogs generated from fixed indexes. The benchmark
uses 10, 50, 100, 500, and 1,000 tools and the same number of skills. Every tenth
skill is loaded. Every twentieth skill also appears in the conversation's
loaded skills, so composition exercises identity deduplication.

Each size gets five warm-up iterations and fifteen measured iterations in the
Dart VM with JIT compilation. The reported latency is the median assembly time.
Assembly includes tool-spec and candidate construction, stable tool naming,
tool-catalog construction, skill conversion, catalog sorting and revision
hashing, XML escaping, and skill-message composition.

Synthetic input generation happens before timing. JSON encoding and UTF-8 byte
counting of the final benchmark envelope happen after timing. Skill-catalog
serialization and revision hashing remain inside the timed assembly. The final
serialized envelope contains tool names,
descriptions, and input schemas, plus skill-message roles, content, and metadata.
Each measured iteration checks that the entire serialized envelope is unchanged.
The benchmark does not construct a provider request or include transcript history,
VM startup, catalog I/O, network calls, or model calls in its measurements.

The byte count measures the benchmark envelope. It is not a model token estimate,
a context-window limit, or a per-request usage or cost measurement. Provider
request encoding and model tokenization can produce different sizes.

## Recorded baseline

Collected on 2026-10-31 at 23:53 UTC in
[Actions run 41253092704, attempt 1](https://github.com/auravibes-apps/auravibes/actions/runs/41253092704/attempts/1)
from commit `005a6238b722159287eb4c559cf967cc6ff49737`. The runner used Ubuntu
24.04.5, kernel `7.0.0-1017-azure`, x86_64, an AMD EPYC 7763 processor with four
logical CPUs, Flutter 3.47.9, and Dart 3.13.7. Each of five sequential fresh JIT
processes used the fixed inputs and produced identical serialized byte counts.
The table shows the range of their five median assembly times:

| Tools | Skills | Loaded skills | Minimum median assembly (µs) | Maximum median assembly (µs) | Serialized context (bytes) |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 10 | 10 | 1 | 1,196 | 2,077 | 5,033 |
| 50 | 50 | 5 | 1,866 | 3,106 | 23,665 |
| 100 | 100 | 10 | 2,530 | 2,841 | 46,955 |
| 500 | 500 | 50 | 7,785 | 8,145 | 235,835 |
| 1,000 | 1,000 | 100 | 16,114 | 17,296 | 471,935 |

The [baseline CSV](baselines/agent_context_assembly_baseline.csv) preserves all
25 original data rows with only a run-number column added. The
[provenance file](baselines/agent_context_assembly_provenance.txt) preserves the
captured source commit/blob, command, SDK, CPU/kernel, and run identifiers.
The benchmark source blob is `dbb4f8385a39c0590f3a4c4229ce380194b812c3`.
The [original artifact](https://github.com/auravibes-apps/auravibes/actions/runs/41253092704/artifacts/13061669116)
contains five untouched stdout CSVs, five empty stderr files, and provenance.
It has 30-day retention; the checked-in CSV and provenance remain available.
Its ZIP SHA-256 is `c3756eaa5a9b7c28d61b91da2993ad2910c184ccc3d6bc5f71945d93db8c76bd`.

The automated executable contract test checks the reported counts and byte
sizes across two independent processes. It does not compare latency values.

## Refreshing the baseline

Run five fresh processes sequentially with the command above and preserve each
process's original CSV output. Record the collection date, benchmark source
commit, `fvm dart --version`, Flutter pin, OS/kernel, CPU model, logical CPU count,
and architecture. Keep the fixture sizes, warm-up count, measured iteration
count, and JIT invocation mode fixed. Combine the data rows into a CSV with
header `run,tools,skills,loaded_skills,median_assembly_us,serialized_context_bytes`,
adding only the run number to each original row. Report each catalog size's
minimum and maximum of the five process medians alongside the raw measurements.
Other hosts can reproduce the inputs and procedure; latency depends on the host.

To capture on hosted CI, manually dispatch `ci.yml` on the source branch with
`capture_context_benchmark=true`. The existing format job captures five fresh
runs after workspace setup and uploads the raw output and provenance before
format checks. Ordinary push and pull-request runs do not capture baselines.

## CI timing policy

There is no latency threshold. Five fresh runs on one shared host cannot
establish stable latency across CI runners. JIT warm-up and
host scheduling can change the medians. A future latency gate needs a controlled
runner and repeated measurements of between-run variability. Deterministic
catalog counts and serialized sizes are checked without a latency ceiling.

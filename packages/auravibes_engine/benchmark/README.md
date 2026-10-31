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

The baseline preserved from commit `2dcc8fff81ef27495837136bb627e0e0904dbdae`
was collected on 2026-10-31 on Linux x86_64 with Dart SDK 3.13.7. Its benchmark
source has Git blob ID `dbb4f8385a39c0590f3a4c4229ce380194b812c3`. Two consecutive
runs used the same fixed inputs and produced identical serialized byte counts:

| Tools | Skills | Loaded skills | Median assembly, run 1 (µs) | Median assembly, run 2 (µs) | Serialized context (bytes) |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 10 | 10 | 1 | 829 | 792 | 5,033 |
| 50 | 50 | 5 | 1,476 | 1,533 | 23,665 |
| 100 | 100 | 10 | 2,076 | 2,003 | 46,955 |
| 500 | 500 | 50 | 7,317 | 6,845 | 235,835 |
| 1,000 | 1,000 | 100 | 14,340 | 13,248 | 471,935 |

The original record did not include the CPU model, logical CPU count, kernel
version, or original stdout files. Treat these timings as a historical comparison
with incomplete host provenance. The automated executable contract test checks
the reported counts and byte sizes across two independent processes. It does
not compare their latency values.

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

## CI timing policy

There is no latency threshold. Two historical runs, or five fresh runs on one
shared host, cannot establish stable latency across CI runners. JIT warm-up and
host scheduling can change the medians. A future latency gate needs a controlled
runner and repeated measurements of between-run variability. Deterministic
catalog counts and serialized sizes are checked without a latency ceiling.

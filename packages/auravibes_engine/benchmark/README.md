# Engine benchmarks

Run the deterministic tool and skill context benchmark from this package:

```sh
fvm dart run benchmark/agent_context_assembly_benchmark.dart
```

The inputs are synthetic catalogs generated from fixed indexes. Each size gets
five warm-up iterations and fifteen measured iterations; the reported latency
is the median assembly time. Assembly includes constructing tool specs and the
tool catalog, plus composing the skill catalog and loaded skill context. The
serialized size is measured after timing as UTF-8 JSON bytes for those tool
specs and context messages. Each iteration checks that the serialized context
is unchanged.

The byte count is a size measure only. It is not a model token estimate or a
per-request usage or cost measurement.

## Baseline

Collected 2026-10-31 on Linux x86_64 with Dart SDK 3.13.7. Two consecutive runs
used the same fixed inputs and produced identical serialized byte counts:

| Tools | Skills | Loaded skills | Median assembly, run 1 (µs) | Median assembly, run 2 (µs) | Serialized context (bytes) |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 10 | 10 | 1 | 829 | 792 | 5,033 |
| 50 | 50 | 5 | 1,476 | 1,533 | 23,665 |
| 100 | 100 | 10 | 2,076 | 2,003 | 46,955 |
| 500 | 500 | 50 | 7,317 | 6,845 | 235,835 |
| 1,000 | 1,000 | 100 | 14,340 | 13,248 | 471,935 |

The shared runner produced noticeable timing variation between consecutive
runs, so these measurements are a reproducible baseline for comparison rather
than a CI threshold.

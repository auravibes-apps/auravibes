# Context assembly benchmark implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. The issue implementer executes in this existing worktree; the parent dispatches a separate reviewer after implementation. Do not create nested agents.

**Goal:** Complete issue #1406 with a deterministic, offline benchmark of tool and skill context assembly, a checked output contract, and a reproducible baseline.

**Architecture:** Preserve the standalone pure Dart benchmark from commit `2dcc8fff81ef27495837136bb627e0e0904dbdae`. It exercises the engine's existing `buildToolCatalog<int>` and `BuildSkillContextMessages.compose` APIs with synthetic catalogs, then serializes a benchmark-specific context envelope outside the timed region. Add a process-level smoke test and baseline documentation without changing engine runtime behavior or public APIs.

**Tech stack:** Pinned Flutter 3.47.9 and its Dart SDK, `dart:io`, `dart:convert`, existing engine APIs, and `package:test`. No added dependencies.

**Spec:** https://github.com/auravibes-apps/auravibes/issues/1406 and its agent-brief comment.

## Global constraints

- "Add a deterministic benchmark using synthetic tool and skill catalogs of increasing sizes."
- "Measure context assembly latency and serialized output size, without network or model calls."
- "Record a reproducible baseline; add a CI threshold only if the measurements are stable enough to avoid noise."
- "Results distinguish assembly performance from model token budgets and per-request usage/cost tracking."
- Keep the engine pure Dart and use its supported exports. Do not change production context assembly for this issue.
- Preserve the existing isolated worktree `/workspace/auravibes-agent-worktrees/issue-1406`, branch `codex/issue-1406-context-benchmark`, and existing implementation commit.
- Run local Dart setup and verification through `tool/validation_lease.py` with the repository's pinned FVM SDK.
- Project bootstrap already passed. Do not bootstrap, reinstall Flutter, or wait for bootstrap. Use the installed pinned SDK and confirm or set its FVM link if needed. If that SDK is unavailable, report the concrete blocker and continue work that does not require it.
- Parent plan review precedes implementation; parent-arranged code review precedes PR creation.

## Existing implementation assessment

The worktree is clean at `2dcc8fff`, one commit ahead of baseline `f00fc7b9`. The existing commit adds only `packages/auravibes_engine/benchmark/agent_context_assembly_benchmark.dart` and its README. There is no prior issue-specific plan.

The benchmark generates catalogs of 10, 50, 100, 500, and 1,000 tools and the same number of skills from fixed indexes. Every tenth skill is loaded. Every twentieth also appears in conversation skills, so composition exercises identity deduplication. Tool schemas have fixed `record_id` and `limit` properties. Synthetic input generation happens before timing.

Each catalog gets five warm-up assemblies and fifteen measured assemblies. Timing includes tool-spec/candidate construction, stable tool naming, catalog construction, skill conversion, catalog sorting/revision hashing, XML escaping, and skill-message composition. JSON encoding and UTF-8 byte counting happen after timing. Each measured iteration compares the entire serialized envelope to its first iteration and fails if it changes.

The CSV interface is already suitable. The README has a two-run baseline and a correct distinction between bytes, token estimates, and model usage/cost. Remaining work is to check the executable output contract and replace the baseline with freshly captured results and enough environment information to reproduce the procedure. Implementation checks have not run in this planning phase. A local `.fvm` link is missing, so execution must select the pinned SDK before validation.

## Review focus

- A new Dart process must use the same package configuration as the test and report all five catalog sizes; Task 1 checks successful process exits and exact row counts.
- Separate runs must preserve catalog counts and serialized sizes despite changing timings; Task 1 compares those columns across two processes.
- Accidentally omitted loaded skills or changed serialization must be observable; Task 1 checks loaded counts and the existing byte-size baseline.
- Timing noise must not cause CI failures; Task 1 accepts all nonnegative latency values and Task 2 explicitly omits latency gates.
- Readers must know the measured envelope is not a provider request or token budget; Task 2 documents timed work, serialized fields, exclusions, and interpretation.

---

### Task 1: Check the benchmark's executable contract

**Files:**
- Preserve: `packages/auravibes_engine/benchmark/agent_context_assembly_benchmark.dart`.
- Create: `packages/auravibes_engine/test/agent_context_assembly_benchmark_test.dart`.
- Inspect: `packages/auravibes_engine/lib/src/tool_catalog.dart`, `packages/auravibes_engine/lib/src/skill_context_messages.dart`.

**Interfaces:**
- Consumes: the benchmark executable's existing `void main()` and CSV header `tools,skills,loaded_skills,median_assembly_us,serialized_context_bytes`.
- Consumes: `buildToolCatalog<int>(Iterable<ToolCatalogCandidate<int>>) -> ToolCatalog<int>` and `BuildSkillContextMessages.compose(...) -> List<AgentChatMessage>` through the existing benchmark, with no production changes.
- Produces: one automated test named `reports deterministic context sizes across independent runs`, using `Process.run(Platform.resolvedExecutable, ['benchmark/agent_context_assembly_benchmark.dart'], workingDirectory: packageRoot)` twice sequentially. Resolve `packageRoot` from the test file's path so invocation from the repository root also works. Pass an explicit package configuration if the SDK invocation requires it.

- [x] **Step 1: Confirm the installed pinned SDK.** Check the installed SDK against `.fvmrc` and confirm or set its local FVM link if needed. Reuse the existing dependency resolution. Do not bootstrap, reinstall Flutter, wait for bootstrap, or change SDK pins or lockfiles to fit the host environment. If the installed pinned SDK is genuinely unavailable, report its expected and observed paths and continue the code and documentation work that does not depend on executing it.
- [x] **Step 2: Add the process-level contract test.** Assert that each process exits with code 0 and empty stderr, outputs the exact header and five data rows, and has five integer columns per row. Assert `(tools, skills, loaded_skills)` equals `(10,10,1)`, `(50,50,5)`, `(100,100,10)`, `(500,500,50)`, `(1000,1000,100)`. Assert serialized byte counts equal `[5033, 23665, 46955, 235835, 471935]` and strictly increase. Compare all count and byte columns between runs. Assert latency is nonnegative, without a ceiling or cross-run equality. Give the process test a two-minute timeout to cover cold VM startup on CI. Preserve failure stdout/stderr in assertion reasons.
- [ ] **Step 3: Run the focused test through the lease.** From `packages/auravibes_engine`, run `python3 "$(git rev-parse --show-toplevel)/tool/validation_lease.py" --label context-benchmark-test -- fvm dart test test/agent_context_assembly_benchmark_test.dart`. Expect one passing test. This characterizes existing implementation and may pass immediately; do not manufacture an implementation failure.
- [x] **Step 4: Inspect the benchmark call graph for offline execution.** Confirm it only constructs synthetic values and calls the two local engine assembly APIs. No model/provider, socket, HTTP, filesystem catalog lookup, or random/time-derived fixture input belongs in the benchmark. Fix only an issue proven by this check or the contract test, then rerun the affected check.
- [ ] **Step 5: Commit the contract test.** Use a focused Conventional Commit such as `test(agent): check context assembly benchmark output`.

### Task 2: Capture a reproducible baseline and document its limits

**Files:**
- Modify: `packages/auravibes_engine/benchmark/README.md`.
- Create: `packages/auravibes_engine/benchmark/baselines/agent_context_assembly_baseline.csv`.
- Update progress: this plan.

**Interfaces:**
- Consumes: unchanged benchmark CSV from Task 1.
- Produces: a raw baseline CSV with header `run,tools,skills,loaded_skills,median_assembly_us,serialized_context_bytes` and 25 rows, five process runs times five catalog sizes. Only `run` is added to the captured benchmark columns.
- Produces: documented baseline provenance and a summary of the observed range of the five per-process medians for each size.

- [ ] **Step 1: Capture environment provenance.** Record collection date, the commit containing the measured Dart source, exact Dart SDK version and FVM Flutter pin, OS/kernel, CPU model, logical CPU count, architecture, and invocation mode. Record that the command runs the Dart VM with JIT compilation and uses five warm-ups and fifteen samples per size. Do not claim that another machine will reproduce latency values.
- [ ] **Step 2: Run five independent processes sequentially through the validation lease.** From the engine package run `fvm dart run benchmark/agent_context_assembly_benchmark.dart` five times, with the lease wrapper shown in Task 1. Capture original stdout outside the repository until all runs finish, then combine their data rows into the baseline CSV with run numbers 1 through 5. Do not regenerate or average timings manually. Verify every run has the expected catalog/count/size columns and record the observed timing range.
- [ ] **Step 3: Replace the README baseline and explain measurement boundaries.** Show the leased run command from the engine directory, link the raw CSV, and document fixture sizes and loaded/deduplicated skill selection. State that the serialized envelope contains tool names/descriptions/input schemas and skill-message roles/content/metadata. State that synthetic input generation, JSON/UTF-8 serialization, VM startup, network/model calls, transcript history, provider request encoding, and service I/O are outside assembly timing. Explain that byte counts are not model token estimates, context-window limits, per-request usage, or cost. Include baseline provenance and per-size minimum/maximum of the five medians.
- [x] **Step 4: Document the CI decision.** Add no latency threshold or workflow change. Five runs on one shared host cannot establish stable cross-runner latency, and JIT warm-up and host scheduling can change medians. The automated contract test checks determinism and structural completeness without failing on timing noise. Future latency gates need a controlled runner and repeated measurements of between-run variability.
- [ ] **Step 5: Run final focused checks.** Run the new contract test and existing `test/tool_catalog_test.dart` and `test/build_skill_context_messages_test.dart` together through the lease. Run leased `fvm dart run melos run validate:changed` once after Dart edits settle, plus leased `fvm dart run tool/check_benchmark_imports.dart` from the repository root. Use `git diff --check` for the documentation and CSV patch. Expected results are passing focused tests, clean changed-file analysis/format, sorted benchmark imports, and no whitespace errors. Do not run a broad Dart suite for this package-local benchmark change.
- [ ] **Step 6: Commit and hand off.** Commit the measured CSV, README, and plan progress, report the final head and exact validation results to the parent, then wait for its independent review. Apply findings and rerun affected checks. Create a PR only after the parent explicitly reports the review is clean; the parent owns CI monitoring and merge.

## Plan self-review

The existing benchmark satisfies the deterministic catalogs, multiple sizes, offline execution, assembly latency, and output-size requirements. Task 1 adds executable regression coverage without changing production APIs or requiring stable timing. Task 2 supplies a captured baseline with provenance, records the reason to omit latency gates, and explains the distinction from token budgets and usage/cost. No UI, network integration, engine optimization, dependency, or CI workflow changes are required.

## Execution ledger

- Parent approved the revised plan on 2026-10-31. Existing benchmark commit is preserved. No bootstrap, Flutter installation, or SDK download is permitted.
- Pre-flight: Task 2 consumes the exact CSV contract characterized by Task 1. Header, catalog sizes, loaded counts, and byte counts agree with the existing implementation and README.
- Task 1: Confirmed installed Flutter 3.47.9 / Dart 3.13.7 from `/home/agent/fvm/versions/3.47.9/bin/cache/flutter.version.json` and created the ignored worktree-root `.fvm/flutter_sdk` link to that installation. Existing root package resolution includes the engine and `package:test`.
- Task 1: Added the executable process contract test. Ruling: Resolve the package root through `Isolate.resolvePackageUri`, which uses the active package configuration and works when tests start from the root or engine package. `Platform.script` under `dart test` can identify the test runner's generated script instead of the test source file.
- Task 1: The focused test command exited 3 in 0.2 seconds before Dart started. The validation lease reported 17.5 GiB available on the worktree volume and 3.0 GiB on `/tmp`, below its 20 GiB reserve. The test has not run. Do not bypass this reserve.
- Task 1: Static call-graph inspection found only fixed synthetic construction, `buildToolCatalog`, and `BuildSkillContextMessages.compose`. These call local hashing, sorting, escaping, and JSON helpers, with no network or provider execution.
- Task 2: Ruling: Preserve the existing two-run baseline and mark its missing CPU/kernel/original-stdout provenance explicitly while fresh capture is blocked. Do not create a CSV that claims to contain freshly captured samples. Five fresh runs and their raw CSV remain pending the validation prerequisite.
- Task 2: Current execution-host provenance, distinct from the historical baseline host, is Linux kernel 6.18.57, x86_64, AMD EPYC 9V74 80-Core Processor, 5 logical CPUs reported by Python. Benchmark source blob is `dbb4f8385a39c0590f3a4c4229ce380194b812c3`.
- Verification: `git diff --check` passed after the test and README edits. Dart tests, pinned formatting/analyzer, benchmark-import validation, and fresh baseline runs remain blocked by the lease prerequisite and are not reported as passing. The existing historical baseline is unchanged; no fresh CSV exists.

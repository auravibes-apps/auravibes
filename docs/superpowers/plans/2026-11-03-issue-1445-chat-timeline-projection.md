# Chat timeline projection performance plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement the approved plan task by task. Parent approved Task 1 only; the hosted baseline showed no material isolated projection cost, and the parent approved the benchmark/evidence-only outcome. Task 2 was not approved or implemented; do not add a projection cache. Parent will arrange an independent code review after implementation. Do not create nested agents.

**Goal:** Complete issue #1445 by measuring repeated derivation in the active chat timeline and optimizing only if the hosted baseline shows a material cost.

**Architecture:** The current `ChatMessagesWidget` resolves the effective message list, calls `ChatTimelineProjection.buildChatTimelineItems`, builds assistant response progress, scans for the retryable user message, and finds the focused item during a widget build. Begin with an opt-in deterministic benchmark around the pure projection path, which is the largest cohesive derivation and already has focused correctness tests. Capture its pre-optimization measurements on hosted CI. If measurements do not show meaningful repeated-prefix cost for representative large transcripts, document the result and stop without adding a cache. If they do, introduce a per-conversation incremental projection cache that preserves the full pure projection as a correctness oracle and falls back to a full rebuild whenever inputs cannot be safely localized.

**Tech stack:** Existing Flutter/Dart SDK, `flutter_test`, immutable `MessageEntity` and `ResolvedChatMessage` fixtures, `Stopwatch`, JSON output, and a temporary opt-in GitHub Actions capture used for the baseline and removed from the final PR. No new package dependency.

**Spec:** https://github.com/auravibes-apps/auravibes/issues/1445

## Global constraints

- Keep this issue about active chat timeline projection during streaming. Do not change conversation hydration, resume, cancellation, database watchers, model request assembly, search, or broad performance budgets. Those concerns are covered separately by #867 and #966.
- Profile before changing the projection. Capture a hosted baseline on the benchmark commit before any production optimization. Send the evidence and interpretation to the parent and wait for approval before implementing the conditional optimization.
- Do not add a timing-based CI pass/fail threshold from one hosted runner. Report the raw samples and runner provenance; propose a gate only if repeated hosted results establish a stable threshold.
- If the baseline shows that stable-prefix projection does not consume a meaningful part of the frame budget in representative workloads, make no production behavior change. Record the data and let the parent close or disposition the issue.
- Any cache must be isolated to the active conversation/widget lifetime. Do not put UI-derived state in a global provider, repository, or persisted model.
- Preserve message order and identity, Activity grouping and associations, `isStreaming`, retryability, focus/search target behavior, A2UI replay payload handling, rich responses, fork references, tool-call argument visibility, and response-action visibility.
- Invalidate or fall back to the existing full projection when message insertion/removal/reordering, an edit, late metadata, streaming-state change, replay payload change, pending-tool-key change, focused target change, or any other input change cannot be safely updated locally.
- Verify optimized output against the full projection for every covered update scenario. If detection/copy costs erase the measured benefit, remove the optimization and retain only the benchmark evidence.
- Use only the dedicated worktree `/workspace/auravibes-agent-worktrees/issue-1445` on `codex/issue-1445-streaming-timeline`; do not edit the primary checkout or another issue worktree.
- The required preflight found no competing branch, worktree, or PR, but reports that the local `.fvm/flutter_sdk` symlink does not match `.fvmrc`. The user has directed us to continue through hosted CI while the local validation lease is blocked. Do not change the SDK symlink, bootstrap, delete files/caches, or bypass the lease. Do not run local Dart/Flutter checks; use hosted CI for the benchmark and validation.
- The worktree starts at `origin/main` `23e8c5c31d9d15e9acf7799a364ae77a4014faf5`. Preserve unrelated work and inspect `git status --short` before and after changes.

## Current code assessment

- `ChatTimelineProjection.buildChatTimelineItems` in `apps/auravibes_app/lib/features/chats/models/resolved_chat_message.dart` scans each resolved message and builds timeline/activity items. Existing correctness coverage is in `apps/auravibes_app/test/features/chats/models/chat_timeline_projection_test.dart`.
- `ChatMessagesWidget` in `apps/auravibes_app/lib/features/chats/widgets/chat_messages_widget.dart` invokes the projection on each build, then derives assistant response progress, retry eligibility, focus position, and reversed display order. The first benchmark should isolate projection time; it must not claim to represent database hydration, full Flutter layout, or total frame time.
- Existing app benchmarks use opt-in tests, deterministic synthetic inputs, warm-ups, repeated samples, JSON output, and hosted capture artifacts. `.github/workflows/ci.yml` already has manual benchmark capture inputs and artifact upload patterns.
- Related #867 is about transcript hydration/resume, cancellation, and watcher scope. #966 is about broad production performance budgets. Neither should be implemented or claimed by this issue.

## Review focus

- Does the benchmark isolate full projection cost from fixture generation, database I/O, and unrelated widget layout?
- Does the workload include realistic message boundaries and activity mixtures, while varying only the streamed tail during update samples?
- Is the baseline captured before production optimization on the exact commit and linked to raw hosted artifacts?
- Is any optimization introduced only after the measured cost justifies it?
- Does incremental handling match full projection for list shape changes, message edits, metadata changes, and global options?
- Are fallback paths explicit, and do they preserve correctness when the cache cannot localize a change?
- Are timing observations reported as runner-specific evidence rather than a general device guarantee?

---

## Task 1: Add an opt-in deterministic timeline benchmark

**Files:**

- Create `apps/auravibes_app/test/features/chats/models/chat_timeline_projection_benchmark_test.dart`.
- Modify `.github/workflows/ci.yml` with an opt-in `capture_chat_timeline_benchmark` workflow-dispatch input and capture step/job following the existing MCP/context benchmark artifact conventions.
- Create a short `docs/research/chat-timeline-projection-benchmark.md` only after hosted output exists; the first plan/baseline commit must not include fabricated measurements.

**Interface and workload:**

- The test is skipped unless `AURAVIBES_CHAT_TIMELINE_BENCHMARK=1` is set by the opt-in capture job. The ordinary CI suite must not acquire a timing gate or a material runtime increase.
- Build deterministic immutable fixtures outside the timed region for 100, 1,000, and 5,000 messages. Use fixed timestamps and stable IDs; mix user boundaries, assistant text, thinking/tool activity, rich/A2UI responses, fork references, and compaction boundaries in a fixed repeatable pattern.
- Record the first projection separately, then measure warmed repeated rebuilds and streaming-tail updates with an unchanged prefix. For each update, replace only the terminal source/message with its next immutable streamed version and call the production projection. Keep input construction, assertion work, JSON encoding, and report generation outside the timed interval.
- Use two warm-up iterations and fifteen measured samples per case. Emit one JSON record with raw samples, median, nearest-rank p95, OS/architecture, Dart/Flutter versions, source revision, workflow/run IDs, message count, and case name. Timing values are informational and never asserted against a fixed threshold.
- Preserve an output sink/checksum and assert expected timeline item/run/message counts so the optimizer cannot discard the projection or benchmark an empty result.

**Hosted capture behavior:**

- The manual workflow capture must verify that checkout `HEAD` equals `GITHUB_SHA`, record the source file blob SHA and runner/Flutter environment, run the opt-in test with `--reporter=expanded`, retain logs and validated JSON records, and upload a short-lived artifact.
- Capture the baseline after this task's benchmark-only commit and before any production projection change. Capture follow-up after any optimization using the same workflow and workload. Record both exact SHAs and artifact URLs in the evidence document.
- Validate schema, expected case count, sample count, nonnegative timing values, and unchanged output checksums. Fail capture validation for missing/malformed evidence, not for slow timings. The manual capture must not be a required status check or change normal PR gating.

**Steps:**

- [x] Add the gated benchmark harness and verify its fixtures include relevant timeline/activity categories without database or network setup.
- [x] Use a temporary manual hosted-capture path and evidence validation; remove the capture-only workflow changes from the final PR.
- [x] Open the benchmark-only PR and trigger the baseline capture on exact commit 0aaddfce7a200ed1e09aead2eed5897766e717d8; required PR CI remains pending.
- [x] Review the baseline raw samples and cost scaling with the parent; the parent approved no cache because the isolated projection cost was not material.
- [x] Record the no-cache conclusion and exact hosted evidence with no production code changes.

## Task 2: Optimize only a measured stable-prefix bottleneck

**Disposition:** Not performed. The hosted baseline did not establish a material isolated projection bottleneck, and the parent approved the benchmark/evidence-only outcome.

**Files, only if the parent approves the baseline:**

- Modify `apps/auravibes_app/lib/features/chats/models/resolved_chat_message.dart` or add a narrowly scoped projection-cache model beside it.
- Modify `apps/auravibes_app/lib/features/chats/widgets/chat_messages_widget.dart` only to own/reset the cache per workspace/conversation and pass current immutable inputs. Keep the rest of the screen derivation unchanged unless the benchmark separately demonstrates it is material.
- Extend `apps/auravibes_app/test/features/chats/models/chat_timeline_projection_test.dart` and add any focused widget regression only where required to exercise cache ownership/reset.

**Behavior:**

- Keep the current `buildChatTimelineItems` full projection as a stateless reference path and fallback. Add incremental reuse only for the workload proven hot by Task 1.
- Cache derived facts/output at stable message identity, incorporating every relevant immutable source field, `isStreaming`, replay payloads, pending tool-call visibility, and focused target state. New widgets/conversations must not inherit cached data across workspace, conversation, or a different source list.
- Recompute the changed suffix and any neighboring entries whose Activity boundary/final-response classification depends on the changed row. Handle null placeholders, message ID collisions, edits, insertions/removals, reordering, and late A2UI/tool/compaction metadata. If identity or invalidation cannot be proven, call the existing full projection.
- Emit current `ResolvedChatMessage` sources and preserve the exact ordering, item/run grouping, response flags, tool-call grouping, and focus/search results from the full path. Do not retain stale streaming wrappers or entries after updates.
- Do not add a custom hash that walks the full content/metadata of every message on every build. If the cache requires a full deep comparison, measure that cost; if it erases the improvement, retain the simple full projection.

**Tests:**

- Compare incremental output to full projection after each deterministic streamed-tail chunk; assert message IDs, item types, source message identity, Activity run boundaries, narrative/thinking/response/tool entries, and response-action flags.
- Cover append, removal, insertion/reorder, edit to an earlier message, content/status/streaming transition, late tool-call/A2UI/attachment/compaction metadata, replay payload changes, pending-tool-call key toggles, and search-target changes.
- Verify switching workspace/conversation resets cache state and an unsupported/global input change uses the full fallback.
- Retain the existing full-projection tests as an independent behavior oracle; add no expected-value snapshots that merely reuse incremental output.

**Steps:**

- [ ] Implement the smallest cache surface supported by the approved evidence. Preserve the pure full path and document invalidation/fallback conditions in code.
- [ ] Add tests for every listed update class; compare against a newly recomputed full projection after every update.
- [ ] Run the hosted focused tests and standard CI; address failures without local lease bypass.
- [ ] Capture follow-up benchmark evidence on the exact final head using the same hosted workflow input and workload as baseline.
- [ ] If update detection or cache management does not reduce the measured cost, remove the cache and report the benchmark-only outcome.

## Task 3: Evidence, review, and PR delivery

**Files:**

- Create or update `docs/research/chat-timeline-projection-benchmark.md` with baseline/follow-up results and limitations.
- No UI screenshot is planned: this issue must not change visual behavior. If implementation changes visible UI or screenshots/goldens, pause and add same-route before/after evidence to the PR.

**Steps:**

- [x] Document the exact baseline commit, workflow-run/artifact link, Flutter/Dart version, runner OS, workloads, warm-ups/sample count, medians/p95/raw samples, and total-rendering limitation.
- [x] Record the parent-approved no-cache decision and add no timing thresholds.
- [ ] Review the final diff against `origin/main` for behavior scope, cache invalidation correctness, stale item references, unnecessary allocations, code complexity, and absence of unrelated transcript/provider changes.
- [ ] Parent arranges an independent review. Address every finding and repeat the affected hosted tests/review until no actionable findings remain.
- [x] Create PR #1790 referencing Closes #1445 with baseline evidence, scope, and the hosted-only validation note. Codex artifact attachment confirmation is pending.
- [ ] Wait for hosted CI. Parent merges only after the exact current head is reviewed, all required checks are green, `mergeStateStatus` is `CLEAN`, the local review checkout matches that head, and no approval requirement remains.

## Verification commands

Do not execute locally while the validation lease/setup is blocked. Hosted CI should run the focused projection correctness tests and regular PR gates. The temporary manual capture workflow used for the baseline has been removed from the final PR; set the benchmark environment variable in a hosted job to run it again:

```bash
# Hosted CI correctness coverage
flutter test test/features/chats/models/chat_timeline_projection_test.dart --no-pub

# Hosted CI opt-in baseline/follow-up capture only
AURAVIBES_CHAT_TIMELINE_BENCHMARK=1 \
  flutter test test/features/chats/models/chat_timeline_projection_benchmark_test.dart \
  --no-pub --reporter=expanded
```

The local validation lease blocker is the existing `.fvm/flutter_sdk` mismatch against `.fvmrc`. Do not attempt these commands locally, modify that symlink, bootstrap, or delete caches. Report hosted CI run links and exact status instead.

## Execution record

- [x] Read issue #1445, related #867 and #966, app architecture instructions, CI parity/policy, existing timeline projection, widget call site, existing timeline tests, and opt-in benchmark/capture patterns.
- [x] Required preflight found no matching branch, worktree, or PR. It reported the existing pinned Flutter SDK symlink mismatch; no SDK/bootstrap/validation action was performed.
- [x] Created dedicated clean worktree `/workspace/auravibes-agent-worktrees/issue-1445` on `codex/issue-1445-streaming-timeline` from `origin/main` at `23e8c5c31d9d15e9acf7799a364ae77a4014faf5`.
- [x] No production source was edited and no local tests or analyzers were run during planning.
- [x] Parent reviewed and approved the plan, with Task 1 only authorized. The hosted baseline was reviewed; Task 2 was not approved because the isolated projection cost was not material.
- [x] Added the opt-in synthetic benchmark test; its temporary manual capture workflow was removed before the final PR. No production projection/cache code was changed.
- [x] `git diff --cached --check` passed. No Flutter/Dart tests or analyzers were run locally because the validation lease/setup is blocked and the user directed use of hosted CI.
- [x] Hosted baseline correctness and capture completed; raw evidence was recorded and parent approved no cache.
- [x] Removed temporary capture-only workflow changes from the final PR.
- [ ] Final hosted PR checks and parent review; the current PR head is tracked on #1790.

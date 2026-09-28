# CI Reliability and Failure Diagnostics Design

**Date:** 2026-09-24
**Status:** Written spec; awaiting review
**Scope:** GitHub Actions test execution, changed-test runner diagnostics, Flutter widget-test timeout configuration

## Intent

Improve AuraVibes CI diagnosis and prevent hung Flutter widget tests from consuming ten minutes each. Work only in the dedicated CI worktree. Preserve the existing PR #999 worktree, reasoning-feature behavior, required quality gates, test selection safety, and coverage policy.

## Observed Evidence

- PR #999 head `5efe217d4156054c3ee94fffba66a04b7f31dc9a`, run `35993275875`, failed analysis and all three app test shards. App shard durations were 14:09, 24:39, and 31:51. App shard 2 logged 34 failed tests, including missing-widget finders.
- Three widget tests each reached Flutter's ten-minute timeout: `compact_agent_selector_test.dart` / “sheet mode updates when agents arrive after mount”; `chat_list_widget_test.dart` / “shows error state when stream has error”; and `conversation_tool_tile_test.dart` / “workspace-enabled”. Each test file uses `tester.runAsync` around widget pumping. This is correlation, not proof of the hang cause.
- The selector passes `--timeout=30s`. Flutter's `testWidgets` supplies an explicit `binding.defaultTestTimeout`; `AutomatedTestWidgetsFlutterBinding` defaults it to ten minutes. That explicit per-test timeout takes precedence over the CLI default. The current command therefore does not impose its intended 30-second ceiling on widget tests.
- Successful main run `34244680672` had app shards at 13:22, 14:22, and 13:53. It predates timing-artifact generation and has no `test-timings` artifact. The current test plan reported no usable historical timings and used fixed shards. Current evidence points to the three ten-minute stalls—not demonstrated shard imbalance—as the major runtime increase.
- Other Finder/assertion failures are real test failures. They remain failures; this design does not classify them as infrastructure noise or weaken analysis/format/test gates.

## Design

### 1. Align widget-test timeout with CI policy

Configure one private shared timeout helper under `tool/testing/`, called from each Flutter test package's `test/flutter_test_config.dart`. When `CI=true`, set the automated Flutter binding's default widget-test timeout to 30 seconds, matching the existing selector command. Preserve local defaults and any test's explicit timeout override. Keep the app's existing localization logger configuration. Add thin config entrypoints for `packages/auravibes_ui` and `widgetbook`, the other workspace packages using `flutter_test`; leave Dart-only packages unchanged.

This makes the existing CI policy effective across Flutter test packages; it does not claim to fix the underlying hangs. After this guard is in place, inspect the three named app tests under the shorter deadline. Change test code only if a focused rerun identifies a concrete cause. Do not add delays, retries, skipped tests, or blanket `pumpAndSettle` calls.

### 2. Preserve reproducible shard diagnostics on failure

- Have `tool/changed_test_selector.dart` report the package, effective child command, and launch exception to stderr. Do not swallow process-launch details.
- Add a per-shard GitHub step summary showing test-plan mode/reason, shard index/count, timing source (historical or fixed fallback), and selected file paths or native shard arguments.
- Make the selector's JSON test report available for every non-empty test mode. Upload the plan, shard assignment, and report when a test command completes, including failed commands; skip upload for cancellation.
- Keep historical timing aggregation restricted to successful full-suite runs on `main`. Failed-run reports aid diagnosis but must not seed future balancing with incomplete timing samples.

### 3. Preserve existing correctness gates

Keep full-suite fallback, package/path validation, formatter and analyzer fatal gates, coverage generation, and Sonar behavior unchanged. Continue failing CI on test or analysis failures. Do not edit production reasoning code or tests to mask PR #999 failures. Do not introduce retries, test exclusions, broad test-selection changes, or coverage reductions.

## Files Expected to Change

- `.github/workflows/ci.yml` — per-shard summary and failure-safe diagnostic artifact upload.
- `tool/changed_test_selector.dart` and focused tests — effective command and launch-failure diagnostics; report generation where needed.
- `tool/testing/` plus `test/flutter_test_config.dart` in the app, UI package, and widgetbook — shared CI timeout configuration. App config retains its localization logger filter.
- Focused tests for selector/configuration only, if required by implementation.

## Acceptance Criteria

1. Under `CI=true`, app, UI, and widgetbook `testWidgets` use the intended 30-second default; non-CI defaults remain unchanged, and explicit per-test timeouts still work.
2. CI summary identifies exact selection mode, fallback/timing source, shard assignment, and invocation inputs.
3. A failed test command leaves its JSON report and shard-plan artifact downloadable; canceled jobs do not block on artifact upload.
4. Historical timing merge still consumes only successful full-suite `main` runs.
5. Focused selector and Flutter-test configuration checks pass; workflow YAML/action validation passes.
6. The three known stalled tests either complete or fail at the configured deadline, not ten minutes. Any remaining Finder/assertion failures remain visible and require a separate root-cause fix.
7. No reasoning-feature behavior, required gate, test skip, retry, or coverage policy changes.

## Risks and Boundaries

- Thirty seconds may be too short for a legitimate widget test. Such a case must declare a test-specific timeout with evidence; do not raise the global CI ceiling to hide hangs.
- The cause of the three observed stalls is not yet known. Timeout alignment improves CI runtime and diagnosis but does not guarantee those tests pass.
- Failure reports contain test output and stack traces. Store only non-secret test artifacts and use the workflow's existing retention policy unless review identifies sensitive content.

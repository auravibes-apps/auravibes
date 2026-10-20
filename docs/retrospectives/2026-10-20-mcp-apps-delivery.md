# MCP Apps delivery retrospective

**Date:** 2026-10-20

**Scope:** Issue #1389 implementation and PR recovery.

## Outcome

- [PR #1615](https://github.com/auravibes-apps/auravibes/pull/1615) merged by admin squash after exact-head CI passed. Main merge commit: `ae3aacd0f9d0700a69da365f4f0a19e193f5d6af`.
- Hosted CI run `39498995083` passed with 34 successful checks and five conditional skips. Focused widget tests passed 3/3; targeted fatal analysis and local `validate:pr` passed.
- Local `validate:ci` did not run because the coordinator's full-suite slot was not granted.
- [PR #1616](https://github.com/auravibes-apps/auravibes/pull/1616) added the MCP Apps architecture map; it found no navigation or duplicate-gate documentation gap.

## Findings

### Embedded view coverage

Review found that fallback-only tests did not prove successful resource delivery to the embedded host. Added a fake-platform widget test for resource loading, bridge initialization, and tool-input/tool-result delivery. The fake does not execute page JavaScript or prove native sandbox behavior.

**Follow-up:** Add a real-platform smoke when stable WebView automation is available.

### Cross-platform date command

The supplied `date -Is` command failed on macOS. `date +%Y-%m-%dT%H:%M:%S%z` worked.

**Follow-up:** Use the portable form or document the macOS/Linux alternatives in cross-platform instructions.

### PR check polling

Full check rollups were noisy. The existing compact query in [agent operations](../agents/operations.md#pr-check-monitoring) shows only pending, failed, or cancelled checks.

**Follow-up:** Reuse the existing query; no new polling documentation or duplicate analysis/DCL gate needed.

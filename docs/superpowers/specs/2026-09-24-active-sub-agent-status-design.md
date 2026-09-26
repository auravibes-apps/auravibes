# Active Sub-Agent Status Design

**Date:** 2026-09-24
**Status:** Spec ready; implementation authorized
**Scope:** Issues #898, #899, #900; deterministic Marionette smoke fixture for #902

## Intent

Make the existing chat-level active-sub-agent count actionable and trustworthy. Users should reach one child directly, choose among several, and see each child’s current lifecycle state. Terminal paths must clear live state, including when cancellation cleanup stalls. Keep all behavior scoped to the open parent conversation.

## Existing Seam

`SubAgentRunner` creates child conversations and starts app runtime handles. `ActiveSubAgentRuntime` owns live child IDs and completion waiters. `ResolvedToolService` starts children; `AgentToolResumeService` resumes them; `ChatConversationScreen` currently renders a non-interactive count pill and stops children. Child conversation titles and history already persist through `childConversationsStreamProvider`.

`AgentCancellationRuntime._completeScope` currently waits indefinitely for cleanup and scope closure. `forceClear` removes the scope but does not close it; a stalled cleanup or missing close can leave `waitForCompletion` unresolved. Child terminal updates can also arrive through more than one path, so duplicate completion must not erase failure detail or stopped state.

## Design

1. Keep `ActiveSubAgentRuntime` as the only source of live-child truth. Track live status (`running`, `awaiting approval`) per child; count only live IDs. Derive child labels from persisted conversation titles. Keep existing completion/failure data available for terminal rows while the parent’s status sheet is open.
2. Replace the passive pill with a semantic button. One live child opens its `SubAgentConversationRoute`; multiple live children open a localized bottom sheet with stable child titles, lifecycle labels, safe error detail where available, and a row action to open each child. Preserve mouse, keyboard, and touch activation. Keep the pill absent at live count zero.
3. Mark a child `awaiting approval` when its initial agent turn yields `waitForToolApproval`; mark it `running` when approved continuation resumes. On finish, update status and remove it from live state. Preserve provider/runtime failure objects through the engine request handle; render only `LogRedaction.redact(error)`, never stack traces or raw secret-bearing payloads.
4. Make terminal completion idempotent. Ensure force-clear/replacement closes old scopes. Bound cleanup waiting to five seconds; timeout proceeds with completion-map cleanup so parent stop cannot hang. A timed-out cleanup operation may continue in the background; it must not retain active-child UI state.
5. Add allowlisted Marionette fixture actions backed by the real `SubAgentRunner`, local demo conversation/repositories, and a deterministic continuation that waits for approval instead of calling a model provider. Fixture can start one or two children and finish a selected child. Smoke flow covers hidden → one → two → one → hidden, then completion and parent-stop behavior, localized count, and accessible name. Fixture creates no credentials and makes no network calls.

## Alternatives Considered

- **UI-only routing from the current ID set:** smallest change, but cannot identify children, distinguish approval waits, or preserve failure details. Rejected for #899.
- **App-wide activity surface:** could expose children after leaving the parent, but is #901’s separate product scope. Excluded.
- **Use a live model/provider for smoke:** tests production provider wiring but requires secrets/network and is nondeterministic. Rejected; local fixture exercises the production runner and persistence without provider execution.

## Acceptance Mapping

| Issue | Acceptance | Implementation evidence |
|---|---|---|
| #898 | One child opens directly; multiple children show accessible chooser; mouse/keyboard/touch work; hidden at zero | Interactive pill, titled rows, route navigation, live-only count; widget/semantics tests |
| #899 | Stable labels; running/approval/failed/stopped where available; safe error details; child navigation; localization/accessibility | Persisted child titles, runtime status, redacted failure presentation, localized strings, status-sheet tests |
| #900 | Clear on done/failure/cancel/parent stop/cleanup timeout; no stale resurrection; concurrency/terminal regression coverage | Idempotent runtime finish, bounded cancellation cleanup, state never rebuilt from history; focused lifecycle tests |
| #902 | Repeatable credential-free local smoke for all count transitions, accessible/localized label, completion and parent cancellation | Marionette fixture actions plus isolated-app smoke runbook; leave issue open if end-to-end execution is blocked |

## Scope Boundaries

- #901 remains excluded: no sidebar, conversation-list, or app-wide active-work surface.
- No retries, provider credentials, production-server dependency, schema migration, or new package.
- No unrelated conversation/tool redesign.
- Create PR closure references only for issues fully implemented and verified. If isolated Marionette end-to-end smoke cannot run, finish #898–#900, leave #902 open with exact blocker, and do not block their PR.

## Self-Review

- **Scope:** only existing chat runtime/UI plus a debug-only local fixture; #901 excluded.
- **Lifecycle:** normal completion, failure, child stop, parent stop, replacement, force-clear, and cleanup timeout all converge on idempotent terminal handling.
- **Privacy:** provider errors pass through existing `LogRedaction`; stack traces and credentials never enter UI.
- **Accessibility/localization:** pill and chooser use localized labels/status and expose semantic actions.
- **Verification:** focused engine/runtime/widget/extension tests; run Marionette only in an isolated dev app. Do not claim #902 solved without the smoke evidence.

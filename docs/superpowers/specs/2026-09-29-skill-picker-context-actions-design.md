# Skill Picker and Context Actions Design

## Goal

Make conversation skills discoverable, add-only, context-aware, and explicitly usable from the chat composer, picker, and assistant suggestions. Adding or recovering a skill must not create a user prompt or start an agent turn. `Use now` remains a separate, deliberate action that sends one visible user request through normal continuation.

## Verified context (2026-09-29)

- Assigned open issues: #617, #880–882, #886, and #1200–1202.
- Live dependencies #879, #616, and #864 are closed and their implementations are present on this worktree's `origin/main` base. #1145 is merged and resolves the context refresh work; #887 is closed.
- The selector already distinguishes persisted selection from prepared context and credential readiness. Its current error status does not retain cause-specific recovery information.
- The selector's add usecase only persists selection. Existing A2UI form actions create a chat message, so they cannot implement promptless Add.
- Existing A2UI contracts and catalogs are shared between app and server. Suggestions must be represented in that contract and validated at the app action boundary.
- This work stays on the current default-branch base; it does not depend on another group's branch or PR.
- The current selector removes skills and fires add requests without pending/error state. Its search field does not exist.
- #1200 recovery categories are missing credentials, unavailable/stale metadata, and transient preparation failure. Credential setup has an existing route; stale metadata refreshes the picker; transient preparation exposes explicit Retry.
- #1201 requires `Use now` in both picker and suggestion surfaces, with exactly one visible user request through normal continuation. Add stays promptless.
- #1202 requires deterministic app-level coverage across compaction, resume, and fork without network/model calls.

## User flow brief

1. From an active conversation, the user can open Skills beside the composer and see the number of skills added to that conversation. The control remains accessible with zero skills and on narrow layouts.
2. The picker shows added skills and current-context status separately from available skills. Search matches title and description across both groups. Add persists one selection, shows pending and localized failure states, and never sends a message or starts a continuation.
3. If an added skill's context is missing or invalid, the picker explains the bounded cause and offers a safe next action: open credential setup, refresh current metadata, or explicitly retry. Retry reports Preparing, Ready, Needs context, or a specific Error. It preserves selection and does not send a model request or create any message.
4. An assistant response may include a typed skill suggestion with only a skill slug and catalog revision. The app resolves title and description from its current catalog and derives workspace/conversation identity from trusted route state. A stale suggestion opens the current picker without mutating state.
5. Add on a suggestion remains promptless. Use now is separate on both picker and suggestion surfaces; a direct tap validates readiness, persists selection if needed, then sends exactly one localized visible request through normal continuation and approval. Invalid, stale, unavailable, unauthorized, duplicate, or credential-blocked actions do not start a turn.

## Design

Reuse the existing skill selector provider, conversation context runtime, credential-readiness checks, load usecase, and normal message continuation. Add only the state and orchestration needed for actionable context failures, promptless typed suggestion actions, and a distinct Use now path. Do not create a second source of selection or readiness state.

Expose an app-owned Skills control beside the composer while keeping the current overflow entry point. Count persisted selections, including skills whose current context needs recovery. Keep Add and Use now as separate actions: picker Add only selects; Use now creates a user-visible request and uses normal conversation continuation. Resolve suggestion titles and descriptions from the current catalog, never from model-supplied display text or executable arguments.

Add a shared A2UI SkillSuggestion contract with a validated slug and catalog revision. Expose its schema through the existing passive A2UI skill resource only after capability activation; do not inject the prompt globally. Negotiate the component through the existing supported-component set so local and server responses use the same contract. At action time, verify the conversation/workspace relationship, current skill availability, catalog revision, and credential readiness. Stale suggestions fall back to the current picker. Local and cloud chat use the same app action boundary.

For context retry, provide a chat-owned read-only preparation path. Reuse the same skill-context and activation-capability sources as ordinary continuation; preview tool/context state without syncing permissions or reconciling transcript rows. Update the existing context runtime, preserve selection, and avoid sending a request or creating any message. Do not route Retry through the full continuation call. Keep failure categories bounded to missing credentials, unavailable/stale skill metadata, and transient preparation failure; never surface raw exception text or credential data.

For assistant suggestions, validate the current catalog revision, skill availability, credential readiness, and route ownership at the app action boundary. Both picker and suggestion Use now actions call the ordinary send-message usecase with localized text naming the skill and referring to the user's latest request. Guard duplicate taps before any selection or message mutation.

For #886, remove unload UI and app-level unload services/providers only after auditing all callers. Keep persisted false rows readable and unchanged, keep re-add idempotent, retain fork behavior, and do not delete historical rows or add a migration that rewrites them. Retain generic cloud resource deletion and unrelated server lifecycle behavior.

## Alternatives considered

- **Parse assistant text or links for skill suggestions:** rejected because display text is not a bounded, validated action payload and would be brittle across wording changes.
- **Execute a skill command directly from the card:** rejected because it bypasses the normal user-visible request and continuation/approval path.
- **Run Retry through normal continuation preparation:** rejected because the full path may persist transcript/tool state and then send a model request. Retry needs an explicit preparation-only boundary.

## Constraints and exclusions

- No new dependency.
- All user-visible strings and errors are localized in English and Spanish.
- Do not touch #868 or #947.
- Do not reimplement closed dependencies #879, #616, or #864.
- No provider-specific wire format or general-purpose A2UI action framework.
- No destructive cleanup of legacy local rows, cloud tombstones, or conversation history.

## Verification

- Widget/provider tests cover search, empty results, zero/one/multiple composer counts, context status, localized recovery, credential-route return, explicit retry, pending/duplicate add, add-only behavior, stale suggestion fallback, and narrow layout.
- Usecase/action tests prove invalid or stale suggestions cannot mutate selection, Add creates no message/request, and picker/card Use now creates one localized visible request and one normal continuation.
- A deterministic app continuation-preparation test covers selection and status after compaction, resume, and fork, with changed revisions and preparation failure, without network/model providers or transcript writes.
- Persistence tests confirm legacy false rows remain readable and explicit re-add promotes the existing row.
- Review the final diff and run focused tests plus the repository's PR validation gates before opening and merging one PR.

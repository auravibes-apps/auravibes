# Compaction Budgets and Checkpoint History Design

**Date:** 2026-09-25
**Status:** Design approved in chat; implementation plan pending
**Issues:** [#868](https://github.com/auravibes-apps/auravibes/issues/868), [#947](https://github.com/auravibes-apps/auravibes/issues/947)

## Goal

Add provider/model-specific compaction budgets and let users inspect and restore conversation compaction checkpoints in both local and cloud workspaces, without deleting source messages.

## Current behavior

- `CompactionSettings` persists workspace auto-compaction thresholds. Local storage maps settings to Drift columns; cloud storage writes the serialized settings through the existing workspace resource.
- `selectAgentCompactionRange` preserves the tail after the latest user message and blocks unsafe unresolved-tool states. Context usage uses provider-reported cumulative tokens when available, otherwise a four-characters-per-token estimate including tool arguments and results.
- Local prompt selection uses the latest sent compaction summary and its covered-message IDs. Summary metadata already records the covered range and creation time, but not the compaction model.
- Cloud prompt assembly currently sends all nonqueued messages. It must adopt deterministic checkpoint selection to make compaction and restore effective in cloud conversations too.

## Chosen approach

Persist one active checkpoint ID per conversation. Keep every source message and compaction summary. Restore changes only the active ID; prompt selection reconstructs context from that checkpoint and later source messages. New successful compaction activates its new summary. A null ID resolves to the latest valid summary, preserving local legacy behavior and bringing cloud legacy conversations onto the same selection behavior.

A new fork inherits only checkpoints present within its effective fork boundary. A checkpoint outside that boundary cannot be selected in the fork.

Rejected alternatives: creating a new conversation for every restore changes restore semantics; toggling metadata on every summary rewrites history and adds synchronization races.

## Model-specific budgets

Add optional `reserveTokens` and `keepRecentTokens` fields under `CompactionSettings.modelOverrides`, keyed by exact, case-sensitive `providerId/modelId` identity. Keep current workspace compaction trigger settings separate and unchanged.

- Resolve each field independently for the selected model. Missing, malformed, negative, or model-incompatible values contribute no override; existing behavior remains fallback. Invalid serialized override data must not make the rest of workspace settings unreadable.
- Reserve no more than the model's known `limitOutput`; use it with `limitContext` as the output-room constraint during range selection. If required model limits are unavailable or invalid, ignore the budget override.
- Use `keepRecentTokens` to extend the protected tail backwards from the existing latest-user-turn boundary until the estimated recent budget is met. Never split a message or tool exchange. The existing latest-user-turn tail remains the minimum protected tail.
- Keep current unresolved-tool, unfinished-message, and message-status checks. If a safe range cannot preserve the tail and output reserve within the model context, return no range rather than splitting or discarding messages.
- Model switching resolves a fresh override by provider/model identity; it never reuses another model's budget.

Persist the map through the existing settings path. Cloud continues using workspace resource JSON. Local storage adds a nullable JSON column and an additive Drift migration; existing rows and settings remain intact. Add a per-model editor to the existing compaction settings UI with localized labels and numeric validation. Reset/removal clears the override and restores legacy behavior.
The cloud compaction worker reads that resource when selecting a range, so local and cloud use the same saved budget.

## Checkpoint data and prompt selection

Each compaction summary remains a normal retained message with its covered range, timestamp, and provider/model IDs. Add provider/model metadata to new summaries only; history displays legacy summaries with model marked unavailable. Do not include credentials or secrets.

Add a nullable active checkpoint ID to local and server conversation records. Local prompt selection and cloud server prompt assembly use the selected checkpoint, or latest valid checkpoint when the field is null:

1. Include selected summary.
2. Exclude original messages covered by that summary.
3. Include later source messages through current conversation head.
4. Ignore other compaction summaries, including newer summaries when an older checkpoint is selected.

Validate checkpoint identity and conversation/fork ownership before restore. Keep checkpoint-history UI in conversation details. Show range, creation time, provider/model, and active state; restoring selects that checkpoint without modifying source messages.

## Restore safety

Reject restore while conversation is streaming, compaction is active, a turn is active, approvals are unresolved, or tool calls remain unresolved. Local usecase checks existing conversation/compaction/tool state before changing the active ID. Cloud restore is a server-authoritative mutation: serialize with conversation mutations, check active turn and unresolved approvals/tool calls, and update the active ID only when safe. Return a typed, localized failure to the UI.

## Persistence and migration

- Local Drift: add nullable active-checkpoint ID to conversations and nullable model-override JSON to workspace compaction settings; advance schema version with forward migration. No rows or messages are deleted.
- Serverpod: add nullable active-checkpoint ID to `Conversation` with a forward migration. Update protocol request/response definitions and regenerate server/client code. Existing null values resolve to latest valid checkpoint.
- Cloud compaction settings remain in the existing workspace resource; no settings schema migration is needed.
- Update Freezed/Drift/Serverpod generated output only through project generators.

## Verification

Focused tests must cover:

- Model switching, independent field resolution, absent/invalid/removed override fallback, and unchanged workspace trigger behavior.
- Short contexts, missing model limits, oversized messages/tool results, and whole-message/tool-exchange boundaries.
- Multiple checkpoint revisions, deterministic prompt selection after restoring an older checkpoint, retained source messages, and new-compaction activation.
- Fork boundaries and checkpoint inheritance.
- Restore rejection during streaming, active compaction/turn, pending approval, and unresolved tool calls, locally and in cloud endpoint tests.
- Local settings migration and cloud settings serialization compatibility.

Run focused tests and analyzers first. Inspect generated output and migrations. Run the repository's broader validation only after focused checks pass and scope warrants it. Open one Conventional Commit PR with `Closes #868` and `Closes #947`; do not merge.

## Risks and review focus

1. Token estimates are approximate without provider usage. Preserve whole messages and fail closed when the protected tail cannot fit.
2. Stale or cross-conversation checkpoint IDs must never select another conversation's history; validate ownership at restore and prompt assembly.
3. A restore racing with streaming, approval resolution, or a new compaction must serialize or fail without changing the active checkpoint.
4. Nullable additive migrations preserve stored data, but server/client protocol regeneration and compatibility require focused migration and integration tests.

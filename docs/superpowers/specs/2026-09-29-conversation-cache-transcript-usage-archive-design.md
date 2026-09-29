# Conversation Cache, Transcript, Usage, and Archive Design

**Date:** 2026-09-29  
**Baseline:** `main` at `a063c767c59d36be404931ec78d7c92cc4021ccb`  
**Live issue audit:** 2026-09-29T12:03:08-05:00

## Goal

Implement assigned open issues #865–867, #873, #1076, #1082, and #1152–1154 in one reviewable PR. Keep #868 and #947 outside scope. Preserve existing provider fallbacks, transcript authorization, archive redaction, and full model continuation history.

## Current evidence

- All nine assigned issues were open at audit time.
- #865 currently lists #1153 as its active dependency; its body still names closed #864.
- #866's body depends on #865. #873 consumes #865 usage metadata and may include #866 requests.
- #1082 and #1152 share single-archive compatibility and redaction constraints. #1154 protects transcript replay used by #1152.
- #867 requires before/after measurements and explicitly says to stop without speculative pagination when no material bottleneck appears.
- Anthropic traffic currently uses `genkit_anthropic 0.4.0`; pinned adapter source confirms it takes only the first system message, drops later system messages, and sends all tools in the top-level request. Pinned `anthropic_sdk_dart 8.0.0` exposes the needed wire types.
- `LanguageModelUsage` stores prompt, response, and total tokens. Model pricing has input, cache-read, and output fields. Usage persistence does not currently cover compaction or a provider request independently from its visible message.
- Local conversation watch currently observes whole message, conversation, and attachment tables, then reloads the effective transcript.
- Existing archive v1 encodes one conversation from visible messages; import decodes before writes. Existing transcript-context updates are version 1 and are filtered from visible messages.

## Design

### Provider capability and Anthropic request encoding (#1153, #865)

Define independent provider/model capability gates for prompt-cache markers, mid-conversation system blocks, tool additions/removals, and deferred tools. Unknown, custom, and unsupported models default false. Use an explicit provider/model capability source, then carry these fields through the model entity, local model catalog storage, and selected-workspace model mapping so request encoding uses the same source after reload. Bump and migrate Drift schema for the new persisted fields.

For the Claude API, current Anthropic docs list `claude-fable-5-1`, `claude-mythos-5-1`, `claude-fable-5`, `claude-mythos-5`, `claude-opus-5-5`, `claude-opus-4-8`, `claude-opus-5`, and `claude-sonnet-5-5` for mid-conversation system messages and beta tool changes. `claude-sonnet-5` is explicitly unsupported for those features. Keep cache-marker capability independent from those advanced transcript features. Disable advanced features for custom API endpoints. Source: [Anthropic mid-conversation system messages and tool changes](https://platform.claude.com/docs/en/build-with-claude/mid-conversation-system-messages), current 2026-09-29.

Add a narrow Anthropic request adapter using the pinned SDK. Keep the leading system prompt and stable initial tool list byte-stable; mark cache boundaries only when explicitly supported. Encode later system text and tool-state deltas only at legal message positions and only when each capability permits them. Preserve existing approval and execution semantics. Unsupported models use the existing compatible representation. Invalid placement, redefinition, or authorization-sensitive changes fail through a typed provider error rather than silently altering access.

Keep provider diagnostics free of prompts, credentials, signed URLs, and raw payloads. Map reported cache-read and cache-write usage into provider result metadata.

### Request usage and cost (#873)

Extend provider usage with optional cache-read and cache-write counts. Add a local durable request-usage record with request, conversation, provider/model, request kind, token counts, known/unknown cost, outcome, and timestamp. Store assistant generations, compaction generations, and eligible cache warm requests separately from visible text. Preserve unavailable fields as null.

Calculate costs only from complete applicable prices. Extend the existing catalog price mapping for cache-write price where the source provides it; do not infer zero. Aggregate by the conversation that owns the request. Forked message references do not copy usage records, so branch totals do not double count inherited rows.

Use a Drift schema migration with the corresponding version bump. Keep request usage and cost out of model-visible transcript and logs.

### Active-run cache warming (#866)

Keep warming disabled by default and enable only through an explicit opt-in setting. Retain request identity only for a supported Anthropic active tool run. Schedule at most one no-retry, one-token refresh for a known TTL when pricing and conservative expected-savings inputs meet a minimum threshold. Skip unknown TTL/pricing, unsupported capabilities, and non-replayable thinking. Cancel on run completion/cancel, backgrounding, compaction, fork, model/context/tool changes. Record returned usage through #873 without adding a chat message or changing conversation output.

### Conversation resume (#867)

First add a repeatable SQLite-backed large-conversation benchmark measuring first useful render, full hydration, and cancellation for small and large transcripts. Use its baseline before query changes. If it shows no material bottleneck, keep current loading semantics and record the measurement as the issue disposition. If it shows a material bottleneck, progressively publish a recent window and hydrate older rows, while cancelling stale mapping and narrowing Drift invalidation to the selected conversation and inherited fork sources where supported. Model continuation, fork, and compaction keep the full ordered effective transcript.

### Bulk selection (#1076)

Disable row selection while pin/delete is pending. Retain failed conversation IDs in selection after completion. Test delayed success and failure paths.

### Transcript schema safety (#1154)

Replace generic decode failure with a typed, redacted diagnosis. Keep known version 1 deterministic; define explicit migrations for formats introduced here. Unknown future or malformed payloads block replay before tools/provider work. Visible transcript and export paths remain available.

### Multi-conversation archives and context (#1082, #1152)

Add a versioned multi-conversation envelope containing independently encoded conversation archives, attachment bytes, and an explicit allowlisted agent-context payload. Preserve ordered trusted context messages, ordered tool state, safe approval state, compaction snapshots, and context-affecting conversation selections. Remap message anchors and conversation/message IDs during import. Do not copy database/tool-call IDs, credentials, auth headers, MCP secrets, or private paths.

Validate the entire batch—including versions, bounds, attachment references, context payloads, and redaction allowlist—before staging or database writes. Reuse existing file APIs, then import each conversation independently in one batch-level operation. Continue importing single-conversation archive v1. Internal context stays hidden from chat bubbles.

## Verification

- Focused tests for each task, using FVM-pinned Flutter/Dart.
- Run the required root validation, dependency validator, and import sorter once implementation stabilizes.
- Run the assigned PR checks and wait for required hosted CI before merge.
- Review diff, migration output, generated files, archive allowlist, wire serialization, and branch usage aggregation.

## Constraints and risks

- Provider support and pricing data are time-sensitive; gate each feature independently and default unknowns to disabled/null.
- Warming spends tokens and network/battery. Default off, no retry, no background execution, and no unknown economics.
- Archive import can partially mutate local state if validation is interleaved with writes; validate the full payload first and clean staged files on failure.
- Fork inheritance is recursive. Usage remains attached to the originating conversation and transcript hydration must preserve existing fork boundaries.
- Generated Dart files must be produced by generators, never hand-edited.

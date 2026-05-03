# Research: Agent Conversation Compaction Settings

## Decision: Persist compaction summaries in existing message stream

**Decision**: Store each compaction result as a normal persisted message with metadata flagging it as compaction (`manual` or `auto`) and recording represented range.

**Rationale**: Existing message ordering, persistence, and metadata infrastructure already exists in Drift/message repository. This avoids adding a new table and keeps compaction checkpoints durable across restarts.

**Alternatives considered**:

- Separate compaction table: cleaner separation, but extra migration and query complexity for MVP.
- In-memory compaction state only: simpler initially, but lost on restart and not inspectable.

## Decision: Store compaction settings globally in shared preferences

**Decision**: Persist compaction settings as global app preferences containing auto-enabled state, usage percentage threshold, remaining-token threshold, and reset-to-default behavior.

**Rationale**: The clarified spec requires a dedicated settings section and global defaults. Shared preferences match the current no-schema-change constraint and avoid per-conversation/per-model complexity until there is a concrete use case.

**Alternatives considered**:

- Per-model settings: more precise, but adds UI and migration complexity beyond MVP.
- Drift settings table: more queryable, but unnecessary for global preferences and would add migration work.

## Decision: Use deterministic thresholds for auto eligibility

**Decision**: Auto compaction eligibility is decided by deterministic checks: auto compaction enabled, no unsafe tool/conversation state, usage percentage at or above threshold, and remaining tokens at or below threshold.

**Rationale**: Deterministic checks make settings testable and predictable. The AI service should summarize once eligibility is known, not decide whether user settings apply.

**Alternatives considered**:

- Ask the AI service whether compaction is needed: harder to test and can ignore explicit user settings.
- Percent-only trigger: unsafe across models because large and small contexts have very different remaining-token risk at the same percentage.

## Decision: Default remaining-token threshold uses a dynamic safety gap

**Decision**: Default remaining-token threshold is `max(maxOutputTokens, 20% of selected model context limit)`, capped at 15,000 tokens. Users can override it in settings.

**Rationale**: A dynamic gap scales with model size while avoiding excessive safety buffers for very large contexts. It follows the research recommendation and reduces premature compaction on large-context models.

**Alternatives considered**:

- Fixed `4,000` tokens: simpler, but too small for large outputs and too rigid across providers.
- Percent-only threshold: lacks a concrete floor for small context models.
- Uncapped `20%`: can be too conservative for very large context windows.

## Decision: Generate summaries through the active conversation model/provider

**Decision**: `CompactConversationUsecase` calls the AI agent service using the same model provider and model selected for the active conversation, with a compaction-specific system prompt.

**Rationale**: The user explicitly required compaction to use the AI agent service and same model provider. This also avoids adding a separate summarizer-model setting for MVP.

**Alternatives considered**:

- Dedicated weak/cheap summarizer model: can reduce cost, but adds new settings and provider compatibility questions.
- Local rule-based summarization: avoids provider calls but produces lower-quality summaries and diverges from agent-compaction patterns.

## Decision: Keep stored compaction content untrimmed; normalize only for model payload

**Decision**: Persist original compaction text exactly as generated. Apply trimming/whitespace normalization only when building agent history payload.

**Rationale**: Users need a trustworthy details view of the exact compacted content. Token-efficiency normalization belongs to prompt construction, not storage.

**Alternatives considered**:

- Trim at storage time: lower storage noise, but destroys user-visible fidelity.
- Store raw and normalized copies: redundant state and sync risk.

## Decision: Show a visible `Compacted` widget in chat with tap-to-details behavior

**Decision**: Compaction summaries remain in normal transcript as a dedicated compacted message widget. Tapping opens compaction details similar to tool-result inspection.

**Rationale**: Clarification requires user transparency that compaction occurred and what was compacted, without exposing low-level metadata.

**Alternatives considered**:

- Hide compaction summaries from transcript: less noise, but conflicts with transparency requirement.
- Show plain system text message: lower implementation cost, weaker affordance and discoverability.

## Decision: Show in-progress compaction in conversation list as separate temporary row

**Decision**: While compaction runs (manual or auto), conversation list shows a temporary `Compacting` loading row, separate from existing conversation row.

**Rationale**: Matches requested UX and avoids mutating base row semantics while still signaling pending compaction state.

**Alternatives considered**:

- Replace conversation row with loading variant: cleaner but conflicts with explicit user choice.
- Global spinner only: weak per-conversation visibility.

## Decision: Reuse existing send queue by treating compaction as busy

**Decision**: Reuse the current queued-send mechanism for messages sent during compaction by adding compaction-active as a busy/queue condition.

**Rationale**: Preserves ordering guarantees and avoids parallel send/compaction race conditions with minimal new logic.

**Alternatives considered**:

- Block sends entirely during compaction: avoids queue complexity but degrades UX.
- Allow parallel sends while compacting: higher race risk around prompt boundary updates.

## Decision: Prompt boundary anchored at latest compaction summary

**Decision**: Prompt assembly includes the newest compaction summary and subsequent prompt-eligible messages only.

**Rationale**: Prevents duplicated old context and aligns with existing compaction-range semantics.

**Alternatives considered**:

- Filter by covered message IDs each turn: more precise but more expensive and fragile.
- Include all history plus summary: duplicates context, violates FR-012/SC-006.

## Decision: Keep a safe recent tail outside compacted ranges

**Decision**: Compaction range selection must keep at least the latest user turn, latest assistant turn, and complete tool-call/result groups uncompressed.

**Rationale**: Recent tail preservation reduces summary ambiguity and prevents invalid model histories caused by splitting tool-call/result relationships.

**Alternatives considered**:

- Compact all messages before latest summary: may remove important active context.
- Keep only the latest user message: insufficient for assistant/tool continuity.

## Decision: Auto compaction executes before continuation and blocks on required failure

**Decision**: Auto check runs before assistant continuation. If thresholds require compaction and compaction fails, continuation is blocked and a visible recoverable error is persisted.

**Rationale**: Enforces configured safety gate and preserves explicit failure semantics.

**Alternatives considered**:

- Continue without compaction on failure: keeps flow moving but violates required threshold behavior.
- Surface transient error only: risks losing failure context after navigation/restart.

## Decision: Retry context-overflow continuations once after safe compaction

**Decision**: If an assistant continuation fails with a provider context-overflow error and the conversation is safe to compact, run auto compaction and retry the assistant request exactly once.

**Rationale**: This recovers from inaccurate prompt-token estimates without creating infinite retry loops or duplicate assistant requests.

**Alternatives considered**:

- No retry: leaves recoverable long-context failures unresolved.
- Unlimited retries: risks loops and provider cost spikes.

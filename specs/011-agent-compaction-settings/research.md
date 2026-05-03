# Research: Agent Conversation Compaction Settings

## Decision: Persist compaction summaries in existing message stream

**Decision**: Store each compaction result as a normal persisted message with metadata flagging it as compaction (`manual` or `auto`) and recording represented range.

**Rationale**: Existing message ordering, persistence, and metadata infrastructure already exists in Drift/message repository. This avoids adding a new table and keeps compaction checkpoints durable across restarts.

**Alternatives considered**:

- Separate compaction table: cleaner separation, but extra migration and query complexity for MVP.
- In-memory compaction state only: simpler initially, but lost on restart and not inspectable.

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

## Decision: Auto compaction executes before continuation and blocks on required failure

**Decision**: Auto check runs before assistant continuation. If thresholds require compaction and compaction fails, continuation is blocked and a visible recoverable error is persisted.

**Rationale**: Enforces configured safety gate and preserves explicit failure semantics.

**Alternatives considered**:

- Continue without compaction on failure: keeps flow moving but violates required threshold behavior.
- Surface transient error only: risks losing failure context after navigation/restart.

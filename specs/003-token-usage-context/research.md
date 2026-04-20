# Research: Conversation Token Usage Indicator

## Decision 1: Persist usage in existing message metadata JSON

- **Decision**: Extend `MessageMetadataEntity` with token usage fields and persist through existing `metadata` column.
- **Rationale**: Current repository already serializes/deserializes metadata JSON; avoids Drift schema migration.
- **Alternatives considered**:
  - Add dedicated token columns in `messages` table (rejected: unnecessary migration and broader surface area).

## Decision 2: Per-message used tokens formula

- **Decision**: `used = totalTokens ?? (promptTokens + completionTokens) ?? 0`.
- **Rationale**: Works across providers where streaming events may not emit full totals.
- **Alternatives considered**:
  - Require `totalTokens` only (rejected: would undercount many stream/provider cases).

## Decision 3: Conversation total source of truth

- **Decision**: Sum usage from conversation messages and overlay in-flight streaming usage from runtime state.
- **Rationale**: Matches existing message content overlay approach and enables live updates.
- **Alternatives considered**:
  - Recompute only after message finalized (rejected: fails live-update requirement).

## Decision 4: Context limit denominator

- **Decision**: Use selected model `limitContext` for conversation percent denominator.
- **Rationale**: Explicit requirement and aligns user mental model of context window.
- **Alternatives considered**:
  - Static global limit (rejected: incorrect for model-specific windows).

## Decision 5: UI behavior for edge cases

- **Decision**: Clamp percent/progress in `[0,100]`; guard division by zero.
- **Rationale**: Prevents invalid UI states and regressions when model limit unavailable.
- **Alternatives considered**:
  - Allow overflow >100 in progress ring (rejected for this scope; can be added later with warning style).

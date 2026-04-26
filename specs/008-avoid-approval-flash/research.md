# Research: Avoid Approval Flash

## Decision: Use One Shared Tool Permission Decision

**Rationale**: Current code has two separate concerns: `pendingToolCallsProvider` exposes every pending tool call by checking only `MessageToolCallEntity.isPending`, while `RunAllowedToolsUsecase` later resolves tool permission through `_checkToolPermission`. This ordering allows a pending but already-approved tool call to appear in `ChatToolApprovalCard` before execution finishes. A shared decision use case keeps execution and UI visibility aligned with FR-006.

**Alternatives considered**:

- Duplicate the permission check in the widget/provider: rejected because it repeats permission-table ID resolution and risks future divergence.
- Hide all pending calls while the agent is busy: rejected because unapproved tools must still show approval controls.
- Add a short debounce before showing approval UI: rejected because it masks the symptom and can delay legitimate safety prompts.

## Decision: Filter Approval UI by `needsConfirmation`

**Rationale**: The approval card is only appropriate when a pending tool call needs user confirmation. Calls with `granted` should run, and disabled/not-configured outcomes should be resolved into explicit statuses rather than prompting approval. Filtering by the shared decision result preserves existing safety behavior and removes the flash for already-approved calls.

**Alternatives considered**:

- Filter by workspace or conversation permission mode directly: rejected because resolved permission already accounts for precedence and unavailable tools.
- Add display-only flags to message metadata: rejected because it adds persisted state for a derived UI concern and would require backfill/migration thinking.

## Decision: Keep Storage Unchanged

**Rationale**: Existing Drift tables already contain workspace and conversation permission state, and `messages` metadata already carries tool call status. The feature changes decision timing and sharing, not persisted shape.

**Alternatives considered**:

- Add a display state field to tool calls: rejected as unnecessary persisted duplication.
- Add a conversation-level approval cache: rejected because repository permission checks already provide the authoritative result.

## Decision: Test Provider/Use Case Behavior, Not Animation Timing

**Rationale**: The visible flash is caused by exposing already-approved pending calls to the approval UI source. Tests should prove approved calls are omitted from approval-card input and unapproved calls remain visible. This is more deterministic than timing-based widget animation tests.

**Alternatives considered**:

- Golden or screenshot tests for flash: rejected because transient frame assertions are brittle and harder to maintain.
- End-to-end timing test only: rejected because it would not isolate the permission decision regression.

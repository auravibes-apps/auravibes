# Feature Specification: Agent Conversation Compaction Settings

**Feature Branch**: `011-agent-compaction-settings`  
**Created**: 2026-05-02  
**Status**: Draft  
**Input**: User description: "auto compact, manual compact, and configurable compaction variables such as percentage and token thresholds in a dedicated settings section"

## Clarifications

### Session 2026-05-02

- Q: How should compaction summary messages appear in the chat transcript? → A: Hidden from normal chat view, used only for prompt context and metadata.
- Q: What default remaining-token threshold should auto compaction use? → A: 4,000 tokens.
- Q: When manual compaction succeeds, should the app immediately ask the assistant to continue? → A: No, manual compaction only creates a checkpoint and waits for the next user action.
- Q: If automatic compaction fails before an assistant continuation, what should happen? → A: Block assistant continuation and show a recoverable error.
- Q: Should the app keep a user-visible record of automatic compaction failure after blocking continuation? → A: Persist a visible error message in the chat.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Automatic Compaction Prevents Context Exhaustion (Priority: P1)

As a user running a long AI agent conversation, I want the app to automatically compact older conversation context before the model runs out of usable context, so the agent can continue working without me manually restarting or losing the important state.

**Why this priority**: Auto compaction protects the core agent workflow. Without it, long-running conversations can fail or degrade when context grows too large.

**Independent Test**: Start a conversation that reaches the configured compaction threshold, send another message, and verify the app compacts eligible prior context before the assistant continues while preserving the visible conversation history.

**Acceptance Scenarios**:

1. **Given** auto compaction is enabled and a conversation exceeds the configured percentage threshold and remaining-token threshold, **When** the user sends a message or the agent prepares its next response, **Then** the app compacts eligible prior context before the assistant response is requested.
2. **Given** a conversation is below either configured threshold, **When** the user sends a message, **Then** the app does not compact automatically.
3. **Given** a conversation has pending tool approvals or unresolved tool calls, **When** the conversation exceeds the configured threshold, **Then** auto compaction waits until the tool state is resolved before compacting.

---

### User Story 2 - Manual Compaction From Chat Input (Priority: P2)

As a user in a long conversation, I want a manual compact control in the chat input area, so I can intentionally compress context before continuing.

**Why this priority**: Manual compaction gives users control when they know the conversation should be checkpointed, even if automatic thresholds have not been reached.

**Independent Test**: Open an existing conversation with enough messages, press the compact control in the chat input area, and verify the app creates a compacted context summary while the visible transcript remains available.

**Acceptance Scenarios**:

1. **Given** a conversation has enough eligible prior context, **When** the user presses the manual compact control, **Then** the app compacts the eligible context and shows clear completion feedback.
2. **Given** the conversation is currently busy, waiting for tool approval, or has no eligible context to compact, **When** the user views the chat input area, **Then** the manual compact control is disabled or unavailable with an understandable reason.
3. **Given** manual compaction fails, **When** the failure occurs, **Then** the app leaves the conversation unchanged and shows a recoverable error message.
4. **Given** manual compaction succeeds, **When** the summary checkpoint is created, **Then** the app waits for the next user action and does not automatically request another assistant response.

---

### User Story 3 - Configure Compaction Defaults (Priority: P3)

As a user, I want a dedicated compaction settings section where I can modify auto compaction behavior, so I can tune long-conversation behavior for my models and workflow.

**Why this priority**: Different models and workflows have different context sizes and risk tolerance. Settings avoid hardcoded thresholds and make compaction behavior transparent.

**Independent Test**: Change compaction settings, return to a conversation, and verify auto compaction decisions use the updated values.

**Acceptance Scenarios**:

1. **Given** the user opens settings, **When** they navigate to the compaction section, **Then** they can view and edit auto compaction enabled state, usage percentage threshold, and remaining-token threshold.
2. **Given** the user changes and saves compaction settings, **When** a conversation later approaches the configured limits, **Then** auto compaction uses the saved settings.
3. **Given** the user enters invalid compaction settings, **When** they try to save, **Then** the app explains the validation issue and does not save invalid values.

---

### Edge Cases

- Auto compaction is disabled: the app never compacts automatically but still allows manual compaction when eligible.
- Threshold settings are changed while a conversation is open: the next compaction check uses the updated settings.
- Remaining-token threshold is greater than the selected model's context limit: the app treats the setting as invalid or asks the user to correct it before saving.
- Compaction summary generation fails or is cancelled: no eligible conversation context is marked compacted, and the user can retry.
- Automatic compaction fails after thresholds are met: the app blocks the pending assistant continuation, leaves compactable context unchanged, persists a visible chat error message, and allows the user to retry.
- A conversation already has a previous compaction summary: new compaction updates the active compacted context without duplicating old compacted content in the next prompt.
- Compaction summary messages are hidden from the normal chat transcript while still being available for prompt context and metadata-driven behavior.
- The latest messages contain unresolved tool approvals, active tool calls, unsent user drafts, or failed messages: compaction skips unsafe ranges and never splits tool calls from their results.
- The selected model has no known context limit: auto compaction does not run from percentage-based thresholds, and the app communicates that context-limit data is unavailable.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST provide automatic conversation compaction for AI agent conversations when auto compaction is enabled and all configured threshold conditions are met.
- **FR-002**: The system MUST evaluate auto compaction before each assistant continuation when the conversation is not waiting on unresolved tool approval or tool execution state.
- **FR-003**: The system MUST support a configurable usage percentage threshold for auto compaction.
- **FR-004**: The system MUST support a configurable remaining-token threshold for auto compaction.
- **FR-005**: The system MUST require auto compaction to satisfy both configured percentage and remaining-token threshold conditions before compacting automatically.
- **FR-006**: The system MUST expose a dedicated compaction section in settings where users can enable or disable auto compaction and change compaction thresholds.
- **FR-007**: The system MUST persist compaction settings so they continue to apply after app restart.
- **FR-008**: The system MUST validate compaction settings before saving and reject invalid percentage or token values.
- **FR-009**: Users MUST be able to manually compact an eligible conversation from the chat input area.
- **FR-010**: The system MUST prevent manual compaction while the conversation is busy, waiting for tool approval, or has no eligible context to compact.
- **FR-011**: The system MUST preserve the full visible conversation history after auto or manual compaction.
- **FR-012**: The system MUST ensure compacted context is used for future assistant responses instead of sending both the compacted older content and its summary.
- **FR-013**: The system MUST select prompt context from the latest compaction summary forward when a compaction summary exists, and MUST select all prompt-eligible conversation messages when no compaction summary exists.
- **FR-014**: The system MUST preserve tool-call continuity by never compacting a range that splits an unresolved tool call, pending approval, or tool result from the assistant message that produced it.
- **FR-015**: The system MUST show clear user feedback when manual compaction starts, succeeds, fails, or is unavailable.
- **FR-016**: The system MUST leave compactable context and compaction metadata unchanged if compaction fails, while allowing required auto-compaction failures to persist a visible chat error message.
- **FR-017**: The system MUST record enough compaction state to identify which prior conversation content is represented by the active compaction summary.
- **FR-018**: The system MUST allow users to reset compaction settings to default values.
- **FR-019**: The system MUST mark each compaction summary with whether it was created manually or automatically.
- **FR-020**: The system MUST ensure compaction summary messages do not contain thinking output or tool-call metadata.
- **FR-021**: The system MUST hide compaction summary messages from the normal chat transcript while preserving them for prompt context and metadata-driven behavior.
- **FR-022**: The system MUST NOT automatically request an assistant response after a manual compaction succeeds.
- **FR-023**: The system MUST block the pending assistant continuation and persist a visible recoverable chat error message if required automatic compaction fails.

### Key Entities

- **Compaction Settings**: User-controlled preferences for auto compaction enabled state, usage percentage threshold, remaining-token threshold, and default reset behavior.
- **Compaction Summary**: A concise representation of earlier conversation context that future assistant responses can use instead of the full compacted content.
- **Compaction Range**: The set of prior conversation messages represented by a compaction summary.
- **Eligible Conversation Context**: Conversation content that is safe to compact because it is no longer active, unresolved, or required as immediate recent context.

### Assumptions

- Default auto compaction is enabled.
- Default usage percentage threshold is 80%.
- Default remaining-token threshold is 4,000 tokens and can be changed in compaction settings.
- Manual compaction keeps a recent uncompressed tail rather than replacing the entire conversation context.
- Manual compaction is a checkpoint action and does not continue the assistant until the user sends or triggers another action.
- Automatic compaction failure blocks the pending assistant continuation, persists a visible chat error message, and does not mark any context as compacted.
- Compaction affects model context only; it does not delete or hide existing visible chat messages.
- Settings apply globally to all conversations unless a future feature adds per-workspace or per-model overrides.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In test conversations that cross configured thresholds, auto compaction occurs before the next assistant response for 100% of tested eligible checks.
- **SC-002**: Users can manually compact an eligible conversation in no more than two actions from the chat screen.
- **SC-003**: Users can find and update compaction settings in under 30 seconds during usability testing.
- **SC-004**: After compaction, 100% of visible chat messages remain accessible to the user.
- **SC-005**: Invalid compaction settings are rejected 100% of the time with a user-readable explanation.
- **SC-006**: No assistant response is requested with duplicated compacted content and summary content after a successful compaction.
- **SC-007**: Compaction never proceeds in test cases with unresolved tool approvals or pending tool calls.
- **SC-008**: 100% of compaction summary messages created in tests are marked as manual or automatic and contain no tool-call metadata.
- **SC-009**: 100% of compaction summary messages created in tests are absent from the normal visible chat transcript.
- **SC-010**: 100% of successful manual compaction tests produce no automatic assistant continuation.
- **SC-011**: 100% of failed required auto-compaction tests block assistant continuation, preserve uncompacted context, and create a visible chat error message.

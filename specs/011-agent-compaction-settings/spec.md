# Feature Specification: Agent Conversation Compaction Settings

**Feature Branch**: `011-agent-compaction-settings`  
**Created**: 2026-05-02  
**Status**: Draft  
**Input**: User description: "auto compact, manual compact, and configurable compaction variables such as percentage and token thresholds in a dedicated settings section"

## Clarifications

### Session 2026-05-02

- Q: How should compaction summary messages appear in the chat transcript? → A: Hidden from normal chat view, used only for prompt context and metadata.
- Q: What default remaining-token threshold should auto compaction use? → A: Dynamic safety gap: `max(maxOutputTokens, 20% of context limit)`, capped at 15,000 tokens.
- Q: When manual compaction succeeds, should the app immediately ask the assistant to continue? → A: No, manual compaction only creates a checkpoint and waits for the next user action.
- Q: If automatic compaction fails before an assistant continuation, what should happen? → A: Block assistant continuation and show a recoverable error.
- Q: Should the app keep a user-visible record of automatic compaction failure after blocking continuation? → A: Persist a visible error message in the chat.
- Q: How should compaction summaries appear in chat history? → A: Show a visible Compacted widget in chat history that can be tapped to open compaction details.
- Q: How should in-progress compaction appear in the conversation list? → A: Show a separate temporary Compacting row (tool-like loading) instead of replacing the existing conversation widget.
- Q: How should user messages behave while compaction is running? → A: Reuse the existing send queue and treat active compaction as a busy/queueing condition.
- Q: How should compaction message text be stored versus sent to agent history? → A: Store the original untrimmed compaction message for user inspection, and trim/normalize only when preparing agent-history payload.

### Session 2026-05-03

- Q: How should automatic compaction combine configured thresholds with AI-based summarization? → A: Deterministic thresholds trigger compaction; the AI agent service generates the summary using the same provider/model as the conversation.
- Q: Should auto compaction retry after a provider context-overflow error? → A: Retry once after safe compaction if conversation state is still eligible.
- Q: What recent context must remain uncompressed after compaction? → A: Keep at least the latest user turn, latest assistant turn, and complete tool-call/result groups.
- Q: Can users manually compact before automatic thresholds are met? → A: Yes, when enough eligible context exists and the conversation is not busy.

## User Scenarios & Testing _(mandatory)_

### User Story 1 - Automatic Compaction Prevents Context Exhaustion (Priority: P1)

As a user running a long AI agent conversation, I want the app to automatically compact older conversation context before the model runs out of usable context, so the agent can continue working without me manually restarting or losing the important state.

**Why this priority**: Auto compaction protects the core agent workflow. Without it, long-running conversations can fail or degrade when context grows too large.

**Independent Test**: Start a conversation that reaches the configured compaction threshold, send another message, and verify the app compacts eligible prior context before the assistant continues while preserving the visible conversation history.

**Acceptance Scenarios**:

1. **Given** auto compaction is enabled and a conversation exceeds the configured percentage threshold and remaining-token threshold, **When** the user sends a message or the agent prepares its next response, **Then** the app compacts eligible prior context before the assistant response is requested.
2. **Given** a conversation is below either configured threshold, **When** the user sends a message, **Then** the app does not compact automatically.
3. **Given** a conversation has pending tool approvals or unresolved tool calls, **When** the conversation exceeds the configured threshold, **Then** auto compaction waits until the tool state is resolved before compacting.
4. **Given** auto or manual compaction starts, **When** the user views the conversation list, **Then** the app shows a separate temporary Compacting row with tool-style loading until compaction completes.
5. **Given** compaction is running, **When** the user sends messages, **Then** the system uses the existing message-send queue by treating compaction as a busy condition and sends queued messages in order after compaction finishes.
6. **Given** an assistant request fails with a provider context-overflow error and the conversation state is safe to compact, **When** auto compaction succeeds, **Then** the app retries the assistant request once.

---

### User Story 2 - Manual Compaction From Chat Input (Priority: P2)

As a user in a long conversation, I want a manual compact control in the chat input area, so I can intentionally compress context before continuing.

**Why this priority**: Manual compaction gives users control when they know the conversation should be checkpointed, even if automatic thresholds have not been reached.

**Independent Test**: Open an existing conversation with enough messages, press the compact control in the chat input area, and verify the app creates a compacted context summary while the visible transcript remains available.

**Acceptance Scenarios**:

1. **Given** a conversation has enough eligible prior context, even if it is below automatic compaction thresholds, **When** the user presses the manual compact control, **Then** the app compacts the eligible context and shows clear completion feedback.
2. **Given** the conversation is currently busy, waiting for tool approval, or has no eligible context to compact, **When** the user views the chat input area, **Then** the manual compact control is disabled or unavailable with an understandable reason.
3. **Given** manual compaction fails, **When** the failure occurs, **Then** the app leaves the conversation unchanged and shows a recoverable error message.
4. **Given** manual compaction succeeds, **When** the summary checkpoint is created, **Then** the app waits for the next user action and does not automatically request another assistant response.
5. **Given** a compaction summary exists, **When** the user views chat history, **Then** the app shows a visible Compacted widget that can be tapped to view compaction details.
6. **Given** a user opens compaction details, **When** compaction content is displayed, **Then** the app shows the stored original text without trimming or whitespace normalization.

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
- A provider returns a context-overflow error during assistant continuation: if the conversation is safe to compact, the app compacts eligible context and retries the assistant request once; if retry fails, it follows the automatic compaction failure behavior.
- Automatic compaction fails after thresholds are met: the app blocks the pending assistant continuation, leaves compactable context unchanged, persists a visible chat error message, and allows the user to retry.
- A conversation already has a previous compaction summary: new compaction updates the active compacted context without duplicating old compacted content in the next prompt.
- Compaction summaries are shown in chat as a visible Compacted widget that users can tap to inspect details, while represented context still routes through compaction metadata.
- The latest messages contain unresolved tool approvals, active tool calls, unsent user drafts, or failed messages: compaction skips unsafe ranges and never splits tool calls from their results.
- The selected model has no known context limit: auto compaction does not run from percentage-based thresholds, and the app communicates that context-limit data is unavailable.
- While compaction is running, conversation list state shows a temporary Compacting row and removes it when compaction finishes or fails.

## Requirements _(mandatory)_

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
- **FR-021**: The system MUST show each compaction summary in the normal chat transcript as a visible `Compacted` widget that users can tap to inspect compaction details.
- **FR-022**: The system MUST NOT automatically request an assistant response after a manual compaction succeeds.
- **FR-023**: The system MUST block the pending assistant continuation and persist a visible recoverable chat error message if required automatic compaction fails.
- **FR-024**: The system MUST show a temporary `Compacting` row with tool-like loading in the conversation list while compaction is in progress, without replacing the existing conversation row.
- **FR-025**: The system MUST treat active compaction as a busy condition for sending and MUST route user messages sent during compaction through the existing message-send queue.
- **FR-026**: The system MUST store compaction message text in its original untrimmed form for user-visible inspection.
- **FR-027**: The system MUST apply compaction-text trimming or whitespace normalization only when constructing agent-history payload sent to the model.
- **FR-028**: The system MUST use deterministic threshold checks to decide when automatic compaction is required.
- **FR-029**: The system MUST generate compaction summaries by calling the AI agent service with the same model provider and model selected for the active conversation.
- **FR-030**: The system MUST pass a compaction-specific system prompt to the AI agent service that instructs it to preserve compacted conversation state for future use cases without inventing unseen context.
- **FR-031**: The system MUST use a default remaining-token safety gap of `max(maxOutputTokens, 20% of the selected model context limit)`, capped at 15,000 tokens, unless the user configures a different remaining-token threshold.
- **FR-032**: The system MUST retry an assistant continuation at most once after a provider context-overflow error when safe auto compaction succeeds.
- **FR-033**: The system MUST keep at least the latest user turn, latest assistant turn, and complete tool-call/result groups uncompressed when creating a compaction summary.
- **FR-034**: The system MUST allow manual compaction before automatic thresholds are met when enough eligible context exists and the conversation is not busy.

### Key Entities

- **Compaction Settings**: User-controlled preferences for auto compaction enabled state, usage percentage threshold, remaining-token threshold, and default reset behavior.
- **Compaction Summary**: A concise representation of earlier conversation context that future assistant responses can use instead of the full compacted content.
- **Compaction Range**: The set of prior conversation messages represented by a compaction summary.
- **Eligible Conversation Context**: Conversation content that is safe to compact because it is no longer active, unresolved, or required as immediate recent context.

### Assumptions

- Default auto compaction is enabled.
- Default usage percentage threshold is 80%.
- Default remaining-token threshold is `max(maxOutputTokens, 20% of the selected model context limit)`, capped at 15,000 tokens, and can be changed in compaction settings.
- Automatic compaction eligibility is decided by configured thresholds before invoking AI summary generation.
- Compaction summary generation uses the active conversation model/provider rather than a separate fallback summarizer model.
- Manual compaction keeps a recent uncompressed tail rather than replacing the entire conversation context.
- The recent uncompressed tail includes at least the latest user turn, latest assistant turn, and complete tool-call/result groups.
- Manual compaction does not require automatic threshold conditions when enough eligible context exists.
- Manual compaction is a checkpoint action and does not continue the assistant until the user sends or triggers another action.
- Automatic compaction failure blocks the pending assistant continuation, persists a visible chat error message, and does not mark any context as compacted.
- Compaction affects model context only; it does not delete or hide existing visible chat messages.
- Settings apply globally to all conversations unless a future feature adds per-workspace or per-model overrides.

## Success Criteria _(mandatory)_

### Measurable Outcomes

- **SC-001**: In test conversations that cross configured thresholds, auto compaction occurs before the next assistant response for 100% of tested eligible checks.
- **SC-002**: Users can manually compact an eligible conversation in no more than two actions from the chat screen.
- **SC-003**: Users can find and update compaction settings in under 30 seconds during usability testing.
- **SC-004**: After compaction, 100% of visible chat messages remain accessible to the user.
- **SC-005**: Invalid compaction settings are rejected 100% of the time with a user-readable explanation.
- **SC-006**: No assistant response is requested with duplicated compacted content and summary content after a successful compaction.
- **SC-007**: Compaction never proceeds in test cases with unresolved tool approvals or pending tool calls.
- **SC-008**: 100% of compaction summary messages created in tests are marked as manual or automatic and contain no tool-call metadata.
- **SC-009**: 100% of compaction summary messages created in tests are shown as a visible `Compacted` widget in the normal chat transcript with a working details interaction.
- **SC-010**: 100% of successful manual compaction tests produce no automatic assistant continuation.
- **SC-011**: 100% of failed required auto-compaction tests block assistant continuation, preserve uncompacted context, and create a visible chat error message.
- **SC-012**: 100% of compaction runs show a temporary `Compacting` row in the conversation list during execution, and remove it on completion or failure.
- **SC-013**: In tests where users send messages during compaction, 100% of messages are queued via the existing queue and later sent in original order after compaction completes.
- **SC-014**: In compaction detail-view tests, 100% of stored compaction messages preserve original whitespace/content fidelity.
- **SC-015**: In payload-construction tests, 100% of compaction messages sent to agent history use normalized text while stored visible content remains unchanged.
- **SC-016**: In compaction-generation tests, 100% of summaries are requested through the AI agent service using the active conversation model provider/model and a compaction-specific system prompt.
- **SC-017**: In context-overflow tests with safe eligible context, 100% of assistant continuations retry exactly once after successful auto compaction.
- **SC-018**: In compaction-boundary tests, 100% of summaries keep the latest user turn, latest assistant turn, and complete tool-call/result groups outside the compacted range.
- **SC-019**: In manual compaction tests below automatic thresholds, 100% of eligible non-busy conversations can still be compacted manually.

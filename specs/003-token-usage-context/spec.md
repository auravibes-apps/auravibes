# Feature Specification: Conversation Token Usage Indicator

**Feature Branch**: `003-token-usage-context`  
**Created**: 2026-04-15  
**Status**: Draft  
**Input**: User description: "Store token usage in messages, calculate total token usage by conversation, and show used/limit/percent with circular progress in the conversation top bar."

## User Scenarios & Testing *(mandatory)*

<!--
  IMPORTANT: User stories should be PRIORITIZED as user journeys ordered by importance.
  Each user story/journey must be INDEPENDENTLY TESTABLE - meaning if you implement just ONE of them,
  you should still have a viable MVP (Minimum Viable Product) that delivers value.
  
  Assign priorities (P1, P2, P3, etc.) to each story, where P1 is the most critical.
  Think of each story as a standalone slice of functionality that can be:
  - Developed independently
  - Tested independently
  - Deployed independently
  - Demonstrated to users independently
-->

### User Story 1 - View live context usage while chatting (Priority: P1)

As a user in a conversation, I can see how many tokens have been used out of the model context limit and the percentage consumed, so I can decide when to shorten prompts or start a new conversation.

**Why this priority**: This is the core user value requested and must work in real time while responses stream.

**Independent Test**: Send a message that produces a streaming assistant response and verify the top bar updates continuously to show used tokens, max limit, percentage text, and circular progress.

**Acceptance Scenarios**:

1. **Given** a conversation with prior messages that have token usage data, **When** the conversation screen opens, **Then** the top bar shows `used/limit - percent` derived from those messages.
2. **Given** an assistant response is streaming with growing token usage, **When** new stream chunks arrive, **Then** top bar values and progress indicator update without waiting for stream completion.

---

### User Story 2 - Preserve usage across app restarts (Priority: P2)

As a user returning to a conversation, I can still see accurate usage totals without re-running old requests.

**Why this priority**: Persisted usage avoids confusion and keeps historical context consumption visible.

**Independent Test**: Complete a conversation turn, close/reopen app, open same conversation, and verify displayed usage matches previous session.

**Acceptance Scenarios**:

1. **Given** assistant messages were previously stored with usage, **When** app restarts and conversation reloads, **Then** usage totals are reconstructed from stored message data and displayed.

---

### User Story 3 - Graceful behavior with partial usage data (Priority: P3)

As a user, I still get a stable usage display even if a provider returns partial token fields.

**Why this priority**: Different providers and stream events may omit some usage fields.

**Independent Test**: Simulate usage where `totalTokens` is absent but prompt/response are present and verify display computes correctly.

**Acceptance Scenarios**:

1. **Given** a message has no `totalTokens` but has prompt and completion tokens, **When** totals are computed, **Then** system uses `prompt + completion` for that message.

---

### Edge Cases

<!--
  ACTION REQUIRED: The content in this section represents placeholders.
  Fill them out with the right edge cases.
-->

- Model context limit is missing or zero: UI must not divide by zero and must show a safe fallback (e.g., used only and 0% progress).
- Percent exceeds 100 due to stale or changed model limit: display raw percent value (may exceed 100) while clamping progress bar to 100%.
- Streaming usage not present on intermediate chunks: keep last known value until a newer valid value arrives.
- A message has no usage fields at all: treat message usage as zero.

## Requirements *(mandatory)*

<!--
  ACTION REQUIRED: The content in this section represents placeholders.
  Fill them out with the right functional requirements.
-->

### Functional Requirements

- **FR-001**: System MUST store token usage per message in message metadata using the fields `promptTokens`, `completionTokens`, and `totalTokens` when available.
- **FR-002**: System MUST compute message token usage using this order: `totalTokens`; otherwise `promptTokens + completionTokens`; otherwise `0`.
- **FR-003**: System MUST compute conversation used tokens from the latest assistant message usage (with streaming overlay when in-progress).
- **FR-004**: System MUST include in-progress streaming usage in conversation totals while the assistant message is unfinished.
- **FR-005**: System MUST use the selected conversation model context window limit as the denominator for percent usage.
- **FR-006**: System MUST display in the conversation top bar: used tokens, model limit, and percent in the format `39k/205k - 19%`.
- **FR-007**: System MUST render a circular progress indicator in the top bar where fill amount matches displayed percent.
- **FR-008**: System MUST update the top bar usage display live during streaming responses.
- **FR-009**: System MUST persist message usage so totals remain available after app restart.
- **FR-010**: System MUST clamp progress to a minimum of 0 and maximum of 1.0; raw percent may exceed 100 to indicate overflow.

### Key Entities *(include if feature involves data)*

- **MessageUsageMetadata**: Per-message usage snapshot with `promptTokens`, `completionTokens`, `totalTokens`.
- **ConversationUsageSummary**: Derived runtime aggregate for one conversation with `usedTokens`, `limitTokens`, `percentUsed`.

## Clarifications

### Session 2026-04-15

- Q: Scope level for tracking? → A: Per conversation only.
- Q: Formula for used tokens? → A: prompt + completion, with total when provided.
- Q: Denominator for percent? → A: selected model max context window.
- Q: Update timing? → A: live while streaming.
- Q: Persistence strategy? → A: minimal message metadata fields only.

## Success Criteria *(mandatory)*

<!--
  ACTION REQUIRED: Define measurable success criteria.
  These must be technology-agnostic and measurable.
-->

### Measurable Outcomes

- **SC-001**: In 100% of tested conversation loads, top bar displays a usage string in `used/limit - percent%` format within 1 second of screen render.
- **SC-002**: During streamed assistant responses, displayed used tokens and percent refresh at least once per persisted stream update cycle.
- **SC-003**: In provider payloads lacking `totalTokens` but containing prompt and completion tokens, computed used tokens are correct in 100% of test cases.
- **SC-004**: After app restart, conversation usage totals match pre-restart values for 100% of tested conversations with stored metadata.

# Feature Specification: Avoid Approval Flash

**Feature Branch**: `008-avoid-approval-flash`  
**Created**: 2026-04-25  
**Status**: Draft  
**Input**: User description: "it seams that when a tool that is approved when it appears on the agent loop, on the conversation screen, it flash the tool aproval widgets even when its approved always or by conversation, the case is that if is approved it sould not flashes, it should just run, might be that the widgets dont know about the approval or something like that, but dont want to have code duplicated, so we need it in a clean and optimised way"

## User Scenarios & Testing _(mandatory)_

### User Story 1 - Approved Tools Run Without Flash (Priority: P1)

As a user watching the conversation, I want tools that are already approved to run without briefly showing approval controls, so the agent loop feels stable and does not ask for decisions I have already made.

**Why this priority**: This is the core defect. A visible flash for already-approved tools creates confusion and makes users think another approval is required.

**Independent Test**: Can be fully tested by approving a tool for the current conversation or permanently, then triggering the same tool again and confirming no approval prompt or approval controls appear at any point before execution.

**Acceptance Scenarios**:

1. **Given** a tool has been approved for the current conversation, **When** the agent requests that tool again, **Then** the conversation shows the tool running without any visible approval prompt flash.
2. **Given** a tool has been approved always, **When** the agent requests that tool in any eligible conversation, **Then** the conversation shows the tool running without any visible approval prompt flash.
3. **Given** an already-approved tool starts running, **When** the conversation screen updates through the request and execution states, **Then** no approval-only controls are rendered briefly or temporarily.

---

### User Story 2 - Unapproved Tools Still Require Approval (Priority: P2)

As a user, I want tools without an applicable approval to still ask for permission, so safety controls remain intact while approved tools skip unnecessary prompts.

**Why this priority**: The fix must not weaken approval behavior for tools that have not been authorized.

**Independent Test**: Can be tested by triggering a tool with no prior approval and confirming the user must approve or reject it before it runs.

**Acceptance Scenarios**:

1. **Given** a tool has no applicable approval, **When** the agent requests that tool, **Then** the conversation displays approval controls and waits for the user's decision.
2. **Given** a user rejects a tool request, **When** the agent loop continues, **Then** the rejected tool does not run as though it were approved.

---

### User Story 3 - Consistent Approval State Across Conversation Updates (Priority: P3)

As a user, I want the conversation display to match the actual approval state consistently, so tool activity does not flicker or contradict the saved approval decision during rapid updates.

**Why this priority**: The user specifically noted that the visible approval controls may not know about approval state. Consistency prevents regressions during streaming, refresh, or state changes.

**Independent Test**: Can be tested by repeatedly triggering approved tools while the conversation updates and confirming the display remains stable across every request lifecycle.

**Acceptance Scenarios**:

1. **Given** multiple tool requests arrive in sequence and some are already approved, **When** the conversation screen updates, **Then** only unapproved requests show approval controls.
2. **Given** an approval decision changes from pending to approved, **When** the same request transitions to running, **Then** the approval controls disappear without reappearing as a flash.

### Edge Cases

- An approval exists for one conversation only: the tool must skip approval flashes only in that conversation and still require approval elsewhere.
- An approval exists as always-approved: the tool must skip approval flashes everywhere the approval applies.
- An approval is revoked, expired, or no longer applicable: the next matching tool request must show approval controls normally.
- Several tool requests appear close together: each request must use its own applicable approval state without borrowing another request's decision.
- The conversation is reopened or refreshed: approved requests must still display as running or completed without replaying approval controls.

## Requirements _(mandatory)_

### Functional Requirements

- **FR-001**: The system MUST determine whether a tool request already has an applicable approval before showing approval controls to the user.
- **FR-002**: The system MUST NOT show approval controls, even briefly, for a tool request that is already approved for the current conversation.
- **FR-003**: The system MUST NOT show approval controls, even briefly, for a tool request that is approved always and matches the approval scope.
- **FR-004**: The system MUST continue showing approval controls for tool requests that do not have an applicable approval.
- **FR-005**: The system MUST keep approval display behavior consistent with the decision used to run or block the tool.
- **FR-006**: The system MUST use a single shared approval decision outcome for both deciding whether a tool can run and deciding whether approval controls should be visible.
- **FR-007**: The system MUST preserve existing approve, reject, approve-for-conversation, and approve-always user outcomes.
- **FR-008**: The system MUST handle rapid conversation updates without transiently displaying approval controls for already-approved tool requests.
- **FR-009**: The system MUST clearly distinguish pending approval, approved/running, rejected, and completed tool request states in the conversation.

### Key Entities

- **Tool Request**: A requested action from the agent that may require user approval before it can run.
- **Approval Decision**: The user's authorization outcome for a tool request, including one-time, conversation-scoped, always-approved, rejected, or pending states.
- **Conversation Display State**: The user-visible state for each tool request in the conversation, including whether approval controls should appear.

### Assumptions

- Existing approval scopes include at least one conversation-scoped approval and one always-approved option.
- The desired behavior applies only when an approval is already valid before or at the time the tool request appears in the conversation.
- The feature should remove unnecessary approval-control flashes without changing the meaning of approvals or rejections.
- A clean implementation means approval visibility and tool execution decisions should share the same underlying decision result instead of duplicating approval checks.

## Success Criteria _(mandatory)_

### Measurable Outcomes

- **SC-001**: In 100% of tested already-approved tool requests, approval controls never appear before the tool starts running.
- **SC-002**: In 100% of tested unapproved tool requests, approval controls still appear and the tool does not run before user approval.
- **SC-003**: Users can trigger an already-approved tool and see it progress to running without any extra approval action in under 1 second under normal app conditions.
- **SC-004**: Repeated approved tool requests across at least 20 consecutive conversation updates show zero visible approval-control flashes.
- **SC-005**: No existing approval outcome changes: approve, reject, approve-for-conversation, and approve-always continue to produce the same user-visible result except for removing unnecessary flashes.

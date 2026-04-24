# Feature Specification: Reusable Agents

**Feature Branch**: `007-reusable-agents`  
**Created**: 2026-04-24  
**Status**: Draft  
**Input**: User description: "Agent workflows: reusable agents, tool presets, scheduled/background tasks, flow builder. A table that design the agent per workflow. If user don't have an agent, the user can run conversation with no agent (or a general agent from our system whatever is best for UX). In new chat and in conversation, the chat interface should allow selecting an agent from no agent to any created one. When creating or editing the agent, the agent has name and instructions. No tools for now, no model for now. When a user selects an agent for the conversation, then the instructions are added as system prompts. How other AI agents manage the agents system instructions?"

## Clarifications

### Session 2026-04-24

- Q: What ownership scope should reusable agents have? → A: Workspace-scoped agents
- Q: What uniqueness rule should reusable agent names follow? → A: Store display name and slug; slug must be unique per workspace
- Q: What should happen when users delete reusable agents? → A: Users can delete agents; conversations using them fall back to "No Agent"
- Q: Should conversations use latest agent instructions or a selection-time snapshot? → A: Conversations always use the latest saved agent instructions

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Create a reusable agent (Priority: P1)

A user creates a reusable agent by giving it a clear name and reusable instructions so they can apply the same behavior across multiple chats.

**Why this priority**: Agent creation is the foundation for reuse. Without it, chat selection has no user-created agents to apply.

**Independent Test**: Can be fully tested by creating an agent with a name and instructions, then confirming it appears in the user's agent list.

**Acceptance Scenarios**:

1. **Given** a user has no reusable agents, **When** they create an agent with a valid name and instructions, **Then** the agent is saved and appears in the agent list.
2. **Given** a user enters an empty name or empty instructions, **When** they try to save the agent, **Then** the system prevents saving and explains which field needs input.
3. **Given** a user has existing reusable agents, **When** they create another agent with a distinct name, **Then** both agents remain available for future conversations.
4. **Given** a user enters a name whose generated slug already exists in the workspace, **When** they try to save the agent, **Then** the system prevents saving and asks for a distinct name.

---

### User Story 2 - Select an agent for a new chat (Priority: P1)

A user starts a new chat and chooses whether the conversation should use no agent or one of their reusable agents.

**Why this priority**: The main value of reusable agents is applying saved instructions at conversation start.

**Independent Test**: Can be fully tested by opening a new chat, selecting an agent, sending a message, and confirming the conversation uses the selected agent's instructions.

**Acceptance Scenarios**:

1. **Given** a user has created reusable agents, **When** they start a new chat, **Then** the chat interface offers "No Agent" and each created agent as choices.
2. **Given** a user selects "No Agent" for a new chat, **When** they send a message, **Then** the conversation runs without user-defined agent instructions.
3. **Given** a user selects a reusable agent for a new chat, **When** they send a message, **Then** the conversation applies that agent's instructions to the assistant behavior.

---

### User Story 3 - Change the agent in an existing conversation (Priority: P2)

A user changes the selected agent inside an existing conversation so future assistant responses follow the newly selected instructions.

**Why this priority**: Users may discover that a conversation needs a different role or no agent after it has already started.

**Independent Test**: Can be fully tested by changing the selected agent in an existing conversation and confirming subsequent responses use the new selection.

**Acceptance Scenarios**:

1. **Given** a conversation is using "No Agent", **When** the user selects a reusable agent, **Then** future assistant responses use the selected agent's instructions.
2. **Given** a conversation is using one reusable agent, **When** the user selects a different reusable agent, **Then** future assistant responses use the new agent's instructions.
3. **Given** a conversation is using a reusable agent, **When** the user selects "No Agent", **Then** future assistant responses stop using user-defined agent instructions.

---

### User Story 4 - Edit a reusable agent (Priority: P2)

A user edits a reusable agent's name or instructions so the saved agent remains useful as their workflow changes.

**Why this priority**: Agent instructions need refinement over time, but editing can ship after basic create-and-select behavior.

**Independent Test**: Can be fully tested by editing an existing agent, selecting it in a conversation, and confirming the updated instructions are used for future responses.

**Acceptance Scenarios**:

1. **Given** a user has an existing agent, **When** they edit the agent name, **Then** selectors and lists show the updated name.
2. **Given** a user has an existing agent, **When** they edit the agent instructions, **Then** future responses in conversations using that agent apply the updated instructions.
3. **Given** a conversation already used an agent before it was edited, **When** the user continues the conversation, **Then** the interface clearly reflects the currently selected agent and uses the latest saved instructions for future responses.

---

### User Story 5 - Browse agents in a workflow-oriented table (Priority: P3)

A user views reusable agents in a table-like management surface so they can scan names, instructions previews, and usage context before editing or selecting one.

**Why this priority**: A table improves management as agents grow, but creation and selection deliver the first usable value.

**Independent Test**: Can be fully tested by creating multiple agents and confirming the management surface presents them in a scannable list with edit access.

**Acceptance Scenarios**:

1. **Given** a user has multiple agents, **When** they open agent management, **Then** each agent appears as one row or item with its name and an instructions preview.
2. **Given** a user wants to refine an agent, **When** they choose edit from the management surface, **Then** they can update the agent's name and instructions.

---

### User Story 6 - Delete a reusable agent (Priority: P3)

A user deletes a reusable agent they no longer need so outdated instructions do not clutter the workspace's agent list.

**Why this priority**: Deletion completes the agent lifecycle, but users can still get value from create, edit, and select before deletion ships.

**Independent Test**: Can be fully tested by deleting an agent and confirming it no longer appears in agent management or chat selectors.

**Acceptance Scenarios**:

1. **Given** a user has an existing reusable agent, **When** they delete the agent, **Then** it no longer appears in the workspace's agent management surface or chat selectors.
2. **Given** a deleted agent was selected in existing conversations, **When** those conversations are opened or continued, **Then** they fall back to "No Agent" before the next message is sent.

### Edge Cases

- If a user has no created agents, the chat selector still allows starting or continuing with "No Agent".
- If an agent is renamed while selected in a conversation, the conversation selector shows the updated name without changing the selected agent.
- If an edited name would create a duplicate workspace slug, the system prevents saving and keeps the previous agent values.
- If an agent's instructions are very long, the management surface truncates previews while preserving the full instructions for editing and conversation use.
- If the selected agent is deleted, the conversation falls back to "No Agent" and informs the user before the next message is sent.
- If a user switches agents mid-conversation, only future assistant responses are affected; previous messages remain unchanged.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Users MUST be able to create a workspace-scoped reusable agent with a name and instructions.
- **FR-002**: Users MUST be able to edit a reusable agent's name and instructions.
- **FR-003**: The system MUST prevent saving a reusable agent when the name or instructions are empty.
- **FR-004**: The system MUST store both the user-facing agent name and a slug derived from that name.
- **FR-005**: Reusable agent slugs MUST be unique within each workspace.
- **FR-006**: Users MUST be able to delete reusable agents from the current workspace.
- **FR-007**: When a reusable agent is deleted, the system MUST remove it from the workspace's agent management surface and chat selectors.
- **FR-008**: Conversations that referenced a deleted agent MUST fall back to "No Agent" before the next message is sent.
- **FR-009**: Users MUST be able to view reusable agents for the current workspace in a management surface suitable for scanning multiple agents.
- **FR-010**: The agent management surface MUST show each agent's name, slug, and a preview of its instructions.
- **FR-011**: The chat interface MUST let users choose "No Agent" or one of the current workspace's reusable agents when starting a new chat.
- **FR-012**: The chat interface MUST let users choose "No Agent" or one of the current workspace's reusable agents from within an existing conversation.
- **FR-013**: "No Agent" MUST be available even when the user has no created agents.
- **FR-014**: When a reusable agent is selected for a conversation, the assistant MUST apply that agent's instructions as higher-priority conversation guidance than the user's normal message content.
- **FR-015**: User-created agent instructions MUST NOT override non-user system safety, security, or platform rules.
- **FR-016**: Changing the selected agent in an existing conversation MUST affect future assistant responses only.
- **FR-017**: The system MUST clearly show the currently selected agent for a conversation.
- **FR-018**: Conversations using a reusable agent MUST use the latest saved instructions for that agent when generating future assistant responses.
- **FR-019**: The current feature MUST exclude tool presets, scheduled or background tasks, flow-builder behavior, and model selection.

### Key Entities

- **Reusable Agent**: A workspace-scoped assistant profile with a display name, unique workspace slug, and instructions. It is intended to be selected across multiple conversations in that workspace.
- **Conversation Agent Selection**: The current agent choice for a conversation. It can be "No Agent" or one reusable agent.
- **Agent Management Surface**: A scannable list or table where users create, review, and edit reusable agents.

### Assumptions

- "No Agent" is the default state because it is explicit, predictable, and avoids inventing an unseen general-agent behavior.
- Reusable agents belong to one workspace and are not available from other workspaces.
- Agent slugs are derived from display names and must be unique only inside their workspace.
- Agent instructions act like conversation-level system guidance, while platform and safety rules remain higher priority.
- Agent edits apply to future uses and future responses; historical messages are not rewritten.
- Conversation agent selections reference the reusable agent itself, not a frozen copy of the instructions.
- Deleted agents are unavailable for future selection, and affected conversations use "No Agent" going forward.
- Tool presets, scheduled/background tasks, and flow builder are future workflow capabilities, not part of this feature's first scope.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can create a reusable agent with valid name and instructions in under 60 seconds.
- **SC-002**: A user can start a new chat with "No Agent" or a selected reusable agent in 2 actions or fewer from the new-chat screen.
- **SC-003**: A user can change the selected agent in an existing conversation in 2 actions or fewer from the conversation screen.
- **SC-004**: 95% of tested agent selections result in future assistant responses following the selected agent's instructions while preserving higher-priority platform rules.
- **SC-005**: Users can identify the currently selected conversation agent within 3 seconds during usability testing.
- **SC-006**: Users can find and edit an existing reusable agent within 30 seconds when the account has at least 10 agents.

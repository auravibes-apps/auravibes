# Data Model: Reusable Agents

## Entity: ReusableAgent

Workspace-scoped assistant profile selected by conversations.

Fields:
- `id`: Unique identifier.
- `workspaceId`: Parent workspace identifier. Required.
- `name`: User-facing display name. Required, trimmed, non-empty.
- `slug`: Slug derived from `name`. Required, non-empty, unique within `workspaceId`.
- `instructions`: User-authored reusable agent instructions. Required, trimmed, non-empty.
- `createdAt`: Creation timestamp.
- `updatedAt`: Last update timestamp.

Relationships:
- Belongs to one Workspace.
- Can be referenced by many Conversations.

Validation:
- `workspaceId` must not be empty.
- `name` must not be empty after trimming.
- `slug` must not be empty after generation.
- `(workspaceId, slug)` must be unique.
- `instructions` must not be empty after trimming.

Lifecycle:
- Created from Agents management screen.
- Edited from Agents management screen.
- Deleted from Agents management screen.
- Deleted agents are unavailable in selectors.

## Entity: Conversation

Existing conversation entity extended with optional selected agent.

Added field:
- `agentId`: Optional selected reusable agent identifier. `null` means "No Agent".

Relationships:
- Belongs to one Workspace.
- May reference one ReusableAgent in the same workspace.

Validation:
- `agentId` may be null.
- If `agentId` is present, the referenced agent must exist in the conversation workspace.

Lifecycle:
- New conversation starts with `agentId` from the new-chat selector.
- Existing conversation can update `agentId` from the conversation selector.
- If referenced agent is deleted, conversation falls back to `agentId = null` before the next message is sent.

## Entity: ConversationAgentSelection

User-facing state derived from Conversation and ReusableAgent.

Fields:
- `conversationId`: Conversation identifier.
- `selectedAgentId`: Optional reusable agent identifier.
- `label`: "No Agent" or selected agent display name.
- `slug`: Selected agent slug when present.

Validation:
- `selectedAgentId = null` is always valid.
- Selected agent must belong to the same workspace as the conversation.

## State Transitions

```text
ReusableAgent
  draft input -> saved
  saved -> edited
  saved -> deleted

Conversation.agentId
  null -> agentId        (user selects agent)
  agentId -> otherAgent  (user switches agent)
  agentId -> null        (user selects No Agent)
  deletedAgent -> null   (fallback before next send)
```

## Database Notes

- Add `agents` table with a foreign key to `workspaces`.
- Add unique index for `(workspace_id, slug)`.
- Add nullable `agent_id` to `conversations`.
- Migration increments Drift schema version.
- Deleting an agent should make affected conversations behave as "No Agent"; implementation may either null affected `agent_id` values in the delete operation or use nullable references with fallback logic, but user-visible behavior must match the spec.

## Prompt Composition

Prompt generation receives:
- Existing conversation messages.
- Optional selected agent instructions resolved from the latest saved ReusableAgent.

Output rule:
- If no agent is selected, build prompt from conversation messages only.
- If an agent is selected, prepend agent instructions as conversation-level guidance before conversation history.
- User-created agent instructions do not override platform safety or security rules.

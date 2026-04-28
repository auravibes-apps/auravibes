# Data Model: Avoid Approval Flash

## Tool Request

Represents an agent-requested tool call stored on the latest assistant message.

**Current source**: `MessageToolCallEntity` in message metadata.

**Fields used by this feature**:

- `id`: Unique tool-call ID used for result updates and approval actions.
- `name`: Tool name used for resolution and display.
- `argumentsRaw`: Raw arguments displayed in the approval card and passed to execution.
- `resultStatus`: Null while pending; non-null when resolved.
- `responseRaw`: Optional tool execution or skip response.

**Validation rules**:

- Only pending calls (`resultStatus == null`) are candidates for approval UI or execution.
- Missing or unresolved tools must become explicit result statuses, not approval prompts.

## Approval Decision

Represents the effective decision for a pending tool request in a conversation.

**Current source**: Existing conversation/workspace tool permission records resolved through `ConversationToolsRepository.checkToolPermission`.

**Fields needed by shared decision result**:

- `toolCallId`: Links the decision to a `Tool Request`.
- `resolvedTool`: Runtime tool metadata needed for execution when available.
- `permissionTableId`: Workspace-tool record ID used for permission checks when available.
- `permissionResult`: Effective `ToolPermissionResult`.

**Validation rules**:

- `granted`: Tool may execute immediately and must not show approval controls.
- `needsConfirmation`: Tool must remain pending and show approval controls.
- `disabledInConversation`, `disabledInWorkspace`, `notConfigured`: Tool should be resolved with the matching explicit status and must not show approval controls.

## Conversation Display State

Represents the conversation-screen projection of pending tool calls.

**Current source**: Provider consumed by `ChatToolApprovalCard` and `ChatConversationScreen`.

**Fields used by this feature**:

- `messageId`: Latest assistant message containing the tool call.
- `toolCall`: Pending `MessageToolCallEntity` needing user confirmation.

**Validation rules**:

- Include only tool calls whose shared approval decision is `needsConfirmation`.
- Exclude already-approved tool calls before rendering the approval card.
- Update consistently when permissions or message metadata change.

## State Transitions

```text
Pending tool request
├── shared decision: granted
│   └── executing/resolved, no approval card
├── shared decision: needsConfirmation
│   └── approval card visible, waits for user action
├── shared decision: disabled/notConfigured
│   └── resolved with explicit status, no approval card
└── user rejects/skips/stops
    └── resolved with user-selected status
```

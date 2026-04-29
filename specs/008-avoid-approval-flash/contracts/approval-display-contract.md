# Contract: Approval Display Decision

## Purpose

Ensure the conversation UI and tool execution use the same effective approval decision for each pending tool request.

## Inputs

- `conversationId`: Current conversation ID.
- `workspaceId`: Workspace containing tool configuration.
- `messageId`: Latest assistant message ID.
- `toolCall`: Pending tool request from message metadata.

## Decision Results

| Result                   | Execution behavior                  | Approval UI behavior            |
| ------------------------ | ----------------------------------- | ------------------------------- |
| `granted`                | Execute tool immediately            | Do not render approval controls |
| `needsConfirmation`      | Wait for user decision              | Render approval controls        |
| `disabledInConversation` | Resolve as disabled in conversation | Do not render approval controls |
| `disabledInWorkspace`    | Resolve as disabled in workspace    | Do not render approval controls |
| `notConfigured`          | Resolve as not configured           | Do not render approval controls |

## Invariants

- A tool call must not be included in approval-card input unless the shared decision result is `needsConfirmation`.
- A tool call that execution treats as `granted` must never render approval controls first.
- A tool call that lacks an applicable approval must continue to render approval controls and wait.
- The UI must not duplicate raw permission-mode precedence logic; it must consume the shared decision outcome.

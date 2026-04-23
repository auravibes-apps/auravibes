# Feature Specification: Fix Native Tool Permissions

**Feature Branch**: `006-fix-native-tool-permissions`
**Created**: 2026-04-22
**Status**: Draft
**Input**: User description: "it seems native tools are failing to run, when it is about to ask for permissions it just skip and just fail the execution and the agent just keep failing trying to call the tools again and again"

## User Scenarios & Testing _(mandatory)_

### User Story 1 - Native Tool Permission Prompt Shows Correctly (Priority: P1)

When the AI agent decides to call a native tool (e.g., URL fetcher) that requires user approval, the app must display the tool approval card in the chat UI. The user can then choose to approve, skip, or stop all pending tools.

**Why this priority**: This is the core user-facing bug. Without a working permission prompt for native tools, the entire native tool system is broken. Users cannot use any native tool that requires approval.

**Independent Test**: Start a conversation, enable a native tool with "always ask" permission, send a message that triggers the tool call. Verify the approval card appears in the chat with the tool name, arguments, and action buttons.

**Acceptance Scenarios**:

1. **Given** a native tool is enabled with "always ask" permission, **When** the agent calls that tool, **Then** the chat UI displays the tool approval card with the tool name and arguments
2. **Given** the approval card is shown for a native tool, **When** the user taps "Allow Once", **Then** the native tool executes and its result is sent back to the agent
3. **Given** the approval card is shown for a native tool, **When** the user taps "Skip", **Then** the tool is marked as skipped and the agent continues without retrying that tool
4. **Given** the approval card is shown for a native tool, **When** the user taps "Allow for Conversation", **Then** the tool executes AND future calls to the same tool in this conversation auto-approve

---

### User Story 2 - Native Tool Failures Are Not Retried in a Loop (Priority: P2)

When a native tool call fails for any reason (not configured, execution error, disabled), the agent must not enter an infinite retry loop. The failure should be communicated clearly to the user, and the agent should either proceed without the tool or stop and inform the user.

**Why this priority**: The retry loop wastes API tokens, produces confusing repeated error messages in the chat, and makes the app appear frozen or broken. Fixing this prevents resource waste even if the underlying permission issue persists.

**Independent Test**: Trigger a native tool call that will fail (e.g., tool not configured in workspace). Verify the agent does not retry the same tool call more than once in a single conversation turn.

**Acceptance Scenarios**:

1. **Given** a native tool call fails with a "not configured" status, **When** the error is returned to the agent, **Then** the agent receives a clear error message and does not retry the same tool call
2. **Given** a native tool call fails with an execution error, **When** the error is returned to the agent, **Then** the agent loop proceeds to the next iteration without re-calling the failed tool
3. **Given** multiple native tool calls are pending and one fails, **When** the agent loop continues, **Then** only the failed tool is marked with error status; other pending tools remain unaffected

---

### User Story 3 - Native Tool Permission Errors Are Diagnosable (Priority: P3)

When native tool permission checks fail, the app must provide enough information for the user to understand why the tool cannot run (e.g., not enabled in workspace, disabled in conversation, missing configuration).

**Why this priority**: Without clear error messages, users cannot self-diagnose whether the issue is a workspace configuration problem, a conversation-level disable, or a bug. This reduces support burden and enables self-service.

**Independent Test**: Trigger a native tool call for a tool that is not configured in the workspace. Verify the chat displays a user-friendly error message indicating the tool needs to be enabled.

**Acceptance Scenarios**:

1. **Given** a native tool is called but not enabled in the workspace, **When** the permission check returns "not configured", **Then** the chat displays a message like "Tool 'url' is not enabled in this workspace. Enable it in workspace settings."
2. **Given** a native tool is disabled at the conversation level, **When** the permission check returns "disabled in conversation", **Then** the chat displays a message indicating the tool was disabled for this conversation
3. **Given** a native tool resolution fails (composite ID parsing error), **When** the tool cannot be found, **Then** the error includes the tool name that was attempted

---

### Edge Cases

- What happens when a native tool call arguments are malformed (missing `input` field)?
- What happens when the workspace tool database ID in the composite name does not match any workspace tool record?
- How does the system handle a native tool that is enabled in the workspace but the tool implementation is missing from `NativeToolService`?
- What happens when the user changes tool permissions while the agent loop is running?
- What happens when multiple tool calls are returned by the LLM and some are native and some are MCP?

## Requirements _(mandatory)_

### Functional Requirements

- **FR-001**: The permission check for native/built-in tools MUST use `resolvedTool.toolIdentifier` (the type string, e.g., "url") for workspace tool lookup, then `workspaceTool.id` (PK) for conversation override lookup
- **FR-002**: When a native tool's workspace permission mode is "always ask", the system MUST return `needsConfirmation` and leave the tool call pending for user approval
- **FR-003**: When a native tool's workspace permission mode is "always allow", the system MUST return `granted` and execute the tool immediately
- **FR-004**: When a native tool is not found in the workspace tools (no matching database record), the system MUST return `notConfigured` with a descriptive error message rather than silently failing
- **FR-005**: The agent iteration loop MUST NOT re-invoke the same failed native tool call in subsequent iterations
- **FR-006**: Tool call result statuses (`notConfigured`, `disabledInWorkspace`, `disabledInConversation`, `toolNotFound`, `executionError`) MUST be persisted to the message metadata so the agent does not re-attempt them
- **FR-007**: Native tool error messages shown to the user MUST include the tool name and a human-readable explanation of why the tool could not run
- **FR-008**: The tool approval card in the chat UI MUST render correctly for native tools, showing the tool name, arguments preview, and action buttons (Allow Once, Allow for Conversation, Skip, Stop All)

### Key Entities

- **NativeToolType**: Enum of available native tool types (currently: `url`). Used to identify which native tool implementation to invoke.
- **ResolvedTool**: Union type representing a resolved tool (builtIn / mcp / native). Contains the `tableId` (workspace tool database ID) used for permission lookups.
- **ToolPermissionResult**: Enum representing the outcome of a permission check (`granted` / `needsConfirmation` / `disabledInConversation` / `disabledInWorkspace` / `notConfigured`).
- **ToolCallResultStatus**: Enum representing the outcome of a tool execution attempt (`success` / `skipped` / `stopped` / `toolNotFound` / `notConfigured` / `disabledInWorkspace` / `disabledInConversation` / `executionError`).
- **MessageToolCallEntity**: Represents a tool call within a message, including `resultStatus` (null = pending), `responseRaw`, and `isPending` / `isResolved` flags.

## Success Criteria _(mandatory)_

### Measurable Outcomes

- **SC-001**: 100% of native tool calls with "always ask" permission display the approval card in the chat before execution
- **SC-002**: Zero native tool calls result in the agent retrying the same failed tool call more than once per conversation turn
- **SC-003**: Users can identify the cause of any native tool failure from the message displayed in the chat, without needing to inspect logs or database records
- **SC-004**: Native tools with "always allow" permission execute immediately without showing an approval card, completing within normal execution time

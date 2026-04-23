# Data Model: Fix Native Tool Permissions

**Date**: 2026-04-22
**Feature**: 006-fix-native-tool-permissions

## Entities

No new entities. All entities below already exist in the codebase.

### ResolvedTool (existing)

| Field          | Type               | Description                                       |
| -------------- | ------------------ | ------------------------------------------------- |
| type           | `ResolvedToolType` | builtIn / mcp / native                            |
| tableId        | `String`           | Workspace tool database ID for permission lookups |
| toolIdentifier | `String`           | Tool type identifier (e.g., "url", "calculator")  |
| mcpServerId    | `String?`          | MCP server ID (null for native/built-in)          |
| nativeTool     | `NativeToolType?`  | Native tool type enum                             |

### MessageToolCallEntity (existing)

| Field        | Type                    | Description                                     |
| ------------ | ----------------------- | ----------------------------------------------- |
| id           | `String`                | Unique tool call ID                             |
| name         | `String`                | Composite tool name (e.g., "native_abc123_url") |
| argumentsRaw | `String`                | JSON arguments                                  |
| resultStatus | `ToolCallResultStatus?` | null = pending, or terminal status              |
| responseRaw  | `String?`               | Tool result or error message                    |

### ToolCallResultStatus (existing enum)

| Value                    | Meaning                                    |
| ------------------------ | ------------------------------------------ |
| `null` (pending)         | Awaiting permission check or user approval |
| `success`                | Tool executed successfully                 |
| `skipped`                | User skipped the tool                      |
| `stopped`                | User stopped all pending tools             |
| `toolNotFound`           | Composite name could not be resolved       |
| `notConfigured`          | Tool not in workspace tools or disabled    |
| `disabledInWorkspace`    | Tool disabled at workspace level           |
| `disabledInConversation` | Tool disabled at conversation level        |
| `executionError`         | Tool threw during execution                |

### ToolPermissionResult (existing enum)

| Value                    | Meaning                            |
| ------------------------ | ---------------------------------- |
| `granted`                | Auto-approved (alwaysAllow)        |
| `needsConfirmation`      | Requires user approval (alwaysAsk) |
| `disabledInConversation` | Blocked by conversation override   |
| `disabledInWorkspace`    | Blocked by workspace setting       |
| `notConfigured`          | No workspace tool record found     |

## Proposed Changes to Existing Data

### MessageToolCallEntity.responseRaw — Enhanced for error statuses

Currently: `null` for all error statuses.
Proposed: Descriptive error message including tool name and reason.

Example for `notConfigured`:

```
"Tool 'url' is not enabled in this workspace. Enable it in workspace settings to use it."
```

Example for `toolNotFound`:

```
"Tool 'native_abc123_unknown' could not be resolved. The tool may have been removed."
```

### Agent Iteration State — New tracking (in-memory only)

Track failed tool names across iterations to prevent LLM retry loops:

| Field           | Type          | Description                                             |
| --------------- | ------------- | ------------------------------------------------------- |
| failedToolNames | `Set<String>` | Tool composite names that failed in previous iterations |

This is in-memory state within `RunAgentIterationUsecase`, not persisted to DB.

## State Transitions

### Tool Call Lifecycle (existing, documented for clarity)

```
LLM returns tool call (resultStatus = null)
        |
        v
LoadLatestMessageToolCallsUsecase
  ├── resolveTool() = null  →  toolNotFound (terminal)
  └── resolveTool() = ResolvedTool
          |
          v
  RunAllowedToolsUsecase._checkToolPermission()
    ├── notConfigured        →  notConfigured (terminal) [FIX: add descriptive responseRaw]
    ├── disabledInWorkspace  →  disabledInWorkspace (terminal)
    ├── disabledInConversation → disabledInConversation (terminal)
    ├── granted              →  execute → success | executionError (terminal)
    └── needsConfirmation    →  left pending
                                  |
                                  v
                            UI shows approval card
                                  |
                  ┌───────────────┼───────────────┐
                  v               v               v
          Allow Once/     Skip            Stop All
          Allow for Conv  ↓               ↓
                  ↓       skipped          stopped
          execute → success | error
```

### Agent Loop Iteration (existing, with proposed retry guard)

```
RunAgentIterationUsecase.while(true)
        |
        v
  ContinueAgentUsecase → LLM response with tool calls
        |
        v
  RunAllowedToolsUsecase → permission checks + execution
        |
        v
  Decision?
    ├── done              → exit loop
    ├── waitForApproval   → exit loop, wait for user
    └── continueIteration → loop back
                              |
                              [NEW] Check if LLM called a tool
                              that already failed → inject
                              "do not retry" context
```

# Research: Fix Native Tool Permissions

**Date**: 2026-04-22
**Feature**: 006-fix-native-tool-permissions

## Decision 1: Permission Resolution Fix

**Decision**: Add diagnostic logging to `_resolvePermissionTableId` and verify the workspace tool lookup succeeds for native tools. If the lookup fails, include the composite tool name and resolved `tableId` in the error context.

**Rationale**: The current code path for native tools in `_resolvePermissionTableId` (line 143-145 of `run_allowed_tools_usecase.dart`) simply returns `resolvedTool.tableId` without verifying the workspace tool exists. This means the subsequent `checkToolPermission` call receives a `toolId` that may not correspond to any workspace tool record, causing a `notConfigured` result.

**Alternatives considered**:

- Always return `needsConfirmation` for native tools when workspace tool lookup fails — rejected: masks the configuration problem
- Auto-create workspace tool records on-the-fly — rejected: violates YAGNI and could create duplicate records

## Decision 2: Agent Loop Retry Guard

**Decision**: Track failed tool names across iterations in `RunAgentIterationUsecase`. If the same tool name fails in consecutive iterations, inject a system message into the chat history telling the LLM not to retry that tool.

**Rationale**: The agent loop (`RunAgentIterationUsecase`) has a `while(true)` loop that calls `ContinueAgentUsecase` → `RunAllowedToolsUsecase` → repeat. When a tool fails, the error status is persisted but the LLM may generate a new tool call with the same name in the next iteration. There's no mechanism to tell the LLM "stop calling this tool."

**Alternatives considered**:

- Maximum iteration count — rejected: too coarse, would stop the entire agent loop even if other tools work
- Deduplicate tool calls by name in `LoadLatestMessageToolCallsUsecase` — rejected: only prevents re-execution of already-persisted calls, not new calls from the LLM
- Return a richer error message in the tool result — considered as complementary fix (see Decision 3)

## Decision 3: Rich Error Messages for Tool Failures

**Decision**: Include the tool name, failure reason, and suggested action in the `responseRaw` field when a tool call fails. Currently, error statuses (`notConfigured`, `toolNotFound`, `executionError`) are persisted but the `responseRaw` is null or generic.

**Rationale**: When the LLM receives the tool results, it sees the `ToolCallResultStatus` mapped to a generic "Tool execution failed." message in the chat history. With a richer message like "Tool 'url' is not configured in this workspace. Do not retry this tool.", the LLM can make a better decision about whether to retry or try a different approach.

**Alternatives considered**:

- Separate error message field — rejected: would require schema changes to `MessageToolCallEntity`
- Only UI-facing error messages — rejected: doesn't help the LLM avoid retries

## References

- `run_allowed_tools_usecase.dart`: Permission gate (lines 126-160)
- `run_agent_iteration_usecase.dart`: Agent loop (lines 41-77)
- `load_latest_message_tool_calls_usecase.dart`: Tool call loader (lines 30-76)
- `conversation_tools_repository_impl.dart`: Permission check (lines 298-341)
- `tool_resolver_service.dart`: Composite ID parsing (lines 44-81)
- `build_combined_tool_specs_usecase.dart`: Tool spec assembly (lines 27-100)

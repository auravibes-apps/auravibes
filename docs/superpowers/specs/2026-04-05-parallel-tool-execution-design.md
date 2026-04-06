# Parallel Tool Execution Design

**Date:** 2026-04-05
**Status:** Approved
**Scope:** `run_allowed_tools_usecase.dart`

## Problem

Tool calls in `RunAllowedToolsUsecase` execute sequentially via a `for` loop. Each tool awaits the previous one, including both permission checks and execution. This means if an AI requests 5 tools, they run one after another regardless of independence. A slow or failing tool blocks all subsequent tools.

## Solution

Split the sequential loop into two phases:
1. **Phase 1 (sequential):** Check permissions for all tools. Permission checks are fast DB reads and don't benefit from parallelism.
2. **Phase 2 (parallel):** Execute all granted tools concurrently using `Future.wait`.

Error resilience is preserved: each tool's `_executeTool` already catches `Object` and returns `executionError`. `Future.wait` waits for all futures to complete, so one failure doesn't affect others.

## Architecture

### Current Flow

```
Load tool calls
  → for each tool: check permission → execute (sequential)
  → update DB
  → decide next action
```

### New Flow

```
Load tool calls
  → Phase 1: for each tool: check permission (sequential, fast DB reads)
     → partition into: granted[], needsConfirmation, denied[]
  → Phase 2: Future.wait(granted.map(executeSafely))
     → each tool runs independently, errors caught per-tool
  → update DB (single batch write with all results)
  → decide next action
```

## Detailed Changes

### File: `run_allowed_tools_usecase.dart`

**Replace** the sequential `for` loop (lines 62-103) with two phases:

#### Phase 1: Permission checks (sequential)

```dart
final grantedTools = <ToolToCall>[];
for (final toolToCall in latestToolCalls.toolsToRun) {
  final permission = await _checkToolPermission(
    conversationId: conversationId,
    workspaceId: workspaceId,
    resolvedTool: toolToCall.tool,
  );

  switch (permission) {
    case ToolPermissionResult.granted:
      grantedTools.add(toolToCall);
    case ToolPermissionResult.needsConfirmation:
      hasPendingTools = true;
    case ToolPermissionResult.disabledInConversation:
      updates.add(_ToolResultUpdate(
        toolCallId: toolToCall.id,
        resultStatus: ToolCallResultStatus.disabledInConversation,
      ));
    case ToolPermissionResult.disabledInWorkspace:
      updates.add(_ToolResultUpdate(
        toolCallId: toolToCall.id,
        resultStatus: ToolCallResultStatus.disabledInWorkspace,
      ));
    case ToolPermissionResult.notConfigured:
      updates.add(_ToolResultUpdate(
        toolCallId: toolToCall.id,
        resultStatus: ToolCallResultStatus.notConfigured,
      ));
  }
}
```

#### Phase 2: Parallel execution

```dart
if (grantedTools.isNotEmpty) {
  final executionResults = await Future.wait(
    grantedTools.map((tool) => _executeSafely(toolToCall: tool)),
  );
  updates.addAll(executionResults);
}
```

#### New helper method: `_executeSafely`

Wraps `_executeTool` to always return a `_ToolResultUpdate`, ensuring `Future.wait` never receives a rejected future:

```dart
Future<_ToolResultUpdate> _executeSafely({required ToolToCall toolToCall}) async {
  final result = await _executeTool(toolToCall: toolToCall);
  return _ToolResultUpdate(
    toolCallId: toolToCall.id,
    resultStatus: result.resultStatus,
    responseRaw: result.responseRaw,
  );
}
```

This is a thin wrapper because `_executeTool` already catches all exceptions and returns `_ToolExecutionResult` with appropriate status. The wrapper converts it to `_ToolResultUpdate` for the updates list.

### Files NOT Changed

| File | Reason |
|------|--------|
| `approve_tool_call_usecase.dart` | Executes single tool on approval. After approval, calls `runAllowedToolsUsecase` which now runs remaining tools in parallel. |
| `load_latest_message_tool_calls_usecase.dart` | Loads and resolves tool calls — no execution logic. |
| `get_agent_iteration_decision_usecase.dart` | Decision logic unchanged. |
| `handle_tool_approval_iteration_usecase.dart` | Orchestration unchanged — calls `runAllowedToolsUsecase` which gets the parallel behavior. |
| `_updateToolResults` | Already batched — single DB write with all updates. No changes needed. |

## Error Handling

- Each tool's `_executeTool` catches `Object` and returns `ToolCallResultStatus.executionError`
- `Future.wait` with the safe wrapper ensures all futures complete (no rejection)
- One tool failure has zero impact on other tools
- All results (success + errors) collected and written to DB in one batch

## Testing Strategy

### Unit tests for `RunAllowedToolsUsecase`

1. **Single tool granted** — runs and returns result (baseline, should still work)
2. **Multiple tools granted** — all execute in parallel, all results collected
3. **One tool throws** — other tools still complete, failed tool gets `executionError`
4. **Mixed permissions** — some granted, some need confirmation, some denied — correct partitioning
5. **Tool not found** — existing behavior preserved
6. **All tools need confirmation** — returns `waitForToolApproval`, no execution
7. **Resume after approval** — remaining auto-approved tools run in parallel

## Constraints

- Only `run_allowed_tools_usecase.dart` is modified (minimal blast radius)
- No new dependencies
- No changes to database schema or message format
- No changes to UI layer
- Backward compatible with existing tool call flow

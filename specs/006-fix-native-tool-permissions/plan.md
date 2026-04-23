# Implementation Plan: Fix Native Tool Permissions

**Branch**: `006-fix-native-tool-permissions` | **Date**: 2026-04-22 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/006-fix-native-tool-permissions/spec.md`

## Summary

Native tools in the AuraVibes AI agent fail when the permission system requires user approval. The agent does not display the approval prompt, the tool call fails silently, and the agent loop retries the same call indefinitely. Fix targets the permission resolution pipeline in `RunAllowedToolsUsecase`, the agent iteration loop in `RunAgentIterationUsecase`, and the error feedback to the LLM to prevent retry loops.

## Technical Context

**Language/Version**: Dart 3.11+ (FVM pinned to 3.41.4+)
**Primary Dependencies**: Flutter, Riverpod (with code generation), dartantic_ai, Drift (database)
**Storage**: Drift SQLite — `workspace_tools`, `conversation_tools` tables (read-only for this fix)
**Testing**: `fvm flutter test` — unit tests for use cases, widget tests for approval card
**Target Platform**: iOS, Android, macOS, Windows, Linux, Web
**Project Type**: Mobile/desktop app (Flutter monorepo)
**Performance Goals**: No performance impact — permission checks are single DB reads
**Constraints**: Must not break existing built-in tool or MCP tool permission flows
**Scale/Scope**: Changes in `apps/auravibes_app/` only — no package changes

## Constitution Check

_GATE: Must pass before Phase 0 research. Re-check after Phase 1 design._

| Principle                         | Status  | Notes                                                |
| --------------------------------- | ------- | ---------------------------------------------------- |
| I. Start with User Needs          | ✅ Pass | Core user blocker: native tools unusable             |
| II. Design with Data              | ✅ Pass | Uses existing DB schema, no schema changes           |
| III. Package-First Architecture   | ✅ Pass | Changes in app layer only, no new packages           |
| IV. UI Kit Mandate                | ✅ Pass | Reuses existing `ChatToolApprovalCard`               |
| V. Test-Driven Development        | ✅ Pass | TDD required: tests first, then fix                  |
| VI. Fail Fast + Explicit Errors   | ✅ Pass | Fix makes errors explicit instead of silent          |
| VII. Simplicity + YAGNI           | ✅ Pass | Minimal fix to existing code, no new abstractions    |
| VIII. Observability + Performance | ✅ Pass | N/A — single DB reads, no perf concern               |
| IX. Security + Privacy            | ✅ Pass | No security regression — permission checks preserved |
| X. Code Quality Standards         | ✅ Pass | Follows existing patterns, `very_good_analysis`      |

No violations. Proceeding.

## Project Structure

### Documentation (this feature)

```text
specs/006-fix-native-tool-permissions/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```text
apps/auravibes_app/
├── lib/
│   ├── features/
│   │   ├── chats/
│   │   │   └── usecases/
│   │   │       ├── run_agent_iteration_usecase.dart     # Agent loop — retry guard
│   │   │       ├── continue_agent_usecase.dart          # LLM streaming — error context
│   │   │       └── resume_conversation_if_ready_usecase.dart  # Resume after approval
│   │   └── tools/
│   │       └── usecases/
│   │           ├── run_allowed_tools_usecase.dart       # Permission gate — primary fix target
│   │           ├── approve_tool_call_usecase.dart       # User approval handler
│   │           ├── skip_tool_call_usecase.dart          # Skip handler
│   │           ├── stop_all_pending_tool_calls_usecase.dart  # Stop all handler
│   │           └── load_latest_message_tool_calls_usecase.dart  # Tool call loader
│   ├── services/
│   │   └── tools/
│   │       ├── tool_resolver_service.dart               # Composite ID parsing
│   │       ├── native_tool_service.dart                 # Native tool registry
│   │       └── models/
│   │           └── resolved_tool.dart                   # Resolved tool union type
│   └── domain/
│       ├── enums/
│       │   ├── tool_permission_result.dart              # Permission check results
│       │   └── tool_call_result_status.dart             # Tool execution results
│       └── repositories/
│           └── conversation_tools_repository.dart       # Permission check interface
├── data/
│   └── repositories/
│       └── conversation_tools_repository_impl.dart      # Permission check impl
└── test/
    └── features/
        └── tools/
            └── usecases/
                ├── run_allowed_tools_usecase_test.dart   # NEW: tests for permission flow
                └── load_latest_message_tool_calls_usecase_test.dart  # NEW: resolution tests
```

**Structure Decision**: Changes confined to `apps/auravibes_app/`. No package changes needed.

## Key Code Paths

### Current Flow (broken)

```
1. LLM returns tool call with name: "native_<tableId>_<toolId>"
2. ToolResolverService.resolveTool() → ResolvedTool.native(tableId, nativeToolType)
3. RunAllowedToolsUsecase._checkToolPermission()
   → _resolvePermissionTableId(resolvedTool)
   → For native tools: returns resolvedTool.tableId (workspace tool DB ID)
   → conversationToolsRepository.checkToolPermission(workspaceId, tableId)
4. checkToolPermission() looks up workspace tool by DB ID
   → If not found: returns notConfigured ← LIKELY FAILURE POINT
   → If found + alwaysAsk: returns needsConfirmation
5. For notConfigured: tool marked with error status, no approval prompt
6. Agent loop sees tool error, LLM retries same tool → infinite loop
```

### Root Cause Analysis

The permission resolution for native tools passes `resolvedTool.tableId` (the workspace tool's database ID) directly to `checkToolPermission()`. This works **if** the workspace tool record exists. But if:

- The native tool is not registered in the workspace tools table
- The table ID in the composite name is stale or incorrect
- The workspace tool was deleted

Then `checkToolPermission()` returns `notConfigured`, the tool fails with no approval prompt, and the agent retries.

Additionally, there is **no guard in the agent loop** to prevent the LLM from re-calling a tool that already failed. The `LoadLatestMessageToolCallsUsecase` only loads `isPending` tool calls, but if the LLM generates a **new** tool call with the same name in the next iteration, it's treated as a fresh call.

### Proposed Fix

**Fix 1 — Permission resolution**: Ensure `_resolvePermissionTableId` for native tools returns the correct workspace tool ID, and add logging when the lookup fails.

**Fix 2 — Agent loop retry guard**: After tool failures are persisted, the agent loop should detect repeated failures for the same tool type and stop retrying. Track failed tool names across iterations.

**Fix 3 — Error messages**: Include the tool name and human-readable reason in the error response sent back to the LLM, so it can make an informed decision instead of blindly retrying.

## Complexity Tracking

No violations to justify.

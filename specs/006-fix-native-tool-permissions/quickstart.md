# Quickstart: Fix Native Tool Permissions

**Date**: 2026-04-22
**Feature**: 006-fix-native-tool-permissions

## Overview

Fix three issues in the AuraVibes AI agent's native tool system:

1. Permission resolution returns `notConfigured` for valid native tools (no approval prompt shown)
2. Agent loop retries failed tool calls indefinitely (no retry guard)
3. Error messages don't include enough context for the LLM to avoid retrying

## Prerequisites

- Flutter SDK via FVM (3.41.4+)
- Existing workspace with native tools configured
- Test environment that can simulate tool calls

## Implementation Steps

### Step 1: Write failing tests (TDD)

Create tests for the permission resolution and retry guard:

```bash
# New test files
apps/auravibes_app/test/features/tools/usecases/run_allowed_tools_usecase_test.dart
apps/auravibes_app/test/features/tools/usecases/load_latest_message_tool_calls_usecase_test.dart
```

Tests to write:

1. Native tool with "always ask" permission → returns `needsConfirmation` (not `notConfigured`)
2. Native tool with "always allow" permission → returns `granted` and executes
3. Native tool not in workspace → returns `notConfigured` with descriptive error message
4. Agent loop tracks failed tools across iterations → stops retrying
5. Error `responseRaw` includes tool name and reason

### Step 2: Fix permission resolution

**File**: `apps/auravibes_app/lib/features/tools/usecases/run_allowed_tools_usecase.dart`

- Add logging to `_resolvePermissionTableId` when lookup fails
- Ensure `_checkToolPermission` returns `needsConfirmation` for native tools with `alwaysAsk` permission mode
- Add descriptive `responseRaw` for error statuses

### Step 3: Add retry guard to agent loop

**File**: `apps/auravibes_app/lib/features/chats/usecases/run_agent_iteration_usecase.dart`

- Track `failedToolNames` set across loop iterations
- When `RunAllowedToolsUsecase` returns tools with error status, add their names to the set
- Before calling `ContinueAgentUsecase`, check if the LLM's tool calls include any previously failed names
- If so, skip those tool calls or mark them with error before executing

### Step 4: Enhance error messages

**File**: `apps/auravibes_app/lib/features/tools/usecases/run_allowed_tools_usecase.dart`

- In the error status cases (lines 79-99), add descriptive `responseRaw`:
  - `notConfigured`: "Tool '{name}' is not enabled in this workspace."
  - `disabledInWorkspace`: "Tool '{name}' is disabled in workspace settings."
  - `disabledInConversation`: "Tool '{name}' is disabled for this conversation."

### Step 5: Verify

```bash
# Run tests
fvm flutter test apps/auravibes_app/test/features/tools/usecases/ --no-pub

# Run analysis
fvm dart analyze apps/auravibes_app/

# Format
fvm dart format apps/auravibes_app/lib/features/tools/usecases/
fvm dart format apps/auravibes_app/lib/features/chats/usecases/
```

### Step 6: Manual testing

1. Create a workspace with a native tool (URL fetcher) enabled with "always ask"
2. Start a conversation and send a message that triggers the native tool
3. Verify the approval card appears
4. Test "Allow Once", "Allow for Conversation", "Skip", and "Stop All"
5. Test with a native tool NOT in the workspace → verify error message appears and agent doesn't retry

## Files Changed

| File                                               | Change Type                                                    |
| -------------------------------------------------- | -------------------------------------------------------------- |
| `run_allowed_tools_usecase.dart`                   | Modify: add logging, fix permission resolution, enhance errors |
| `run_agent_iteration_usecase.dart`                 | Modify: add retry guard                                        |
| `run_allowed_tools_usecase_test.dart`              | New: unit tests                                                |
| `load_latest_message_tool_calls_usecase_test.dart` | New: unit tests                                                |

## Rollback

Revert the commits on this branch. No database schema changes, no new packages.

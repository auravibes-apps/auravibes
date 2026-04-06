# Parallel Tool Execution Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split sequential tool execution in `RunAllowedToolsUsecase` into sequential permission checks + parallel execution so multiple granted tools run concurrently and one failure doesn't block others.

**Architecture:** Two-phase approach — Phase 1 loops through tools sequentially checking permissions (fast DB reads), collecting granted tools into a list. Phase 2 runs all granted tools via `Future.wait`. A new `_executeSafely` helper wraps `_executeTool` to guarantee each future returns a `_ToolResultUpdate` (no rejections).

**Tech Stack:** Dart 3.x async (`Future.wait`), existing mockito/mockito annotations for tests.

**Spec:** `docs/superpowers/specs/2026-04-05-parallel-tool-execution-design.md`

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `apps/auravibes_app/lib/features/tools/usecases/run_allowed_tools_usecase.dart` | Modify | Two-phase execution + `_executeSafely` helper |
| `apps/auravibes_app/test/features/tools/usecases/run_allowed_tools_usecase_test.dart` | Modify | Add 4 new test cases for parallel behavior |

---

### Task 1: Refactor sequential loop into two phases

**Files:**
- Modify: `apps/auravibes_app/lib/features/tools/usecases/run_allowed_tools_usecase.dart:62-103`

- [ ] **Step 1: Replace the sequential for-loop with two-phase logic**

Replace lines 62–103 (the entire `for (final toolToCall in latestToolCalls.toolsToRun)` block) with:

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
          updates.add(
            _ToolResultUpdate(
              toolCallId: toolToCall.id,
              resultStatus: ToolCallResultStatus.disabledInConversation,
            ),
          );
        case ToolPermissionResult.disabledInWorkspace:
          updates.add(
            _ToolResultUpdate(
              toolCallId: toolToCall.id,
              resultStatus: ToolCallResultStatus.disabledInWorkspace,
            ),
          );
        case ToolPermissionResult.notConfigured:
          updates.add(
            _ToolResultUpdate(
              toolCallId: toolToCall.id,
              resultStatus: ToolCallResultStatus.notConfigured,
            ),
          );
      }
    }

    if (grantedTools.isNotEmpty) {
      final executionResults = await Future.wait(
        grantedTools.map((tool) => _executeSafely(toolToCall: tool)),
      );
      updates.addAll(executionResults);
    }
```

- [ ] **Step 2: Add the `_executeSafely` helper method**

Add this method to the `RunAllowedToolsUsecase` class, after `_executeTool` (after line 200):

```dart
  Future<_ToolResultUpdate> _executeSafely({
    required ToolToCall toolToCall,
  }) async {
    final result = await _executeTool(toolToCall: toolToCall);
    return _ToolResultUpdate(
      toolCallId: toolToCall.id,
      resultStatus: result.resultStatus,
      responseRaw: result.responseRaw,
    );
  }
```

- [ ] **Step 3: Verify existing tests still pass**

Run: `fvm flutter test apps/auravibes_app/test/features/tools/usecases/run_allowed_tools_usecase_test.dart --no-pub`
Expected: All 3 existing tests PASS.

- [ ] **Step 4: Commit**

```bash
git add apps/auravibes_app/lib/features/tools/usecases/run_allowed_tools_usecase.dart
git commit -m "feat: split tool execution into sequential permission checks + parallel execution"
```

---

### Task 2: Add test for multiple granted tools executing in parallel

**Files:**
- Modify: `apps/auravibes_app/test/features/tools/usecases/run_allowed_tools_usecase_test.dart`

- [ ] **Step 1: Write the failing test**

Add the following test inside the `group('RunAllowedToolsUsecase', () {` block, after the last existing test:

```dart
    test(
      'executes multiple granted tools and collects all results',
      () async {
        final tool1 = ToolToCall(
          id: 'tool-1',
          tool: ResolvedTool.builtIn(
            tableId: 'calc',
            toolIdentifier: 'calculator',
            tooltype: UserToolType.calculator,
          ),
          argumentsRaw: '{"input": "1+1"}',
        );
        final tool2 = ToolToCall(
          id: 'tool-2',
          tool: ResolvedTool.builtIn(
            tableId: 'calc',
            toolIdentifier: 'calculator',
            tooltype: UserToolType.calculator,
          ),
          argumentsRaw: '{"input": "2+2"}',
        );

        final multiToolMessage = MessageEntity(
          id: 'message-1',
          conversationId: 'conversation-1',
          content: 'assistant',
          messageType: MessageType.text,
          isUser: false,
          status: MessageStatus.sent,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          metadata: const MessageMetadataEntity(
            toolCalls: [
              MessageToolCallEntity(
                id: 'tool-1',
                name: 'built_in_calc_calculator',
                argumentsRaw: '{"input": "1+1"}',
              ),
              MessageToolCallEntity(
                id: 'tool-2',
                name: 'built_in_calc_calculator',
                argumentsRaw: '{"input": "2+2"}',
              ),
            ],
          ),
        );

        when(
          loadLatestMessageToolCallsUsecase.call(
            conversationId: 'conversation-1',
          ),
        ).thenAnswer(
          (_) async => LoadLatestMessageToolCallsResult(
            messageId: 'message-1',
            hasToolCalls: true,
            toolsToRun: [tool1, tool2],
            notFoundToolCallIds: const [],
          ),
        );
        when(messageRepository.getMessageById('message-1')).thenAnswer(
          (_) async => multiToolMessage,
        );
        when(
          conversationToolsRepository.checkToolPermission(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolId: 'calc',
          ),
        ).thenAnswer((_) async => ToolPermissionResult.granted);
        when(
          messageRepository.updateMessage('message-1', any),
        ).thenAnswer((_) async => multiToolMessage);
        when(
          getAgentIterationDecisionUsecase.call(messageId: 'message-1'),
        ).thenAnswer((_) async => AgentIterationDecision.continueIteration);

        final result = await usecase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
        );

        expect(result, AgentIterationDecision.continueIteration);
        final update =
            verify(
                  messageRepository.updateMessage('message-1', captureAny),
                ).captured.single
                as MessageToUpdate;
        final updatedToolCalls = update.metadata?.toolCalls;
        expect(updatedToolCalls, isNotNull);
        expect(
          updatedToolCalls
              ?.firstWhere((tc) => tc.id == 'tool-1')
              .resultStatus,
          ToolCallResultStatus.success,
        );
        expect(
          updatedToolCalls
              ?.firstWhere((tc) => tc.id == 'tool-2')
              .resultStatus,
          ToolCallResultStatus.success,
        );
      },
    );
```

- [ ] **Step 2: Run test to verify it passes**

Run: `fvm flutter test apps/auravibes_app/test/features/tools/usecases/run_allowed_tools_usecase_test.dart --no-pub`
Expected: All 4 tests PASS (3 existing + 1 new).

- [ ] **Step 3: Commit**

```bash
git add apps/auravibes_app/test/features/tools/usecases/run_allowed_tools_usecase_test.dart
git commit -m "test: add test for multiple granted tools executing in parallel"
```

---

### Task 3: Add test for one tool throwing while others complete

**Files:**
- Modify: `apps/auravibes_app/test/features/tools/usecases/run_allowed_tools_usecase_test.dart`

- [ ] **Step 1: Write the failing test**

Add the following test inside the existing group block. This test uses a tool with invalid arguments to trigger an `executionError`, alongside a valid tool:

```dart
    test(
      'one tool failure does not block other tools from completing',
      () async {
        final goodTool = ToolToCall(
          id: 'tool-good',
          tool: ResolvedTool.builtIn(
            tableId: 'calc',
            toolIdentifier: 'calculator',
            tooltype: UserToolType.calculator,
          ),
          argumentsRaw: '{"input": "1+1"}',
        );
        final badTool = ToolToCall(
          id: 'tool-bad',
          tool: ResolvedTool.builtIn(
            tableId: 'calc',
            toolIdentifier: 'calculator',
            tooltype: UserToolType.calculator,
          ),
          argumentsRaw: '{}',
        );

        final mixedMessage = MessageEntity(
          id: 'message-1',
          conversationId: 'conversation-1',
          content: 'assistant',
          messageType: MessageType.text,
          isUser: false,
          status: MessageStatus.sent,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          metadata: const MessageMetadataEntity(
            toolCalls: [
              MessageToolCallEntity(
                id: 'tool-good',
                name: 'built_in_calc_calculator',
                argumentsRaw: '{"input": "1+1"}',
              ),
              MessageToolCallEntity(
                id: 'tool-bad',
                name: 'built_in_calc_calculator',
                argumentsRaw: '{}',
              ),
            ],
          ),
        );

        when(
          loadLatestMessageToolCallsUsecase.call(
            conversationId: 'conversation-1',
          ),
        ).thenAnswer(
          (_) async => LoadLatestMessageToolCallsResult(
            messageId: 'message-1',
            hasToolCalls: true,
            toolsToRun: [goodTool, badTool],
            notFoundToolCallIds: const [],
          ),
        );
        when(messageRepository.getMessageById('message-1')).thenAnswer(
          (_) async => mixedMessage,
        );
        when(
          conversationToolsRepository.checkToolPermission(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolId: 'calc',
          ),
        ).thenAnswer((_) async => ToolPermissionResult.granted);
        when(
          messageRepository.updateMessage('message-1', any),
        ).thenAnswer((_) async => mixedMessage);
        when(
          getAgentIterationDecisionUsecase.call(messageId: 'message-1'),
        ).thenAnswer((_) async => AgentIterationDecision.continueIteration);

        final result = await usecase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
        );

        expect(result, AgentIterationDecision.continueIteration);
        final update =
            verify(
                  messageRepository.updateMessage('message-1', captureAny),
                ).captured.single
                as MessageToUpdate;
        final updatedToolCalls = update.metadata?.toolCalls;
        expect(updatedToolCalls, isNotNull);
        expect(
          updatedToolCalls
              ?.firstWhere((tc) => tc.id == 'tool-good')
              .resultStatus,
          ToolCallResultStatus.success,
        );
        expect(
          updatedToolCalls
              ?.firstWhere((tc) => tc.id == 'tool-bad')
              .resultStatus,
          ToolCallResultStatus.executionError,
        );
      },
    );
```

- [ ] **Step 2: Run test to verify it passes**

Run: `fvm flutter test apps/auravibes_app/test/features/tools/usecases/run_allowed_tools_usecase_test.dart --no-pub`
Expected: All 5 tests PASS.

- [ ] **Step 3: Commit**

```bash
git add apps/auravibes_app/test/features/tools/usecases/run_allowed_tools_usecase_test.dart
git commit -m "test: add test for one tool failure not blocking other tools"
```

---

### Task 4: Add test for mixed permissions (granted + needs confirmation + denied)

**Files:**
- Modify: `apps/auravibes_app/test/features/tools/usecases/run_allowed_tools_usecase_test.dart`

- [ ] **Step 1: Write the failing test**

Add the following test inside the existing group block. This verifies correct partitioning when tools have different permission results:

```dart
    test(
      'correctly partitions tools with mixed permissions',
      () async {
        final grantedTool = ToolToCall(
          id: 'tool-granted',
          tool: ResolvedTool.builtIn(
            tableId: 'calc',
            toolIdentifier: 'calculator',
            tooltype: UserToolType.calculator,
          ),
          argumentsRaw: '{"input": "1+1"}',
        );
        final pendingTool = ToolToCall(
          id: 'tool-pending',
          tool: ResolvedTool.builtIn(
            tableId: 'other',
            toolIdentifier: 'other_tool',
            tooltype: UserToolType.calculator,
          ),
          argumentsRaw: '{"input": "test"}',
        );
        final disabledTool = ToolToCall(
          id: 'tool-disabled',
          tool: ResolvedTool.builtIn(
            tableId: 'disabled',
            toolIdentifier: 'disabled_tool',
            tooltype: UserToolType.calculator,
          ),
          argumentsRaw: '{"input": "test"}',
        );

        final mixedMessage = MessageEntity(
          id: 'message-1',
          conversationId: 'conversation-1',
          content: 'assistant',
          messageType: MessageType.text,
          isUser: false,
          status: MessageStatus.sent,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
          metadata: const MessageMetadataEntity(
            toolCalls: [
              MessageToolCallEntity(
                id: 'tool-granted',
                name: 'built_in_calc_calculator',
                argumentsRaw: '{"input": "1+1"}',
              ),
              MessageToolCallEntity(
                id: 'tool-pending',
                name: 'other_tool',
                argumentsRaw: '{"input": "test"}',
              ),
              MessageToolCallEntity(
                id: 'tool-disabled',
                name: 'disabled_tool',
                argumentsRaw: '{"input": "test"}',
              ),
            ],
          ),
        );

        when(
          loadLatestMessageToolCallsUsecase.call(
            conversationId: 'conversation-1',
          ),
        ).thenAnswer(
          (_) async => LoadLatestMessageToolCallsResult(
            messageId: 'message-1',
            hasToolCalls: true,
            toolsToRun: [grantedTool, pendingTool, disabledTool],
            notFoundToolCallIds: const [],
          ),
        );
        when(messageRepository.getMessageById('message-1')).thenAnswer(
          (_) async => mixedMessage,
        );
        when(
          conversationToolsRepository.checkToolPermission(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolId: 'calc',
          ),
        ).thenAnswer((_) async => ToolPermissionResult.granted);
        when(
          conversationToolsRepository.checkToolPermission(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolId: 'other',
          ),
        ).thenAnswer(
          (_) async => ToolPermissionResult.needsConfirmation,
        );
        when(
          conversationToolsRepository.checkToolPermission(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolId: 'disabled',
          ),
        ).thenAnswer(
          (_) async => ToolPermissionResult.disabledInWorkspace,
        );
        when(
          messageRepository.updateMessage('message-1', any),
        ).thenAnswer((_) async => mixedMessage);

        final result = await usecase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
        );

        expect(result, AgentIterationDecision.waitForToolApproval);
        final update =
            verify(
                  messageRepository.updateMessage('message-1', captureAny),
                ).captured.single
                as MessageToUpdate;
        final updatedToolCalls = update.metadata?.toolCalls;
        expect(updatedToolCalls, isNotNull);
        expect(
          updatedToolCalls
              ?.firstWhere((tc) => tc.id == 'tool-granted')
              .resultStatus,
          ToolCallResultStatus.success,
        );
        expect(
          updatedToolCalls
              ?.firstWhere((tc) => tc.id == 'tool-pending')
              .resultStatus,
          isNull,
        );
        expect(
          updatedToolCalls
              ?.firstWhere((tc) => tc.id == 'tool-disabled')
              .resultStatus,
          ToolCallResultStatus.disabledInWorkspace,
        );
      },
    );
```

- [ ] **Step 2: Run test to verify it passes**

Run: `fvm flutter test apps/auravibes_app/test/features/tools/usecases/run_allowed_tools_usecase_test.dart --no-pub`
Expected: All 6 tests PASS.

- [ ] **Step 3: Commit**

```bash
git add apps/auravibes_app/test/features/tools/usecases/run_allowed_tools_usecase_test.dart
git commit -m "test: add test for mixed permissions partitioning"
```

---

### Task 5: Add test for all tools needing confirmation (no execution)

**Files:**
- Modify: `apps/auravibes_app/test/features/tools/usecases/run_allowed_tools_usecase_test.dart`

- [ ] **Step 1: Write the failing test**

Add the following test inside the existing group block:

```dart
    test(
      'returns waitForToolApproval when all tools need confirmation',
      () async {
        final tool1 = ToolToCall(
          id: 'tool-1',
          tool: ResolvedTool.builtIn(
            tableId: 'tool-a',
            toolIdentifier: 'tool_a',
            tooltype: UserToolType.calculator,
          ),
          argumentsRaw: '{"input": "1+1"}',
        );
        final tool2 = ToolToCall(
          id: 'tool-2',
          tool: ResolvedTool.builtIn(
            tableId: 'tool-b',
            toolIdentifier: 'tool_b',
            tooltype: UserToolType.calculator,
          ),
          argumentsRaw: '{"input": "2+2"}',
        );

        when(
          loadLatestMessageToolCallsUsecase.call(
            conversationId: 'conversation-1',
          ),
        ).thenAnswer(
          (_) async => LoadLatestMessageToolCallsResult(
            messageId: 'message-1',
            hasToolCalls: true,
            toolsToRun: [tool1, tool2],
            notFoundToolCallIds: const [],
          ),
        );
        when(
          conversationToolsRepository.checkToolPermission(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolId: 'tool-a',
          ),
        ).thenAnswer(
          (_) async => ToolPermissionResult.needsConfirmation,
        );
        when(
          conversationToolsRepository.checkToolPermission(
            conversationId: 'conversation-1',
            workspaceId: 'workspace-1',
            toolId: 'tool-b',
          ),
        ).thenAnswer(
          (_) async => ToolPermissionResult.needsConfirmation,
        );

        final result = await usecase.call(
          conversationId: 'conversation-1',
          workspaceId: 'workspace-1',
        );

        expect(result, AgentIterationDecision.waitForToolApproval);
        verifyNever(
          messageRepository.updateMessage(any, any),
        );
      },
    );
```

- [ ] **Step 2: Run test to verify it passes**

Run: `fvm flutter test apps/auravibes_app/test/features/tools/usecases/run_allowed_tools_usecase_test.dart --no-pub`
Expected: All 7 tests PASS.

- [ ] **Step 3: Commit**

```bash
git add apps/auravibes_app/test/features/tools/usecases/run_allowed_tools_usecase_test.dart
git commit -m "test: add test for all tools needing confirmation"
```

---

### Task 6: Run full test suite and analyze

**Files:**
- No file changes

- [ ] **Step 1: Run the full test suite for this file**

Run: `fvm flutter test apps/auravibes_app/test/features/tools/usecases/run_allowed_tools_usecase_test.dart --no-pub`
Expected: All 7 tests PASS.

- [ ] **Step 2: Run analyze on the changed files**

Run: `fvm dart analyze apps/auravibes_app/lib/features/tools/usecases/run_allowed_tools_usecase.dart apps/auravibes_app/test/features/tools/usecases/run_allowed_tools_usecase_test.dart`
Expected: No issues found.

---

## Self-Review

**1. Spec coverage:**
- Sequential permission checks → Phase 1 in Task 1 ✅
- Parallel execution via `Future.wait` → Phase 2 in Task 1 ✅
- `_executeSafely` helper → Task 1 ✅
- Error resilience (one failure doesn't block others) → Task 3 ✅
- Mixed permissions → Task 4 ✅
- All tools need confirmation → Task 5 ✅
- Multiple granted tools → Task 2 ✅
- Single tool granted (baseline) → covered by existing test ✅
- Resume after approval → covered by `approve_tool_call_usecase` calling `runAllowedToolsUsecase` (no code change needed) ✅
- Tool not found → covered by existing test ✅

**2. Placeholder scan:** No TBD, TODO, or vague steps. All code blocks are complete.

**3. Type consistency:**
- `_executeSafely` returns `Future<_ToolResultUpdate>` → matches `Future.wait` type and `updates.addAll` ✅
- `_ToolResultUpdate` constructor matches existing usage (`toolCallId`, `resultStatus`, `responseRaw`) ✅
- `_executeTool` returns `_ToolExecutionResult` → `_executeSafely` reads `.resultStatus` and `.responseRaw` which are fields on `_ToolExecutionResult` ✅

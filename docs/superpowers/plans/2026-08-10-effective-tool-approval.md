# Effective Tool Approval Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make local and cloud tool approval evaluate the exact skill tool hidden inside `call_skill_tool`, ask on first use, and keep cloud policy server-authoritative.

**Architecture:** Add one host-neutral effective-target resolver to `auravibes_engine`; local and server adapters supply loaded-manifest target resolution and retain their existing persistence. Both hosts evaluate the canonical target descriptor, never the wrapper. Existing pending/resume storage remains; only target selection, defaults, presentation, and structured logs change.

**Tech Stack:** Dart, Flutter, Riverpod, Drift, Serverpod, `package:test`, `flutter_test`.

## Global Constraints

- Preserve LLM-visible skill tool schemas and names.
- `list_skills` defaults to allow; `load_skill`, `unload_skill`, and exact nested skill tools default to ask.
- “Allow conversation” grants exact effective target only.
- Local conversations use local policy persistence; cloud conversations use server policy persistence.
- Malformed, stale, ambiguous, unloaded, or unresolved targets fail closed.
- Never log arguments, credentials, headers, response bodies, or secrets.
- Do not hand-edit generated files.
- No DB migration unless tests prove exact-target records cannot use existing storage.

---

### Task 1: Add canonical effective approval target resolution

**Files:**
- Create: `packages/auravibes_engine/lib/src/tool_approval_target.dart`
- Modify: `packages/auravibes_engine/lib/auravibes_engine.dart`
- Test: `packages/auravibes_engine/test/tool_approval_target_test.dart`

**Interfaces:**
- Consumes: `AgentResolvedToolName`, `SkillCommandTarget`, `callSkillToolName`.
- Produces:

```dart
typedef ResolveSkillApprovalTarget = Future<AgentResolvedToolName?> Function(
  SkillCommandTarget command,
);

Future<AgentResolvedToolName?> resolveEffectiveToolApprovalTarget({
  required AgentResolvedToolName requestedTarget,
  required Map<String, Object?> arguments,
  required ResolveSkillApprovalTarget resolveSkillTarget,
});
```

- Non-`call_skill_tool` targets return unchanged.
- `call_skill_tool` parses `SkillCommandTarget`, invokes resolver, and returns exact target.
- Invalid command or unresolved target returns `null`; no wrapper fallback.

- [ ] **Step 1: Write failing engine tests**

Cover unchanged direct targets, DuckDuckGo wrapper resolution, malformed arguments, unresolved targets, and resolver not called for direct tools.

```dart
test('resolves call_skill_tool to exact nested target', () async {
  final target = await resolveEffectiveToolApprovalTarget(
    requestedTarget: AgentResolvedToolName.skillControl(callSkillToolName),
    arguments: const {
      'skill': 'duckduckgo',
      'tool': 'search',
      'args': <String, Object?>{},
      'revision': 'r1',
    },
    resolveSkillTarget: (_) async => AgentResolvedToolName.skillNative(
      tableId: 'skill__app__duckduckgo__search',
      skillSlug: 'duckduckgo',
      toolIdentifier: 'search',
    ),
  );
  expect(target?.fullName, 'skill__app__duckduckgo__search');
});
```

- [ ] **Step 2: Run focused engine test and verify failure**

Run from `packages/auravibes_engine`:

```bash
fvm dart test test/tool_approval_target_test.dart
```

Expected: FAIL because resolver API does not exist.

- [ ] **Step 3: Implement minimal resolver and public export**

Catch only `FormatException` from command parsing. Let host resolver operational errors propagate so they are logged rather than mislabeled malformed input.

- [ ] **Step 4: Run engine tests and analyzer**

```bash
fvm dart test test/tool_approval_target_test.dart
fvm dart analyze lib/src/tool_approval_target.dart test/tool_approval_target_test.dart --fatal-infos --fatal-warnings
```

Expected: PASS; no diagnostics.

- [ ] **Step 5: Commit**

```bash
git add packages/auravibes_engine/lib/src/tool_approval_target.dart packages/auravibes_engine/lib/auravibes_engine.dart packages/auravibes_engine/test/tool_approval_target_test.dart
git commit -m "feat(engine): resolve effective approval targets"
```

---

### Task 2: Apply exact-target approval in local execution

**Files:**
- Modify: `apps/auravibes_app/lib/services/agent_harness/agent_tool_execution_service.dart:94-151`
- Modify: `apps/auravibes_app/lib/features/tools/usecases/tool_approval_decision.dart:44-121`
- Test: `apps/auravibes_app/test/services/agent_harness/agent_tool_execution_service_test.dart`
- Test: `apps/auravibes_app/test/features/tools/usecases/resolve_tool_approval_decision_usecase_test.dart`

**Interfaces:**
- Consumes: Task 1 `resolveEffectiveToolApprovalTarget`.
- Produces: local `resolveToolApprovalDecision` always passes exact nested `ResolvedTool` to `ResolveToolApprovalDecisionUsecase`; unresolved wrapper returns `notConfigured`.
- Existing `permissionTableIdFor(toolName: effectiveTarget.fullName)` remains exact grant storage.

- [ ] **Step 1: Add failing local target tests**

Assert:

```text
call_skill_tool(duckduckgo/search) -> resolver receives skill__app__duckduckgo__search
call_skill_tool(malformed) -> notConfigured
call_skill_tool(unresolved) -> notConfigured
direct tool -> unchanged
```

Also assert a grant for `skill__app__duckduckgo__search` does not grant another target and a legacy `call_skill_tool` grant is ignored.

- [ ] **Step 2: Run focused tests and verify at least legacy-wrapper isolation fails**

From `apps/auravibes_app`:

```bash
fvm flutter test test/services/agent_harness/agent_tool_execution_service_test.dart --no-pub
fvm flutter test test/features/tools/usecases/resolve_tool_approval_decision_usecase_test.dart --no-pub
```

- [ ] **Step 3: Replace local inline JSON/target logic with shared resolver**

Keep `ResolvedTool` conversion in app adapter:

```dart
final effective = await resolveEffectiveToolApprovalTarget(
  requestedTarget: resolvedTool.resolvedName,
  arguments: decoded,
  resolveSkillTarget: (command) => resolveSkillCommandTarget!(
    conversationId: conversationId,
    workspaceId: workspaceId,
    command: command,
  ),
);
if (effective == null) return notConfigured;
final approvalTool = ResolvedTool.skillCommand(
  commandName: resolvedTool.toolIdentifier,
  target: effective,
);
```

Use actual existing `ResolvedTool` descriptor getter/name; do not add duplicate descriptor state.

- [ ] **Step 4: Enforce local defaults**

In approval decision usecase, special-case only fixed policy:

```dart
if (resolvedTool.isSkillControl &&
    resolvedTool.toolIdentifier == agent.listSkillsToolName) {
  return ToolApprovalDecision(
    toolCallId: toolCallId,
    permissionResult: ToolPermissionResult.granted,
  );
}
```

Keep new synced skill permission rows at `PermissionAccess.ask`. Do not auto-grant load, unload, or nested tools.

- [ ] **Step 5: Run focused tests and analyzer**

```bash
fvm flutter test test/services/agent_harness/agent_tool_execution_service_test.dart --no-pub
fvm flutter test test/features/tools/usecases/resolve_tool_approval_decision_usecase_test.dart --no-pub
fvm dart analyze lib/services/agent_harness/agent_tool_execution_service.dart lib/features/tools/usecases/tool_approval_decision.dart --fatal-infos --fatal-warnings
```

Expected: PASS; no diagnostics.

- [ ] **Step 6: Commit**

```bash
git add apps/auravibes_app/lib/services/agent_harness/agent_tool_execution_service.dart apps/auravibes_app/lib/features/tools/usecases/tool_approval_decision.dart apps/auravibes_app/test/services/agent_harness/agent_tool_execution_service_test.dart apps/auravibes_app/test/features/tools/usecases/resolve_tool_approval_decision_usecase_test.dart
git commit -m "fix(app): approve exact skill tool targets"
```

---

### Task 3: Show effective target in local and cloud approval cards

**Files:**
- Modify: `apps/auravibes_app/lib/features/chats/widgets/chat_tool_approval_card.dart:100-170,248-360`
- Modify: `apps/auravibes_app/lib/features/chats/providers/tool_display_name_provider.dart`
- Test: `apps/auravibes_app/test/features/chats/widgets/chat_tool_approval_card_test.dart`

**Interfaces:**
- Consumes: original tool call name plus `argumentsRaw`.
- Produces: presentation-only effective name for `call_skill_tool`; approval action still references original message/tool-call IDs.

- [ ] **Step 1: Add failing widget tests**

Build pending local and cloud cards for `call_skill_tool` arguments targeting DuckDuckGo. Assert visible text contains `DuckDuckGo` and `Search`, does not present generic `Call Skill Tool` as primary title, and credential-like argument values remain redacted.

- [ ] **Step 2: Run widget test and verify failure**

```bash
cd apps/auravibes_app
fvm flutter test test/features/chats/widgets/chat_tool_approval_card_test.dart --no-pub
```

- [ ] **Step 3: Derive presentation target without changing execution identity**

Add one private parser in existing widget/provider path:

```dart
AgentResolvedToolName? _effectiveDisplayTarget(
  String toolName,
  String argumentsRaw,
)
```

For `call_skill_tool`, parse only `skill` and `tool`; format `skill__app__<skill>__<tool>` through existing `ToolNameFormatter`. On malformed data, retain generic wrapper title. Never expose raw `args`.

- [ ] **Step 4: Run widget test and analyzer**

```bash
fvm flutter test test/features/chats/widgets/chat_tool_approval_card_test.dart --no-pub
fvm dart analyze lib/features/chats/widgets/chat_tool_approval_card.dart lib/features/chats/providers/tool_display_name_provider.dart --fatal-infos --fatal-warnings
```

- [ ] **Step 5: Commit**

```bash
git add apps/auravibes_app/lib/features/chats/widgets/chat_tool_approval_card.dart apps/auravibes_app/lib/features/chats/providers/tool_display_name_provider.dart apps/auravibes_app/test/features/chats/widgets/chat_tool_approval_card_test.dart
git commit -m "fix(ui): show effective skill approval target"
```

---

### Task 4: Apply shared target resolution and defaults on cloud server

**Files:**
- Modify: `apps/auravibes_server/lib/src/features/conversations/engine/server_tool_runtime.dart:484-523,780-890,940-990`
- Modify: `apps/auravibes_server/lib/src/features/conversations/engine/server_tool_executor.dart:603-675,1263-1296`
- Test: `apps/auravibes_server/test/integration/features/conversations/conversation_engine_host_regression_test.dart`
- Test: `apps/auravibes_server/test/integration/features/conversations/conversation_execution_state_test.dart`
- Test: `apps/auravibes_server/test/features/conversations/engine/server_tool_executor_test.dart`

**Interfaces:**
- Consumes: Task 1 resolver and existing `resolveCloudSkillCommandTarget`.
- Produces: server `_permission` always receives effective descriptor; server persists pending state before execution; `list_skills` defaults allow.

- [ ] **Step 1: Add failing server integration tests**

Cover:

```text
list_skills -> completed without pending approval
load_skill -> awaitingApproval on first use
call_skill_tool duckduckgo/search -> pending row identity is exact target
legacy call_skill_tool alwaysAllow record -> nested call still awaits approval
exact duckduckgo/search alwaysAllow -> executes
exact grant for different nested tool -> still awaits approval
executor callback count remains zero before approval
```

- [ ] **Step 2: Run focused server tests and verify failures**

From `apps/auravibes_server`:

```bash
fvm dart test test/integration/features/conversations/conversation_engine_host_regression_test.dart
fvm dart test test/integration/features/conversations/conversation_execution_state_test.dart
```

- [ ] **Step 3: Replace server inline wrapper unwrapping with shared resolver**

Use `resolveEffectiveToolApprovalTarget` before `_permission`. Preserve authoritative `_skillTargets` lookup and `resolveCloudSkillCommandTarget`. If resolver returns null, persist `notConfigured`/`executionError` without executing.

- [ ] **Step 4: Add bounded server execution for registered service callbacks**

Update eligibility to accept `urlTemplate != null || callback != null` only for tools found in compiled `serviceSkillDefinitions`. Refactor `_runNativeSkill` to invoke `AppSkillExecutor` for both template and callback tools.

Inject a server-owned `SkillHttpClient` into callback execution. For every `UrlRequest`, perform `requirePublicUriSyntax`, DNS lookup, private/loopback IP rejection, redirects disabled, bounded `_readResponse`, cancellation checks, and forced client close. Require HTTPS when callback input contains resolved credentials. Never execute callbacks from user or persisted dynamic skill definitions.

Add executor tests proving DuckDuckGo callback runs through injected server HTTP, private/loopback targets and redirects fail, cancellation closes request, response limits remain enforced, and a dynamic/user skill cannot supply a callback.

- [ ] **Step 5: Enforce cloud defaults**

Change `defaultCloudToolPermission`:

```dart
if (descriptor.kind == AgentResolvedToolKind.skillControl &&
    descriptor.toolIdentifier == listSkillsToolName) {
  return AgentToolPermissionResult.granted;
}
if ((descriptor.isSkill || descriptor.kind == AgentResolvedToolKind.skillControl) &&
    serverToolIsExecutable(descriptor)) {
  return AgentToolPermissionResult.needsConfirmation;
}
return AgentToolPermissionResult.notConfigured;
```

Do not consult wrapper permission after nested resolution.

- [ ] **Step 6: Run server tests and analyzer**

```bash
fvm dart test test/integration/features/conversations/conversation_engine_host_regression_test.dart
fvm dart test test/integration/features/conversations/conversation_execution_state_test.dart
fvm dart test test/features/conversations/engine/server_tool_executor_test.dart
fvm dart analyze lib/src/features/conversations/engine/server_tool_runtime.dart lib/src/features/conversations/engine/server_tool_executor.dart --fatal-infos --fatal-warnings
```

- [ ] **Step 7: Commit**

```bash
git add apps/auravibes_server/lib/src/features/conversations/engine/server_tool_runtime.dart apps/auravibes_server/lib/src/features/conversations/engine/server_tool_executor.dart apps/auravibes_server/test/integration/features/conversations/conversation_engine_host_regression_test.dart apps/auravibes_server/test/integration/features/conversations/conversation_execution_state_test.dart apps/auravibes_server/test/features/conversations/engine/server_tool_executor_test.dart
git commit -m "fix(server): enforce exact skill tool approvals"
```

---

### Task 5: Harden cloud approval resume authority

**Files:**
- Modify: `apps/auravibes_server/lib/src/features/conversations/engine/server_tool_runtime.dart:525-531,860-930`
- Modify: `apps/auravibes_server/lib/src/features/conversations/usecases/conversation_usecases.dart:1400-1445`
- Test: `apps/auravibes_server/test/integration/features/conversations/conversation_execution_state_test.dart`

**Interfaces:**
- Consumes: persisted pending tool call identified by workspace, conversation turn, message ID, and tool-call ID.
- Produces: one-time state transition `pending -> approved -> running -> completed`; stale/mismatched decisions do not execute.

- [ ] **Step 1: Add failing authority tests**

Assert mismatched message ID, tool-call ID, workspace, already-completed call, and client-supplied target cannot resume execution. Assert matching server pending call resumes once and second approval is a no-op/rejection.

- [ ] **Step 2: Run focused test and verify failure where state validation is missing**

```bash
cd apps/auravibes_server
fvm dart test test/integration/features/conversations/conversation_execution_state_test.dart
```

- [ ] **Step 3: Add minimum compare-and-transition validation**

Reuse existing durable call row and replay states. Do not create parallel approval storage. Resolve target again from persisted original arguments before execution; never trust target sent by client.

- [ ] **Step 4: Run focused test and analyzer**

```bash
fvm dart test test/integration/features/conversations/conversation_execution_state_test.dart
fvm dart analyze lib/src/features/conversations/engine/server_tool_runtime.dart --fatal-infos --fatal-warnings
```

- [ ] **Step 5: Commit**

```bash
git add apps/auravibes_server/lib/src/features/conversations/engine/server_tool_runtime.dart apps/auravibes_server/test/integration/features/conversations/conversation_execution_state_test.dart
git commit -m "fix(server): harden tool approval resume"
```

---

### Task 6: Add structured approval logs without secrets

**Files:**
- Modify: `apps/auravibes_app/lib/services/agent_harness/agent_tool_execution_service.dart`
- Modify: `apps/auravibes_server/lib/src/features/conversations/engine/server_tool_runtime.dart`
- Test: `apps/auravibes_app/test/services/agent_harness/agent_tool_execution_service_test.dart`
- Test: `apps/auravibes_server/test/integration/features/conversations/conversation_execution_state_test.dart`

**Interfaces:**
- Produces log events for resolved decision, pending transition, denial, approval resume, retry suppression, and execution failure.
- Fields: host, conversation ID, message ID when available, tool-call ID, wrapper name, effective target, outcome, reason.
- Excludes raw arguments and execution payloads.

- [ ] **Step 1: Add log-capture tests**

Assert event contains IDs and effective target. Assert sentinel secret placed in arguments is absent from every captured record.

- [ ] **Step 2: Run focused tests and verify missing records fail**

```bash
cd apps/auravibes_app
fvm flutter test test/services/agent_harness/agent_tool_execution_service_test.dart --no-pub
cd ../../apps/auravibes_server
fvm dart test test/integration/features/conversations/conversation_execution_state_test.dart
```

- [ ] **Step 3: Emit bounded structured messages through existing loggers**

Do not add a logging dependency. Use app `Logger` and Serverpod `session.log`. Log reason codes, not exception/stringified request bodies.

- [ ] **Step 4: Run tests and analyzers**

```bash
cd apps/auravibes_app
fvm flutter test test/services/agent_harness/agent_tool_execution_service_test.dart --no-pub
cd ../../apps/auravibes_server
fvm dart test test/integration/features/conversations/conversation_execution_state_test.dart
cd ../..
fvm dart analyze apps/auravibes_app/lib/services/agent_harness/agent_tool_execution_service.dart apps/auravibes_server/lib/src/features/conversations/engine/server_tool_runtime.dart --fatal-infos --fatal-warnings
```

- [ ] **Step 5: Commit**

```bash
git add apps/auravibes_app/lib/services/agent_harness/agent_tool_execution_service.dart apps/auravibes_app/test/services/agent_harness/agent_tool_execution_service_test.dart apps/auravibes_server/lib/src/features/conversations/engine/server_tool_runtime.dart apps/auravibes_server/test/integration/features/conversations/conversation_execution_state_test.dart
git commit -m "feat: log effective tool approval decisions"
```

---

### Task 7: Run parity and repository gates

**Files:**
- Modify only for defects exposed by validation: files from Tasks 1-6.
- Update: `docs/superpowers/specs/2026-08-10-effective-tool-approval-design.md` only if implementation required an approved design correction.

**Interfaces:**
- Produces verified parity: same effective target and approval outcome for equivalent local/cloud scenarios.

- [ ] **Step 1: Run all focused suites once**

```bash
cd packages/auravibes_engine
fvm dart test test/tool_approval_target_test.dart
cd ../../apps/auravibes_app
fvm flutter test test/services/agent_harness/agent_tool_execution_service_test.dart --no-pub
fvm flutter test test/features/tools/usecases/resolve_tool_approval_decision_usecase_test.dart --no-pub
fvm flutter test test/features/chats/widgets/chat_tool_approval_card_test.dart --no-pub
cd ../auravibes_server
fvm dart test test/integration/features/conversations/conversation_engine_host_regression_test.dart
fvm dart test test/integration/features/conversations/conversation_execution_state_test.dart
fvm dart test test/features/conversations/engine/server_tool_executor_test.dart
```

Expected: all PASS.

- [ ] **Step 2: Run broad required validation**

From repository root:

```bash
fvm dart run melos run validate:quick
```

Expected: PASS. If it reports unrelated baseline diagnostics, document exact diagnostics; do not broaden scope.

- [ ] **Step 3: Mechanically inspect security invariants**

```bash
rg "callSkillToolName|call_skill_tool" apps/auravibes_app/lib/services/agent_harness apps/auravibes_server/lib/src/features/conversations/engine packages/auravibes_engine/lib/src
rg "argumentsRaw|request.arguments" apps/auravibes_app/lib/services/agent_harness/agent_tool_execution_service.dart apps/auravibes_server/lib/src/features/conversations/engine/server_tool_runtime.dart
```

Confirm wrapper is resolved before policy lookup, no wrapper grant authorizes nested execution, and logs do not include raw arguments.

- [ ] **Step 4: Review diff and whitespace**

```bash
git diff --check
git status --short
git diff --stat
```

Confirm unrelated pre-existing changes remain untouched.

Any validation defect must be fixed and committed in its owning Task 1-6 commit before this task is marked complete; final validation creates no catch-all commit.

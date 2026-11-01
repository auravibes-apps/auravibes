import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/workspace_agent_hook_settings_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/chats/agent_adapters/workspace_lifecycle_hook_runner.dart';
import 'package:auravibes_app/services/agent_lifecycle_hook_config.dart';
import 'package:auravibes_app/services/agent_lifecycle_hook_runtime.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late WorkspaceRepository workspaceRepository;
  late WorkspaceAgentHookSettingsRepository settingsRepository;

  setUp(() {
    database = AppDatabase(
      connection: DatabaseConnection(NativeDatabase.memory()),
    );
    workspaceRepository = WorkspaceRepository(database);
    settingsRepository = WorkspaceAgentHookSettingsRepository(
      database.workspaceAgentHookSettingsDao,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'workspace opt-in is required before inspecting or running hooks',
    () async {
      final workspace = await _createWorkspace(workspaceRepository);
      final runtime = _FakeHookRuntime();
      final runner = _runner(settingsRepository, workspaceRepository, runtime);

      final result = await runner.beforeTool(
        request: _request(workspace.id),
        isCancellationRequested: (_) => false,
      );

      expect(result.outcome, agent.AgentToolHookOutcome.allow);
      expect(runtime.inspectCount, 0);
      expect(runtime.invokeCount, 0);
    },
  );

  test(
    'trusted configuration still requires explicit workspace opt-in',
    () async {
      final workspace = await _createWorkspace(workspaceRepository);
      await _trust(settingsRepository, workspace.id);
      final runtime = _FakeHookRuntime();
      final runner = _runner(settingsRepository, workspaceRepository, runtime);

      final result = await runner.beforeTool(
        request: _request(workspace.id),
        isCancellationRequested: (_) => false,
      );

      expect(result.outcome, agent.AgentToolHookOutcome.allow);
      expect(runtime.invokeCount, 0);
    },
  );

  test('trust and opt-in do not carry between workspaces', () async {
    final trustedWorkspace = await _createWorkspace(workspaceRepository);
    final otherWorkspace = await workspaceRepository.createWorkspace(
      const WorkspaceToCreate(name: 'Other local', type: .local),
    );
    await _trust(settingsRepository, trustedWorkspace.id, enabled: true);
    final runtime = _FakeHookRuntime();
    final runner = _runner(settingsRepository, workspaceRepository, runtime);

    final result = await runner.beforeTool(
      request: _request(otherWorkspace.id),
      isCancellationRequested: (_) => false,
    );

    expect(result.outcome, agent.AgentToolHookOutcome.allow);
    expect(runtime.inspectCount, 0);
    expect(runtime.invokeCount, 0);
  });

  test('missing workspace scope fails closed before tool execution', () async {
    final runtime = _FakeHookRuntime();
    final runner = _runner(settingsRepository, workspaceRepository, runtime);

    final result = await runner.beforeTool(
      request: _request(''),
      isCancellationRequested: (_) => false,
    );

    expect(result.outcome, agent.AgentToolHookOutcome.unavailable);
    expect(runtime.inspectCount, 0);
    expect(runtime.invokeCount, 0);
  });

  test('local trusted block is redacted and receives no tool values', () async {
    final workspace = await _createWorkspace(workspaceRepository);
    await _trust(settingsRepository, workspace.id, enabled: true);
    final runtime = _FakeHookRuntime(
      output: const AgentLifecycleHookInvocationResult(
        outcome: agent.AgentToolHookOutcome.success,
        stdout: '{"decision":"block","reason":"secret=do-not-leak"}',
      ),
    );
    final runner = _runner(settingsRepository, workspaceRepository, runtime);

    final result = await runner.beforeTool(
      request: _request(workspace.id),
      isCancellationRequested: (_) => false,
    );

    expect(result.outcome, agent.AgentToolHookOutcome.block);
    expect(result.reason, contains('[REDACTED]'));
    expect(result.reason, isNot(contains('do-not-leak')));
    final hookInput = jsonDecode(runtime.lastInput!) as Map<String, dynamic>;
    expect(hookInput['tool'], 'search');
    expect(hookInput['argumentNames'], ['api_key', 'query']);
    expect(runtime.lastInput, isNot(contains('secret-value')));
  });

  test('bounds the sanitized metadata sent to hook commands', () async {
    final workspace = await _createWorkspace(workspaceRepository);
    await _trust(settingsRepository, workspace.id, enabled: true);
    final runtime = _FakeHookRuntime();
    final runner = _runner(settingsRepository, workspaceRepository, runtime);

    await runner.beforeTool(
      request: agent.AgentToolLifecycleHookRequest(
        workspaceId: workspace.id,
        conversationId: 'conversation-1',
        toolCallId: 'c' * 1000,
        tool: ResolvedTool.skillControl(toolIdentifier: 'search'),
        argumentNames: List.filled(100, 'name' * 100),
      ),
      isCancellationRequested: (_) => false,
    );

    final inputRaw = runtime.lastInput!;
    expect(utf8.encode(inputRaw).length, lessThanOrEqualTo(8192));
    final input = jsonDecode(inputRaw) as Map<String, dynamic>;
    expect(input['toolCallId'], hasLength(128));
    expect(input['argumentNames'], hasLength(24));
    expect((input['argumentNames'] as List).first, hasLength(24));
  });

  test(
    'remote workspace hooks fail closed without launching commands',
    () async {
      final workspace = await workspaceRepository.createWorkspace(
        const WorkspaceToCreate(
          name: 'Remote',
          type: .remote,
          url: 'https://example.invalid',
        ),
      );
      await _trust(settingsRepository, workspace.id, enabled: true);
      final runtime = _FakeHookRuntime();
      final runner = _runner(settingsRepository, workspaceRepository, runtime);

      final result = await runner.beforeTool(
        request: _request(workspace.id),
        isCancellationRequested: (_) => false,
      );

      expect(result.outcome, agent.AgentToolHookOutcome.unavailable);
      expect(runtime.invokeCount, 0);
    },
  );

  test('changed configuration fingerprint fails closed', () async {
    final workspace = await _createWorkspace(workspaceRepository);
    await _trust(settingsRepository, workspace.id, enabled: true);
    final runtime = _FakeHookRuntime(digest: 'changed');
    final runner = _runner(settingsRepository, workspaceRepository, runtime);

    final result = await runner.beforeTool(
      request: _request(workspace.id),
      isCancellationRequested: (_) => false,
    );

    expect(result.outcome, agent.AgentToolHookOutcome.unavailable);
    expect(runtime.invokeCount, 0);
  });

  test('post-hook context is redacted before reaching model context', () async {
    final workspace = await _createWorkspace(workspaceRepository);
    await _trust(
      settingsRepository,
      workspace.id,
      enabled: true,
      event: AgentLifecycleHookEvent.afterTool,
    );
    final runtime = _FakeHookRuntime(
      event: AgentLifecycleHookEvent.afterTool,
      output: const AgentLifecycleHookInvocationResult(
        outcome: agent.AgentToolHookOutcome.success,
        stdout: '{"context":"token=do-not-leak"}',
      ),
    );
    final runner = _runner(settingsRepository, workspaceRepository, runtime);

    final result = await runner.afterTool(
      request: _request(workspace.id),
      toolSucceeded: true,
      isCancellationRequested: (_) => false,
    );

    expect(result.outcome, agent.AgentToolHookOutcome.success);
    expect(result.context, contains('[REDACTED]'));
    expect(result.context, isNot(contains('do-not-leak')));
  });
}

Future<WorkspaceEntity> _createWorkspace(WorkspaceRepository repository) =>
    repository.createWorkspace(
      const WorkspaceToCreate(name: 'Local', type: .local),
    );

Future<void> _trust(
  WorkspaceAgentHookSettingsRepository repository,
  String workspaceId, {
  bool enabled = false,
}) async {
  await repository.selectConfig(workspaceId, canonicalPath: '/tmp/hooks.json');
  await repository.trustConfig(
    workspaceId,
    canonicalPath: '/tmp/hooks.json',
    digest: 'trusted',
  );
  if (enabled) await repository.setEnabled(workspaceId, enabled: true);
}

WorkspaceLifecycleHookRunner _runner(
  WorkspaceAgentHookSettingsRepository settingsRepository,
  WorkspaceRepository workspaceRepository,
  AgentLifecycleHookRuntime runtime,
) => WorkspaceLifecycleHookRunner(
  settingsRepository: settingsRepository,
  workspaceRepository: workspaceRepository,
  runtime: runtime,
);

agent.AgentToolLifecycleHookRequest<ResolvedTool> _request(
  String workspaceId,
) => agent.AgentToolLifecycleHookRequest(
  workspaceId: workspaceId,
  conversationId: 'conversation-1',
  toolCallId: 'call-1',
  tool: ResolvedTool.skillControl(toolIdentifier: 'search'),
  argumentNames: const ['api_key', 'query'],
);

class _FakeHookRuntime implements AgentLifecycleHookRuntime {
  _FakeHookRuntime({
    this.digest = 'trusted',
    this.event = AgentLifecycleHookEvent.beforeTool,
    this.output = const AgentLifecycleHookInvocationResult(
      outcome: agent.AgentToolHookOutcome.success,
      stdout: '{"decision":"allow"}',
    ),
  });

  final String digest;
  final AgentLifecycleHookEvent event;
  final AgentLifecycleHookInvocationResult output;
  var inspectCount = 0;
  var invokeCount = 0;
  String? lastInput;

  @override
  bool get isSupported => true;

  @override
  Future<AgentLifecycleHookSourceSnapshot> inspect(String sourcePath) async {
    inspectCount++;
    final hook = AgentLifecycleHookDefinition(
      event: event,
      command: '/bin/true',
      args: const [],
    );

    return AgentLifecycleHookSourceSnapshot(
      canonicalPath: sourcePath,
      digest: digest,
      config: AgentLifecycleHookConfig(hooks: [hook]),
      commandPaths: {event: '/bin/true'},
    );
  }

  @override
  Future<AgentLifecycleHookInvocationResult> invoke({
    required AgentLifecycleHookSourceSnapshot snapshot,
    required AgentLifecycleHookDefinition hook,
    required String input,
    required agent.AgentToolHookCancellationChecker isCancellationRequested,
    required String conversationId,
  }) async {
    invokeCount++;
    lastInput = input;

    return output;
  }
}

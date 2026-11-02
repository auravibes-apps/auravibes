import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/workspace_agent_hook_settings_repository.dart';
import 'package:auravibes_app/data/repositories/workspace_repository.dart';
import 'package:auravibes_app/domain/entities/workspace_entity.dart';
import 'package:auravibes_app/features/chats/agent_adapters/workspace_lifecycle_hook_runner.dart';
import 'package:auravibes_app/services/agent_lifecycle_hook_config.dart';
import 'package:auravibes_app/services/agent_lifecycle_hook_runtime.dart';
import 'package:auravibes_app/services/agent_lifecycle_hook_runtime_io.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as agent;
import 'package:drift/drift.dart' hide isNotNull, isNull;
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

  final secretExamples = {
    'api_key=private-api-key': ['private-api-key'],
    'Authorization: Bearer private-bearer': ['private-bearer'],
    'Authorization: Basic cHJpdmF0ZS1iYXNpYw==': ['cHJpdmF0ZS1iYXNpYw=='],
    '{"password":"private-password"}': ['private-password'],
    'https://private-user:private-password@example.invalid/?token=private-token':
        ['private-user', 'private-password', 'private-token'],
    'Cookie: session=private-cookie': ['private-cookie'],
  };
  for (final event in AgentLifecycleHookEvent.values) {
    for (final example in secretExamples.entries) {
      test('$event redacts recognized secrets in ${example.key}', () async {
        final workspace = await _createWorkspace(workspaceRepository);
        await _trust(settingsRepository, workspace.id, enabled: true);
        final runtime = _FakeHookRuntime(
          event: event,
          output: AgentLifecycleHookInvocationResult(
            outcome: agent.AgentToolHookOutcome.success,
            stdout: jsonEncode(
              event == AgentLifecycleHookEvent.beforeTool
                  ? {'decision': 'block', 'reason': example.key}
                  : {'context': example.key},
            ),
          ),
        );
        final runner = _runner(
          settingsRepository,
          workspaceRepository,
          runtime,
        );
        final text = event == AgentLifecycleHookEvent.beforeTool
            ? (await runner.beforeTool(
                request: _request(workspace.id),
                isCancellationRequested: (_) => false,
              )).reason
            : (await runner.afterTool(
                request: _request(workspace.id),
                toolSucceeded: true,
                isCancellationRequested: (_) => false,
              )).context;
        expect(text, contains('[REDACTED]'));
        for (final secret in example.value) {
          expect(text, isNot(contains(secret)));
        }
      });
    }

    for (final output in [
      'token=private-malformed-response',
      jsonEncode(
        event == AgentLifecycleHookEvent.beforeTool
            ? {
                'decision': 'allow',
                'arguments': {'query': 'replacement'},
              }
            : {'context': 'supplemental', 'result': 'replacement'},
      ),
    ]) {
      test('$event rejects malformed or rewriting output: $output', () async {
        final workspace = await _createWorkspace(workspaceRepository);
        await _trust(settingsRepository, workspace.id, enabled: true);
        final runtime = _FakeHookRuntime(
          event: event,
          output: AgentLifecycleHookInvocationResult(
            outcome: agent.AgentToolHookOutcome.success,
            stdout: output,
          ),
        );
        final runner = _runner(
          settingsRepository,
          workspaceRepository,
          runtime,
        );
        if (event == AgentLifecycleHookEvent.beforeTool) {
          final result = await runner.beforeTool(
            request: _request(workspace.id),
            isCancellationRequested: (_) => false,
          );
          expect(result.outcome, agent.AgentToolHookOutcome.failed);
          expect(result.reason, isNot(contains('private-malformed-response')));
        } else {
          final result = await runner.afterTool(
            request: _request(workspace.id),
            toolSucceeded: true,
            isCancellationRequested: (_) => false,
          );
          expect(result.outcome, agent.AgentToolHookOutcome.failed);
          expect(result.context, isNull);
        }
      });
    }
  }

  for (final event in AgentLifecycleHookEvent.values) {
    for (final change in ['revoke', 'disable', 'replace', 'cancel']) {
      test('$event does not invoke after $change during inspection', () async {
        final workspace = await _createWorkspace(workspaceRepository);
        await _trust(settingsRepository, workspace.id, enabled: true);
        final started = Completer<void>();
        final release = Completer<void>();
        var cancelled = false;
        final runtime = _FakeHookRuntime(
          event: event,
          onInspect: () async {
            started.complete();
            await release.future;
          },
        );
        final runner = _runner(
          settingsRepository,
          workspaceRepository,
          runtime,
        );
        final pending = event == AgentLifecycleHookEvent.beforeTool
            ? runner
                  .beforeTool(
                    request: _request(workspace.id),
                    isCancellationRequested: (_) => cancelled,
                  )
                  .then((result) => result.outcome)
            : runner
                  .afterTool(
                    request: _request(workspace.id),
                    toolSucceeded: true,
                    isCancellationRequested: (_) => cancelled,
                  )
                  .then((result) {
                    expect(result.context, isNull);
                    return result.outcome;
                  });
        await started.future;
        switch (change) {
          case 'revoke':
            await settingsRepository.revokeTrust(workspace.id);
          case 'disable':
            await settingsRepository.setEnabled(workspace.id, enabled: false);
          case 'replace':
            await settingsRepository.selectConfig(
              workspace.id,
              canonicalPath: '/tmp/other-hooks.json',
            );
          case 'cancel':
            cancelled = true;
        }
        release.complete();

        expect(
          await pending,
          change == 'cancel'
              ? agent.AgentToolHookOutcome.cancelled
              : agent.AgentToolHookOutcome.unavailable,
        );
        expect(runtime.invokeCount, 0);
      });
    }
  }

  test(
    'revoking trust during runtime reinspection prevents process launch',
    () async {
      final workspace = await _createWorkspace(workspaceRepository);
      final directory = await Directory.systemTemp.createTemp(
        'aura-hook-trust-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final marker = File('${directory.path}/executed');
      final configFile = File('${directory.path}/hooks.json');
      await configFile.writeAsString(
        jsonEncode({
          'version': 1,
          'hooks': [
            {
              'event': 'beforeTool',
              'command': '/usr/bin/python3',
              'args': [
                '-c',
                'from pathlib import Path; '
                    'Path(${jsonEncode(marker.path)}).write_text("executed"); '
                    'print(\'{"decision":"allow"}\')',
              ],
            },
          ],
        }),
      );
      final snapshot = await const IoAgentLifecycleHookRuntime().inspect(
        configFile.path,
      );
      await settingsRepository.selectConfig(
        workspace.id,
        canonicalPath: snapshot.canonicalPath,
      );
      await settingsRepository.trustConfig(
        workspace.id,
        canonicalPath: snapshot.canonicalPath,
        digest: snapshot.digest,
      );
      await settingsRepository.setEnabled(workspace.id, enabled: true);
      final runtime = _PausingReinspectionRuntime();
      final runner = _runner(settingsRepository, workspaceRepository, runtime);
      final pending = runner.beforeTool(
        request: _request(workspace.id),
        isCancellationRequested: (_) => false,
      );
      await runtime.started.future;
      await settingsRepository.revokeTrust(workspace.id);
      runtime.release.complete();

      expect((await pending).outcome, agent.AgentToolHookOutcome.unavailable);
      expect(await marker.exists(), isFalse);
    },
    skip:
        !(Platform.isLinux || Platform.isMacOS) ||
        !File('/usr/bin/python3').existsSync(),
  );

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
    await _trust(settingsRepository, workspace.id, enabled: true);
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
    this.onInspect,
    this.output = const AgentLifecycleHookInvocationResult(
      outcome: agent.AgentToolHookOutcome.success,
      stdout: '{"decision":"allow"}',
    ),
  });

  final String digest;
  final AgentLifecycleHookEvent event;
  final Future<void> Function()? onInspect;
  final AgentLifecycleHookInvocationResult output;
  var inspectCount = 0;
  var invokeCount = 0;
  String? lastInput;

  @override
  bool get isSupported => true;

  @override
  Future<AgentLifecycleHookSourceSnapshot> inspect(String sourcePath) async {
    inspectCount++;
    await onInspect?.call();
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
    Future<bool> Function()? isStillTrusted,
  }) async {
    invokeCount++;
    lastInput = input;

    return output;
  }
}

class _PausingReinspectionRuntime extends IoAgentLifecycleHookRuntime {
  final started = Completer<void>();
  final release = Completer<void>();
  var inspections = 0;

  @override
  Future<AgentLifecycleHookSourceSnapshot> inspect(String sourcePath) async {
    inspections++;
    if (inspections == 2) {
      started.complete();
      await release.future;
    }
    return super.inspect(sourcePath);
  }
}

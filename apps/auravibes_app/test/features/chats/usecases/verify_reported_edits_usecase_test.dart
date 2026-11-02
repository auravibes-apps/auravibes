import 'dart:async';
import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/workspace_verification_repository.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/features/chats/agent_adapters/create_mcp_scoped_verification_runner.dart';
import 'package:auravibes_app/features/chats/agent_adapters/resolved_tool_service.dart';
import 'package:auravibes_app/features/chats/agent_adapters/scoped_verification_cancellation.dart';
import 'package:auravibes_app/features/chats/models/scoped_verification_invocation.dart';
import 'package:auravibes_app/features/chats/providers/agent_cancellation_runtime.dart';
import 'package:auravibes_app/features/chats/usecases/verify_reported_edits_usecase.dart';
import 'package:auravibes_app/features/tools/models/tool_approval_decision.dart';
import 'package:auravibes_app/services/agent_harness/mcp_tool_caller_result.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final holder = _FixtureHolder();
  setUp(() async {
    holder.current = await _Fixture.create();
  });
  tearDown(() async {
    holder.current.runtime.dispose();
    await holder.current.database.close();
  });

  test(
    'disabled settings preserve model text without probing a runner',
    () async {
      final result = await holder.current.call('one');
      expect(result, 'edit completed');
      expect(holder.current.operations, isEmpty);
    },
  );

  test(
    'two sequential edits build fresh runners and both verify successfully',
    () async {
      await holder.current.enable();
      final first = _verification(await holder.current.call('one'));
      final second = _verification(await holder.current.call('two'));
      expect(first['state'], 'pass');
      expect(second['state'], 'pass');
      expect(holder.current.operations, [
        'capabilities',
        'start',
        'capabilities',
        'start',
      ]);
      expect(holder.current.operationIds.toSet(), hasLength(2));
      expect(
        identical(
          holder.current.runners.firstOrNull,
          holder.current.runners[1],
        ),
        isFalse,
      );
      expect(holder.current.closedSessions, 2);
      expect(holder.current.runtime.current('chat'), isNull);
    },
  );

  test(
    'failed feedback permits one authorized repair without replaying edits',
    () async {
      await holder.current.enable();
      holder.current.exitCode = 1;
      final first = _verification(await holder.current.call('one'));
      expect(first['state'], 'fail');
      expect(first['output'], 'check failed');
      expect(first['repairAllowed'], isTrue);
      final repaired = _verification(await holder.current.call('two'));
      expect(repaired['state'], 'fail');
      expect(repaired['repairAllowed'], isFalse);
      final exhausted = _verification(await holder.current.call('three'));
      expect(exhausted['state'], 'incomplete');
      expect(exhausted['reason'], 'repair_limit_reached');
      expect(
        holder.current.operations.where((operation) => operation == 'start'),
        hasLength(2),
      );
    },
  );

  test(
    'successful repair clears failure without restoring its spent token',
    () async {
      await holder.current.enable();
      holder.current.exitCode = 2;
      final _ = await holder.current.call('one');
      holder.current.exitCode = 0;
      final result = _verification(await holder.current.call('two'));
      expect(result['state'], 'pass');
      expect(result['repairAttemptsRemaining'], 0);
    },
  );

  test(
    'unlisted tools, MCP errors, text and app data never select commands',
    () async {
      await holder.current.enable();
      final _ = await holder.current.call(
        'one',
        tool: ResolvedTool.mcp(
          tableId: 'unlisted',
          toolIdentifier: 'other',
          mcp: (
            mcpServerId: 'server',
            mcpSlug: 'server',
            outputSchemaJson: null,
          ),
        ),
      );
      final _ = await holder.current.call(
        'two',
        result: .new(
          modelText: 'error',
          appData: const {},
          structuredContent: _report(),
          isError: true,
        ),
      );
      final text = await holder.current.call(
        'three',
        result: .new(
          modelText: jsonEncode(_report()),
          appData: {'auravibesChangedPaths': _report()},
        ),
      );
      expect(_verification(text)['state'], 'skipped');
      expect(holder.current.operations, isEmpty);
    },
  );

  test(
    'malformed paths reject the entire report before reserving a command',
    () async {
      await holder.current.enable();
      final result = _verification(
        await holder.current.call(
          'one',
          result: const McpToolCallerResult(
            modelText: 'edit completed',
            appData: {},
            structuredContent: {
              'auravibesChangedPaths': {
                'version': 1,
                'workspaceRoot': 'root',
                'paths': ['safe.dart', '../outside.dart'],
              },
            },
          ),
        ),
      );
      expect(result['reason'], 'invalid_report');
      expect(result['state'], 'incomplete');
      expect(holder.current.operations, isEmpty);
      expect(
        await holder.current.database
            .select(holder.current.database.workspaceVerificationRuns)
            .get(),
        isEmpty,
      );
    },
  );

  test(
    'runner permission denial preserves the edit and reports incomplete',
    () async {
      await holder.current.enable();
      holder.current.permitted = false;
      final result = _verification(await holder.current.call('one'));
      expect(result['state'], 'incomplete');
      expect(holder.current.operations, isEmpty);
    },
  );

  test('a missing compliant runner never claims a check ran', () async {
    await holder.current.enable();
    holder.current.compliant = false;
    final result = _verification(await holder.current.call('one'));
    expect(result['state'], 'incomplete');
    expect(result['reason'], 'unsupported_runner');
    expect(holder.current.operations, ['capabilities']);
  });

  test(
    'replayed tool call returns its recorded outcome with no second start',
    () async {
      await holder.current.enable();
      final first = _verification(await holder.current.call('one'));
      final replay = _verification(await holder.current.call('one'));
      expect(replay['state'], first['state']);
      expect(holder.current.operations, ['capabilities', 'start']);
    },
  );

  test(
    'feedback stays inside the agent context limit even with JSON escapes',
    () {
      final result = ScopedVerificationResult(
        outcome: .fail,
        reason: 'nonzero_exit',
        output: '\u0000' * 60000,
        maxOutputBytes: 65536,
        repairAttemptsRemaining: 1,
      );
      final feedback = buildScopedVerificationFeedback('"' * 60000, result);
      expect(
        utf8.encode(jsonEncode(feedback)).length,
        lessThanOrEqualTo(16384),
      );
      expect(_verification(feedback)['state'], 'fail');
      expect(_verification(feedback)['repairAllowed'], isTrue);
      expect(_verification(feedback)['outputTruncated'], isTrue);
    },
  );

  test(
    'shared tool execution preserves mutation success and private app data',
    () async {
      await holder.current.enable();
      holder.current.exitCode = 1;
      var edits = 0;
      final service = ResolvedToolService(
        agentCancellationRuntime: holder.current.runtime,
        mcpToolCaller:
            ({
              required mcpServerId,
              required toolIdentifier,
              required arguments,
              onElicitation,
            }) async {
              edits++;

              return McpToolCallerResult(
                modelText: 'edit completed',
                appData: const {'private': 'app-only-marker'},
                structuredContent: _report(),
              );
            },
        scopedVerification: holder.current.usecase,
      );
      final executor = AgentToolBatchExecutor<ResolvedTool>(
        runResolvedTool: service.call,
        isCancellationRequested: (_) => false,
        logToolExecutionError: (error) =>
            fail('A completed edit must not become a mutation error: $error'),
      );
      final results = await executor.call([
        AgentToolBatchCall(
          conversationId: 'chat',
          messageId: 'assistant',
          toolCallId: 'one',
          tool: ResolvedTool.mcp(
            tableId: 'edit',
            toolIdentifier: 'edit_file',
            mcp: (
              mcpServerId: 'server',
              mcpSlug: 'server',
              outputSchemaJson: null,
            ),
          ),
          argumentsRaw: '{}',
        ),
      ]);
      final result = results.single.result;
      expect(result.resultStatus, AgentToolResultStatus.success);
      expect(
        _verification(
          jsonDecode(
            result.responseRaw ?? (throw StateError('Missing tool response.')),
          ) as Object,
        )['state'],
        'fail',
      );
      expect(result.responseRaw, isNot(contains('app-only-marker')));
      expect(
        service.takeMcpAppResultData(conversationId: 'chat', toolCallId: 'one'),
        {'private': 'app-only-marker'},
      );
      expect(edits, 1);
      expect(holder.current.operations, ['capabilities', 'start']);
    },
  );

  test(
    'cancellation while the runner factory is pending cannot launch late work',
    () async {
      await holder.current.enable();
      final entered = Completer<void>();
      final pending = Completer<ScopedVerificationRunner?>();
      final usecase = VerifyReportedEditsUsecase(
        repository: holder.current.repository,
        resolveIdentity: (_) async =>
            (workspaceId: 'workspace', turnId: 'turn'),
        createRunner: (_) {
          entered.complete();

          return pending.future;
        },
        cancellation: holder.current.cancellation,
      );
      final output = usecase(
        conversationId: 'chat',
        toolCallId: 'one',
        tool: ResolvedTool.mcp(
          tableId: 'edit',
          toolIdentifier: 'edit_file',
          mcp: (
            mcpServerId: 'server',
            mcpSlug: 'server',
            outputSchemaJson: null,
          ),
        ),
        result: McpToolCallerResult(
          modelText: 'edit completed',
          appData: const {},
          structuredContent: _report(),
        ),
      );
      await entered.future;
      final handle = holder.current.runtime.toolCancellationHandle(
        conversationId: 'chat',
        toolCallId: 'one',
      );
      expect(await handle?.requestCancellation(), isTrue);
      expect(_verification(await output)['state'], 'cancelled');
      pending.complete();
      expect(holder.current.operations, isEmpty);
    },
  );

  test(
    'a connection completed after cancellation is closed without dispatch',
    () async {
      await holder.current.enable();
      final connection = Completer<ScopedVerificationOwnedCaller>();
      holder.current.pendingConnection = connection.future;
      final output = holder.current.call('one');
      await holder.current.openingConnection.future;
      final handle = holder.current.runtime.toolCancellationHandle(
        conversationId: 'chat',
        toolCallId: 'one',
      );
      expect(await handle?.requestCancellation(), isTrue);
      expect(_verification(await output)['state'], 'cancelled');
      connection.complete((
        call: holder.current._caller,
        close: () {
          holder.current.closedSessions++;
        },
      ));
      for (var index = 0; index < 10; index++) {
        await Future<void>.delayed(.zero);
      }
      expect(holder.current.closedSessions, 1);
      expect(holder.current.operations, isEmpty);
    },
  );

  test(
    'connection cancellation exceptions preserve the cancelled result',
    () async {
      await holder.current.enable();
      final usecase = VerifyReportedEditsUsecase(
        repository: holder.current.repository,
        resolveIdentity: (_) async =>
            (workspaceId: 'workspace', turnId: 'turn'),
        createRunner: (input) async {
          input.cancellation.requestStop();
          throw StateError('Connection cancelled.');
        },
        cancellation: holder.current.cancellation,
      );
      final output = await usecase(
        conversationId: 'chat',
        toolCallId: 'one',
        tool: ResolvedTool.mcp(
          tableId: 'edit',
          toolIdentifier: 'edit_file',
          mcp: (
            mcpServerId: 'server',
            mcpSlug: 'server',
            outputSchemaJson: null,
          ),
        ),
        result: McpToolCallerResult(
          modelText: 'edit completed',
          appData: const {},
          structuredContent: _report(),
        ),
      );
      expect(_verification(output)['state'], 'cancelled');
      expect(_verification(output)['reason'], 'cancelled');
      expect(holder.current.operations, isEmpty);
    },
  );
}

Map<String, Object?> _verification(Object output) =>
    (output as Map<String, Object?>)['verification']! as Map<String, Object?>;
Map<String, Object?> _report() => {
  'auravibesChangedPaths': {
    'version': 1,
    'workspaceRoot': 'root',
    'paths': ['lib/main.dart'],
  },
};

final class _Fixture {
  new(this.database);
  final AppDatabase database;
  final runtime = AgentCancellationRuntime();
  final operations = <String>[];
  final operationIds = <String>[];
  final runners = <ScopedVerificationRunner>[];
  bool permitted = true;
  bool compliant = true;
  int exitCode = 0;
  int closedSessions = 0;
  Future<ScopedVerificationOwnedCaller>? pendingConnection;
  final openingConnection = Completer<void>();

  WorkspaceVerificationRepository? _repository;
  ScopedVerificationCancellation? _cancellation;
  CreateMcpScopedVerificationRunner? _runnerFactory;
  VerifyReportedEditsUsecase? _usecase;

  WorkspaceVerificationRepository get repository =>
      _repository ??= .new(database);
  ScopedVerificationCancellation get cancellation =>
      _cancellation ??= .new(runtime);
  CreateMcpScopedVerificationRunner get runnerFactory =>
      _runnerFactory ??= .new(
        database: database,
        repository: repository,
        openSession: (_, _) async {
          if (!openingConnection.isCompleted) openingConnection.complete();

          return await (pendingConnection ??
              Future.value((
                call: _caller,
                close: () {
                  closedSessions++;
                },
              )));
        },
        permission: (request) async => ToolApprovalDecision(
          toolCallId: request.toolCallId,
          permissionResult: permitted ? .granted : .disabledInWorkspace,
        ),
      );
  VerifyReportedEditsUsecase get usecase =>
      _usecase ??= .new(
        repository: repository,
        resolveIdentity: (_) async =>
            (workspaceId: 'workspace', turnId: 'turn'),
        createRunner: (input) async {
          final runner = await runnerFactory(input);
          if (runner != null) runners.add(runner);

          return runner;
        },
        cancellation: cancellation,
      );

  Future<Object> call(
    String id, {
    ResolvedTool? tool,
    McpToolCallerResult? result,
  }) => usecase(
    conversationId: 'chat',
    toolCallId: id,
    tool:
        tool ??
        ResolvedTool.mcp(
          tableId: 'edit',
          toolIdentifier: 'edit_file',
          mcp: (
            mcpServerId: 'server',
            mcpSlug: 'server',
            outputSchemaJson: null,
          ),
        ),
    result:
        result ??
        McpToolCallerResult(
          modelText: 'edit completed',
          appData: const {},
          structuredContent: _report(),
        ),
  );

  Future<void> enable() => repository.saveSettings(
    'workspace',
    .new(
      enabled: true,
      runnerToolId: 'runner',
      mcpServerId: 'server',
      workspaceRoot: 'root',
      editToolIds: const {'edit'},
      checks: [
        ScopedVerificationCheck(
          id: 'check',
          executable: 'dart',
          arguments: const ['analyze'],
          pathSuffixes: const ['.dart'],
        ),
      ],
    ),
  );

  static Future<_Fixture> create() async {
    final database = AppDatabase(connection: NativeDatabase.memory());
    final _ = await database
        .into(database.workspaces)
        .insert(
          WorkspacesCompanion.insert(
            id: const Value('workspace'),
            name: 'Local',
            type: .local,
          ),
        );
    final _ = await database
        .into(database.conversations)
        .insert(
          ConversationsCompanion.insert(
            id: const Value('chat'),
            workspaceId: 'workspace',
            title: 'Work',
          ),
        );
    final _ = await database
        .into(database.messages)
        .insert(
          MessagesCompanion.insert(
            id: const Value('turn'),
            conversationId: 'chat',
            content: 'Edit',
            messageType: .text,
            isUser: true,
            status: .sent,
          ),
        );
    final _ = await database
        .into(database.mcpServers)
        .insert(
          McpServersCompanion.insert(
            id: const Value('server'),
            workspaceId: 'workspace',
            name: 'Code',
            url: 'https://runner.example/mcp',
            transport: const McpTransportTypeStreamableHttp(),
          ),
        );
    final _ = await database
        .into(database.toolsGroups)
        .insert(
          ToolsGroupsCompanion.insert(
            id: const Value('group'),
            workspaceId: 'workspace',
            mcpServerId: const Value('server'),
            name: 'Code',
            permissions: .granted,
          ),
        );
    for (final entry in {'edit': 'edit_file', 'runner': 'verify'}.entries) {
      final _ = await database
          .into(database.tools)
          .insert(
            ToolsCompanion.insert(
              id: .new(entry.key),
              workspaceId: 'workspace',
              workspaceToolsGroupId: const Value('group'),
              toolId: entry.value,
              isEnabled: const Value(true),
              permissions: const Value(.granted),
            ),
          );
    }

    return _Fixture(database);
  }

  Future<Object?> _caller({
    required String mcpServerId,
    required String toolIdentifier,
    required Map<String, dynamic> arguments,
    Object? onElicitation,
  }) async {
    expect(mcpServerId, 'server');
    expect(toolIdentifier, 'verify');
    expect(onElicitation, isNull);
    final operation = arguments['operation'] as String;
    operations.add(operation);
    if (operation == 'capabilities') {
      return McpToolCallerResult(
        modelText: '',
        appData: const {},
        structuredContent: {
          'protocol': ScopedVerificationLimits.protocol,
          'capabilities': {
            for (final feature
                in ScopedVerificationCapabilities.requiredFeatures)
              feature: compliant,
          },
        },
      );
    }
    final id = arguments['operationId'] as String;
    operationIds.add(id);

    return McpToolCallerResult(
      modelText: '',
      appData: const {},
      structuredContent: {
        'protocol': ScopedVerificationLimits.protocol,
        'operationId': id,
        'workspaceRoot': 'root',
        'state': 'completed',
        'scopeValidated': true,
        'checks': [
          {'id': 'check', 'exitCode': exitCode},
        ],
        'output': 'check failed',
        'outputTruncated': false,
        'originalOutputBytes': 12,
      },
    );
  }
}

final class _FixtureHolder {
  _Fixture? _current;

  _Fixture get current =>
      _current ?? (throw StateError('Test fixture is not initialized.'));
  set current(_Fixture value) {
    _current = value;
  }
}

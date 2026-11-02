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
  late _Fixture fixture;
  setUp(() async {
    fixture = await _Fixture.create();
  });
  tearDown(() async {
    fixture.runtime.dispose();
    await fixture.database.close();
  });

  test(
    'disabled settings preserve model text without probing a runner',
    () async {
      final result = await fixture.call('one');
      expect(result, 'edit completed');
      expect(fixture.operations, isEmpty);
    },
  );

  test(
    'two sequential edits build fresh runners and both verify successfully',
    () async {
      await fixture.enable();
      final first = _verification(await fixture.call('one'));
      final second = _verification(await fixture.call('two'));
      expect(first['state'], 'pass');
      expect(second['state'], 'pass');
      expect(fixture.operations, [
        'capabilities',
        'start',
        'capabilities',
        'start',
      ]);
      expect(fixture.operationIds.toSet(), hasLength(2));
      expect(identical(fixture.runners[0], fixture.runners[1]), isFalse);
      expect(fixture.closedSessions, 2);
      expect(fixture.runtime.current('chat'), isNull);
    },
  );

  test(
    'failed feedback permits one authorized repair without replaying edits',
    () async {
      await fixture.enable();
      fixture.exitCode = 1;
      final first = _verification(await fixture.call('one'));
      expect(first['state'], 'fail');
      expect(first['output'], 'check failed');
      expect(first['repairAllowed'], isTrue);
      final repaired = _verification(await fixture.call('two'));
      expect(repaired['state'], 'fail');
      expect(repaired['repairAllowed'], isFalse);
      final exhausted = _verification(await fixture.call('three'));
      expect(exhausted['state'], 'incomplete');
      expect(exhausted['reason'], 'repair_limit_reached');
      expect(
        fixture.operations.where((operation) => operation == 'start'),
        hasLength(2),
      );
    },
  );

  test(
    'successful repair clears failure without restoring its spent token',
    () async {
      await fixture.enable();
      fixture.exitCode = 2;
      final _ = await fixture.call('one');
      fixture.exitCode = 0;
      final result = _verification(await fixture.call('two'));
      expect(result['state'], 'pass');
      expect(result['repairAttemptsRemaining'], 0);
    },
  );

  test(
    'unlisted tools, MCP errors, text and app data never select commands',
    () async {
      await fixture.enable();
      final _ = await fixture.call(
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
      final _ = await fixture.call(
        'two',
        result: McpToolCallerResult(
          modelText: 'error',
          appData: const {},
          structuredContent: _report(),
          isError: true,
        ),
      );
      final text = await fixture.call(
        'three',
        result: McpToolCallerResult(
          modelText: jsonEncode(_report()),
          appData: {'auravibesChangedPaths': _report()},
        ),
      );
      expect(_verification(text)['state'], 'skipped');
      expect(fixture.operations, isEmpty);
    },
  );

  test(
    'malformed paths reject the entire report before reserving a command',
    () async {
      await fixture.enable();
      final result = _verification(
        await fixture.call(
          'one',
          result: McpToolCallerResult(
            modelText: 'edit completed',
            appData: const {},
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
      expect(fixture.operations, isEmpty);
      expect(
        await fixture.database
            .select(fixture.database.workspaceVerificationRuns)
            .get(),
        isEmpty,
      );
    },
  );

  test(
    'runner permission denial preserves the edit and reports incomplete',
    () async {
      await fixture.enable();
      fixture.permitted = false;
      final result = _verification(await fixture.call('one'));
      expect(result['state'], 'incomplete');
      expect(fixture.operations, isEmpty);
    },
  );

  test('a missing compliant runner never claims a check ran', () async {
    await fixture.enable();
    fixture.compliant = false;
    final result = _verification(await fixture.call('one'));
    expect(result['state'], 'incomplete');
    expect(result['reason'], 'unsupported_runner');
    expect(fixture.operations, ['capabilities']);
  });

  test(
    'replayed tool call returns its recorded outcome with no second start',
    () async {
      await fixture.enable();
      final first = _verification(await fixture.call('one'));
      final replay = _verification(await fixture.call('one'));
      expect(replay['state'], first['state']);
      expect(fixture.operations, ['capabilities', 'start']);
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
      await fixture.enable();
      fixture.exitCode = 1;
      var edits = 0;
      final service = ResolvedToolService(
        agentCancellationRuntime: fixture.runtime,
        scopedVerification: fixture.usecase,
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
      );
      final executor = AgentToolBatchExecutor<ResolvedTool>(
        runResolvedTool:
            ({
              required conversationId,
              required toolCallId,
              required tool,
              required arguments,
            }) => service.call(
              conversationId: conversationId,
              toolCallId: toolCallId,
              tool: tool,
              arguments: arguments,
            ),
        isCancellationRequested: (_) => false,
        logToolExecutionError: (_) {},
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
        _verification(jsonDecode(result.responseRaw!) as Object)['state'],
        'fail',
      );
      expect(result.responseRaw, isNot(contains('app-only-marker')));
      expect(
        service.takeMcpAppResultData(conversationId: 'chat', toolCallId: 'one'),
        {'private': 'app-only-marker'},
      );
      expect(edits, 1);
      expect(fixture.operations, ['capabilities', 'start']);
    },
  );

  test(
    'cancellation while the runner factory is pending cannot launch late work',
    () async {
      await fixture.enable();
      final entered = Completer<void>();
      final pending = Completer<ScopedVerificationRunner?>();
      final usecase = VerifyReportedEditsUsecase(
        repository: fixture.repository,
        resolveIdentity: (_) async =>
            (workspaceId: 'workspace', turnId: 'turn'),
        cancellation: fixture.cancellation,
        createRunner: (_) {
          entered.complete();
          return pending.future;
        },
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
      final handle = fixture.runtime.toolCancellationHandle(
        conversationId: 'chat',
        toolCallId: 'one',
      );
      expect(await handle?.requestCancellation(), isTrue);
      expect(_verification(await output)['state'], 'cancelled');
      pending.complete();
      expect(fixture.operations, isEmpty);
    },
  );

  test(
    'a connection completed after cancellation is closed without dispatch',
    () async {
      await fixture.enable();
      final connection = Completer<ScopedVerificationOwnedCaller>();
      fixture.pendingConnection = connection.future;
      final output = fixture.call('one');
      await fixture.openingConnection.future;
      final handle = fixture.runtime.toolCancellationHandle(
        conversationId: 'chat',
        toolCallId: 'one',
      );
      expect(await handle?.requestCancellation(), isTrue);
      expect(_verification(await output)['state'], 'cancelled');
      connection.complete((
        call: fixture._caller,
        close: () {
          fixture.closedSessions++;
        },
      ));
      for (var index = 0; index < 10; index++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(fixture.closedSessions, 1);
      expect(fixture.operations, isEmpty);
    },
  );

  test(
    'connection cancellation exceptions preserve the cancelled result',
    () async {
      await fixture.enable();
      final usecase = VerifyReportedEditsUsecase(
        repository: fixture.repository,
        resolveIdentity: (_) async =>
            (workspaceId: 'workspace', turnId: 'turn'),
        cancellation: fixture.cancellation,
        createRunner: (input) async {
          input.cancellation.requestStop();
          throw StateError('Connection cancelled.');
        },
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
      expect(fixture.operations, isEmpty);
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
  _Fixture(this.database);
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

  late final repository = WorkspaceVerificationRepository(database);
  late final cancellation = ScopedVerificationCancellation(runtime);
  late final runnerFactory = CreateMcpScopedVerificationRunner(
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
  late final usecase = VerifyReportedEditsUsecase(
    repository: repository,
    resolveIdentity: (_) async => (workspaceId: 'workspace', turnId: 'turn'),
    cancellation: cancellation,
    createRunner: (input) async {
      final runner = await runnerFactory(input);
      if (runner != null) runners.add(runner);
      return runner;
    },
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
    ScopedVerificationSettings(
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

  Future<Object?> _caller({
    required String mcpServerId,
    required String toolIdentifier,
    required Map<String, dynamic> arguments,
    Object? onElicitation,
  }) async {
    final operation = arguments['operation'] as String;
    operations.add(operation);
    if (operation == 'capabilities')
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

  static Future<_Fixture> create() async {
    final database = AppDatabase(connection: NativeDatabase.memory());
    await database
        .into(database.workspaces)
        .insert(
          WorkspacesCompanion.insert(
            id: const Value('workspace'),
            name: 'Local',
            type: .local,
          ),
        );
    await database
        .into(database.conversations)
        .insert(
          ConversationsCompanion.insert(
            id: const Value('chat'),
            workspaceId: 'workspace',
            title: 'Work',
          ),
        );
    await database
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
    await database
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
    await database
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
      await database
          .into(database.tools)
          .insert(
            ToolsCompanion.insert(
              id: Value(entry.key),
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
}

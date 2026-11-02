import 'dart:async';

import 'package:auravibes_app/features/chats/agent_adapters/mcp_scoped_verification_runner.dart';
import 'package:auravibes_app/services/agent_harness/mcp_tool_caller.dart';
import 'package:auravibes_app/services/agent_harness/mcp_tool_caller_result.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only the bound server and configured argv/check paths reach MCP', () async {
    final fixture = _Fixture();
    final request = ScopedVerificationRequest(operationId: 'operation', workspaceRoot: 'root', deadline: DateTime.utc(2026, 11, 2, 0, 0, 30), selections: [ScopedVerificationSelection(check: ScopedVerificationCheck(id: 'dart', executable: 'dart', arguments: const ['analyze']), paths: const [r'lib/$(touch marker).dart'])]);
    await fixture.runner.start(request);
    expect(fixture.calls, [
      {
        'mcpServerId': 'server', 'toolIdentifier': 'verify',
        'arguments': {
          'operation': 'start', 'protocol': 'auravibes.scoped-verification/1',
          'operationId': 'operation', 'workspaceRoot': 'root',
          'deadlineMs': DateTime.utc(2026, 11, 2, 0, 0, 30).millisecondsSinceEpoch,
          'maxOutputBytes': 16384,
          'checks': [{'id': 'dart', 'executable': 'dart', 'arguments': ['analyze'], 'paths': [r'lib/$(touch marker).dart']}],
        },
      },
    ]);
  });

  test('another editing server cannot authorize a runner dispatch', () async {
    final fixture = _Fixture();
    final runner = McpScopedVerificationRunner(mcpServerId: 'server', editMcpServerId: 'other', runnerToolIdentifier: 'verify', caller: fixture.caller, isAllowed: () async => true);
    await expectLater(runner.capabilities(), throwsFormatException);
    expect(fixture.calls, isEmpty);
  });

  test('denied execution and unbound cancellation create no dispatch', () async {
    final fixture = _Fixture();
    fixture.allowed = false;
    await expectLater(fixture.runner.capabilities(), throwsStateError);
    await expectLater(fixture.runner.poll('operation'), throwsStateError);
    await expectLater(fixture.runner.cancel('operation'), throwsStateError);
    expect(fixture.calls, isEmpty);
  });

  test('revocation during a bound run permits only that operation cleanup', () async {
    final fixture = _Fixture()..structured = {..._job(), 'state': 'running', 'checks': <Object?>[]};
    final runner = fixture.runner;
    await runner.start(_request());
    fixture.allowed = false;
    await expectLater(runner.poll('operation'), throwsStateError);
    fixture.structured = {..._job(), 'state': 'cancelled', 'checks': <Object?>[], 'cancellationRecorded': true};
    final cancelled = await runner.cancel('operation');
    expect(cancelled.state, ScopedVerificationJobState.cancelled);
    expect(cancelled.cancellationRecorded, isTrue);
    expect(fixture.calls.map((call) => (call['arguments']! as Map)['operation']), ['start', 'cancel']);
    expect(fixture.calls.last['arguments'], {
      'operation': 'cancel', 'protocol': 'auravibes.scoped-verification/1',
      'operationId': 'operation', 'workspaceRoot': 'root',
      'deadlineMs': DateTime.utc(2026, 11, 2, 0, 0, 30).millisecondsSinceEpoch,
    });
    await expectLater(runner.cancel('somebody-elses-operation'), throwsStateError);
    expect(fixture.calls, hasLength(2));
    await expectLater(runner.start(_request(operationId: 'another')), throwsStateError);
    expect(fixture.calls, hasLength(2));
  });

  test('cancel binds an admitted start even before its remote registration', () async {
    final fixture = _Fixture();
    final delayed = Completer<Object?>();
    final calls = <String>[];
    final runner = McpScopedVerificationRunner(
      mcpServerId: 'server', editMcpServerId: 'server', runnerToolIdentifier: 'verify',
      isAllowed: () async => fixture.allowed,
      caller: ({required mcpServerId, required toolIdentifier, required arguments, onElicitation}) async {
        calls.add(arguments['operation'] as String);
        if (arguments['operation'] == 'start') return await delayed.future;
        expect(arguments['operationId'], 'operation');
        expect(arguments['workspaceRoot'], 'root');
        expect(arguments['deadlineMs'], DateTime.utc(2026, 11, 2, 0, 0, 30).millisecondsSinceEpoch);
        return McpToolCallerResult(modelText: '', appData: const {}, structuredContent: {..._job(), 'state': 'cancelled', 'checks': <Object?>[], 'cancellationRecorded': true});
      },
    );
    final start = runner.start(_request());
    for (var index = 0; index < 5; index++) { await Future<void>.value(); }
    fixture.allowed = false;
    expect((await runner.cancel('operation')).cancellationRecorded, isTrue);
    delayed.complete(McpToolCallerResult(modelText: '', appData: const {}, structuredContent: {..._job(), 'state': 'cancelled', 'checks': <Object?>[], 'cancellationRecorded': true}));
    expect((await start).state, ScopedVerificationJobState.cancelled);
    expect(calls, ['start', 'cancel']);
  });

  test('cancelled receipts without tombstone confirmation remain unknown', () async {
    final fixture = _Fixture();
    final runner = fixture.runner;
    await runner.start(_request());
    fixture.structured = {..._job(), 'state': 'cancelled', 'checks': <Object?>[]};
    await expectLater(runner.cancel('operation'), throwsFormatException);
  });

  test('cancel during pending admission prevents late permission from starting', () async {
    final permission = Completer<bool>();
    final calls = <Map<String, dynamic>>[];
    final runner = McpScopedVerificationRunner(
      mcpServerId: 'server', editMcpServerId: 'server', runnerToolIdentifier: 'verify',
      isAllowed: () => permission.future,
      caller: ({required mcpServerId, required toolIdentifier, required arguments, onElicitation}) async {
        calls.add(arguments);
        return McpToolCallerResult(modelText: '', appData: const {}, structuredContent: {..._job(), 'state': 'cancelled', 'checks': <Object?>[], 'cancellationRecorded': true});
      },
    );
    final start = runner.start(_request());
    final failsAfterCancellation = expectLater(start, throwsStateError);
    expect((await runner.cancel('operation')).cancellationRecorded, isTrue);
    permission.complete(true);
    await failsAfterCancellation;
    expect(calls.map((arguments) => arguments['operation']), ['cancel']);
    expect(calls.single['operationId'], 'operation');
    expect(calls.single['workspaceRoot'], 'root');
    expect(calls.single['deadlineMs'], DateTime.utc(2026, 11, 2, 0, 0, 30).millisecondsSinceEpoch);
    await expectLater(runner.start(_request()), throwsStateError);
    expect(calls, hasLength(1));
  });

  test('an admitted runner cannot replace its operation when still permitted', () async {
    final fixture = _Fixture();
    final runner = fixture.runner;
    await runner.start(_request());
    await expectLater(runner.start(_request(operationId: 'other')), throwsStateError);
    expect(fixture.calls, hasLength(1));
  });

  test('capabilities need the explicit versioned integration contract', () async {
    final fixture = _Fixture();
    fixture.structured = {
      'protocol': 'auravibes.scoped-verification/1',
      'capabilities': {for (final feature in ScopedVerificationCapabilities.requiredFeatures) feature: true},
    };
    expect((await fixture.runner.capabilities()).supported, isTrue);
    fixture.structured = {'protocol': 'shell', 'command': 'run tests'};
    await expectLater(fixture.runner.capabilities(), throwsFormatException);
  });

  test('JSON model text and app data cannot manufacture a runner receipt', () async {
    final fixture = _Fixture();
    fixture.rawResult = const McpToolCallerResult(modelText: '{"state":"completed","exitCode":0}', appData: {'command': 'touch marker'});
    await expectLater(fixture.runner.poll('operation'), throwsFormatException);
    expect(fixture.calls, hasLength(1));
  });

  test('failed MCP calls and extra authority fields are not completion', () async {
    final fixture = _Fixture();
    fixture.rawResult = McpToolCallerResult(modelText: 'error', appData: const {}, structuredContent: _job(), isError: true);
    await expectLater(fixture.runner.poll('operation'), throwsFormatException);
    fixture.rawResult = null;
    fixture.structured = {..._job(), 'command': 'injected'};
    await expectLater(fixture.runner.poll('operation'), throwsFormatException);
  });

  test('missing exits, malformed types, and unknown states fail closed', () async {
    for (final entry in <String, Object?>{
      'checks': [{'id': 'dart'}], 'scopeValidated': 'true',
      'originalOutputBytes': -1, 'state': 'success',
      'outputTruncated': true,
    }.entries) {
      final fixture = _Fixture()..structured = {..._job(), entry.key: entry.value};
      await expectLater(fixture.runner.poll('operation'), throwsFormatException);
    }
  });
}

ScopedVerificationRequest _request({String operationId = 'operation'}) => ScopedVerificationRequest(operationId: operationId, workspaceRoot: 'root', deadline: DateTime.utc(2026, 11, 2, 0, 0, 30), selections: [ScopedVerificationSelection(check: ScopedVerificationCheck(id: 'dart', executable: 'dart'), paths: const ['lib/main.dart'])]);

final class _Fixture {
  bool allowed = true;
  Object? structured = _job();
  Object? rawResult;
  final calls = <Map<String, Object?>>[];
  McpToolCaller get caller => ({required mcpServerId, required toolIdentifier, required arguments, onElicitation}) async {
    calls.add({'mcpServerId': mcpServerId, 'toolIdentifier': toolIdentifier, 'arguments': arguments});
    return rawResult ?? McpToolCallerResult(modelText: 'command suggestion: run something else', appData: const {}, structuredContent: structured);
  };
  McpScopedVerificationRunner get runner => McpScopedVerificationRunner(mcpServerId: 'server', editMcpServerId: 'server', runnerToolIdentifier: 'verify', caller: caller, isAllowed: () async => allowed);
}

Map<String, Object?> _job() => {
  'protocol': 'auravibes.scoped-verification/1', 'operationId': 'operation',
  'workspaceRoot': 'root', 'state': 'completed', 'scopeValidated': true,
  'checks': [{'id': 'dart', 'exitCode': 0}], 'output': '',
  'outputTruncated': false, 'originalOutputBytes': 0,
};

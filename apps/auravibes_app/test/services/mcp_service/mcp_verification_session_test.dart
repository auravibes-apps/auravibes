import 'dart:async';

import 'package:auravibes_app/services/mcp_service/mcp_verification_session.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_client/mcp_client.dart' as mcp;

void main() {
  test(
    'same verification client dispatches cancel while start is still pending',
    () async {
      final sdk = _Client();
      final session = McpVerificationSession(
        client: sdk,
        serverId: 'server',
        toolIdentifier: 'verify',
      );
      addTearDown(session.close);
      final start = session.call(
        mcpServerId: 'server',
        toolIdentifier: 'verify',
        arguments: _arguments('start'),
      );
      final cancel = await session
          .call(
            mcpServerId: 'server',
            toolIdentifier: 'verify',
            arguments: _arguments('cancel'),
          )
          .timeout(const Duration(seconds: 1));
      expect(sdk.operations, ['start', 'cancel']);
      expect(sdk.started.isCompleted, isFalse);
      expect(cancel, isNotNull);
      sdk.started.complete(_response());
      final _ = await start;
    },
  );

  test(
    'elicitation is cancelled immediately and fails the pending check',
    () async {
      final sdk = _Client();
      final session = McpVerificationSession(
        client: sdk,
        serverId: 'server',
        toolIdentifier: 'verify',
      );
      addTearDown(session.close);
      final start = session.call(
        mcpServerId: 'server',
        toolIdentifier: 'verify',
        arguments: _arguments('start'),
      );
      final failure = expectLater(start, throwsFormatException);
      final handler =
          sdk.handler ?? (throw StateError('Missing elicitation handler.'));
      final reply = await handler(
        mcp.ElicitRequestFormParams(
          message: 'Prompt',
          requestedSchema: const {
            'type': 'object',
            'properties': <String, Object?>{},
          },
        ),
      );
      expect(reply.action, mcp.ElicitResultAction.cancel);
      await failure;
      expect(sdk.started.isCompleted, isFalse);
      final _ = await session.call(
        mcpServerId: 'server',
        toolIdentifier: 'verify',
        arguments: _arguments('cancel'),
      );
      sdk.started.complete(_response());
    },
  );

  test(
    'transport guard detects an undeclared elicitation '
    'without another UI handler',
    () async {
      final sdk = _Client();
      final ordinary = _Client();
      var ordinaryPrompts = 0;
      ordinary.onElicitationRequestTyped((_) async {
        ordinaryPrompts++;

        return mcp.ElicitResult(action: mcp.ElicitResultAction.decline);
      });
      final original = ordinary.handler;
      final ordinaryCall = ordinary.callTool('ordinary', _arguments('start'));
      final session = McpVerificationSession(
        client: sdk,
        serverId: 'server',
        toolIdentifier: 'verify',
      );
      final transport = _Transport();
      final guarded = session.guardTransport(transport);
      final received = <Object?>[];
      final subscription = guarded.onMessage.listen(received.add);
      addTearDown(() async {
        session.close();
        await subscription.cancel();
        transport.close();
      });
      final start = session.call(
        mcpServerId: 'server',
        toolIdentifier: 'verify',
        arguments: _arguments('start'),
      );
      final failure = expectLater(start, throwsFormatException);
      transport.messages.add({
        'jsonrpc': '2.0',
        'id': 123,
        'method': 'elicitation/create',
        'params': {'message': 'Unexpected'},
      });
      await failure;
      expect(received, hasLength(1));
      expect(ordinary.handler, same(original));
      expect(ordinaryPrompts, 0);
      expect(ordinary.operations, ['start']);
      expect(ordinary.started.isCompleted, isFalse);
      sdk.started.complete(_response());
      ordinary.started.complete(_response());
      final _ = await ordinaryCall;
    },
  );

  test('repeated close disconnects the owned client exactly once', () {
    final sdk = _Client();
    final _ = McpVerificationSession(
      client: sdk,
      serverId: 'server',
      toolIdentifier: 'verify',
    )
      ..close()
      ..close();
    expect(sdk.disconnects, 1);
  });
}

Map<String, dynamic> _arguments(String operation) => {
  'protocol': ScopedVerificationLimits.protocol,
  'operation': operation,
  'operationId': 'operation',
};
mcp.CallToolResult _response() => mcp.CallToolResult(
  content: const [],
  structuredContent: const {'receipt': 'fixture'},
);

final class _Client extends Fake implements mcp.Client {
  int disconnects = 0;
  final operations = <String>[];
  final started = Completer<mcp.CallToolResult>();
  Future<mcp.ElicitResult> Function(mcp.ElicitRequestParams)? handler;
  @override
  void onElicitationRequestTyped(
    Future<mcp.ElicitResult> Function(mcp.ElicitRequestParams) handler,
  ) {
    this.handler = handler;
  }

  @override
  Future<mcp.CallToolResult> callTool(
    String name,
    Map<String, dynamic> arguments, {
    Map<String, dynamic>? meta,
    mcp.RequestOptions? options,
  }) async {
    final operation = arguments['operation'] as String;
    operations.add(operation);

    return operation == 'start' ? await started.future : _response();
  }

  @override
  void disconnect() {
    disconnects++;
  }
}

final class _Transport implements mcp.ClientTransport {
  final messages = StreamController<Object?>.broadcast(sync: true);
  final sent = <Object?>[];
  final _closed = Completer<void>();
  @override
  Stream<Object?> get onMessage => messages.stream;
  @override
  Future<void> get onClose => _closed.future;
  @override
  void send(Object? message) => sent.add(message);
  @override
  void close() {
    if (!_closed.isCompleted) {
      _closed.complete();
      final _ = messages.close();
    }
  }
}

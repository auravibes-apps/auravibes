import 'dart:convert';

import 'package:auravibes_app/services/mcp_service/mcp_app_message_bridge.dart';
import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'initializes before sending the original tool input and result',
    () async {
      final bridge = McpAppMessageBridge(
        initialArguments: const {'city': 'Bogota'},
        initialResult: const {
          'content': [
            {'type': 'text', 'text': 'Sunny'},
          ],
          'structuredContent': {'temperature': 22},
        },
        callTool: (_, _) async => const {},
      );

      final initialize = await bridge.handleMessage(
        jsonEncode({'jsonrpc': '2.0', 'id': 1, 'method': 'ui/initialize'}),
      );
      expect(initialize.single['id'], 1);
      expect(
        (initialize.single['result']! as Map)['protocolVersion'],
        '2026-01-26',
      );

      final initialized = await bridge.handleMessage(
        jsonEncode({
          'jsonrpc': '2.0',
          'method': 'ui/notifications/initialized',
        }),
      );
      expect(initialized.map((message) => message['method']), [
        'ui/notifications/tool-input',
        'ui/notifications/tool-result',
      ]);
      final firstInitialized = initialized.firstOrNull;
      if (firstInitialized == null) fail('Expected initial tool messages.');
      final params = firstInitialized['params'];
      if (params is! Map<String, Object?>) {
        fail('Expected initial tool parameters.');
      }
      expect(params['arguments'], {'city': 'Bogota'});
      expect(
        await bridge.handleMessage(
          jsonEncode({
            'jsonrpc': '2.0',
            'method': 'ui/notifications/initialized',
          }),
        ),
        isEmpty,
      );

      bridge.reset();
      final _ = await bridge.handleMessage(
        jsonEncode({'jsonrpc': '2.0', 'id': 2, 'method': 'ui/initialize'}),
      );
      final retryInitialized = await bridge.handleMessage(
        jsonEncode({
          'jsonrpc': '2.0',
          'method': 'ui/notifications/initialized',
        }),
      );
      expect(retryInitialized.map((message) => message['method']), [
        'ui/notifications/tool-input',
        'ui/notifications/tool-result',
      ]);
    },
  );

  test(
    'mediates app tool calls and returns server results by request id',
    () async {
      final calls = <({String name, Map<String, dynamic> arguments})>[];
      final bridge = McpAppMessageBridge(
        initialArguments: const {},
        initialResult: const {'content': []},
        callTool: (name, arguments) async {
          calls.add((name: name, arguments: arguments));

          return const {'content': []};
        },
      );
      expect(
        await bridge.handleMessage(
          jsonEncode({'jsonrpc': '2.0', 'id': 1, 'method': 'ui/initialize'}),
        ),
        hasLength(1),
      );
      expect(
        await bridge.handleMessage(
          jsonEncode({
            'jsonrpc': '2.0',
            'method': 'ui/notifications/initialized',
          }),
        ),
        hasLength(2),
      );

      final response = await bridge.handleMessage(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': 2,
          'method': 'tools/call',
          'params': {
            'name': 'refresh',
            'arguments': {'limit': 4},
          },
        }),
      );

      expect(calls.single.name, 'refresh');
      expect(calls.single.arguments, {'limit': 4});
      expect(response.single['id'], 2);
      expect(response.single['result'], {'content': <Object?>[]});
    },
  );

  test('waits for app resource teardown response', () async {
    final bridge = McpAppMessageBridge(
      initialArguments: const {},
      initialResult: const {'content': []},
      callTool: (_, _) async => const {},
    );
    expect(
      await bridge.handleMessage(
        jsonEncode({'jsonrpc': '2.0', 'id': 1, 'method': 'ui/initialize'}),
      ),
      hasLength(1),
    );
    expect(
      await bridge.handleMessage(
        jsonEncode({
          'jsonrpc': '2.0',
          'method': 'ui/notifications/initialized',
        }),
      ),
      hasLength(2),
    );

    final teardown = bridge.beginResourceTeardown();
    if (teardown == null) fail('Expected initialized view teardown.');
    expect(teardown.message['method'], 'ui/resource-teardown');
    final response = bridge.handleMessage(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': teardown.message['id'],
        'result': <String, Object?>{},
      }),
    );
    expect(await response, isEmpty);
    await teardown.response;
  });

  test('clears a teardown request after its response times out', () async {
    final bridge = McpAppMessageBridge(
      initialArguments: const {},
      initialResult: const {'content': []},
      callTool: (_, _) async => const {},
    );
    expect(
      await bridge.handleMessage(
        jsonEncode({'jsonrpc': '2.0', 'id': 1, 'method': 'ui/initialize'}),
      ),
      hasLength(1),
    );
    expect(
      await bridge.handleMessage(
        jsonEncode({
          'jsonrpc': '2.0',
          'method': 'ui/notifications/initialized',
        }),
      ),
      hasLength(2),
    );

    final first = bridge.beginResourceTeardown();
    if (first == null) fail('Expected initialized view teardown.');
    await first.response;
    expect(
      await bridge.handleMessage(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': first.message['id'],
          'result': <String, Object?>{},
        }),
      ),
      isEmpty,
    );

    final next = bridge.beginResourceTeardown();
    if (next == null) fail('Expected a new teardown request.');
    expect(next.message['id'], isNot(first.message['id']));
    expect(
      await bridge.handleMessage(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': next.message['id'],
          'result': <String, Object?>{},
        }),
      ),
      isEmpty,
    );
    await next.response;
  });

  test(
    'rejects tool calls before initialization and malformed arguments',
    () async {
      final bridge = McpAppMessageBridge(
        initialArguments: const {},
        initialResult: const {'content': []},
        callTool: (_, _) async => const {},
      );

      final beforeInitialization = await bridge.handleMessage(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': 3,
          'method': 'tools/call',
          'params': {'name': 'refresh'},
        }),
      );
      expect((beforeInitialization.single['error']! as Map)['code'], -32002);

      expect(
        await bridge.handleMessage(
          jsonEncode({'jsonrpc': '2.0', 'id': 1, 'method': 'ui/initialize'}),
        ),
        hasLength(1),
      );
      expect(
        await bridge.handleMessage(
          jsonEncode({
            'jsonrpc': '2.0',
            'method': 'ui/notifications/initialized',
          }),
        ),
        hasLength(2),
      );
      final malformed = await bridge.handleMessage(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': 4,
          'method': 'tools/call',
          'params': {'name': 'refresh', 'arguments': <Object?>[]},
        }),
      );
      expect((malformed.single['error']! as Map)['code'], -32602);
    },
  );

  test('rejects oversized app messages before decoding them', () async {
    final bridge = McpAppMessageBridge(
      initialArguments: const {},
      initialResult: const {'content': []},
      callTool: (_, _) async => const {},
    );
    final response = await bridge.handleMessage(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': 5,
        'method': 'ping',
        'params': {'value': ''.padRight(1 << 20, 'a')},
      }),
    );

    expect(response.single['id'], isNull);
    expect((response.single['error']! as Map)['code'], -32600);
  });
}

import 'dart:convert';

import 'package:auravibes_app/services/mcp_service/mcp_app_message_bridge.dart';
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
      expect((initialized.first['params']! as Map)['arguments'], {
        'city': 'Bogota',
      });
      expect(
        await bridge.handleMessage(
          jsonEncode({
            'jsonrpc': '2.0',
            'method': 'ui/notifications/initialized',
          }),
        ),
        isEmpty,
      );
    },
  );

  test(
    'mediates app tool calls and returns server results by request id',
    () async {
      final calls = <(String, Map<String, dynamic>)>[];
      final bridge = McpAppMessageBridge(
        initialArguments: const {},
        initialResult: const {'content': []},
        callTool: (name, arguments) async {
          calls.add((name, arguments));

          return const {'content': []};
        },
      );
      await bridge.handleMessage(
        jsonEncode({'jsonrpc': '2.0', 'id': 1, 'method': 'ui/initialize'}),
      );
      await bridge.handleMessage(
        jsonEncode({
          'jsonrpc': '2.0',
          'method': 'ui/notifications/initialized',
        }),
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

      expect(calls.single.$1, 'refresh');
      expect(calls.single.$2, {'limit': 4});
      expect(response.single['id'], 2);
      expect(response.single['result'], {'content': []});
    },
  );

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

      await bridge.handleMessage(
        jsonEncode({'jsonrpc': '2.0', 'id': 1, 'method': 'ui/initialize'}),
      );
      await bridge.handleMessage(
        jsonEncode({
          'jsonrpc': '2.0',
          'method': 'ui/notifications/initialized',
        }),
      );
      final malformed = await bridge.handleMessage(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': 4,
          'method': 'tools/call',
          'params': {'name': 'refresh', 'arguments': []},
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

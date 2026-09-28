import 'dart:io';

import 'package:auravibes_server/src/features/mcp_servers/mcp_server_probe.dart';
import 'package:test/test.dart';

void main() {
  test('rejects unsupported transport before connecting', () async {
    final probe = McpServerProbe(
      lookup: (_) async => [InternetAddress('8.8.8.8')],
    );

    await expectLater(
      probe(
        uri: Uri.parse('https://example.com/mcp'),
        transport: 'stdio',
        useHttp2: false,
      ),
      throwsFormatException,
    );
  });

  test('does not treat SSE as streamable HTTP', () async {
    final probe = McpServerProbe(
      lookup: (_) async => [InternetAddress('8.8.8.8')],
    );

    await expectLater(
      probe(
        uri: Uri.parse('https://example.com/sse'),
        transport: 'sse',
        useHttp2: false,
      ),
      throwsFormatException,
    );
  });

  test('rejects a DNS answer containing any private address', () async {
    final probe = McpServerProbe(
      lookup: (_) async => [
        InternetAddress('8.8.8.8'),
        InternetAddress('127.0.0.1'),
      ],
    );

    await expectLater(
      probe(
        uri: Uri.parse('https://example.com/mcp'),
        transport: 'streamableHttp',
        useHttp2: false,
      ),
      throwsFormatException,
    );
  });

  test(
    'cloud discovery collects ordered pages and keeps schema JSON',
    () async {
      final cursors = <String?>[];
      final tools = await collectCloudMcpTools((cursor) async {
        cursors.add(cursor);
        return switch (cursor) {
          null => {
            'tools': [
              {
                'name': 'first',
                'inputSchema': {'type': 'object'},
                'outputSchema': {'type': 'object'},
              },
            ],
            'nextCursor': 'opaque',
          },
          _ => {
            'tools': [
              {'name': 'last'},
            ],
          },
        };
      });

      expect(cursors, [null, 'opaque']);
      expect(tools.map((tool) => tool.name), ['first', 'last']);
      expect(tools.first.inputSchemaJson, '{"type":"object"}');
      expect(tools.first.outputSchemaJson, '{"type":"object"}');
      expect(tools.last.inputSchemaJson, '{}');
      expect(tools.last.outputSchemaJson, isNull);
    },
  );

  test('cloud discovery rejects a later-page invalid catalog', () async {
    await expectLater(
      collectCloudMcpTools(
        (cursor) async => cursor == null
            ? {
                'tools': [
                  {'name': 'first'},
                ],
                'nextCursor': 'second',
              }
            : {
                'tools': [
                  {
                    'name': 'invalid',
                    'inputSchema': <Object?, Object?>{1: 'x'},
                  },
                ],
              },
      ),
      throwsFormatException,
    );
  });
}

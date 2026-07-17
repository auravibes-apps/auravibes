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
}

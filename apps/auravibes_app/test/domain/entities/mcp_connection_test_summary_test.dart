import 'dart:convert';

import 'package:auravibes_app/domain/entities/mcp_connection_test_summary.dart';
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('McpConnectionTestSummary', () {
    test('round trips only normalized diagnostic fields', () {
      final summary = McpConnectionTestSummary(
        status: 'success',
        testedAt: .utc(2026, 9, 29),
        transport: const McpTransportTypeStreamableHttp(useHttp2: true),
        toolCount: 3,
        durationMilliseconds: 42,
      );

      final json = jsonDecode(summary.toJson()) as Map<String, dynamic>;
      expect(json.keys.toSet(), {
        'status',
        'testedAt',
        'transport',
        'toolCount',
        'durationMilliseconds',
      });

      final restored = McpConnectionTestSummary.fromJson(summary.toJson());
      expect(restored?.status, 'success');
      expect(restored?.testedAt, summary.testedAt);
      expect(
        restored?.transport,
        isA<McpTransportTypeStreamableHttp>().having(
          (transport) => transport.useHttp2,
          'useHttp2',
          isTrue,
        ),
      );
      expect(restored?.toolCount, 3);
      expect(restored?.durationMilliseconds, 42);
    });

    test('rejects malformed or unsafe summary values', () {
      expect(McpConnectionTestSummary.fromJson('{'), isNull);
      expect(
        McpConnectionTestSummary.fromJson(
          jsonEncode({
            'status': 'unrecognized',
            'testedAt': '2026-09-29T00:00:00Z',
            'transport': const McpTransportTypeSSE().toJson(),
            'toolCount': 1,
            'durationMilliseconds': 20,
          }),
        ),
        isNull,
      );
      expect(
        McpConnectionTestSummary.fromJson(
          jsonEncode({
            'status': 'unknown',
            'testedAt': '2026-09-29T00:00:00Z',
            'transport': const McpTransportTypeSSE().toJson(),
            'toolCount': -1,
            'durationMilliseconds': 20,
          }),
        ),
        isNull,
      );
    });
  });
}

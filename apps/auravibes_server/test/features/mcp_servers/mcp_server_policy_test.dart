import 'dart:io';

import 'package:auravibes_server/src/features/mcp_servers/mcp_server_policy.dart';
import 'package:test/test.dart';

void main() {
  test('rejects unsafe targets and bounds schemas', () {
    expect(
      () => McpServerPolicy.validateUri('http://example.com/mcp'),
      throwsFormatException,
    );
    expect(
      () => McpServerPolicy.validateAddresses([
        InternetAddress('127.0.0.1'),
      ]),
      throwsFormatException,
    );
    expect(
      McpServerPolicy.boundedSchema({
        'type': 'object',
        'properties': <String, Object?>{},
      }),
      '{"type":"object","properties":{}}',
    );
    Object? deep = 'value';
    for (var index = 0; index < 18; index++) {
      deep = [deep];
    }
    expect(() => McpServerPolicy.boundedSchema(deep), throwsFormatException);
  });
}

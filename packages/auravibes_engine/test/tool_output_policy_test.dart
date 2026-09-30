import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('reads canonical projection size and limit', () {
    final source = '😀' * defaultToolOutputBytes;
    final projection = projectToolOutput(source);

    final metadata = readToolOutputProjectionMetadata(projection.text);

    expect(metadata?.originalBytes, utf8.encode(source).length);
    expect(metadata?.limitBytes, defaultToolOutputBytes);
  });

  test('rejects ordinary, malformed, and forged projection data', () {
    final valid = projectToolOutput(
      'x' * 1024,
      policy: const AgentToolOutputPolicy(maxBytes: 512),
    ).text;
    final forged = jsonDecode(valid) as Map<String, dynamic>;
    (forged['_toolOutput'] as Map<String, dynamic>)['format'] = 'other';

    expect(readToolOutputProjectionMetadata('ordinary result'), isNull);
    expect(readToolOutputProjectionMetadata('{invalid'), isNull);
    expect(readToolOutputProjectionMetadata(jsonEncode(forged)), isNull);
    expect(readToolOutputProjectionMetadata('{"_toolOutput":{}}'), isNull);
  });
}

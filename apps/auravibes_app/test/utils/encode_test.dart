import 'package:auravibes_app/utils/encode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('safeJsonEncode', () {
    test('returns null for null input', () {
      expect(JsonCodec.encode(null), isNull);
    });

    test('encodes a string', () {
      expect(JsonCodec.encode('hello'), '"hello"');
    });

    test('encodes a map', () {
      final result = JsonCodec.encode({'key': 'value'});
      expect(result, '{"key":"value"}');
    });

    test('encodes a list', () {
      final result = JsonCodec.encode([1, 2, 3]);
      expect(result, '[1,2,3]');
    });

    test('encodes an int', () {
      expect(JsonCodec.encode(42), '42');
    });

    test('encodes a bool', () {
      expect(JsonCodec.encode(true), 'true');
    });
  });

  group('safeJsonDecode', () {
    test('decodes a valid JSON string', () {
      final result = JsonCodec.decode('{"key":"value"}');
      expect(result, {'key': 'value'});
    });

    test('returns null for invalid JSON', () {
      expect(JsonCodec.decode('not json'), isNull);
    });

    test('decodes nested JSON object', () {
      final result = JsonCodec.decode('{"a":{"b":1}}');
      expect(result, {
        'a': {'b': 1},
      });
    });
  });
}

// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
import 'package:auravibes_app/utils/encode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('safeJsonEncode', () {
    test('returns null for null input', () {
      expect(safeJsonEncode(null), isNull);
    });

    test('encodes a string', () {
      expect(safeJsonEncode('hello'), '"hello"');
    });

    test('encodes a map', () {
      final result = safeJsonEncode({'key': 'value'});
      expect(result, '{"key":"value"}');
    });

    test('encodes a list', () {
      final result = safeJsonEncode([1, 2, 3]);
      expect(result, '[1,2,3]');
    });

    test('encodes an int', () {
      expect(safeJsonEncode(42), '42');
    });

    test('encodes a bool', () {
      expect(safeJsonEncode(true), 'true');
    });
  });

  group('safeJsonDecode', () {
    test('decodes a valid JSON string', () {
      final result = safeJsonDecode('{"key":"value"}');
      expect(result, {'key': 'value'});
    });

    test('returns null for invalid JSON', () {
      expect(safeJsonDecode('not json'), isNull);
    });

    test('decodes nested JSON object', () {
      final result = safeJsonDecode('{"a":{"b":1}}');
      expect(result, {
        'a': {'b': 1},
      });
    });
  });
}

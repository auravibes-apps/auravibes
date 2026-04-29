import 'package:auravibes_app/utils/try_decode_tool_metadata.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tryDecodeToolMetadata', () {
    test('returns null for null input', () {
      expect(tryDecodeToolMetadata(null), isNull);
    });

    test('decodes a JSON string map with multiple keys', () {
      final result = tryDecodeToolMetadata('{"key": "value", "num": 42}');
      expect(result, '{\n  "key": "value",\n  "num": 42\n}');
    });

    test('decodes a JSON string list', () {
      final result = tryDecodeToolMetadata('[1, 2, 3]');
      expect(result, '[\n  1,\n  2,\n  3\n]');
    });

    test('unwraps single-key maps recursively to leaf value', () {
      final result = tryDecodeToolMetadata('{"wrapper": {"inner": "value"}}');
      expect(result, 'value');
    });

    test('unwraps deeply nested single-key maps', () {
      final result = tryDecodeToolMetadata(
        '{"a": {"b": {"c": {"d": "final"}}}}',
      );
      expect(result, 'final');
    });

    test('handles plain string (not JSON)', () {
      final result = tryDecodeToolMetadata('just a string');
      expect(result, 'just a string');
    });

    test('handles input Map (unwraps single-key)', () {
      final result = tryDecodeToolMetadata({'key': 'value'});
      expect(result, 'value');
    });

    test('handles input Map with multiple keys', () {
      final result = tryDecodeToolMetadata({'a': 1, 'b': 2});
      expect(result, '{\n  "a": 1,\n  "b": 2\n}');
    });

    test('handles non-JSON-string input (List)', () {
      final result = tryDecodeToolMetadata([1, 2, 3]);
      expect(result, '[\n  1,\n  2,\n  3\n]');
    });

    test('handles non-JSON-string input (int)', () {
      final result = tryDecodeToolMetadata(42);
      expect(result, '42');
    });

    test('handles non-JSON-string input (bool)', () {
      final result = tryDecodeToolMetadata(true);
      expect(result, 'true');
    });

    test('returns null for null decoded value', () {
      final result = tryDecodeToolMetadata('null');
      expect(result, isNull);
    });

    test('handles empty object JSON', () {
      final result = tryDecodeToolMetadata('{}');
      expect(result, '{}');
    });
  });
}

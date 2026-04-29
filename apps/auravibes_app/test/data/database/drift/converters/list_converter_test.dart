import 'package:auravibes_app/data/database/drift/converters/list_converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('stringListConverter', () {
    test('toSql returns JSON string', () {
      final result = stringListConverter.toSql(['a', 'b', 'c']);
      expect(result, '["a","b","c"]');
    });

    test('toSql returns JSON for empty list', () {
      final result = stringListConverter.toSql(<String>[]);
      expect(result, '[]');
    });

    test('fromSql parses JSON string to list', () {
      final result = stringListConverter.fromSql('["a","b","c"]');
      expect(result, ['a', 'b', 'c']);
      expect(result, isA<List<String>>());
    });

    test('fromSql returns empty list for null', () {
      final result = stringListConverter.fromSql('null');
      expect(result, <String>[]);
    });
  });
}

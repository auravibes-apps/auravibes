import 'package:auravibes_app/data/database/drift/converters/list_converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('stringListConverter', () {
    test('toSql serializes populated and empty lists', () {
      expect(stringListConverter.toSql(['a', 'b', 'c']), '["a","b","c"]');
      expect(stringListConverter.toSql(<String>[]), '[]');
    });

    test('fromSql deserializes JSON and treats JSON null as empty', () {
      final result = stringListConverter.fromSql('["a","b","c"]');

      expect(result, ['a', 'b', 'c']);
      expect(result, isA<List<String>>());
      expect(stringListConverter.fromSql('null'), <String>[]);
    });

    test('fromJson deserializes lists and treats null as empty', () {
      expect(stringListConverter.fromJson(['a', 'b']), ['a', 'b']);
      expect(stringListConverter.fromJson(null), <String>[]);
    });

    test('toJson returns values that round-trip through fromJson', () {
      const original = ['x', 'y', 'z'];
      final json = stringListConverter.toJson(original);

      expect(json, original);
      expect(stringListConverter.fromJson(json), original);
    });
  });
}

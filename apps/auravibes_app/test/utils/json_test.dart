// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.
import 'package:auravibes_app/utils/map_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NoKeyMapException', () {
    test('toString includes the key name', () {
      final ex = NoKeyMapException('myKey');
      expect(ex.toString(), 'MapNoEntry: map has no key myKey');
      expect(ex.key, 'myKey');
    });
  });

  group('NoTypeMapException', () {
    test('toString includes key and type', () {
      final ex = NoTypeMapException('myKey', String);
      expect(
        ex.toString(),
        'MapNoEntry: map has no key myKey with type String',
      );
      expect(ex.key, 'myKey');
      expect(ex.type, String);
    });
  });

  group('MapGetter', () {
    final map = <String, dynamic>{
      'stringKey': 'hello',
      'intKey': 42,
      'boolKey': true,
      'nullKey': null,
      'listKey': [1, 2, 3],
    };

    test('get returns value for existing key with correct type', () {
      expect(map.get<String>('stringKey'), 'hello');
      expect(map.get<int>('intKey'), 42);
      expect(map.get<bool>('boolKey'), true);
      expect(map.get<List<int>>('listKey'), [1, 2, 3]);
    });

    test('get returns null for nullable type with missing key', () {
      expect(map.get<String?>('nonexistent'), isNull);
      expect(map.get<int?>('nonexistent'), isNull);
    });

    test('get returns null for nullable type with null value key', () {
      expect(map.get<String?>('nullKey'), isNull);
    });

    test(
      'get throws NoKeyMapException for non-nullable type with missing key',
      () {
        expect(
          () => map.get<String>('nonexistent'),
          throwsA(isA<NoKeyMapException>()),
        );
      },
    );

    test('get throws NoTypeMapException for wrong type', () {
      expect(
        () => map.get<String>('intKey'),
        throwsA(isA<NoTypeMapException>()),
      );
      expect(
        () => map.get<int>('stringKey'),
        throwsA(isA<NoTypeMapException>()),
      );
    });
  });
}

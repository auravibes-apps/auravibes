import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('drops values but preserves field and value types', () {
    expect(
      connectorToolSampleShape(
        jsonEncode({
          'name': 'private',
          'count': 7,
          'metadata': {'email': 'private'},
          'items': ['private'],
          'active': true,
        }),
      ),
      {
        'name': '',
        'count': 0,
        'metadata': <String, Object?>{},
        'items': <Object?>[],
        'active': false,
      },
    );
  });

  test('converts non-JSON text to an empty string sample', () {
    expect(connectorToolSampleShape('private response'), '');
  });
}

import 'package:auravibes_engine/auravibes_engine.dart' show ToolSpec;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ToolSpec', () {
    test('creates with required fields', () {
      final spec = ToolSpec(
        name: 'calculator',
        description: 'Performs calculations',
        inputJsonSchema: {'type': 'object'},
      );

      expect(spec.name, 'calculator');
      expect(spec.description, 'Performs calculations');
      expect(spec.inputJsonSchema, {'type': 'object'});
    });

    test('equals another with same props', () {
      final a = ToolSpec(name: 'a', description: 'a', inputJsonSchema: {});
      final b = ToolSpec(name: 'a', description: 'a', inputJsonSchema: {});
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('not equals when props differ', () {
      final a = ToolSpec(name: 'a', description: 'a', inputJsonSchema: {});
      final b = ToolSpec(name: 'b', description: 'a', inputJsonSchema: {});
      expect(a, isNot(equals(b)));
    });
  });
}

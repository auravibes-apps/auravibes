import 'package:auravibes_app/domain/entities/tool_spec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ToolSpec', () {
    test('creates with required fields', () {
      const spec = ToolSpec(
        name: 'calculator',
        description: 'Performs calculations',
        inputJsonSchema: {'type': 'object'},
      );

      expect(spec.name, 'calculator');
      expect(spec.description, 'Performs calculations');
      expect(spec.inputJsonSchema, {'type': 'object'});
    });

    test('equals another with same props', () {
      const a = ToolSpec(name: 'a', description: 'a', inputJsonSchema: {});
      const b = ToolSpec(name: 'a', description: 'a', inputJsonSchema: {});
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('not equals when props differ', () {
      const a = ToolSpec(name: 'a', description: 'a', inputJsonSchema: {});
      const b = ToolSpec(name: 'b', description: 'a', inputJsonSchema: {});
      expect(a, isNot(equals(b)));
    });
  });
}

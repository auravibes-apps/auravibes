import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('defensively freezes the complete JSON schema', () {
    final nested = <String, Object?>{
      'enum': <Object?>['a'],
    };
    final schema = <String, Object?>{'properties': nested};

    final spec = ToolSpec(
      name: 'tool',
      description: 'description',
      inputJsonSchema: schema,
    );
    nested['enum'] = <Object?>['b'];
    schema['type'] = 'array';

    expect(spec.inputJsonSchema, {
      'properties': {
        'enum': ['a'],
      },
    });
    expect(
      () => spec.inputJsonSchema['type'] = 'array',
      throwsUnsupportedError,
    );
    final properties =
        spec.inputJsonSchema['properties']! as Map<String, Object?>;
    expect(() => properties['type'] = 'string', throwsUnsupportedError);
    final values = properties['enum']! as List<Object?>;
    expect(() => values.add('b'), throwsUnsupportedError);
  });

  test('uses structural equality for frozen JSON', () {
    final first = ToolSpec(
      name: 'tool',
      description: 'description',
      inputJsonSchema: {
        'required': ['value'],
      },
    );
    final second = ToolSpec(
      name: 'tool',
      description: 'description',
      inputJsonSchema: {
        'required': ['value'],
      },
    );

    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });

  test('freezes dynamic JSON maps and lists', () {
    final nested = <String, dynamic>{
      'enum': <dynamic>['a'],
    };
    final schema = <String, dynamic>{'properties': nested};

    final spec = ToolSpec(
      name: 'tool',
      description: 'description',
      inputJsonSchema: schema,
    );
    (nested['enum'] as List<dynamic>).add('b');

    final properties =
        spec.inputJsonSchema['properties']! as Map<String, Object?>;
    expect(properties['enum'], ['a']);
    expect(
      () => (properties['enum']! as List<Object?>).add('b'),
      throwsUnsupportedError,
    );
  });
}

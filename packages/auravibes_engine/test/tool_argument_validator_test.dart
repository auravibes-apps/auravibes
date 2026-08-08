import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

const schema = <String, Object?>{
  'type': 'object',
  'properties': {
    'query': {'type': 'string'},
    'limit': {
      'type': 'integer',
      'enum': [1, 5, 10],
    },
    'tags': {
      'type': 'array',
      'items': {'type': 'string'},
    },
  },
  'required': ['query'],
  'additionalProperties': false,
};

void main() {
  test('accepts arguments matching supported schema subset', () {
    expect(
      () => validateToolArguments(schema, {
        'query': 'cache',
        'limit': 5,
        'tags': ['llm'],
      }),
      returnsNormally,
    );
  });

  test('rejects missing required argument', () {
    expect(
      () => validateToolArguments(schema, const {}),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          r'Missing required argument at $.query',
        ),
      ),
    );
  });

  test('rejects extra argument when additional properties are false', () {
    expect(
      () => validateToolArguments(schema, {
        'query': 'cache',
        'secret': 'nope',
      }),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          r'Unexpected argument at $.secret',
        ),
      ),
    );
  });

  test('rejects wrong scalar type and enum value', () {
    expect(
      () => validateToolArguments(schema, {'query': 7}),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          r'Expected string at $.query',
        ),
      ),
    );
    expect(
      () => validateToolArguments(schema, {
        'query': 'cache',
        'limit': 2,
      }),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          r'Value at $.limit is not in enum',
        ),
      ),
    );
  });

  test('validates nested values and every supported scalar type', () {
    const nestedSchema = <String, Object?>{
      'type': 'object',
      'properties': {
        'config': {
          'type': 'object',
          'properties': {
            'ratio': {'type': 'number'},
            'enabled': {'type': 'boolean'},
            'empty': {'type': 'null'},
          },
        },
      },
    };

    expect(
      () => validateToolArguments(nestedSchema, {
        'config': {'ratio': 0.5, 'enabled': true, 'empty': null},
      }),
      returnsNormally,
    );
    expect(
      () => validateToolArguments(schema, {
        'query': 'cache',
        'tags': ['llm', 7],
      }),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          r'Expected string at $.tags[1]',
        ),
      ),
    );
  });

  test('uses deep JSON enum equality and rejects unsupported types', () {
    const enumSchema = <String, Object?>{
      'enum': [
        {
          'filters': ['cached'],
        },
      ],
    };

    expect(
      () => validateToolArguments(enumSchema, {
        'filters': ['cached'],
      }),
      returnsNormally,
    );
    expect(
      () => validateToolArguments(
        const {'type': 'date'},
        const <String, Object?>{},
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          r'Unsupported schema type at $: date',
        ),
      ),
    );
  });
}

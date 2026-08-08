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


  test('validates nested schemas with narrower runtime map types', () {
    final nestedProperties = <String, Object>{
      'count': <String, Object>{'type': 'integer'},
      'tags': <String, Object>{
        'type': 'array',
        'items': <String, Object>{'type': 'string'},
      },
    };
    final runtimeSchema = <String, Object?>{
      'type': 'object',
      'properties': nestedProperties,
    };

    expect(
      () => validateToolArguments(runtimeSchema, {'count': 'wrong'}),
      throwsFormatException,
    );
    expect(
      () => validateToolArguments(runtimeSchema, {
        'tags': [1],
      }),
      throwsFormatException,
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

  test('formats punctuation in missing argument paths', () {
    const punctuationSchema = <String, Object?>{
      'type': 'object',
      'required': ['query.text'],
    };

    expect(
      () => validateToolArguments(punctuationSchema, const {}),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          r"Missing required argument at $['query.text']",
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

  test('formats punctuation in unexpected argument paths', () {
    const closedSchema = <String, Object?>{
      'type': 'object',
      'additionalProperties': false,
    };

    expect(
      () => validateToolArguments(closedSchema, const {'items[0]': true}),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          r"Unexpected argument at $['items[0]']",
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

  test('formats and escapes punctuation in nested value paths', () {
    const punctuationSchema = <String, Object?>{
      'type': 'object',
      'properties': {
        'config.data': {
          'type': 'object',
          'properties': {
            "owner's": {'type': 'string'},
          },
        },
      },
    };

    expect(
      () => validateToolArguments(punctuationSchema, {
        'config.data': {"owner's": 7},
      }),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          r"Expected string at $['config.data']['owner\'s']",
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

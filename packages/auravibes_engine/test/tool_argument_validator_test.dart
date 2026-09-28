import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_engine/src/tool_schema_strict.dart';
import 'package:genkit/plugin.dart';
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

const recursiveSchema = <String, dynamic>{
  'type': 'object',
  'properties': {
    'node': {r'$ref': r'#/$defs/node'},
    'choice': {
      'anyOf': [
        {'type': 'string'},
        {'type': 'null'},
      ],
    },
  },
  'required': ['node', 'choice'],
  'additionalProperties': false,
  r'$defs': {
    'node': {
      'type': 'object',
      'properties': {
        'value': {'type': 'string'},
        'next': {
          'anyOf': [
            {r'$ref': r'#/$defs/node'},
            {'type': 'null'},
          ],
        },
      },
      'required': ['value', 'next'],
      'additionalProperties': false,
    },
  },
};

final strictCodec = ChatCompletionsCodec(
  errorLabel: 'OpenAI',
  supportsStrictToolSampling: true,
  customize: (model, _) => (model: model, extraBody: {}),
);

final strictModel = ModelCapabilities(
  id: 'gpt-4o',
  name: 'GPT-4o',
  limitContext: 128000,
  limitOutput: 4096,
  inputModalities: const ['text'],
  outputModalities: const ['text'],
  supportsStrictToolSampling: true,
);

Map<String, dynamic> strictRequest(Map<String, dynamic> inputSchema) =>
    strictCodec.buildRequestBody(
      modelName: strictModel.id,
      request: ModelRequest(
        messages: const [],
        config: const {'toolSamplingPolicy': 'require'},
        tools: [
          ToolDefinition(
            name: 'fixture',
            description: 'Fixture.',
            inputSchema: inputSchema,
          ),
        ],
      ),
      stream: false,
      modelCapabilities: strictModel,
    );

void main() {
  test('URL and empty first-party schemas are closed', () {
    for (final candidate in [
      urlToolSpec.inputJsonSchema,
      skillsManagerToolSpecs.first.inputJsonSchema,
      defaultAppSkillToolInputJsonSchema,
    ]) {
      expect(
        strictToolSchemaIssue(Map<String, dynamic>.from(candidate)),
        isNull,
      );
    }
    expect(
      () => validateToolArguments(urlToolSpec.inputJsonSchema, {
        'input': 'https://example.test',
        'unexpected': true,
      }),
      throwsFormatException,
    );
  });

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
      () => validateToolArguments(schema, {'query': 'cache', 'secret': 'nope'}),
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
      () => validateToolArguments(schema, {'query': 'cache', 'limit': 2}),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          r'Value at $.limit is not in enum',
        ),
      ),
    );
  });

  test('rejects numeric values outside schema ranges', () {
    const rangedSchema = <String, Object?>{
      'type': 'object',
      'properties': {
        'limit': {'type': 'integer', 'minimum': 1, 'maximum': 10},
      },
    };

    expect(
      () => validateToolArguments(rangedSchema, {'limit': 0}),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          r'Value at $.limit is below minimum',
        ),
      ),
    );
    expect(
      () => validateToolArguments(rangedSchema, {'limit': 11}),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          r'Value at $.limit is above maximum',
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
      () => validateToolArguments(const {
        'type': 'date',
      }, const <String, Object?>{}),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          r'Unsupported schema type at $: date',
        ),
      ),
    );
  });

  test('strict preflight and arguments share recursive schema traversal', () {
    final request = strictRequest(recursiveSchema);
    final function =
        ((request['tools'] as List<dynamic>).single
                as Map<String, dynamic>)['function']
            as Map<String, dynamic>;
    expect(function['strict'], isTrue);
    expect(function['parameters'], recursiveSchema);
    expect(
      () => validateToolArguments(recursiveSchema, {
        'node': {
          'value': 'first',
          'next': {'value': 'second', 'next': null},
        },
        'choice': null,
      }),
      returnsNormally,
    );
    expect(
      () => validateToolArguments(recursiveSchema, {
        'node': {'value': 4, 'next': null},
        'choice': 'text',
      }),
      throwsFormatException,
    );
  });

  test('strict mode strips supported schema dialect metadata', () {
    const schemanticSchema = <String, dynamic>{
      r'$schema': 'http://json-schema.org/draft-07/schema#',
      'type': 'object',
      'properties': {
        'query': {'type': 'string'},
      },
      'required': ['query'],
      'additionalProperties': false,
    };
    final request = strictRequest(schemanticSchema);
    final function =
        ((request['tools'] as List<dynamic>).single
                as Map<String, dynamic>)['function']
            as Map<String, dynamic>;

    expect(function['strict'], isTrue);
    expect(function['parameters'], {
      'type': 'object',
      'properties': {
        'query': {'type': 'string'},
      },
      'required': ['query'],
      'additionalProperties': false,
    });
    expect(schemanticSchema.containsKey(r'$schema'), isTrue);
    expect(
      strictToolSchemaIssue({
        ...schemanticSchema,
        r'$schema': 'https://json-schema.org/draft/2020-12/schema',
      }),
      isA<ToolSchemaIssue>().having(
        (issue) => issue.reason,
        'reason',
        ToolSchemaIssueReason.unsupportedKeyword,
      ),
    );
  });

  test('nullable type accepts null and declared value', () {
    const nullableSchema = <String, dynamic>{
      'type': 'object',
      'properties': {
        'value': {
          'type': ['null', 'string'],
        },
      },
      'required': ['value'],
      'additionalProperties': false,
    };
    expect(strictRequest(nullableSchema)['tools'], isNotNull);
    expect(
      () => validateToolArguments(nullableSchema, {'value': null}),
      returnsNormally,
    );
    expect(
      () => validateToolArguments(nullableSchema, {'value': 'text'}),
      returnsNormally,
    );
    expect(
      () => validateToolArguments(nullableSchema, {'value': 5}),
      throwsFormatException,
    );
    expect(
      () => validateToolArguments(nullableSchema, const {}),
      returnsNormally,
    );
  });

  test('omitted nullable refs preserve legacy optional arguments', () {
    const optionalSchema = <String, dynamic>{
      'type': 'object',
      'properties': {
        'filter': {r'$ref': r'#/$defs/nullableFilter'},
      },
      'required': ['filter'],
      'additionalProperties': false,
      r'$defs': {
        'nullableFilter': {
          'anyOf': [
            {'type': 'string'},
            {'type': 'null'},
          ],
        },
      },
    };

    expect(strictRequest(optionalSchema)['tools'], isNotNull);
    expect(
      () => validateToolArguments(optionalSchema, const {}),
      returnsNormally,
    );
  });

  test('does not treat excluded null as an optional argument', () {
    const enumSchema = <String, Object?>{
      'type': 'object',
      'properties': {
        'filter': {
          'type': ['string', 'null'],
          'enum': ['recent'],
        },
      },
      'required': ['filter'],
    };

    expect(
      () => validateToolArguments(enumSchema, const {}),
      throwsFormatException,
    );
    expect(
      () => validateToolArguments(enumSchema, {'filter': null}),
      throwsFormatException,
    );
  });

  test('strict preflight rejects missing refs and unsupported keywords', () {
    for (final testCase in [
      (
        field: r'$ref',
        node: const <String, dynamic>{r'$ref': r'#/$defs/missing'},
      ),
      (field: 'oneOf', node: const <String, dynamic>{'oneOf': <Object?>[]}),
    ]) {
      final invalid = <String, dynamic>{
        'type': 'object',
        'properties': {'value': testCase.node},
        'required': ['value'],
        'additionalProperties': false,
      };
      expect(
        () => strictRequest(invalid),
        throwsA(
          isA<ToolSamplingValidationException>().having(
            (error) => error.schemaPath,
            'schemaPath',
            contains(testCase.field),
          ),
        ),
      );
    }
  });

  test('strict preflight enforces provider property and depth limits', () {
    final oversized = <String, dynamic>{
      'type': 'object',
      'properties': {
        for (var index = 0; index < 5001; index++)
          'p$index': {'type': 'string'},
      },
      'required': [for (var index = 0; index < 5001; index++) 'p$index'],
      'additionalProperties': false,
    };
    expect(
      () => strictRequest(oversized),
      throwsA(
        isA<ToolSamplingValidationException>().having(
          (error) => error.schemaReason,
          'schemaReason',
          ToolSchemaIssueReason.providerLimit,
        ),
      ),
    );

    var nested = <String, dynamic>{'type': 'string'};
    for (var depth = 0; depth < 11; depth++) {
      nested = {
        'type': 'object',
        'properties': {'child': nested},
        'required': ['child'],
        'additionalProperties': false,
      };
    }
    expect(
      () => strictRequest(nested),
      throwsA(
        isA<ToolSamplingValidationException>().having(
          (error) => error.schemaReason,
          'schemaReason',
          ToolSchemaIssueReason.providerLimit,
        ),
      ),
    );

    final longName = 'p' * 120001;
    expect(
      () => strictRequest({
        'type': 'object',
        'properties': {
          longName: {'type': 'string'},
        },
        'required': [longName],
        'additionalProperties': false,
      }),
      throwsA(
        isA<ToolSamplingValidationException>().having(
          (error) => error.schemaReason,
          'schemaReason',
          ToolSchemaIssueReason.providerLimit,
        ),
      ),
    );
  });
}

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('adds credential options and rejects duplicate tools', () {
    final schema = materializeSkillToolSchema(
      {'type': 'object', 'properties': {}},
      requiresCredential: true,
      credentialIds: ['a', 'a', 'b'],
    );
    expect((schema['properties']! as Map)['credentialId'], isNotNull);
    expect(schema['required']! as List, contains('credentialId'));
    final first = ToolSpec(name: 'x', description: 'one', inputJsonSchema: {});
    final second = ToolSpec(name: 'x', description: 'two', inputJsonSchema: {});
    expect(() => uniqueToolSpecs([first, second]), throwsStateError);
  });

  test('keeps optional template inputs out of required fields', () {
    final schema = templateInputSchema([
      {'name': 'requiredValue', 'type': 'string'},
      {'name': 'optionalValue', 'type': 'string', 'isOptional': true},
    ], requiresCredential: false);

    expect(schema['required'], ['requiredValue']);
    expect(
      (schema['properties']! as Map<String, Object?>).keys,
      containsAll(['requiredValue', 'optionalValue']),
    );
  });

  test('keeps optional template inputs out of required fields', () {
    final schema = templateInputSchema([
      {'name': 'requiredValue', 'type': 'string'},
      {'name': 'optionalValue', 'type': 'string', 'isOptional': true},
    ], requiresCredential: false);

    expect(schema['required'], ['requiredValue']);
    expect(
      (schema['properties']! as Map<String, Object?>).keys,
      containsAll(['requiredValue', 'optionalValue']),
    );
  });

  test('normalizes registered template schemas for strict providers', () {
    final schema = materializeSkillToolSchema(
      {
        'type': 'object',
        'properties': {
          'query': {'type': 'string'},
          'options': {
            'type': 'object',
            'properties': {
              'mode': {
                'type': 'string',
                'enum': ['fast', 'deep'],
              },
              'enabled': {'type': 'boolean'},
            },
            'required': ['mode'],
            'additionalProperties': false,
          },
          'format': {
            'type': 'string',
            'enum': ['short', 'long'],
            'default': 'short',
          },
        },
        'required': ['query', 'options'],
        'additionalProperties': false,
      },
      requiresCredential: false,
      strictProviderSchema: true,
    );
    final properties = schema['properties']! as Map<String, Object?>;
    final options = properties['options']! as Map<String, Object?>;
    final optionProperties = options['properties']! as Map<String, Object?>;

    expect(schema['required'], ['query', 'options', 'format']);
    expect(schema['additionalProperties'], false);
    expect(properties['format'], {
      'type': ['string', 'null'],
      'enum': ['short', 'long', null],
    });
    expect(options['required'], ['mode', 'enabled']);
    expect(optionProperties['enabled'], {
      'type': ['boolean', 'null'],
    });
    expect(strictToolSchemaIssue(Map<String, dynamic>.from(schema)), isNull);
  });

  test('leaves template schemas unchanged unless strict mode is requested', () {
    final schema = materializeSkillToolSchema({
      'type': 'object',
      'properties': {
        'optionalValue': {'type': 'string'},
      },
    }, requiresCredential: false);

    expect(schema['required'], isNull);
    expect(schema['additionalProperties'], isNull);
    expect((schema['properties']! as Map<String, Object?>)['optionalValue'], {
      'type': 'string',
    });
  });

  test('keeps free-form object properties outside strict closure', () {
    final schema = materializeSkillToolSchema(
      {
        'type': 'object',
        'properties': {
          'query': {'type': 'string'},
          'schema': {'type': 'object'},
        },
        'required': ['query'],
      },
      requiresCredential: false,
      strictProviderSchema: true,
    );

    expect(
      strictToolSchemaIssue(Map<String, dynamic>.from(schema))?.path,
      r'$.properties.schema.properties',
    );
  });

  test('preserves open nested objects for strict-preflight fallback', () {
    final schema = strictSkillToolSchema({
      'type': 'object',
      'properties': {
        'filters': {
          'type': 'object',
          'properties': {
            'tag': {'type': 'string'},
          },
          'additionalProperties': true,
        },
      },
      'required': <String>[],
      'additionalProperties': false,
    }, optionalNullMeansOmission: true);
    final filterSchema =
        (schema['properties']! as Map<String, Object?>)['filters']!
            as Map<String, Object?>;

    expect(filterSchema['additionalProperties'], isTrue);
    expect(
      strictToolSchemaIssue(Map<String, dynamic>.from(schema))?.path,
      r'$.required',
    );
  });

  test('normalizes supported and unsupported input contracts distinctly', () {
    final supported = strictSkillToolSchema({
      'type': 'object',
      'properties': {
        'requiredValue': {'type': 'string'},
        'optionalValue': {'type': 'integer'},
        'nullableValue': {
          'type': ['string', 'null'],
        },
      },
      'required': ['requiredValue', 'nullableValue'],
      'additionalProperties': false,
    }, optionalNullMeansOmission: true);
    final properties = supported['properties']! as Map<String, Object?>;

    expect(supported['required'], [
      'requiredValue',
      'nullableValue',
      'optionalValue',
    ]);
    expect(properties['optionalValue'], {
      'type': ['integer', 'null'],
    });
    expect(properties['nullableValue'], {
      'type': ['string', 'null'],
    });
    expect(strictToolSchemaIssue(Map<String, dynamic>.from(supported)), isNull);

    final unsupported = strictSkillToolSchema({
      'type': 'object',
      'properties': {
        'file': {'type': 'binary'},
      },
      'required': ['file'],
      'additionalProperties': false,
    });

    expect(
      strictToolSchemaIssue(Map<String, dynamic>.from(unsupported))?.path,
      r'$.properties.file.type',
    );
  });

  test('preserves optional values unless null omission is declared', () {
    final source = <String, Object?>{
      'type': 'object',
      'properties': {
        'optionalValue': {'type': 'string'},
        'nullableValue': {
          'type': ['string', 'null'],
        },
      },
      'required': ['nullableValue'],
      'additionalProperties': false,
    };
    final fallback = strictSkillToolSchema(source);
    final arguments = <String, Object?>{
      'optionalValue': null,
      'nullableValue': null,
    };

    expect(fallback, source);
    expect(
      strictToolSchemaIssue(Map<String, dynamic>.from(fallback))?.path,
      r'$.required',
    );
    expect(normalizeSkillToolArguments(source, arguments), arguments);

    final strict = strictSkillToolSchema(
      source,
      optionalNullMeansOmission: true,
    );
    expect(strictToolSchemaIssue(Map<String, dynamic>.from(strict)), isNull);
    expect(
      normalizeSkillToolArguments(
        source,
        arguments,
        optionalNullMeansOmission: true,
      ),
      {'nullableValue': null},
    );
  });

  test('accepts a closed empty input object', () {
    final schema = strictSkillToolSchema({
      'type': 'object',
      'properties': <String, Object?>{},
      'required': <String>[],
      'additionalProperties': false,
    });

    expect(strictToolSchemaIssue(Map<String, dynamic>.from(schema)), isNull);
  });

  test('rejects unknown keys inside closed nested skill inputs', () {
    final schema = strictSkillToolSchema({
      'type': 'object',
      'properties': {
        'filters': {
          'type': 'object',
          'properties': {
            'region': {'type': 'string'},
          },
          'required': <String>[],
          'additionalProperties': false,
        },
      },
      'required': ['filters'],
      'additionalProperties': false,
    });

    expect(
      () => validateToolArguments(schema, {
        'filters': {'unexpected': 'value'},
      }),
      throwsFormatException,
    );
  });

  test('keeps unknown null keys for execution validation', () {
    const schema = <String, Object?>{
      'type': 'object',
      'properties': <String, Object?>{},
      'required': <String>[],
      'additionalProperties': false,
    };
    final normalized = normalizeSkillToolArguments(schema, const {
      'unexpected': null,
    }, optionalNullMeansOmission: true);

    expect(normalized, {'unexpected': null});
    expect(
      () => validateToolArguments(schema, normalized),
      throwsFormatException,
    );
  });

  test('does not mask an invalid root schema type', () {
    final schema = materializeSkillToolSchema(
      {'type': 'string', 'properties': <String, Object?>{}},
      requiresCredential: false,
      strictProviderSchema: true,
    );

    expect(
      strictToolSchemaIssue(Map<String, dynamic>.from(schema))?.path,
      r'$.type',
    );
  });
}

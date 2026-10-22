import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('rejects duplicate tools', () {
    final first = ToolSpec(name: 'x', description: 'one', inputJsonSchema: {});
    final second = ToolSpec(name: 'x', description: 'two', inputJsonSchema: {});
    expect(() => uniqueToolSpecs([first, second]), throwsStateError);
  });

  test('normalizes declared tool schemas for strict providers', () {
    final schema = strictProviderToolSchema({
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
    }, optionalNullMeansOmission: true);
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

  test('leaves schemas unchanged when strictification is unsafe', () {
    final schema = strictProviderToolSchema({
      'type': 'object',
      'properties': {
        'optionalValue': {'type': 'string'},
      },
    });

    expect(schema['required'], isNull);
    expect(schema['additionalProperties'], isNull);
    expect((schema['properties']! as Map<String, Object?>)['optionalValue'], {
      'type': 'string',
    });
  });

  test('preserves unsupported contracts for strict preflight', () {
    final schema = strictProviderToolSchema({
      'type': 'object',
      'properties': {
        'query': {'type': 'string'},
        'schema': {'type': 'object'},
      },
      'required': ['query'],
      'additionalProperties': false,
    }, optionalNullMeansOmission: true);

    expect(schema['required'], ['query']);
    expect(
      strictToolSchemaIssue(Map<String, dynamic>.from(schema))?.path,
      r'$.required',
    );
  });

  test('preserves open nested objects for strict-preflight fallback', () {
    final schema = strictProviderToolSchema({
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
    final supported = strictProviderToolSchema({
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

    final unsupported = strictProviderToolSchema({
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
    final fallback = strictProviderToolSchema(source);
    final arguments = <String, Object?>{
      'optionalValue': null,
      'nullableValue': null,
    };

    expect(fallback, source);
    expect(
      strictToolSchemaIssue(Map<String, dynamic>.from(fallback))?.path,
      r'$.required',
    );
    expect(normalizeToolArguments(source, arguments), arguments);

    final strict = strictProviderToolSchema(
      source,
      optionalNullMeansOmission: true,
    );
    expect(strictToolSchemaIssue(Map<String, dynamic>.from(strict)), isNull);
    expect(
      normalizeToolArguments(
        source,
        arguments,
        optionalNullMeansOmission: true,
      ),
      {'nullableValue': null},
    );
  });

  test('accepts a closed empty input object', () {
    final schema = strictProviderToolSchema({
      'type': 'object',
      'properties': <String, Object?>{},
      'required': <String>[],
      'additionalProperties': false,
    });

    expect(strictToolSchemaIssue(Map<String, dynamic>.from(schema)), isNull);
  });

  test('rejects unknown keys inside closed nested tool inputs', () {
    final schema = strictProviderToolSchema({
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
    final normalized = normalizeToolArguments(schema, const {
      'unexpected': null,
    }, optionalNullMeansOmission: true);

    expect(normalized, {'unexpected': null});
    expect(
      () => validateToolArguments(schema, normalized),
      throwsFormatException,
    );
  });

  test('does not mask an invalid root schema type', () {
    final schema = strictProviderToolSchema({
      'type': 'string',
      'properties': <String, Object?>{},
    }, optionalNullMeansOmission: true);

    expect(
      strictToolSchemaIssue(Map<String, dynamic>.from(schema))?.path,
      r'$.type',
    );
  });
}

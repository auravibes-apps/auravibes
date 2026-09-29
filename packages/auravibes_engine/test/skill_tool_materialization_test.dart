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
          },
          'format': {
            'type': 'string',
            'enum': ['short', 'long'],
            'default': 'short',
          },
        },
        'required': ['query', 'options'],
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

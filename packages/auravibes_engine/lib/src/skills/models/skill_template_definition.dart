import 'dart:convert';

import 'package:auravibes_engine/src/skills/models/skill_credential_attribute_definition.dart';
import 'package:auravibes_engine/src/skills/models/skill_template_input_definition.dart';
import 'package:auravibes_engine/src/skills/models/skill_url_template.dart';

/// Versioned, app-neutral representation of a declarative skill tool.
class const SkillTemplateDefinition({
  required final SkillUrlTemplate request,
  required final Map<String, SkillTemplateInputDefinition> inputs,
  final int version = 1,
  final Map<String, SkillCredentialAttributeDefinition> credentialDefinitions =
      const {},
  final Map<String, Object?>? inputSchemaOverride,
}) {
  factory fromJsonString(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map) {
      throw const FormatException(
        'Skill template definition must be an object.',
      );
    }
    return SkillTemplateDefinition.fromJsonMap(decoded);
  }

  factory fromJsonMap(Map<Object?, Object?> decoded) {
    final versionValue = decoded['version'];
    if (versionValue is! int || versionValue != 1) {
      throw FormatException(
        'Unsupported skill template version: $versionValue.',
      );
    }
    const allowedKeys = {
      'version',
      'inputSchema',
      'request',
      'credentialSchema',
    };
    if (decoded.keys.any(
      (key) => key is! String || !allowedKeys.contains(key),
    )) {
      throw const FormatException(
        'Skill template definition has unknown fields.',
      );
    }
    final request = decoded['request'];
    final inputSchema = decoded['inputSchema'];
    if (request is! Map || inputSchema is! Map) {
      throw const FormatException(
        'Skill template definition requires request and inputSchema.',
      );
    }
    _validateManifestInputSchema(inputSchema);

    final schemaProperties = inputSchema['properties'];
    final required = inputSchema['required'];
    final requiredNames = required is List
        ? required.whereType<String>().toSet()
        : const <String>{};
    final inputs = schemaProperties is Map
        ? schemaProperties.map((key, value) {
            if (value is! Map) {
              throw const FormatException(
                'Input schema property must be an object.',
              );
            }
            return MapEntry(
              '$key',
              SkillTemplateInputDefinition.fromJson(value)
                  .copyWith(optional: !requiredNames.contains('$key')),
            );
          })
        : const <String, SkillTemplateInputDefinition>{};
    final credentialSchema = decoded['credentialSchema'];
    if (decoded.containsKey('credentialSchema') && credentialSchema is! Map) {
      throw const FormatException('credentialSchema must be an object.');
    }
    if (credentialSchema is Map) {
      _validateManifestCredentialSchema(credentialSchema);
    }
    final credentials = credentialSchema is Map
        ? SkillCredentialAttributeDefinition.parseMap(
            jsonEncode(credentialSchema),
          )
        : const <String, SkillCredentialAttributeDefinition>{};

    return SkillTemplateDefinition(
      request: SkillUrlTemplate.fromJsonString(jsonEncode(request)),
      inputs: inputs,
      version: versionValue,
      credentialDefinitions: credentials,
      inputSchemaOverride: _objectMap(inputSchema),
    );
  }

  factory fromLegacyJson({
    required String templateJson,
    required String inputsJson,
    Map<String, SkillCredentialAttributeDefinition> credentialDefinitions =
        const {},
  }) => SkillTemplateDefinition(
    request: SkillUrlTemplate.fromJsonString(templateJson),
    inputs: SkillTemplateInputDefinition.parseMap(inputsJson),
    credentialDefinitions: credentialDefinitions,
  );

  Map<String, Object?> get inputSchema =>
      inputSchemaOverride ??
      {
        'type': 'object',
        'properties': {
          for (final entry in inputs.entries)
            entry.key: _schemaProperty(entry.value),
        },
        'required': [
          for (final entry in inputs.entries)
            if (!entry.value.optional) entry.key,
        ],
        'additionalProperties': false,
      };

  String get legacyTemplateJson => request.toJsonString();

  String get legacyInputsJson => jsonEncode({
    for (final entry in inputs.entries) entry.key: entry.value.toJson(),
  });

  SkillTemplateDefinition copyWith({
    SkillUrlTemplate? request,
    Map<String, SkillTemplateInputDefinition>? inputs,
    int? version,
    Map<String, SkillCredentialAttributeDefinition>? credentialDefinitions,
    Map<String, Object?>? inputSchemaOverride,
  }) => SkillTemplateDefinition(
    request: request ?? this.request,
    inputs: inputs ?? this.inputs,
    version: version ?? this.version,
    credentialDefinitions: credentialDefinitions ?? this.credentialDefinitions,
    inputSchemaOverride: inputSchemaOverride ?? this.inputSchemaOverride,
  );

  Map<String, Object?> toJson() {
    return {
      'version': version,
      'inputSchema': inputSchema,
      'request': request.toJson(),
      if (credentialDefinitions.isNotEmpty)
        'credentialSchema': {
          for (final entry in credentialDefinitions.entries)
            entry.key: {
              'description': entry.value.description,
              if (entry.value.optional) 'optional': true,
              if (!entry.value.secret) 'secret': false,
            },
        },
    };
  }

  String toJsonString() => jsonEncode(toJson());
}

// ignore: unnecessary-nullable, absent or malformed decoded input is normalized to an empty map.
Map<String, Object?> _objectMap(Object? value) {
  if (value is! Map) return const {};

  return value.map((key, value) => MapEntry('$key', value));
}

void _validateManifestInputSchema(Map<Object?, Object?> schema) {
  _validateManifestSchemaNode(schema, root: true);
}

void _validateManifestSchemaNode(
  Map<Object?, Object?> schema, {
  bool root = false,
}) {
  _validateManifestSchemaKeys(schema);
  _validateManifestSchemaRoot(schema, root);
  final type = _validateManifestSchemaType(schema);
  _validateManifestSchemaMetadata(schema);
  _validateManifestSchemaConstraints(schema);
  _validateManifestSchemaProperties(schema);
  _validateManifestSchemaRequired(schema);
  _validateManifestSchemaAlternatives(schema);
  _validateManifestSchemaItems(schema, type);
}

void _validateManifestSchemaKeys(Map<Object?, Object?> schema) {
  const allowedKeys = {
    'type',
    'description',
    'optional',
    'additionalProperties',
    'default',
    'enum',
    'minimum',
    'maximum',
    'items',
    'properties',
    'required',
    'anyOf',
    'oneOf',
  };
  if (schema.keys.any((key) => key is! String || !allowedKeys.contains(key))) {
    throw const FormatException('Input schema has unknown fields.');
  }
}

void _validateManifestSchemaRoot(Map<Object?, Object?> schema, bool root) {
  if (!root) return;

  if (root && schema['type'] != 'object') {
    throw const FormatException('Skill inputSchema must be an object schema.');
  }
  if (root && schema['additionalProperties'] != false) {
    throw const FormatException(
      'Skill inputSchema must reject unknown inputs.',
    );
  }
}

Object? _validateManifestSchemaType(Map<Object?, Object?> schema) {
  final type = schema['type'];
  const supportedTypes = {
    'string',
    'number',
    'integer',
    'boolean',
    'array',
    'object',
  };
  if (type != null && (type is! String || !supportedTypes.contains(type))) {
    throw FormatException('Unsupported input schema type: $type.');
  }
  return type;
}

void _validateManifestSchemaMetadata(Map<Object?, Object?> schema) {
  for (final key in ['description', 'optional', 'additionalProperties']) {
    final value = schema[key];
    if (value == null) continue;
    final valid = key == 'description' ? value is String : value is bool;
    if (!valid) throw FormatException('Input schema $key must be valid.');
  }
}

void _validateManifestSchemaConstraints(Map<Object?, Object?> schema) {
  final enumValues = schema['enum'];
  if (enumValues != null && enumValues is! List) {
    throw const FormatException('Input schema enum must be an array.');
  }
  final minimum = schema['minimum'];
  final maximum = schema['maximum'];
  if (minimum != null && minimum is! num ||
      maximum != null && maximum is! num) {
    throw const FormatException('Input schema ranges must be numbers.');
  }
  if (minimum is num && maximum is num && minimum > maximum) {
    throw const FormatException('Input schema range is invalid.');
  }
}

void _validateManifestSchemaProperties(Map<Object?, Object?> schema) {
  final properties = schema['properties'];
  if (properties == null) return;
  if (properties is! Map) {
    throw const FormatException('Input schema properties must be an object.');
  }
  for (final entry in properties.entries) {
    if (entry.key is! String || entry.value is! Map) {
      throw const FormatException(
        'Input schema properties must be named objects.',
      );
    }
    _validateManifestSchemaNode(entry.value! as Map<Object?, Object?>);
  }
}

void _validateManifestSchemaRequired(Map<Object?, Object?> schema) {
  final required = schema['required'];
  final properties = schema['properties'];
  if (required != null &&
      (required is! List || !required.every((value) => value is String))) {
    throw const FormatException('Input schema required must be strings.');
  }
  if (required is List && properties is Map) {
    final names = properties.keys.whereType<String>().toSet();
    if (!required.every(names.contains)) {
      throw const FormatException(
        'Input schema required fields must be declared properties.',
      );
    }
  }
}

void _validateManifestSchemaAlternatives(Map<Object?, Object?> schema) {
  for (final key in ['anyOf', 'oneOf']) {
    final alternatives = schema[key];
    if (alternatives == null) continue;
    _validateManifestSchemaAlternativeList(key, alternatives);
  }
}

void _validateManifestSchemaAlternativeList(String key, Object? alternatives) {
  if (alternatives is! List ||
      alternatives.isEmpty ||
      alternatives.any((value) => value is! Map)) {
    throw FormatException('Input schema $key must contain objects.');
  }
  for (final alternative in alternatives) {
    _validateManifestSchemaNode(alternative! as Map<Object?, Object?>);
  }
}

void _validateManifestSchemaItems(Map<Object?, Object?> schema, Object? type) {
  final items = schema['items'];
  final properties = schema['properties'];
  if (items != null) {
    if (items is! Map) {
      throw const FormatException('Input schema items must be an object.');
    }
    _validateManifestSchemaNode(items);
  }
  if (type != 'array' && items != null) {
    throw const FormatException('Only arrays may declare input schema items.');
  }
  if (type != 'object' && properties != null) {
    throw const FormatException(
      'Only objects may declare input schema properties.',
    );
  }
}

void _validateManifestCredentialSchema(Map<Object?, Object?> schema) {
  for (final entry in schema.entries) {
    _validateManifestCredentialEntry(entry.key, entry.value);
  }
}

void _validateManifestCredentialEntry(Object? key, Object? value) {
  if (key is! String || value is! Map) {
    throw const FormatException('Credential schema entries must be objects.');
  }
  _validateManifestCredentialDefinition(value);
}

void _validateManifestCredentialDefinition(Map<Object?, Object?> definition) {
  const allowedKeys = {'description', 'optional', 'secret'};
  if (definition.keys.any(
    (key) => key is! String || !allowedKeys.contains(key),
  )) {
    throw const FormatException('Credential schema has unknown fields.');
  }
  final description = definition['description'];
  if (description != null && description is! String) {
    throw const FormatException('Credential schema description must be text.');
  }
  for (final key in ['optional', 'secret']) {
    final value = definition[key];
    if (value != null && value is! bool) {
      throw FormatException('Credential schema $key must be boolean.');
    }
  }
}

Map<String, Object?> _schemaProperty(SkillTemplateInputDefinition definition) {
  final value = Map<String, Object?>.from(definition.toJson())
    ..remove('optional');
  final properties = value['properties'];
  if (properties is Map) {
    value['properties'] = {
      for (final entry in definition.properties.entries)
        entry.key: _schemaProperty(entry.value),
    };
    value['required'] = [
      for (final entry in definition.properties.entries)
        if (!entry.value.optional) entry.key,
    ];
  }
  return value;
}

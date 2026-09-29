import 'dart:convert';

import 'package:auravibes_engine/src/tool_spec.dart';

class const SkillToolMaterializationInput({
  required final String name,
  required final String description,
  required final Map<String, Object?> schema,
  required final bool requiresCredential,
  final Iterable<String> credentialIds = const [],
  final bool isAvailable = true,
  final bool strictProviderSchema = false,
});

ToolSpec? materializeSkillTool(SkillToolMaterializationInput input) {
  final ids = input.credentialIds.toSet();
  if (!input.isAvailable || (input.requiresCredential && ids.isEmpty)) {
    return null;
  }
  return ToolSpec(
    name: input.name,
    description: input.description,
    requiresCredential: input.requiresCredential,
    inputJsonSchema: materializeSkillToolSchema(
      input.schema,
      requiresCredential: input.requiresCredential,
      credentialIds: ids,
      strictProviderSchema: input.strictProviderSchema,
    ),
  );
}

Map<String, Object?> templateInputSchema(
  Object? inputs, {
  required bool requiresCredential,
  Iterable<String> credentialIds = const [],
}) {
  final parsed = switch (inputs) {
    final String value => _decodeTemplateInputs(value),
    final List<Object?> value => value,
    _ => throw const FormatException('Template inputs must be a JSON array.'),
  };
  final properties = <String, Object?>{};
  final required = <String>[];
  for (final raw in parsed) {
    if (raw is! Map) {
      throw const FormatException('Template input must be an object.');
    }
    if (!_isValidTemplateInput(raw, properties)) {
      throw const FormatException('Invalid template input.');
    }
    final name = raw['name'] as String;
    final type = raw['type'] as String?;
    final optional = raw['isOptional'] as bool?;
    properties[name] = {
      'type': type ?? 'string',
      if (raw['description'] case final String description)
        'description': description,
    };
    if (optional != true) required.add(name);
  }
  return materializeSkillToolSchema(
    {
      'type': 'object',
      'properties': properties,
      if (required.isNotEmpty) 'required': required,
      'additionalProperties': false,
    },
    requiresCredential: requiresCredential,
    credentialIds: credentialIds,
  );
}

bool _isValidTemplateInput(
  Map<Object?, Object?> raw,
  Map<String, Object?> properties,
) {
  final name = raw['name'];
  final type = raw['type'];
  final optional = raw['isOptional'];

  return name is String &&
      name.isNotEmpty &&
      !properties.containsKey(name) &&
      (type == null || type is String) &&
      (optional == null || optional is bool);
}

List<Object?> _decodeTemplateInputs(String value) {
  final decoded = jsonDecode(value);
  if (decoded is! List) {
    throw const FormatException('Template inputs must be a JSON array.');
  }
  return decoded;
}

Map<String, Object?> materializeSkillToolSchema(
  Map<String, Object?> schema, {
  required bool requiresCredential,
  Iterable<String> credentialIds = const [],
  bool strictProviderSchema = false,
}) {
  final ids = credentialIds.toSet().toList(growable: false);
  final result = Map<String, Object?>.from(schema);
  final properties = Map<String, Object?>.from(
    result['properties'] as Map? ?? const <String, Object?>{},
  );
  final required = <String>[
    for (final value in result['required'] as List? ?? const <Object?>[])
      if (value is String && value != 'credentialId') value,
  ];
  if (ids.isEmpty) {
    properties.remove('credentialId');
  } else {
    properties['credentialId'] = {'type': 'string', 'enum': ids};
    if (requiresCredential && ids.length > 1) required.add('credentialId');
  }
  result['properties'] = properties;
  if (required.isEmpty) {
    result.remove('required');
  } else {
    result['required'] = required;
  }
  return strictProviderSchema
      ? _strictProviderSchema(result, root: true)
      : result;
}

Map<String, Object?> _strictProviderSchema(
  Map<String, Object?> schema, {
  required bool root,
  bool nullable = false,
}) {
  // Defaults remain in source definitions used by the executor.
  final result = Map<String, Object?>.from(schema)..remove('default');
  if (root) {
    if (result['properties'] is Map) {
      // Runtime validation keeps enforcing source-schema alternatives.
      result.remove('anyOf');
    }
    result.putIfAbsent('type', () => 'object');
  }

  final properties = result['properties'];
  final isObject = root || properties is Map;
  if (isObject) {
    final sourceProperties = properties is Map
        ? Map<String, Object?>.from(properties)
        : const <String, Object?>{};
    final originalRequired = {
      for (final name in result['required'] as List? ?? const [])
        if (name is String) name,
    };
    final strictProperties = <String, Object?>{};
    for (final entry in sourceProperties.entries) {
      final propertySchema = entry.value;
      strictProperties[entry.key] = propertySchema is Map
          ? _strictProviderSchema(
              Map<String, Object?>.from(propertySchema),
              root: false,
              nullable: !originalRequired.contains(entry.key),
            )
          : propertySchema;
    }
    result['properties'] = strictProperties;
    result['required'] = [
      ...originalRequired,
      ...strictProperties.keys.where(
        (name) => !originalRequired.contains(name),
      ),
    ];
    result['additionalProperties'] = false;
  }

  if (result['items'] case final Map<Object?, Object?> items) {
    result['items'] = _strictProviderSchema(
      Map<String, Object?>.from(items),
      root: false,
    );
  }
  if (result[r'$defs'] case final Map<Object?, Object?> definitions) {
    result[r'$defs'] = {
      for (final entry in definitions.entries)
        if (entry.value is Map<Object?, Object?>)
          entry.key: _strictProviderSchema(
            Map<String, Object?>.from(entry.value! as Map),
            root: false,
          )
        else
          entry.key: entry.value,
    };
  }
  if (result['anyOf'] case final List<Object?> alternatives) {
    result['anyOf'] = [
      for (final alternative in alternatives)
        if (alternative is Map<Object?, Object?>)
          _strictProviderSchema(
            Map<String, Object?>.from(alternative),
            root: false,
          )
        else
          alternative,
    ];
  }

  return nullable ? _allowNull(result) : result;
}

Map<String, Object?> _allowNull(Map<String, Object?> schema) {
  final result = Map<String, Object?>.from(schema);
  final type = result['type'];
  if (type is String && type != 'null') {
    result['type'] = [type, 'null'];
  } else if (type is List && !type.contains('null') && type.length == 1) {
    result['type'] = [...type, 'null'];
  }
  if (result['enum'] case final List<Object?> values
      when !values.contains(null)) {
    result['enum'] = [...values, null];
  }
  if (result['anyOf'] case final List<Object?> alternatives
      when !alternatives.any(
        (alternative) =>
            alternative is Map &&
            _schemaTypes(alternative['type'])?.contains('null') == true,
      )) {
    result['anyOf'] = [
      ...alternatives,
      {'type': 'null'},
    ];
  }
  return result;
}

Set<String>? _schemaTypes(Object? value) {
  if (value is String) return {value};
  if (value is! List) return null;
  return value.whereType<String>().toSet();
}

List<ToolSpec> uniqueToolSpecs(Iterable<ToolSpec> specs) {
  final names = <String>{};
  final unique = <ToolSpec>[];
  for (final spec in specs) {
    if (!names.add(spec.name)) {
      throw StateError('Duplicate tool name: ${spec.name}');
    }
    unique.add(spec);
  }
  return unique;
}

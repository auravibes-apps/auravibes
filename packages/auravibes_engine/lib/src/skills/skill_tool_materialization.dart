import 'dart:convert';

import 'package:auravibes_engine/src/tool_spec.dart';

class SkillToolMaterializationInput {
  const SkillToolMaterializationInput({
    required this.name,
    required this.description,
    required this.schema,
    required this.requiresCredential,
    this.credentialIds = const [],
    this.isAvailable = true,
  });

  final String name;
  final String description;
  final Map<String, Object?> schema;
  final bool requiresCredential;
  final Iterable<String> credentialIds;
  final bool isAvailable;
}

ToolSpec? materializeSkillTool(SkillToolMaterializationInput input) {
  final ids = input.credentialIds.toSet();
  if (!input.isAvailable || (input.requiresCredential && ids.isEmpty)) {
    return null;
  }
  return ToolSpec(
    name: input.name,
    description: input.description,
    inputJsonSchema: materializeSkillToolSchema(
      input.schema,
      requiresCredential: input.requiresCredential,
      credentialIds: ids,
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
    final name = raw['name'];
    final type = raw['type'];
    final optional = raw['isOptional'];
    if (name is! String ||
        name.isEmpty ||
        properties.containsKey(name) ||
        type != null && type is! String ||
        optional != null && optional is! bool) {
      throw const FormatException('Invalid template input.');
    }
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
    properties['credentialId'] = {
      'type': 'string',
      'enum': ids,
    };
    if (requiresCredential && ids.length > 1) required.add('credentialId');
  }
  result['properties'] = properties;
  if (required.isEmpty) {
    result.remove('required');
  } else {
    result['required'] = required;
  }
  return result;
}

List<ToolSpec> uniqueToolSpecs(Iterable<ToolSpec> specs) {
  final names = <String>{};
  return [
    for (final spec in specs)
      if (names.add(spec.name)) spec,
  ];
}

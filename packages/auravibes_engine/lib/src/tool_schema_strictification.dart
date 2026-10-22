import 'package:auravibes_engine/src/tool_schema_strict.dart';
import 'package:auravibes_engine/src/tool_spec.dart';

/// Converts a declared skill contract only when object closure preserves its
/// input semantics. Unsupported contracts remain unchanged for strict
/// preflight.
Map<String, Object?> strictProviderToolSchema(
  Map<String, Object?> schema, {
  bool optionalNullMeansOmission = false,
}) {
  final source = Map<String, Object?>.from(schema);
  if (strictToolSchemaIssue(Map<String, dynamic>.from(source)) == null) {
    return source;
  }
  if (source['type'] != 'object' ||
      source['properties'] is! Map ||
      source['additionalProperties'] != false ||
      (!optionalNullMeansOmission && _hasOptionalObjectProperties(source))) {
    return source;
  }

  final strict = _strictProviderSchema(
    source,
    root: true,
    preserveRootAlternatives: true,
  );
  return strictToolSchemaIssue(Map<String, dynamic>.from(strict)) == null
      ? strict
      : source;
}

/// Drops null object properties only when their source contract marks them
/// optional. Keeps unknown keys so the execution validator can reject them.
Map<String, Object?> normalizeToolArguments(
  Map<String, Object?> schema,
  Map<String, Object?> arguments, {
  bool optionalNullMeansOmission = false,
}) => optionalNullMeansOmission
    ? _normalizedToolArguments(schema, arguments)
    : Map<String, Object?>.from(arguments);

Map<String, Object?> _normalizedToolArguments(
  Map<String, Object?> schema,
  Map<String, Object?> arguments,
) {
  final normalized = _normalizeToolValue(schema, arguments);
  if (normalized is! Map<Object?, Object?>) {
    throw StateError('Normalized tool arguments must remain an object.');
  }
  return Map<String, Object?>.from(normalized);
}

bool _hasOptionalObjectProperties(Map<String, Object?> schema) {
  final properties = schema['properties'];
  if (properties is Map) {
    final required = (schema['required'] as List? ?? const [])
        .whereType<String>()
        .toSet();
    if (properties.keys.any(
      (key) => key is String && !required.contains(key),
    )) {
      return true;
    }
    for (final child in properties.values) {
      if (child is Map &&
          _hasOptionalObjectProperties(Map<String, Object?>.from(child))) {
        return true;
      }
    }
  }
  if (schema['items'] case final Map<Object?, Object?> items
      when _hasOptionalObjectProperties(Map<String, Object?>.from(items))) {
    return true;
  }
  if (schema[r'$defs'] case final Map<Object?, Object?> definitions) {
    for (final value in definitions.values) {
      if (value is Map &&
          _hasOptionalObjectProperties(Map<String, Object?>.from(value))) {
        return true;
      }
    }
  }
  if (schema['anyOf'] case final List<Object?> alternatives) {
    for (final alternative in alternatives) {
      if (alternative is Map &&
          _hasOptionalObjectProperties(
            Map<String, Object?>.from(alternative),
          )) {
        return true;
      }
    }
  }
  return false;
}

Object? _normalizeToolValue(Map<Object?, Object?> schema, Object? value) {
  final properties = schema['properties'];
  if (value is Map<Object?, Object?> && properties is Map<Object?, Object?>) {
    final required = (schema['required'] as List? ?? const [])
        .whereType<String>()
        .toSet();
    final normalized = <Object?, Object?>{};
    for (final entry in value.entries) {
      final name = entry.key;
      if (name is String &&
          properties.containsKey(name) &&
          entry.value == null &&
          !required.contains(name)) {
        continue;
      }
      final childSchema = properties[name];
      normalized[name] = childSchema is Map<Object?, Object?>
          ? _normalizeToolValue(childSchema, entry.value)
          : entry.value;
    }
    return normalized;
  }
  final items = schema['items'];
  if (value is List && items is Map<Object?, Object?>) {
    return [for (final item in value) _normalizeToolValue(items, item)];
  }

  return value;
}

Map<String, Object?> _strictProviderSchema(
  Map<String, Object?> schema, {
  required bool root,
  bool nullable = false,
  bool preserveRootAlternatives = false,
}) {
  if (!_canStrictifyProviderSchema(schema, root: root)) {
    return Map<String, Object?>.from(schema);
  }

  // Defaults remain in source definitions used by the executor.
  final result = Map<String, Object?>.from(schema)..remove('default');
  if (root) {
    if (result['properties'] is Map) {
      if (preserveRootAlternatives && result.containsKey('anyOf')) {
        return Map<String, Object?>.from(schema);
      }
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
              preserveRootAlternatives: preserveRootAlternatives,
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
      preserveRootAlternatives: preserveRootAlternatives,
    );
  }
  if (result[r'$defs'] case final Map<Object?, Object?> definitions) {
    result[r'$defs'] = {
      for (final entry in definitions.entries)
        if (entry.value is Map<Object?, Object?>)
          entry.key: _strictProviderSchema(
            Map<String, Object?>.from(entry.value! as Map),
            root: false,
            preserveRootAlternatives: preserveRootAlternatives,
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
            preserveRootAlternatives: preserveRootAlternatives,
          )
        else
          alternative,
    ];
  }

  return nullable ? _allowNull(result) : result;
}

bool _canStrictifyProviderSchema(
  Map<String, Object?> schema, {
  required bool root,
}) {
  if (root && schema['properties'] is! Map) return false;
  if (schema.containsKey('oneOf')) return false;

  final properties = schema['properties'];
  if (properties is Map && schema['type'] == 'object') {
    if (!root && schema['additionalProperties'] != false) return false;
    if (!properties.keys.every((key) => key is String) ||
        !properties.values.every((value) => value is Map)) {
      return false;
    }
    final required = schema['required'];
    if (required != null &&
        (required is! List || !required.every((name) => name is String))) {
      return false;
    }
    if (required is List) {
      final names = required.cast<String>();
      if (names.toSet().length != names.length ||
          !properties.keys.toSet().containsAll(names)) {
        return false;
      }
    }
    return true;
  }

  final types = _schemaTypes(schema['type']);
  if (types != null) {
    if (types.contains('object')) {
      return properties is Map &&
          properties.keys.every((key) => key is String) &&
          properties.values.every((value) => value is Map) &&
          schema['additionalProperties'] == false;
    }
    if (types.contains('array')) return schema['items'] is Map;
    return types.every(
      (type) => const {
        'boolean',
        'integer',
        'null',
        'number',
        'string',
      }.contains(type),
    );
  }

  if (schema['anyOf'] case final List<Object?> alternatives
      when !root && alternatives.isNotEmpty) {
    return alternatives.every(
      (alternative) => alternative is Map<Object?, Object?>,
    );
  }
  return false;
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

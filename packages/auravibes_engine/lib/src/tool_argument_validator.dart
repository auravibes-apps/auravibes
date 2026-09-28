import 'package:auravibes_engine/src/tool_schema.dart';

void validateToolArguments(
  Map<String, Object?> schema,
  Map<String, Object?> arguments,
) {
  final parsed = ToolSchema(schema);
  _validateValue(parsed, (schema: schema, path: r'$'), arguments, r'$', {});
}

void _validateValue(
  ToolSchema parsed,
  ToolSchemaNode node,
  Object? value,
  String path,
  Set<(String, Object?)> active,
) {
  final visit = (node.path, value);
  if (!active.add(visit)) {
    throw FormatException('Recursive schema at $path');
  }
  try {
    _validateNode(parsed, node, value, path, active);
  } finally {
    active.remove(visit);
  }
}

void _validateNode(
  ToolSchema parsed,
  ToolSchemaNode node,
  Object? value,
  String path,
  Set<(String, Object?)> active,
) {
  final schema = node.schema;
  if (schema.containsKey(r'$ref')) {
    final target = parsed.reference(schema[r'$ref']);
    if (target == null) {
      throw FormatException('Unresolved schema reference at $path');
    }
    _validateValue(parsed, target, value, path, active);
    _validateSchemaValue(
      parsed,
      schema,
      value,
      path,
      active,
      ignoredKeywords: const {r'$ref'},
    );
    return;
  }
  if (schema['anyOf'] case final List<dynamic> branches) {
    _validateAnyOf(parsed, node, branches, value, path, active);
    _validateSchemaValue(
      parsed,
      schema,
      value,
      path,
      active,
      ignoredKeywords: const {'anyOf'},
    );
    return;
  }
  _validateSchemaValue(parsed, schema, value, path, active);
}

void _validateSchemaValue(
  ToolSchema parsed,
  Map<String, Object?> schema,
  Object? value,
  String path,
  Set<(String, Object?)> active, {
  Set<String> ignoredKeywords = const {},
}) {
  final keywords = ignoredKeywords.isEmpty
      ? schema
      : (Map<String, Object?>.from(schema)
          ..removeWhere((key, _) => ignoredKeywords.contains(key)));
  final rawType = keywords['type'];
  final types = parsed.types(rawType);
  if (rawType != null && types == null) {
    throw FormatException('Unsupported schema type at $path: $rawType');
  }
  final type = value == null && types?.contains('null') == true
      ? 'null'
      : types?.firstWhere((name) => name != 'null', orElse: () => 'null');
  switch (type) {
    case null:
      break;
    case 'object':
      _validateObject(parsed, keywords, value, path, active);
    case 'array':
      _validateArray(parsed, keywords, value, path, active);
    case 'string':
      _expectType(value is String, 'string', path);
    case 'integer':
      _expectType(value is int, 'integer', path);
    case 'number':
      _expectType(value is num, 'number', path);
    case 'boolean':
      _expectType(value is bool, 'boolean', path);
    case 'null':
      _expectType(value == null, 'null', path);
    case final String name:
      throw FormatException('Unsupported schema type at $path: $name');
  }

  if (type == null && value is Map && _hasObjectConstraints(keywords)) {
    _validateObject(parsed, keywords, value, path, active);
  }
  if (type == null && value is List && _hasArrayConstraints(keywords)) {
    _validateArray(parsed, keywords, value, path, active);
  }

  final allowedValues = keywords['enum'];
  if (allowedValues is List &&
      !allowedValues.any((allowed) => _jsonEquals(allowed, value))) {
    throw FormatException('Value at $path is not in enum');
  }

  if (value is num) {
    final minimum = keywords['minimum'];
    if (minimum is num && value < minimum) {
      throw FormatException('Value at $path is below minimum');
    }
    final maximum = keywords['maximum'];
    if (maximum is num && value > maximum) {
      throw FormatException('Value at $path is above maximum');
    }
  }
  if (value is String) {
    final minimum = keywords['minLength'];
    if (minimum is int && value.length < minimum) {
      throw FormatException('Value at $path is shorter than minLength');
    }
    final maximum = keywords['maxLength'];
    if (maximum is int && value.length > maximum) {
      throw FormatException('Value at $path is longer than maxLength');
    }
  }
  if (keywords.containsKey('const') && !_jsonEquals(keywords['const'], value)) {
    throw FormatException('Value at $path does not match const');
  }
}

bool _hasObjectConstraints(Map<String, Object?> schema) =>
    schema.containsKey('properties') ||
    schema.containsKey('required') ||
    schema.containsKey('additionalProperties');

bool _hasArrayConstraints(Map<String, Object?> schema) =>
    schema.containsKey('items') ||
    schema.containsKey('minItems') ||
    schema.containsKey('maxItems');

void _validateAnyOf(
  ToolSchema parsed,
  ToolSchemaNode node,
  List<dynamic> branches,
  Object? value,
  String path,
  Set<(String, Object?)> active,
) {
  for (var index = 0; index < branches.length; index++) {
    final branch = parsed.node(branches[index], '${node.path}.anyOf[$index]');
    if (branch == null) continue;
    try {
      _validateValue(parsed, branch, value, path, active);
      return;
    } on FormatException {
      // Another branch may match the same value.
    }
  }
  throw FormatException('Value at $path matches no anyOf branch');
}

void _validateObject(
  ToolSchema parsed,
  Map<String, Object?> schema,
  Object? value,
  String path,
  Set<(String, Object?)> active,
) {
  if (value is! Map) {
    throw FormatException('Expected object at $path');
  }

  _validateRequiredProperties(parsed, schema, value, path);
  _validateAdditionalProperties(schema, value, path);
  _validateObjectProperties(parsed, schema, value, path, active);
}

void _validateRequiredProperties(
  ToolSchema parsed,
  Map<String, Object?> schema,
  Map<Object?, Object?> value,
  String path,
) {
  final required = schema['required'];
  if (required is! List) return;

  for (final name in required.whereType<String>()) {
    if (!value.containsKey(name) && !_allowsOmission(parsed, schema, name)) {
      throw FormatException(
        'Missing required argument at ${_propertyPath(path, name)}',
      );
    }
  }
}

bool _allowsOmission(
  ToolSchema parsed,
  Map<String, Object?> schema,
  String name,
) {
  final properties = schema['properties'];
  final property = properties is Map
      ? parsed.node(properties[name], r'$.properties.' + name)
      : null;
  return property != null && parsed.acceptsNull(property);
}

void _validateAdditionalProperties(
  Map<String, Object?> schema,
  Map<Object?, Object?> value,
  String path,
) {
  if (schema['additionalProperties'] != false) return;

  final properties = schema['properties'];
  for (final name in value.keys) {
    if (properties is! Map || !properties.containsKey(name)) {
      throw FormatException(
        'Unexpected argument at ${_propertyPath(path, name)}',
      );
    }
  }
}

void _validateObjectProperties(
  ToolSchema parsed,
  Map<String, Object?> schema,
  Map<Object?, Object?> value,
  String path,
  Set<(String, Object?)> active,
) {
  final properties = schema['properties'];
  if (properties is! Map) return;

  for (final entry in value.entries) {
    final propertySchema = properties[entry.key];
    final child = parsed.node(propertySchema, '$path.properties.${entry.key}');
    if (child != null) {
      _validateValue(
        parsed,
        child,
        entry.value,
        _propertyPath(path, entry.key),
        active,
      );
    }
  }
}

String _propertyPath(String path, Object? name) {
  final segment = name.toString();
  if (RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(segment)) {
    return '$path.$segment';
  }
  final escaped = segment.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
  return "$path['$escaped']";
}

void _validateArray(
  ToolSchema parsed,
  Map<String, Object?> schema,
  Object? value,
  String path,
  Set<(String, Object?)> active,
) {
  if (value is! List) {
    throw FormatException('Expected array at $path');
  }

  final minimum = schema['minItems'];
  if (minimum is int && value.length < minimum) {
    throw FormatException('Value at $path has fewer than minItems');
  }
  final maximum = schema['maxItems'];
  if (maximum is int && value.length > maximum) {
    throw FormatException('Value at $path has more than maxItems');
  }
  final items = parsed.node(schema['items'], '$path.items');
  if (items != null) {
    for (var index = 0; index < value.length; index++) {
      _validateValue(parsed, items, value[index], '$path[$index]', active);
    }
  }
}

void _expectType(bool matches, String type, String path) {
  if (!matches) throw FormatException('Expected $type at $path');
}

bool _jsonEquals(Object? left, Object? right) {
  if (identical(left, right)) return true;
  if (left is Map && right is Map) {
    return left.length == right.length &&
        left.entries.every(
          (entry) =>
              right.containsKey(entry.key) &&
              _jsonEquals(entry.value, right[entry.key]),
        );
  }
  if (left is List && right is List) {
    return left.length == right.length &&
        Iterable<int>.generate(left.length)
            .every((index) => _jsonEquals(left[index], right[index]));
  }
  return left == right;
}

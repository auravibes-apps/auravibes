void validateToolArguments(
  Map<String, Object?> schema,
  Map<String, Object?> arguments,
) {
  _validateValue(schema, arguments, r'$');
}

void _validateValue(Map<String, Object?> schema, Object? value, String path) {
  switch (schema['type']) {
    case null:
      break;
    case 'object':
      _validateObject(schema, value, path);
    case 'array':
      _validateArray(schema, value, path);
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
    case final type:
      throw FormatException('Unsupported schema type at $path: $type');
  }

  final allowedValues = schema['enum'];
  if (allowedValues is List &&
      !allowedValues.any((allowed) => _jsonEquals(allowed, value))) {
    throw FormatException('Value at $path is not in enum');
  }
}

void _validateObject(Map<String, Object?> schema, Object? value, String path) {
  if (value is! Map) {
    throw FormatException('Expected object at $path');
  }

  final required = schema['required'];
  if (required is List) {
    for (final name in required.whereType<String>()) {
      if (!value.containsKey(name)) {
        throw FormatException(
          'Missing required argument at ${_propertyPath(path, name)}',
        );
      }
    }
  }

  final properties = schema['properties'];
  if (schema['additionalProperties'] == false) {
    for (final name in value.keys) {
      if (properties is! Map || !properties.containsKey(name)) {
        throw FormatException(
          'Unexpected argument at ${_propertyPath(path, name)}',
        );
      }
    }
  }

  if (properties is Map) {
    for (final entry in value.entries) {
      final propertySchema = properties[entry.key];
      if (propertySchema is Map) {
        _validateValue(
          Map<String, Object?>.from(propertySchema),
          entry.value,
          _propertyPath(path, entry.key),
        );
      }
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

void _validateArray(Map<String, Object?> schema, Object? value, String path) {
  if (value is! List) {
    throw FormatException('Expected array at $path');
  }

  final itemSchema = schema['items'];
  if (itemSchema is Map) {
    final normalizedItemSchema = Map<String, Object?>.from(itemSchema);
    for (var index = 0; index < value.length; index++) {
      _validateValue(normalizedItemSchema, value[index], '$path[$index]');
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
        Iterable<int>.generate(
          left.length,
        ).every((index) => _jsonEquals(left[index], right[index]));
  }
  return left == right;
}

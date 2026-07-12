import 'dart:collection';

// Fields are deeply frozen; equality preserves replaced app value semantics.
// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

class ToolSpec {
  ToolSpec({
    required this.name,
    required this.description,
    required Map<String, Object?> inputJsonSchema,
  }) : inputJsonSchema = _freezeMap(inputJsonSchema);

  final String name;
  final String description;
  final Map<String, Object?> inputJsonSchema;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToolSpec &&
          name == other.name &&
          description == other.description &&
          _jsonEquals(inputJsonSchema, other.inputJsonSchema);

  @override
  int get hashCode =>
      Object.hash(name, description, _jsonHash(inputJsonSchema));
}

Map<String, Object?> _freezeMap(Map<String, Object?> value) {
  return UnmodifiableMapView({
    for (final entry in value.entries) entry.key: _freezeJson(entry.value),
  });
}

Object? _freezeJson(Object? value) {
  return switch (value) {
    final Map<String, Object?> value => _freezeMap(value),
    final List<Object?> value => List<Object?>.unmodifiable(
      value.map(_freezeJson),
    ),
    _ => value,
  };
}

bool _jsonEquals(Object? left, Object? right) {
  if (identical(left, right)) return true;
  if (left is Map<String, Object?> && right is Map<String, Object?>) {
    return left.length == right.length &&
        left.entries.every(
          (entry) =>
              right.containsKey(entry.key) &&
              _jsonEquals(entry.value, right[entry.key]),
        );
  }
  if (left is List<Object?> && right is List<Object?>) {
    return left.length == right.length &&
        Iterable<int>.generate(left.length).every(
          (index) => _jsonEquals(left[index], right[index]),
        );
  }
  return left == right;
}

int _jsonHash(Object? value) {
  return switch (value) {
    final Map<String, Object?> value => Object.hashAllUnordered(
      value.entries.map(
        (entry) => Object.hash(entry.key, _jsonHash(entry.value)),
      ),
    ),
    final List<Object?> value => Object.hashAll(value.map(_jsonHash)),
    _ => value.hashCode,
  };
}

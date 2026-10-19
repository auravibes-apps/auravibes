typedef McpElicitationFieldValue = Object?;

final class McpElicitationForm({
  required final Map<String, Object?> schema,
  required final Map<String, Map<String, Object?>> properties,
}) {
  static const maxPatternInputLength = 256;

  Map<String, Object?> initialValues() {
    final values = <String, Object?>{};
    for (final entry in properties.entries) {
      final initialValue = _initialValue(entry.key, entry.value);
      if (initialValue.include) values[entry.key] = initialValue.value;
    }

    return values;
  }

  bool isRequired(String name) {
    final requiredNames = schema['required'];

    return requiredNames is List && requiredNames.contains(name);
  }

  ({bool include, Object? value}) _initialValue(
    String name,
    Map<String, Object?> property,
  ) {
    if (property['type'] == 'string' && property['maxLength'] == 0) {
      return (
        include: property.containsKey('default') || isRequired(name),
        value: '',
      );
    }
    if (property.containsKey('default')) {
      return (include: true, value: property['default']);
    }
    if (isRequired(name) && property['type'] == 'boolean') {
      return (include: true, value: false);
    }

    return (include: false, value: null);
  }
}

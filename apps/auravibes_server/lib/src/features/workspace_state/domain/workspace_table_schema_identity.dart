import 'dart:convert';

abstract final class WorkspaceTableSchemaIdentity {
  static bool matches(Map<String, Object?> left, Map<String, Object?> right) =>
      left['labelColumnId'] == right['labelColumnId'] &&
      _columnSignature(left) == _columnSignature(right);

  static String _columnSignature(Map<String, Object?> data) => jsonEncode(
    (data['columns'] as List).cast<Map>().map(_column).toList(),
  );

  static Map<String, Object?> _column(Map column) {
    final values = _defaults(column);
    final keys = values.keys.toList()..sort();

    return {for (final key in keys) key: _value(values[key])};
  }

  static Map<String, Object?> _defaults(Map column) {
    final values = Map<String, Object?>.from(column);
    values['options'] ??= const [];
    values['required'] = false;
    values['unique'] ??= false;
    values['timeZone'] ??= 'UTC';
    if (values['defaultValue'] == null) values.remove('defaultValue');

    return _referenceDefaults(values);
  }

  static Map<String, Object?> _referenceDefaults(Map<String, Object?> values) {
    values['referenceMultiple'] ??= false;
    if (values['targetTableId'] == null) values.remove('targetTableId');
    for (final key in ['dependsOnColumnId', 'targetMatchColumnId']) {
      if (values[key] == null) values.remove(key);
    }

    return values;
  }
}

Object? _value(Object? value) {
  if (value is num) return _number(value);
  if (value is Map) return _map(value);
  if (value is List) return value.map(_value).toList();

  return value;
}

String _number(num value) => value == value.truncateToDouble()
    ? BigInt.from(value).toString()
    : value.toString();

Map<String, Object?> _map(Map value) {
  final keys = value.keys.cast<String>().toList()..sort();

  return {for (final key in keys) key: _value(value[key])};
}

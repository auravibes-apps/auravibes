import 'dart:convert';

abstract final class WorkspaceTableSchemaIdentity {
  static bool matches(Map<String, Object?> left, Map<String, Object?> right) =>
      left['labelColumnId'] == right['labelColumnId'] &&
      _columnSignature(left) == _columnSignature(right);

  static String _columnSignature(Map<String, Object?> data) => jsonEncode(
    (data['columns'] as List).cast<Map>().map(_column).toList(),
  );

  static Map<String, Object?> _column(Map column) {
    final values = Map<String, Object?>.from(column);
    values['options'] ??= const [];
    final keys = values.keys.toList()..sort();

    return {for (final key in keys) key: values[key]};
  }
}

import 'dart:convert';

import 'workspace_table_validation.dart';

abstract final class WorkspaceTableConstraints {
  static Map<String, Object?> defaults(
    Map<String, Object?> schema,
    Map<String, Object?> values,
  ) => {
    for (final column in (schema['columns'] as List).cast<Map>())
      if (column['defaultValue'] != null)
        column['id'] as String: column['defaultValue'],
    ...values,
  };

  static void records(
    Map<String, Object?> schema,
    Iterable<Map<String, Object?>> records,
  ) {
    final seen = <String, Set<String>>{};
    final columns = (schema['columns'] as List).cast<Map>().where(
      (column) => column['unique'] == true,
    );
    for (final values in records) {
      WorkspaceTableValidation.values(schema, values);
      _remember(columns, values, seen);
    }
  }

  static void _remember(
    Iterable<Map> columns,
    Map<String, Object?> values,
    Map<String, Set<String>> seen,
  ) {
    for (final column in columns) {
      final id = column['id'] as String;
      if (!values.containsKey(id)) continue;
      final key = jsonEncode(_comparison(column, values[id]));
      if (!seen.putIfAbsent(id, () => {}).add(key)) {
        throw const FormatException();
      }
    }
  }

  static Object? _comparison(Map column, Object? value) {
    if (column['type'] == 'timestamp' && value is String) {
      return DateTime.tryParse(value)?.toUtc().microsecondsSinceEpoch;
    }

    return _canonical(value);
  }

  static Object? _canonical(Object? value) {
    if (value is num && value == value.truncateToDouble()) {
      return BigInt.from(value).toString();
    }
    if (value is Map) return _map(value);
    if (value is List) return _list(value);

    return value;
  }

  static Object _map(Map value) {
    if (value['amount'] is String && value['currency'] is String) {
      return {
        'amount': _decimal(value['amount'] as String),
        'currency': value['currency'],
      };
    }
    final keys = value.keys.cast<String>().toList()..sort();

    return {for (final key in keys) key: _canonical(value[key])};
  }

  static List<Object?> _list(List values) {
    final entries = values.map(_canonical).toList();
    entries.sort((a, b) => jsonEncode(a).compareTo(jsonEncode(b)));

    return entries;
  }

  static String _decimal(String value) {
    final parts = value.split('.');
    final fraction = parts.length == 2
        ? parts.last.replaceFirst(RegExp(r'0+$'), '')
        : '';
    final whole = parts.first;
    final result = fraction.isEmpty ? whole : '$whole.$fraction';

    return RegExp(r'^-?0(?:\.0*)?$').hasMatch(result) ? '0' : result;
  }
}

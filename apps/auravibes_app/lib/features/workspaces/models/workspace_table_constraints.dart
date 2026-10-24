import 'package:auravibes_app/features/workspaces/models/workspace_column_validation.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:collection/collection.dart';

abstract final class WorkspaceTableConstraints {
  static Map<String, Object?> defaults(
    List<WorkspaceColumn> columns,
    Map<String, Object?> values,
  ) => {
    for (final column in columns)
      if (column.defaultValue != null) column.id: column.defaultValue,
    ...values,
  };

  static void records(
    List<WorkspaceColumn> columns,
    Iterable<WorkspaceRecord> records,
  ) {
    final seen = <String, List<Object?>>{};
    final unique = columns.where((column) => column.isUnique);
    for (final record in records) {
      WorkspaceColumnValidation.values(columns, record.values);
      _remember(unique, record.values, seen);
    }
  }

  static List<WorkspaceRecord> violations(
    List<WorkspaceColumn> columns,
    List<WorkspaceRecord> records,
  ) => records.where((record) => _violates(columns, records, record)).toList();

  static bool same(Object? left, Object? right) =>
      const DeepCollectionEquality.unordered().equals(
        _canonical(left),
        _canonical(right),
      );
  static void _remember(
    Iterable<WorkspaceColumn> columns,
    Map<String, Object?> record,
    Map<String, List<Object?>> seen,
  ) {
    for (final column in columns) {
      if (!record.containsKey(column.id)) continue;
      final values = seen.putIfAbsent(column.id, () => []);
      final value = record[column.id];
      if (values.any((existing) => same(existing, value))) {
        throw const WorkspaceTableException();
      }
      values.add(value);
    }
  }

  static bool _violates(
    List<WorkspaceColumn> columns,
    List<WorkspaceRecord> records,
    WorkspaceRecord record,
  ) {
    if (!WorkspaceColumnValidation.accepts(columns, record.values)) return true;
    for (final column in columns) {
      if (column.isUnique && _duplicate(column.id, record, records)) {
        return true;
      }
    }

    return false;
  }

  static bool _duplicate(
    String id,
    WorkspaceRecord record,
    List<WorkspaceRecord> records,
  ) {
    if (!record.values.containsKey(id)) return false;

    return records.any(
      (other) =>
          other.id != record.id && same(record.values[id], other.values[id]),
    );
  }
}

Object? _canonical(Object? value) {
  if (value is Map &&
      value['amount'] is String &&
      value['currency'] is String) {
    return {
      'amount': _decimal(value['amount'] as String),
      'currency': value['currency'],
    };
  }

  return value;
}

String _decimal(String value) {
  final parts = value.split('.');
  final fraction = parts.length == 2
      ? parts.last.replaceFirst(RegExp(r'0+$'), '')
      : '';
  final whole = parts.firstOrNull ?? '';
  final result = fraction.isEmpty ? whole : '$whole.$fraction';

  return RegExp(r'^-?0(?:\.0*)?$').hasMatch(result) ? '0' : result;
}

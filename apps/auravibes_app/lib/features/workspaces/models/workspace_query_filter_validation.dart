import 'dart:convert';

import 'package:auravibes_app/features/workspaces/models/workspace_column_validation.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';

/// Query operands follow the same value contract as record fields.
abstract final class WorkspaceQueryFilterValidation {
  static bool supports(WorkspaceColumn column) => {
    WorkspaceColumnType.text,
    WorkspaceColumnType.number,
    WorkspaceColumnType.checkbox,
    WorkspaceColumnType.singleSelect,
    WorkspaceColumnType.url,
    WorkspaceColumnType.email,
    WorkspaceColumnType.phone,
    WorkspaceColumnType.dateOnly,
    WorkspaceColumnType.timestamp,
    WorkspaceColumnType.money,
  }.contains(column.type);
  static bool supportsContains(WorkspaceColumn column) => {
    WorkspaceColumnType.text,
    WorkspaceColumnType.email,
    WorkspaceColumnType.url,
    WorkspaceColumnType.phone,
  }.contains(column.type);
  static bool accepts(
    WorkspaceColumn column,
    Object? value, {
    bool contains = false,
  }) => contains
      ? supportsContains(column) && value is String && value.length <= 16384
      : WorkspaceColumnValidation.accepts([column], {column.id: value});
  static Map<String, Object?> parse(
    WorkspaceColumn column,
    String encoded, {
    bool contains = false,
  }) {
    if (contains) {
      if (!accepts(column, encoded, contains: true)) {
        throw const WorkspaceTableException();
      }

      return {column.id: encoded};
    }
    final value = switch (column.type) {
      .number => num.tryParse(encoded),
      .checkbox => switch (encoded) {
        'true' => true,
        'false' => false,
        _ => null,
      },
      .money => _money(encoded),
      _ => encoded,
    };
    WorkspaceColumnValidation.values([column], {column.id: value});

    return {column.id: value};
  }

  static Map<String, dynamic>? _money(String encoded) {
    try {
      final value = jsonDecode(encoded);

      return value is Map<String, dynamic> ? value : null;
    } on FormatException {
      return null;
    }
  }
}

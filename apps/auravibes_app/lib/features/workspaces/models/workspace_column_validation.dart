import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';

abstract final class WorkspaceColumnValidation {
  static void columns(List<WorkspaceColumn> columns, String labelColumnId) {
    if (columns.isEmpty ||
        columns.length > 100 ||
        columns.map((column) => column.id).toSet().length != columns.length ||
        !columns.any(
          (column) => column.id == labelColumnId && column.type == .text,
        )) {
      throw const WorkspaceTableException();
    }
    for (final column in columns) {
      if (column.id.isEmpty ||
          column.name.trim().isEmpty ||
          column.name.length > 200) {
        throw const WorkspaceTableException();
      }
      final selection =
          column.type == .singleSelect || column.type == .multiSelect;
      if (selection
          ? column.options.isEmpty ||
                column.options.length > 100 ||
                column.options.toSet().length != column.options.length ||
                column.options.any(
                  (option) => option.trim().isEmpty || option.length > 200,
                )
          : column.options.isNotEmpty) {
        throw const WorkspaceTableException();
      }
    }
  }

  static void values(
    List<WorkspaceColumn> columns,
    Map<String, Object?> values,
  ) {
    for (final entry in values.entries) {
      final column = columns
          .where((column) => column.id == entry.key)
          .firstOrNull;
      if (column == null || !_valid(column, entry.value)) {
        throw const WorkspaceTableException();
      }
    }
  }

  static bool _valid(WorkspaceColumn column, Object? value) =>
      switch (column.type) {
        .text => value is String && value.length <= 16384,
        .number => value is num && value.isFinite,
        .checkbox => value is bool,
        .singleSelect => value is String && column.options.contains(value),
        .multiSelect =>
          value is List &&
              value.toSet().length == value.length &&
              value.every(
                (entry) => entry is String && column.options.contains(entry),
              ),
        .url => value is String && value.length <= 16384 && _url(value),
        .email =>
          value is String &&
              value.length <= 16384 &&
              RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value),
        .phone =>
          value is String &&
              value.length <= 16384 &&
              RegExp(
                r'^\+?[0-9 ()-]+(?:\s*(?:x|ext\.?)\s*[0-9]+)?$',
                caseSensitive: false,
              ).hasMatch(value) &&
              RegExp('[0-9]').allMatches(value).length >= 3,
      };
  static bool _url(String value) {
    final uri = Uri.tryParse(value);

    return uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty &&
        !value.contains(RegExp(r'\s'));
  }
}

import 'workspace_command.dart';

/// Additional reference authority comes only from verified host creations.
class const WorkspaceReferenceScope(
  final WorkspaceContextSelection selection,
  final List<Map<String, Object?>> created,
) {
  bool tableAllowed(String id) =>
      (selection.kind == 'table' && selection.itemId == id) ||
      created.any((value) => value['kind'] == 'table' && value['id'] == id);

  bool recordAllowed(String tableId, String id) =>
      _selectedRecord(tableId, id) || _createdRecord(tableId, id);

  bool columnAllowed(
    Map<String, Object?> column,
    Map<String, Object?> previous,
  ) {
    if (column['type'] != 'reference') return true;
    final target = column['targetTableId'];
    if (target is! String) return false;
    final retained =
        previous['type'] == 'reference' && previous['targetTableId'] == target;

    return (retained || tableAllowed(target)) &&
        valueAllowed(target, column['defaultValue'], previous['defaultValue']);
  }

  bool valueAllowed(String target, Object? value, Object? previous) {
    final retained = _ReferenceValues.ids(previous).toSet();

    return _ReferenceValues.ids(value)
        .every((id) => retained.contains(id) || recordAllowed(target, id));
  }

  bool valuesAllowed(
    List<Map<String, Object?>> columns,
    Map<String, Object?> values,
    Map<String, Object?> previous,
  ) => columns.every((column) => _valueAllowed(column, values, previous));

  ({Map<String, Object?> values, List<String> restricted}) projectValues(
    List<Map<String, Object?>> columns,
    Map<String, Object?> values,
  ) => _ReferenceProjection.values(this, columns, values);

  Map<String, Object?> readableColumn(Map<String, Object?> column) =>
      _ReferenceProjection.column(this, column);

  bool _selectedRecord(String tableId, String id) =>
      selection.kind == 'table' &&
      selection.itemId == tableId &&
      selection.recordIds.contains(id);

  bool _createdRecord(String tableId, String id) => created.any(
    (value) =>
        value['kind'] == 'record' &&
        value['tableId'] == tableId &&
        value['id'] == id,
  );

  bool _valueAllowed(
    Map<String, Object?> column,
    Map<String, Object?> values,
    Map<String, Object?> previous,
  ) {
    if (column['type'] != 'reference') return true;
    final key = column['id'];
    if (key is! String || !values.containsKey(key)) return true;
    final target = column['targetTableId'];
    final old = _ReferenceValues.ids(previous[key]).toSet();
    final added = _ReferenceValues.ids(values[key])
        .where((id) => !old.contains(id));

    return added.isEmpty ||
        (target is String && added.every((id) => recordAllowed(target, id)));
  }
}

abstract final class _ReferenceValues {
  static Iterable<String> ids(Object? value) => switch (value) {
    final String id when id.isNotEmpty => [id],
    final List<Object?> list => list.whereType<String>(),
    _ => const [],
  };

  static Map<String, Object?> column(
    List<Map<String, Object?>> columns,
    String id,
  ) => columns.where((column) => column['id'] == id).firstOrNull ?? const {};
}

abstract final class _ReferenceProjection {
  static ({Map<String, Object?> values, List<String> restricted}) values(
    WorkspaceReferenceScope scope,
    List<Map<String, Object?>> columns,
    Map<String, Object?> values,
  ) {
    final visible = _select(scope, columns, values);

    return (
      values: visible,
      restricted: values.keys
          .where((key) => !visible.containsKey(key))
          .toList(),
    );
  }

  static Map<String, Object?> _select(
    WorkspaceReferenceScope scope,
    List<Map<String, Object?>> columns,
    Map<String, Object?> values,
  ) => {
    for (final entry in values.entries)
      if (_readable(
        scope,
        _ReferenceValues.column(columns, entry.key),
        entry.value,
      ))
        entry.key: entry.value,
  };

  static Map<String, Object?> column(
    WorkspaceReferenceScope scope,
    Map<String, Object?> column,
  ) {
    final result = {...column}..remove('targetTableId');
    if (column['type'] != 'reference') return result;
    if (!_readable(scope, column, column['defaultValue']))
      result.remove('defaultValue');
    final target = column['targetTableId'];
    if (target is! String || !scope.tableAllowed(target))
      result.remove('targetMatchColumnId');

    return result;
  }

  static bool _readable(
    WorkspaceReferenceScope scope,
    Map<String, Object?> column,
    Object? value,
  ) {
    if (column['type'] != 'reference') return true;
    final target = column['targetTableId'];

    return target is String &&
        _ReferenceValues.ids(value)
            .every((id) => scope.recordAllowed(target, id));
  }
}

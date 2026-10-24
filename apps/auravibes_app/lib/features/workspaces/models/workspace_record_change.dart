import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';

class WorkspaceRecordChange {
  static const maxOperations = 50;

  new({
    required this.table,
    required this.record,
    required Map<String, Object?> values,
  }) : values = _freezeMap(values);
  final WorkspaceTable table;
  final WorkspaceRecord record;
  final Map<String, Object?> values;

  Map<String, Object?> toJson() => {
    'tableId': table.id,
    'schemaRevision': table.schemaRevision,
    'values': values,
  };

  static void validate(List<WorkspaceRecordChange> changes) {
    if (changes.isEmpty ||
        changes.length > maxOperations ||
        !_distinct(changes)) {
      throw const WorkspaceTableException();
    }
    for (final change in changes) {
      change._validate();
    }
  }

  void _validate() {
    if (!table.canEditRecords) {
      throw const WorkspaceTableException(denied: true);
    }
    if (record.id.isEmpty ||
        record.revision < 1 ||
        record.tableId != table.id) {
      throw const WorkspaceTableException();
    }
  }

  static bool _distinct(List<WorkspaceRecordChange> changes) =>
      changes.map((change) => change.record.id).toSet().length ==
      changes.length;
}

Map<String, Object?> _freezeMap(Map<String, Object?> values) =>
    Map.unmodifiable(values.map(_freezeEntry));
MapEntry<String, Object?> _freezeEntry(String key, Object? value) =>
    MapEntry(key, _freeze(value));
Object? _freeze(Object? value) => switch (value) {
  final Map<String, Object?> map => _freezeMap(map),
  final List<Object?> list => List<Object?>.unmodifiable(list.map(_freeze)),
  _ => value,
};

abstract interface class WorkspaceRecordBatchRepository {
  Future<void> apply(
    List<WorkspaceRecordChange> changes, {
    required String requestId,
  });
}

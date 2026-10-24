import 'package:auravibes_app/i18n/locale_keys.dart';

class const WorkspaceTable({
  required final String id,
  required final String name,
  required final String labelColumnId,
  required final List<WorkspaceColumn> columns,
  required final int revision,
  required final int schemaRevision,
  final String? parentId,
  final bool canManage = true,
  final bool canEditRecords = true,
  final bool supportsSharing = false,
}) {
  List<WorkspaceColumn> withColumn(WorkspaceColumn column) => [
    for (final existing in columns)
      if (existing.id == column.id) column else existing,
    if (!columns.any((existing) => existing.id == column.id)) column,
  ];
}

class const WorkspaceTableMember({
  required final String userId,
  required final String label,
  final String? access,
});

abstract interface class WorkspaceTableAccessRepository {
  Future<List<WorkspaceTableMember>> members(String tableId);
  Future<void> setMemberAccess({
    required WorkspaceTable table,
    required String userId,
    required String? access,
  });
}

class const WorkspaceColumn({
  required final String id,
  required final String name,
  final WorkspaceColumnType type = WorkspaceColumnType.text,
  final List<String> options = const [],
  final String timeZone = 'UTC',
}) {
  factory fromJson(Map<String, dynamic> data) => WorkspaceColumn(
    id: data['id'] as String,
    name: data['name'] as String,
    type: WorkspaceColumnType.values.byName(data['type'] as String? ?? 'text'),
    options: _columnOptions(data),
    timeZone: data['timeZone'] as String? ?? 'UTC',
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'options': options,
    'timeZone': timeZone,
  };
}

enum WorkspaceColumnType {
  text,
  number,
  checkbox,
  singleSelect,
  multiSelect,
  url,
  email,
  phone,
  dateOnly,
  timestamp,
  money,
}

class const WorkspaceRecord({
  required final String id,
  required final String tableId,
  required final Map<String, Object?> values,
  required final int revision,
});

class const WorkspaceTableException({
  final bool conflict = false,
  final bool denied = false,
}) implements Exception {
  String get localizationKey {
    if (denied) return LocaleKeys.cloud_errors_permission_denied;

    return conflict
        ? LocaleKeys.cloud_errors_conflict
        : LocaleKeys.workspace_items_invalid_table;
  }

  @override
  String toString() => localizationKey;
}

abstract interface class WorkspaceTableRepository {
  Future<List<WorkspaceTable>> list({String? parentId});
  Future<WorkspaceTable> table(String id);
  Future<WorkspaceTable> create({
    required String name,
    required String labelName,
    String? parentId,
  });
  Future<WorkspaceTable> renameLabel({
    required WorkspaceTable table,
    required String name,
  });
  Future<WorkspaceTable> saveColumn({
    required WorkspaceTable table,
    required WorkspaceColumn column,
  });
  Future<List<WorkspaceRecord>> records(String tableId);
  Future<WorkspaceRecord> record(String tableId, String id);
  Future<WorkspaceRecord> createRecord({
    required WorkspaceTable table,
    required Map<String, Object?> values,
  });
  Future<WorkspaceRecord> updateRecord({
    required WorkspaceTable table,
    required WorkspaceRecord record,
    required Map<String, Object?> values,
  });
}

List<String> _columnOptions(Map<String, dynamic> data) =>
    (data['options'] as List<dynamic>? ?? const []).cast<String>();

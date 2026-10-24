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
  final bool isRequired = false,
  final bool isUnique = false,
  final Object? defaultValue,
  final String timeZone = 'UTC',
  final String? targetTableId,
  final bool referenceMultiple = false,
  final String? dependsOnColumnId,
  final String? targetMatchColumnId,
}) {
  factory fromJson(Map<String, dynamic> data) => _ColumnData(data).build();

  WorkspaceColumn renamed(String value) => WorkspaceColumn(
    id: id,
    name: value,
    type: type,
    options: options,
    isRequired: isRequired,
    isUnique: isUnique,
    defaultValue: defaultValue,
    timeZone: timeZone,
    targetTableId: targetTableId,
    referenceMultiple: referenceMultiple,
    dependsOnColumnId: dependsOnColumnId,
    targetMatchColumnId: targetMatchColumnId,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'options': options,
    'required': isRequired,
    'unique': isUnique,
    if (defaultValue != null) 'defaultValue': defaultValue,
    'timeZone': timeZone,
    'targetTableId': targetTableId,
    'referenceMultiple': referenceMultiple,
    if (dependsOnColumnId != null) 'dependsOnColumnId': dependsOnColumnId,
    if (targetMatchColumnId != null) 'targetMatchColumnId': targetMatchColumnId,
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
  reference,
  attachment,
}

class const WorkspaceRecord({
  required final String id,
  required final String tableId,
  required final Map<String, Object?> values,
  required final int revision,
  final List<String> restrictedReferenceColumns = const [],
});

class const WorkspaceTableException({
  final bool conflict = false,
  final bool incompatibleRelationship = false,
  final bool denied = false,
}) implements Exception {
  String get localizationKey {
    if (denied) return LocaleKeys.cloud_errors_permission_denied;
    if (incompatibleRelationship) {
      return LocaleKeys.workspace_items_reference_incompatible;
    }

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
  Future<WorkspaceTable> updateMetadata({
    required WorkspaceTable table,
    required String name,
    required String? parentId,
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

WorkspaceColumnType _columnType(Map<String, dynamic> data) =>
    WorkspaceColumnType.values.byName(data['type'] as String? ?? 'text');

String _columnTimeZone(Map<String, dynamic> data) =>
    data['timeZone'] as String? ?? 'UTC';

String _columnString(Map<String, dynamic> data, String key) =>
    data[key] as String;
bool _columnFlag(Map<String, dynamic> data, String key) =>
    data[key] as bool? ?? false;

class _ColumnData {
  new(Map<String, Object?> data)
    : _data = data,
      id = _columnString(data, 'id'),
      name = _columnString(data, 'name'),
      type = _columnType(data),
      options = _columnOptions(data),
      required = _columnFlag(data, 'required'),
      unique = _columnFlag(data, 'unique'),
      timeZone = _columnTimeZone(data),
      targetTableId = data['targetTableId'] as String?,
      multiple = _columnFlag(data, 'referenceMultiple'),
      parent = data['dependsOnColumnId'] as String?,
      match = data['targetMatchColumnId'] as String?;
  final String id;
  final String name;
  final WorkspaceColumnType type;
  final List<String> options;
  final bool required;
  final bool unique;
  final String timeZone;
  final String? targetTableId;
  final bool multiple;
  final String? parent;
  final String? match;
  final Map<String, Object?> _data;

  WorkspaceColumn build() => WorkspaceColumn(
    id: id,
    name: name,
    type: type,
    options: options,
    isRequired: required,
    isUnique: unique,
    defaultValue: _data['defaultValue'],
    timeZone: timeZone,
    targetTableId: targetTableId,
    referenceMultiple: multiple,
    dependsOnColumnId: parent,
    targetMatchColumnId: match,
  );
}

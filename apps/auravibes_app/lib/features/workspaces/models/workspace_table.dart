import 'package:auravibes_app/i18n/locale_keys.dart';

class const WorkspaceTable({
  required final String id,
  required final String name,
  required final String labelColumnId,
  required final List<WorkspaceColumn> columns,
  required final int revision,
  required final int schemaRevision,
  final String? parentId,
});

class const WorkspaceColumn({
  required final String id,
  required final String name,
});

class const WorkspaceRecord({
  required final String id,
  required final String tableId,
  required final Map<String, String> values,
  required final int revision,
});

class const WorkspaceTableException({final bool conflict = false})
    implements Exception {
  String get localizationKey => conflict
      ? LocaleKeys.cloud_errors_conflict
      : LocaleKeys.workspace_items_invalid_table;
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
  Future<List<WorkspaceRecord>> records(String tableId);
  Future<WorkspaceRecord> record(String tableId, String id);
  Future<WorkspaceRecord> createRecord({
    required WorkspaceTable table,
    required Map<String, String> values,
  });
  Future<WorkspaceRecord> updateRecord({
    required WorkspaceTable table,
    required WorkspaceRecord record,
    required Map<String, String> values,
  });
}

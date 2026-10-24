import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';

class const WorkspaceRecordQuery({
  final String search = '',
  final String? filterColumnId,
  final String? filterValue,
  final WorkspaceRecordFilterOperator filterOperator =
      WorkspaceRecordFilterOperator.equals,
  final String? sortColumnId,
  final bool descending = false,
  final int offset = 0,
  final int limit = 50,
}) {
  Map<String, Object?> toJson() => {
    'search': search,
    'filterColumnId': filterColumnId,
    'filterValue': filterValue,
    'filterOperator': filterOperator.name,
    'sortColumnId': sortColumnId,
    'descending': descending,
    'offset': offset,
    'limit': limit,
  };
}

enum WorkspaceRecordFilterOperator { equals, contains }

class const WorkspaceRecordPage({
  required final List<WorkspaceRecord> records,
  required final bool hasMore,
});

abstract interface class WorkspaceRecordQueryRepository {
  Future<WorkspaceRecordPage> query(String tableId, WorkspaceRecordQuery query);
}

extension WorkspaceRecordQueryChanges on WorkspaceRecordQuery {
  WorkspaceRecordQuery change({
    String? search,
    String? sort,
    bool? descending,
    int? offset,
  }) => WorkspaceRecordQuery(
    search: search ?? this.search,
    filterColumnId: filterColumnId,
    filterValue: filterValue,
    filterOperator: filterOperator,
    sortColumnId: sort ?? sortColumnId,
    descending: descending ?? this.descending,
    offset: offset ?? 0,
    limit: limit,
  );
  WorkspaceRecordQuery filter(
    String? column,
    String value, {
    WorkspaceRecordFilterOperator operator =
        WorkspaceRecordFilterOperator.equals,
  }) => WorkspaceRecordQuery(
    search: search,
    filterColumnId: column,
    filterValue: value,
    filterOperator: operator,
    sortColumnId: sortColumnId,
    descending: descending,
    limit: limit,
  );
}

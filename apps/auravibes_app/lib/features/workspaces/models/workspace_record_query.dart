import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

@immutable
class const WorkspaceRecordQuery({
  final String search = '',
  final String? filterColumnId,
  final String? filterValue,
  final WorkspaceRecordFilterOperator filterOperator =
      WorkspaceRecordFilterOperator.equals,
  final String? sortColumnId,
  final bool descending = false,
  final int offset = 0,
  final int limit = _defaultPageSize,
}) {
  factory fromJson(Map<String, dynamic> value) => _withFilter(
    _baseQuery(value),
    value,
  ).change(offset: value['offset'] as int? ?? 0);

  @override
  int get hashCode => _identity.hashCode;

  ({
    String search,
    String? filterColumnId,
    String? filterValue,
    WorkspaceRecordFilterOperator filterOperator,
    String? sortColumnId,
    bool descending,
    int offset,
    int limit,
  })
  get _identity => (
    search: search,
    filterColumnId: filterColumnId,
    filterValue: filterValue,
    filterOperator: filterOperator,
    sortColumnId: sortColumnId,
    descending: descending,
    offset: offset,
    limit: limit,
  );

  @override
  bool operator ==(Object other) =>
      other is WorkspaceRecordQuery && _identity == other._identity;

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
  Future<Map<String, Object?>> summarize(
    String tableId,
    WorkspaceRecordQuery query,
    List<String> columnIds,
  );
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

const _defaultPageSize = 50;
WorkspaceRecordQuery _baseQuery(Map<String, dynamic> value) => .new(
  search: value['search'] as String? ?? '',
  sortColumnId: value['sortColumnId'] as String?,
  descending: value['descending'] as bool? ?? false,
  limit: value['limit'] as int? ?? _defaultPageSize,
);
WorkspaceRecordFilterOperator _filterOperator(Map<String, dynamic> value) =>
    WorkspaceRecordFilterOperator.values.byName(
      value['filterOperator'] as String? ?? 'equals',
    );

WorkspaceRecordQuery _withFilter(
  WorkspaceRecordQuery query,
  Map<String, dynamic> value,
) {
  final id = value['filterColumnId'] as String?;
  if (id == null) return query;

  return query.filter(
    id,
    value['filterValue'] as String? ?? '',
    operator: _filterOperator(value),
  );
}

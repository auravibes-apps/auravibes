import 'package:auravibes_app/features/workspaces/models/workspace_record_query.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';

class const QueryWorkspaceRecordsUsecase(
  final WorkspaceRecordQueryRepository repository,
) {
  Future<WorkspaceRecordPage> call(String tableId, WorkspaceRecordQuery query) {
    if (!_validPage(query) ||
        query.search.length > _maxTextLength ||
        (query.filterValue?.length ?? 0) > _maxFilterLength) {
      throw const WorkspaceTableException();
    }

    return repository.query(tableId, query);
  }
}

const _maxPageSize = 100;
const _maxOffset = 100000;
const _maxTextLength = 200;

// Includes the existing 16384-character field bound and money JSON envelope.
const _maxFilterLength = 16448;

bool _validPage(WorkspaceRecordQuery query) =>
    query.limit >= 1 &&
    query.limit <= _maxPageSize &&
    query.offset >= 0 &&
    query.offset <= _maxOffset;

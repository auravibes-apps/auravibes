import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'repositories/workspace_state_repository.dart';
import 'workspace_table_access.dart';

class const WorkspaceTablePageReader(
  final WorkspaceStateRepository _repository,
  final Session _session,
  final WorkspaceMember _member,
) {
  static const _batchSize = 100;

  Future<WorkspaceResourcePage> page(
    WorkspaceResourcePageRequest selector,
  ) async {
    final rows = <WorkspaceResource>[];
    var cursor = selector.afterResourceId;
    while (true) {
      final candidates = await _candidates(selector.resourceKind, cursor);
      await _appendVisible(rows, candidates, selector.limit);
      if (_complete(rows, candidates, selector.limit)) break;
      cursor = candidates.last.resourceId;
    }

    return _page(selector, rows);
  }

  bool _complete(
    List<WorkspaceResource> rows,
    List<WorkspaceResource> candidates,
    int limit,
  ) => rows.length > limit || candidates.length < _batchSize;

  Future<List<WorkspaceResource>> _candidates(
    WorkspaceResourceKind kind,
    String? cursor,
  ) => _repository.readPage(
    _session,
    workspaceId: _member.workspaceId,
    kind: kind,
    limit: _batchSize,
    afterResourceId: cursor,
  );

  Future<void> _appendVisible(
    List<WorkspaceResource> rows,
    List<WorkspaceResource> candidates,
    int limit,
  ) async {
    for (final row in candidates) {
      final visible = await const WorkspaceTableAccess().visible(
        _session,
        _member,
        row,
      );
      if (visible != null) rows.add(visible);
      if (rows.length > limit) break;
    }
  }
}

WorkspaceResourcePage _page(
  WorkspaceResourcePageRequest selector,
  List<WorkspaceResource> rows,
) {
  final hasMore = rows.length > selector.limit;
  if (hasMore) rows.removeLast();

  return WorkspaceResourcePage(
    resourceKind: selector.resourceKind,
    resources: rows,
    nextResourceId: hasMore ? rows.last.resourceId : null,
  );
}

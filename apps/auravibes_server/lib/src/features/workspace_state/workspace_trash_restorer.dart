import 'dart:convert';

import '../../generated/protocol.dart';
import 'workspace_trash_access.dart';
import 'workspace_trash_store.dart';
import 'workspace_trash_validation.dart';

class WorkspaceTrashRestorer(
  final WorkspaceTrashStore store,
  final CloudWorkspace workspace,
  final String userId,
) {
  bool _movedToRoot = false;
  Future<String> restore(
    WorkspaceTrashBatch batch,
    List<WorkspaceResource> rows,
  ) async {
    final now = DateTime.now().toUtc();
    final restored = _restored(trashMembers(batch), rows, now);
    await store.commit(workspace, userId, restored);
    final result = await _validate(restored);
    await store.markRestored(batch, now, result);
    return result;
  }

  List<WorkspaceResource> _restored(
    List<Map<String, dynamic>> members,
    List<WorkspaceResource> rows,
    DateTime now,
  ) {
    final available = _availableFolders(rows, members);
    return members
        .map(
          (member) =>
              _restoreRow(_current(rows, member), member, available, now),
        )
        .toList();
  }

  WorkspaceResource _restoreRow(
    WorkspaceResource row,
    Map<String, dynamic> member,
    Set<String> available,
    DateTime now,
  ) {
    final data = trashData(row);
    if (row.resourceKind != .tableRecord) {
      data['parentId'] = _parent(member['parentId'] as String?, available);
    }
    return row.copyWith(
      data: jsonEncode(data),
      deletedAt: null,
      revision: row.revision + 1,
      updatedAt: now,
    );
  }

  String? _parent(String? id, Set<String> available) {
    if (id == null || available.contains(id)) return id;
    _movedToRoot = true;
    return null;
  }

  Future<String> _validate(List<WorkspaceResource> restored) async {
    final validator = WorkspaceTrashValidation(await store.resources());
    validator.tables(_tableIds(restored));
    return jsonEncode({
      'movedToRoot': _movedToRoot,
      'unresolvedDependencies': validator.dependencies(restored),
    });
  }
}

Set<String> _availableFolders(
  List<WorkspaceResource> rows,
  List<Map<String, dynamic>> members,
) => {
  for (final row in rows)
    if (row.resourceKind == .folder && row.deletedAt == null) row.resourceId,
  for (final member in members)
    if (member['kind'] == 'folder') member['id'] as String,
};
WorkspaceResource _current(
  List<WorkspaceResource> rows,
  Map<String, dynamic> member,
) {
  final current = trashMemberResource(rows, member);
  if (current == null ||
      current.deletedAt == null ||
      current.revision != (member['revision'] as int) + 1) {
    trashConflict();
  }
  return current;
}

Set<String> _tableIds(List<WorkspaceResource> rows) => {
  for (final row in rows)
    if (row.resourceKind == .table) row.resourceId,
  for (final row in rows)
    if (row.resourceKind == .tableRecord) trashData(row)['tableId'] as String,
};

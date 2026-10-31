import 'package:auravibes_engine/src/workspace_context_selection.dart';

/// The resource kind named by a workspace command, if its target is typed.
String? workspaceTargetKind(Map<String, dynamic> arguments) =>
    switch (arguments['action']) {
      'read' when arguments['tableId'] != null => 'table',
      'read'
          when const {
            'folder',
            'table',
            'view',
            'file',
            'workflow',
          }.contains(arguments['kind']) =>
        arguments['kind'] as String,
      'createFolder' || 'createTable' || 'renameFolder' => 'folder',
      'renameTable' ||
      'saveColumn' ||
      'createView' ||
      'createRecord' ||
      'updateRecord' => 'table',
      'saveView' => 'view',
      _ => null,
    };

class const WorkspaceCreatedContext(
  final WorkspaceContextSelection selection,
  final List<Map<String, Object?>> created,
) {
  WorkspaceContextSelection resolve(
    Map<String, dynamic> arguments, {
    String? targetKind,
  }) {
    final owned = _target(arguments, targetKind);
    final id = owned?['id'] as String? ?? selection.itemId;

    return _selection(owned, id);
  }

  WorkspaceContextSelection _selection(Map<String, Object?>? owned, String id) {
    return WorkspaceContextSelection(
      workspaceId: selection.workspaceId,
      conversationId: selection.conversationId,
      itemId: id,
      kind: _kind(owned),
      parentId: _parent(owned),
      recordIds: _records(id, owned == null),
    );
  }

  String _kind(Map<String, Object?>? owned) =>
      owned?['kind'] as String? ?? selection.kind;

  String? _parent(Map<String, Object?>? owned) =>
      owned?['parentId'] as String? ?? selection.parentId;

  Map<String, Object?>? _target(
    Map<String, dynamic> arguments,
    String? targetKind,
  ) {
    final target =
        arguments['tableId'] ?? arguments['parentId'] ?? arguments['id'];
    final kind = targetKind ?? workspaceTargetKind(arguments);
    if (kind == null && selection.kind == 'directory') return null;
    final matches = created.where(
      (resource) =>
          resource['id'] == target &&
          (kind == null || resource['kind'] == kind),
    );

    return matches.singleOrNull;
  }

  List<String> _records(String id, bool selected) => <String>{
    if (selected) ...selection.recordIds,
    for (final resource in created)
      if (resource['kind'] == 'record' && resource['tableId'] == id)
        if (resource['id'] case final String recordId) recordId,
  }.toList();
}

/// Projects a created item into the target used by legacy workspace commands.
WorkspaceContextSelection workspaceCreatedContext(
  WorkspaceContextSelection selection,
  List<Map<String, Object?>> created,
  Map<String, dynamic> arguments, {
  String? targetKind,
}) {
  return WorkspaceCreatedContext(
    selection,
    created,
  ).resolve(arguments, targetKind: targetKind);
}

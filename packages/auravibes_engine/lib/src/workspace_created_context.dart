import 'package:auravibes_engine/src/workspace_context_selection.dart';

class const WorkspaceCreatedContext(
  final WorkspaceContextSelection selection,
  final List<Map<String, Object?>> created,
) {
  WorkspaceContextSelection resolve(Map<String, dynamic> arguments) {
    final owned = _target(arguments);
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

  Map<String, Object?>? _target(Map<String, dynamic> arguments) {
    final target =
        arguments['tableId'] ?? arguments['parentId'] ?? arguments['id'];

    return created.where((resource) => resource['id'] == target).firstOrNull;
  }

  List<String> _records(String id, bool selected) => <String>{
    if (selected) ...selection.recordIds,
    for (final resource in created)
      if (resource['kind'] == 'record' && resource['tableId'] == id)
        if (resource['id'] case final String recordId) recordId,
  }.toList();
}

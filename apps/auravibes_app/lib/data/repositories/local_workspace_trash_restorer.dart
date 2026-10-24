import 'package:auravibes_app/data/repositories/local_trash_node.dart';
import 'package:auravibes_app/data/repositories/local_workspace_trash_reader.dart';
import 'package:auravibes_app/data/repositories/local_workspace_trash_store.dart';
import 'package:auravibes_app/data/repositories/local_workspace_trash_validation.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';

class LocalWorkspaceTrashRestorer(final LocalWorkspaceTrashStore store) {
  bool _movedToRoot = false;
  Future<WorkspaceTrashRestoration> restore(String id) async {
    await store.requireLocal();
    final batch = await store.batch(id);
    final members = localTrashMembers(batch);
    final nodes = await store.nodes();
    await _restoreMembers(members, nodes);
    final unresolved = await _validate(members);
    await store.deleteBatch(id);

    return .new(movedToRoot: _movedToRoot, unresolvedDependencies: unresolved);
  }

  Future<void> _restoreMembers(
    List<LocalTrashNode> members,
    List<LocalTrashNode> nodes,
  ) async {
    final available = _availableFolders(nodes, members);
    for (final original in members) {
      final current = _current(original, nodes);
      await store.tombstone(
        current,
        null,
        parentId: _parent(original, available),
      );
    }
  }

  String? _parent(LocalTrashNode original, Set<String> available) {
    final parent = original.parentId;
    if (parent == null || available.contains(parent)) return parent;
    _movedToRoot = true;

    return null;
  }

  Future<bool> _validate(List<LocalTrashNode> members) async {
    final validation = LocalWorkspaceTrashValidation(
      store.database,
      store.workspaceId,
    );
    final invalid = await validation.tables(_tableIds(members));

    return invalid || await validation.views(members);
  }
}

Set<String> _availableFolders(
  List<LocalTrashNode> nodes,
  List<LocalTrashNode> members,
) => {
  for (final node in nodes)
    if (node.kind == .folder && !node.deleted) node.id,
  for (final node in members)
    if (node.kind == .folder) node.id,
};
LocalTrashNode _current(LocalTrashNode original, List<LocalTrashNode> nodes) {
  final current = _findNode(original, nodes);
  if (current == null ||
      !current.deleted ||
      current.revision != original.revision + 1) {
    throw const WorkspaceTableException(conflict: true);
  }

  return current;
}

Set<String> _tableIds(List<LocalTrashNode> members) => {
  for (final node in members)
    if (node.kind == .table) node.id,
  for (final node in members)
    if (node.kind == .record) _tableId(node),
};
String _tableId(LocalTrashNode node) =>
    node.tableId ?? (throw const WorkspaceTableException());

LocalTrashNode? _findNode(
  LocalTrashNode original,
  List<LocalTrashNode> nodes,
) => nodes
    .where((node) => node.kind == original.kind && node.id == original.id)
    .firstOrNull;

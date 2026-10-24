import 'dart:convert';

import 'package:auravibes_app/data/repositories/local_trash_node.dart';
import 'package:auravibes_app/data/repositories/local_workspace_trash_store.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_table.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_trash_target.dart';
import 'package:crypto/crypto.dart';

class const LocalWorkspaceTrashSelection(
  final LocalTrashNode root,
  final List<LocalTrashNode> members,
) {
  String get token {
    final rows = members.map((node) => jsonEncode(node.toJson())).toList()
      ..sort();

    return sha256.convert(utf8.encode(jsonEncode(rows))).toString();
  }

  static Future<LocalWorkspaceTrashSelection> load(
    LocalWorkspaceTrashStore store,
    WorkspaceTrashTarget target,
  ) async {
    await store.requireLocal();
    final nodes = await store.nodes();
    final root = _root(nodes, target);

    return .new(root, _members(root, nodes));
  }

  WorkspaceTrashBatch impact(WorkspaceTrashTarget target, {String id = ''}) =>
      .new(
        id: id,
        target: target,
        name: root.name,
        affectedCount: members.length,
        planToken: token,
      );
  Future<void> tombstone(LocalWorkspaceTrashStore store) async {
    final now = DateTime.now().toUtc();
    for (final node in members) {
      await store.tombstone(node, now, parentId: node.parentId);
    }
  }
}

LocalTrashNode _root(List<LocalTrashNode> nodes, WorkspaceTrashTarget target) {
  final root = nodes.where((node) => _matches(node, target)).firstOrNull;
  if (root == null ||
      (root.kind == .record && root.tableId != target.tableId)) {
    throw const WorkspaceTableException();
  }
  if (root.revision != target.revision) {
    throw const WorkspaceTableException(conflict: true);
  }

  return root;
}

bool _matches(LocalTrashNode node, WorkspaceTrashTarget target) =>
    !node.deleted && node.kind == target.kind && node.id == target.id;
List<LocalTrashNode> _members(LocalTrashNode root, List<LocalTrashNode> nodes) {
  final selected = _items(root, nodes);
  _appendRecords(selected, nodes);

  return selected;
}

List<LocalTrashNode> _items(LocalTrashNode root, List<LocalTrashNode> nodes) {
  final selected = <LocalTrashNode>[root];
  final folders = <String>{if (root.kind == .folder) root.id};
  var changed = true;
  while (changed) {
    changed = _appendChildren(selected, folders, nodes);
  }

  return selected;
}

void _appendRecords(List<LocalTrashNode> selected, List<LocalTrashNode> nodes) {
  final tables = selected
      .where((node) => node.kind == .table)
      .map((node) => node.id)
      .toSet();
  selected.addAll(nodes.where((node) => _recordInTables(node, tables)));
}

bool _recordInTables(LocalTrashNode node, Set<String> tables) =>
    !node.deleted && node.kind == .record && tables.contains(node.tableId);
bool _appendChildren(
  List<LocalTrashNode> selected,
  Set<String> folders,
  List<LocalTrashNode> nodes,
) {
  var added = false;
  for (final node in nodes) {
    if (!_child(node, folders) || selected.contains(node)) continue;
    selected.add(node);
    if (node.kind == .folder) {
      final _ = folders.add(node.id);
    }
    added = true;
  }

  return added;
}

bool _child(LocalTrashNode node, Set<String> folders) =>
    !node.deleted && folders.contains(node.parentId);
